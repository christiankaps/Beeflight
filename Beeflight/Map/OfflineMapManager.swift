import Foundation
import Observation

/// Manages the offline tile packs: discovering what's installed, downloading
/// a new whole-globe pack, and deleting it.
///
/// State model:
/// - `bundledStore`    — the `MBTilesStore` for the bundled base pack, if any.
/// - `downloadedStore` — the `MBTilesStore` for the currently downloaded pack,
///                       if any. At most one exists at a time.
/// - `installedTier`   — the highest tier currently available on disk.
/// - `downloadState`   — idle / downloading(progress) / failed(message).
@Observable
final class OfflineMapManager: NSObject {
    enum DownloadState: Equatable {
        case idle
        case downloading(tier: MapTileTier, progress: Double, receivedBytes: Int64, totalBytes: Int64)
        case failed(message: String)
    }

    private(set) var bundledStore: MBTilesStore?
    private(set) var downloadedStore: MBTilesStore?
    private(set) var downloadState: DownloadState = .idle

    /// Bytes on disk for the downloaded pack (0 if none).
    private(set) var downloadedBytes: Int64 = 0

    /// Tier represented by `downloadedStore`, if any.
    private(set) var downloadedTier: MapTileTier?

    /// Highest tier available on disk right now.
    var installedTier: MapTileTier {
        downloadedTier ?? .builtIn
    }

    private let fileManager: FileManager
    private let session: URLSession
    private var activeTask: URLSessionDownloadTask?
    private var downloadingTier: MapTileTier?

    override init() {
        self.fileManager = .default
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.waitsForConnectivity = false
        // The delegate queue must be serial for our progress callbacks.
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: opQueue)
        super.init()
        loadInstalledPacks()
    }

    // MARK: - Discovery

    /// Inspects the bundle and Application Support directory, opening any
    /// `.mbtiles` that are present. Safe to call at any time.
    func loadInstalledPacks() {
        // Bundled base pack
        if let url = Bundle.main.url(forResource: "world-z0-z3", withExtension: "mbtiles") {
            self.bundledStore = MBTilesStore(url: url)
        } else {
            self.bundledStore = nil
        }

        // Downloaded pack (at most one). Reset first so that any failure
        // to locate the maps directory leaves a consistent "nothing
        // downloaded" state rather than whatever we had before.
        self.downloadedStore = nil
        self.downloadedTier = nil
        self.downloadedBytes = 0

        guard let dir = Self.mapsDirectory(fileManager: fileManager) else { return }
        let candidates: [(MapTileTier, URL)] = MapTileTier.allCases
            .filter { $0.isDownloadable }
            .map { ($0, dir.appendingPathComponent($0.downloadFilename)) }
        if let (tier, url) = candidates.first(where: { fileManager.fileExists(atPath: $0.1.path) }) {
            self.downloadedStore = MBTilesStore(url: url)
            self.downloadedTier = tier
            self.downloadedBytes = Self.fileSize(at: url, fileManager: fileManager)
        }
    }

    // MARK: - Download

    /// Starts a download for the given tier. No-ops if already downloading or
    /// if the tier isn't downloadable. Replaces any existing downloaded pack
    /// on success.
    func startDownload(tier: MapTileTier) {
        guard tier.isDownloadable else { return }
        guard case .idle = downloadState else { return }
        guard let url = tier.downloadURL else {
            downloadState = .failed(message: "No download URL configured.")
            return
        }

        downloadingTier = tier
        downloadState = .downloading(tier: tier, progress: 0, receivedBytes: 0, totalBytes: tier.approximateBytes)

        // The temp file provided to the completion handler is deleted as
        // soon as that handler returns. We move it to its destination
        // synchronously on the URLSession's delegate queue, then hand the
        // result off to the main actor for state updates.
        let fm = self.fileManager
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            let moveResult: Result<URL, Error>? = {
                if let error { return .failure(error) }
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    return .failure(NSError(domain: "OfflineMapManager", code: http.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]))
                }
                guard let tempURL, let dir = Self.mapsDirectory(fileManager: fm) else {
                    return .failure(NSError(domain: "OfflineMapManager", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No destination directory."]))
                }
                do {
                    // Enforce at most one downloaded pack on disk.
                    for other in MapTileTier.allCases where other.isDownloadable {
                        let u = dir.appendingPathComponent(other.downloadFilename)
                        if fm.fileExists(atPath: u.path) { try fm.removeItem(at: u) }
                    }
                    let dest = dir.appendingPathComponent(tier.downloadFilename)
                    try fm.moveItem(at: tempURL, to: dest)
                    return .success(dest)
                } catch {
                    return .failure(error)
                }
            }()
            Task { @MainActor [weak self] in
                self?.finishDownload(tier: tier, result: moveResult)
            }
        }
        // Observe progress via KVO on the task's progress object.
        observeProgress(of: task, tier: tier)
        self.activeTask = task
        task.resume()
    }

    /// Cancels any in-flight download.
    func cancelDownload() {
        activeTask?.cancel()
        activeTask = nil
        downloadingTier = nil
        if case .downloading = downloadState {
            downloadState = .idle
        }
    }

    /// Deletes the downloaded pack, if any. The bundled base pack remains.
    func deleteDownloadedPack() {
        cancelDownload()
        // Close the store before removing the file (SQLite holds the fd).
        downloadedStore = nil
        downloadedTier = nil
        downloadedBytes = 0
        if let dir = Self.mapsDirectory(fileManager: fileManager) {
            for tier in MapTileTier.allCases where tier.isDownloadable {
                let url = dir.appendingPathComponent(tier.downloadFilename)
                try? fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: - Internal

    private var progressObservation: NSKeyValueObservation?

    private func observeProgress(of task: URLSessionDownloadTask, tier: MapTileTier) {
        progressObservation?.invalidate()
        progressObservation = task.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard case .downloading = self.downloadState else { return }
                let received = progress.completedUnitCount
                let total = progress.totalUnitCount > 0 ? progress.totalUnitCount : tier.approximateBytes
                self.downloadState = .downloading(
                    tier: tier,
                    progress: progress.fractionCompleted.isFinite ? progress.fractionCompleted : 0,
                    receivedBytes: received,
                    totalBytes: total
                )
            }
        }
    }

    private func finishDownload(tier: MapTileTier, result: Result<URL, Error>?) {
        defer {
            activeTask = nil
            downloadingTier = nil
            progressObservation?.invalidate()
            progressObservation = nil
        }

        guard let result else {
            downloadState = .failed(message: "Unknown download error.")
            return
        }

        switch result {
        case .failure(let error):
            let code = (error as NSError).code
            if code == NSURLErrorCancelled {
                downloadState = .idle
            } else {
                downloadState = .failed(message: error.localizedDescription)
            }
        case .success(let dest):
            // Release any prior store before opening the new one.
            downloadedStore = nil
            guard let newStore = MBTilesStore(url: dest) else {
                try? fileManager.removeItem(at: dest)
                downloadState = .failed(message: "Downloaded file is not a valid MBTiles archive.")
                return
            }
            downloadedStore = newStore
            downloadedTier = tier
            downloadedBytes = Self.fileSize(at: dest, fileManager: fileManager)
            downloadState = .idle
        }
    }

    // MARK: - Paths

    private static func mapsDirectory(fileManager: FileManager) -> URL? {
        guard let support = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        let dir = support.appendingPathComponent("Maps", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func fileSize(at url: URL, fileManager: FileManager) -> Int64 {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else { return 0 }
        return size.int64Value
    }
}
