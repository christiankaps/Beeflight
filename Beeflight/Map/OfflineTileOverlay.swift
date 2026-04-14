import Foundation
import MapKit

/// Tile overlay that serves tiles from one or two `MBTilesStore` instances:
/// a downloadable "primary" pack (if present) and the bundled "base" pack as
/// fallback. Tile lookups try primary first, then base. Returning 1x1
/// transparent pixel for misses keeps `MKMapView` from drawing Apple's base
/// map (we've set `canReplaceMapContent = true`) and avoids any network.
final class OfflineTileOverlay: MKTileOverlay {
    /// Serves the higher-detail downloaded pack. May be nil.
    var primary: MBTilesStore?
    /// Serves the bundled baseline pack. May be nil if the bundle resource
    /// is missing (development builds without the binary tileset).
    var base: MBTilesStore?

    init(primary: MBTilesStore?, base: MBTilesStore?) {
        self.primary = primary
        self.base = base
        // tileSize 256 matches standard web-map tile dimensions.
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = true
        self.tileSize = CGSize(width: 256, height: 256)
        // Max zoom the highest-detail store reports. MapKit will request
        // tiles at or below this; above, it upsamples.
        self.maximumZ = max(primary?.maxZoom ?? 0, base?.maxZoom ?? 0)
        self.minimumZ = 0
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // Not used: we override loadTile() directly. Return a harmless file
        // URL to satisfy the API contract.
        URL(fileURLWithPath: "/dev/null")
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let z = path.z
        let x = path.x
        let y = path.y

        if let data = primary?.tileData(z: z, x: x, y: y) {
            result(data, nil)
            return
        }
        if let data = base?.tileData(z: z, x: x, y: y) {
            result(data, nil)
            return
        }
        result(Self.blankTile, nil)
    }

    /// A cached 1x1 fully-transparent PNG used when no tile is available.
    /// MKMapView handles upscaling these to 256x256 without artifacts.
    private static let blankTile: Data = {
        // Minimal 1x1 transparent PNG (67 bytes).
        // Generated once, embedded as a literal to avoid a bundle asset.
        let bytes: [UInt8] = [
            0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,
            0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,
            0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,
            0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,
            0x89,0x00,0x00,0x00,0x0D,0x49,0x44,0x41,
            0x54,0x78,0x9C,0x63,0x00,0x01,0x00,0x00,
            0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,
            0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,
            0x42,0x60,0x82
        ]
        return Data(bytes)
    }()
}
