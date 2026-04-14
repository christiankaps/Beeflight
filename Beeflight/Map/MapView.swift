import SwiftUI
import MapKit

/// SwiftUI wrapper around `MKMapView` rendering tiles from the
/// `OfflineMapManager`'s currently installed packs. The wrapper is
/// deliberately thin: it only reinstalls the tile overlay when the pack set
/// changes, and forwards user-tracking mode changes.
struct MapView: UIViewRepresentable {
    var manager: OfflineMapManager
    var followMode: MapFollowMode

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false
        mapView.pointOfInterestFilter = .excludingAll
        installOverlay(on: mapView, context: context)
        apply(followMode: followMode, to: mapView, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Reinstall overlay if the manager's stores changed identity.
        let stores = StoreIdentity(primary: manager.downloadedStore, base: manager.bundledStore)
        if context.coordinator.lastStores != stores {
            installOverlay(on: mapView, context: context)
            context.coordinator.lastStores = stores
        }
        apply(followMode: followMode, to: mapView, animated: true)
    }

    // MARK: - Overlay installation

    private func installOverlay(on mapView: MKMapView, context: Context) {
        // Remove any previous offline overlay.
        let existing = mapView.overlays.compactMap { $0 as? OfflineTileOverlay }
        if !existing.isEmpty {
            mapView.removeOverlays(existing)
        }

        let overlay = OfflineTileOverlay(
            primary: manager.downloadedStore,
            base: manager.bundledStore
        )
        context.coordinator.overlay = overlay
        // .aboveLabels replaces any Apple base map content.
        mapView.addOverlay(overlay, level: .aboveLabels)
    }

    private func apply(followMode: MapFollowMode, to mapView: MKMapView, animated: Bool) {
        let desired: MKUserTrackingMode = {
            switch followMode {
            case .off: return .none
            case .follow: return .follow
            case .followWithHeading: return .followWithHeading
            }
        }()
        if mapView.userTrackingMode != desired {
            mapView.setUserTrackingMode(desired, animated: animated)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var overlay: OfflineTileOverlay?
        var lastStores: StoreIdentity = StoreIdentity(primary: nil, base: nil)

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? OfflineTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tile)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    /// Identity value used to detect when the overlay needs to be rebuilt.
    /// Two stores compare equal only if they're the same instance.
    struct StoreIdentity: Equatable {
        let primaryID: ObjectIdentifier?
        let baseID: ObjectIdentifier?

        init(primary: MBTilesStore?, base: MBTilesStore?) {
            self.primaryID = primary.map { ObjectIdentifier($0) }
            self.baseID = base.map { ObjectIdentifier($0) }
        }
    }
}
