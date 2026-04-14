import SwiftUI

/// Required attribution for OpenStreetMap-derived raster tiles.
struct MapAttributionView: View {
    var body: some View {
        Text("© OpenStreetMap")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel(Text("mapAttribution"))
    }
}
