import SwiftUI

/// The full-screen offline map destination, reachable from the dashboard
/// toolbar. Combines the `MapView`, a follow-mode control, an attribution
/// overlay, and a toolbar entry that opens the download sheet.
struct OfflineMapScreen: View {
    @Bindable var settings: AppSettings
    var manager: OfflineMapManager
    @State private var showDownloadSheet = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MapView(manager: manager, followMode: settings.mapFollowMode)
                .ignoresSafeArea(edges: .bottom)

            MapAttributionView()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .overlay(alignment: .topTrailing) {
            FollowModeButton(mode: $settings.mapFollowMode)
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .navigationTitle("mapTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDownloadSheet = true
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .accessibilityLabel(Text("mapDownloadButton"))
            }
        }
        .sheet(isPresented: $showDownloadSheet) {
            NavigationStack {
                MapDownloadView(manager: manager)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("mapDownloadDone") { showDownloadSheet = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            manager.loadInstalledPacks()
        }
    }
}

/// Cycles through Off → Follow → Follow-with-heading.
private struct FollowModeButton: View {
    @Binding var mode: MapFollowMode

    var body: some View {
        Button {
            mode = mode.next
        } label: {
            Image(systemName: mode.sfSymbol)
                .font(.title3)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel(Text("mapFollowButton"))
    }
}
