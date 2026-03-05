import SwiftUI
import CoreLocation
import CoreMotion

struct ContentView: View {
    @State private var settings = AppSettings()
    @State private var locationManager: LocationManager
    @State private var altimeterManager = AltimeterManager()
    @State private var motionManager = MotionManager()
    @State private var sensorsStarted = false
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage: LocalizedStringKey = ""
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let s = AppSettings()
        let lm = LocationManager()
        lm.applySettings(s)
        _settings = State(initialValue: s)
        _locationManager = State(initialValue: lm)
    }

    var body: some View {
        DashboardView(
            locationManager: locationManager,
            altimeterManager: altimeterManager,
            motionManager: motionManager,
            settings: settings
        )
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .onAppear {
            guard !sensorsStarted else { return }
            sensorsStarted = true
            locationManager.requestAuthorization()
            locationManager.startUpdates()
            altimeterManager.startUpdates()
            motionManager.startUpdates()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                checkPermissions()
            }
        }
        .alert("permissionAlertTitle", isPresented: $showPermissionAlert) {
            Button("permissionOpenSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("permissionDismiss", role: .cancel) {}
        } message: {
            Text(permissionAlertMessage)
        }
    }

    private func checkPermissions() {
        var denied: [LocalizedStringKey] = []

        let locationStatus = locationManager.authorizationStatus
        if locationStatus == .denied || locationStatus == .restricted {
            denied.append("permissionLocation")
        }

        let motionStatus = CMMotionActivityManager.authorizationStatus()
        if motionStatus == .denied || motionStatus == .restricted {
            denied.append("permissionMotion")
        }

        if !denied.isEmpty {
            permissionAlertMessage = "permissionAlertMessage"
            showPermissionAlert = true
        }
    }
}

#Preview {
    ContentView()
}
