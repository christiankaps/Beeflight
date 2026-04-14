import Foundation

/// A whole-globe tile pack detail level.
///
/// The app ships with `builtIn` bundled. The user may optionally download
/// one of the other tiers to replace the currently installed pack.
/// At most one downloaded pack exists on disk at a time.
enum MapTileTier: String, CaseIterable, Identifiable, Sendable {
    /// Bundled in the app; always available; continent-level detail.
    case builtIn
    /// Global, downloadable; large-town-level detail (~z0–z6).
    case standard
    /// Global, downloadable; town-level detail (~z0–z8).
    case detailed

    var id: String { rawValue }

    var minZoom: Int { 0 }

    var maxZoom: Int {
        switch self {
        case .builtIn: return 3
        case .standard: return 6
        case .detailed: return 8
        }
    }

    /// Order-of-magnitude on-disk size in bytes, used for pre-download UI.
    /// Real size is reported from the file system once present.
    var approximateBytes: Int64 {
        switch self {
        case .builtIn: return     2 * 1024 * 1024         //   ~2 MB
        case .standard: return  200 * 1024 * 1024         // ~200 MB
        case .detailed: return 2_000 * 1024 * 1024        //   ~2 GB
        }
    }

    /// Whether this tier is downloaded (vs. bundled).
    var isDownloadable: Bool {
        switch self {
        case .builtIn: return false
        case .standard, .detailed: return true
        }
    }

    /// Basename used for the downloaded `.mbtiles` file under
    /// `Application Support/Maps/`.
    var downloadFilename: String {
        switch self {
        case .builtIn: return "world-z0-z3.mbtiles"
        case .standard: return "world-z0-z6.mbtiles"
        case .detailed: return "world-z0-z8.mbtiles"
        }
    }

    /// The HTTPS URL from which the pack is downloaded.
    ///
    /// These are deliberate placeholders. Before shipping, replace with a
    /// CDN-hosted `.mbtiles` URL under a license compatible with
    /// redistribution (e.g. OSM ODbL raster tiles with attribution).
    var downloadURL: URL? {
        switch self {
        case .builtIn:
            return nil
        case .standard:
            return URL(string: "https://tiles.example.invalid/world-z0-z6.mbtiles")
        case .detailed:
            return URL(string: "https://tiles.example.invalid/world-z0-z8.mbtiles")
        }
    }

    /// True when the tier has a real (non-placeholder) download URL
    /// configured. The UI should disable the Download action otherwise.
    var hasConfiguredDownloadURL: Bool {
        guard let url = downloadURL else { return false }
        let host = url.host ?? ""
        return !host.contains("example.invalid")
    }

    /// Stable key for localized display labels.
    var localizationKey: String {
        switch self {
        case .builtIn: return "mapTierBuiltIn"
        case .standard: return "mapTierStandard"
        case .detailed: return "mapTierDetailed"
        }
    }
}
