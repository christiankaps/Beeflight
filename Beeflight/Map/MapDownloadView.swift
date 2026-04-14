import SwiftUI

/// Sheet for picking and downloading a whole-globe tile pack. Presents the
/// available tiers with size estimates, shows download progress, and allows
/// deleting the currently installed downloaded pack.
struct MapDownloadView: View {
    var manager: OfflineMapManager

    var body: some View {
        List {
            Section {
                ForEach(MapTileTier.allCases) { tier in
                    TierRow(tier: tier, manager: manager)
                }
            } header: {
                Text("mapDownloadHeader")
            } footer: {
                Text("mapDownloadFooter")
            }

            if let tier = manager.downloadedTier {
                Section {
                    HStack {
                        Label {
                            Text(LocalizedStringKey(tier.localizationKey))
                        } icon: {
                            Image(systemName: "externaldrive.fill")
                        }
                        Spacer()
                        Text(Self.formatBytes(manager.downloadedBytes))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Button(role: .destructive) {
                        manager.deleteDownloadedPack()
                    } label: {
                        Label("mapDeleteDownloaded", systemImage: "trash")
                    }
                } header: {
                    Text("mapInstalledHeader")
                }
            }

            if case .failed(let message) = manager.downloadState {
                Section {
                    Label {
                        Text(message)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("mapErrorHeader")
                }
            }
        }
        .navigationTitle("mapDownloadTitle")
        .navigationBarTitleDisplayMode(.inline)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let fmt = ByteCountFormatter()
        fmt.allowedUnits = [.useMB, .useGB]
        fmt.countStyle = .file
        return fmt.string(fromByteCount: bytes)
    }
}

/// One row per `MapTileTier`. Shows state (installed, downloading, or
/// available) and the primary action for that state.
private struct TierRow: View {
    let tier: MapTileTier
    var manager: OfflineMapManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label {
                    Text(LocalizedStringKey(tier.localizationKey))
                } icon: {
                    Image(systemName: icon)
                }
                Spacer()
                Text(sizeLabel)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .font(.footnote)
            }

            if case let .downloading(t, progress, received, total) = manager.downloadState, t == tier {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                    HStack {
                        Text(progressLabel(received: received, total: total))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("mapDownloadCancel") {
                            manager.cancelDownload()
                        }
                        .font(.caption)
                    }
                }
            } else {
                actionRow
            }
        }
        .padding(.vertical, 2)
    }

    private var icon: String {
        switch tier {
        case .builtIn: return "shippingbox.fill"
        case .standard: return "map"
        case .detailed: return "map.fill"
        }
    }

    private var isInstalled: Bool {
        switch tier {
        case .builtIn: return manager.bundledStore != nil
        case .standard, .detailed: return manager.downloadedTier == tier
        }
    }

    private var sizeLabel: String {
        if isInstalled, tier.isDownloadable {
            return MapDownloadView.formatBytes(manager.downloadedBytes)
        }
        return MapDownloadView.formatBytes(tier.approximateBytes)
    }

    @ViewBuilder
    private var actionRow: some View {
        switch tier {
        case .builtIn:
            HStack(spacing: 6) {
                Image(systemName: manager.bundledStore != nil ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(manager.bundledStore != nil ? .green : .orange)
                Text(manager.bundledStore != nil ? "mapBuiltInInstalled" : "mapBuiltInMissing")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .standard, .detailed:
            if isInstalled {
                Label("mapTierInstalled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.footnote)
            } else if case .downloading = manager.downloadState {
                // another tier is downloading → dim
                Text("mapDownloadBusy")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if !tier.hasConfiguredDownloadURL {
                Label("mapDownloadUnavailable", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    manager.startDownload(tier: tier)
                } label: {
                    Label("mapDownloadAction", systemImage: "arrow.down.circle")
                        .font(.footnote)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private func progressLabel(received: Int64, total: Int64) -> String {
        let r = MapDownloadView.formatBytes(received)
        let t = MapDownloadView.formatBytes(total)
        return "\(r) / \(t)"
    }
}
