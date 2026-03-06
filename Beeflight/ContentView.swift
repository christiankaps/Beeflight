import SwiftUI
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
            UIDevice.current.isBatteryMonitoringEnabled = true
            locationManager.requestAuthorization()
            locationManager.startUpdates()
            altimeterManager.startUpdates()
            motionManager.startUpdates()
            updateRateForBatteryState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            updateRateForBatteryState()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSProcessInfoPowerStateDidChange)) { _ in
            updateRateForBatteryState()
        }
        .onChange(of: settings.autoUpdateRate) {
            updateRateForBatteryState()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                checkPermissions()
                updateRateForBatteryState()
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

    private func updateRateForBatteryState() {
        guard settings.autoUpdateRate else { return }

        let newRate: UpdateRate
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            newRate = .low
        } else {
            let batteryState = UIDevice.current.batteryState
            switch batteryState {
            case .charging, .full:
                newRate = .maximum
            default:
                newRate = .medium
            }
        }

        if settings.updateRate != newRate {
            settings.updateRate = newRate
            locationManager.applySettings(settings)
        }
    }

    private func checkPermissions() {
        let locationDenied = locationManager.authorizationStatus == .denied
            || locationManager.authorizationStatus == .restricted
        let motionDenied = CMMotionActivityManager.authorizationStatus() == .denied
            || CMMotionActivityManager.authorizationStatus() == .restricted

        if locationDenied || motionDenied {
            permissionAlertMessage = "permissionAlertMessage"
            showPermissionAlert = true
        }
    }
}

#Preview {
    ContentView()
}
