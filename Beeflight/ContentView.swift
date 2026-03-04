import SwiftUI

struct ContentView: View {
    @State private var settings = AppSettings()
    @State private var locationManager: LocationManager
    @State private var altimeterManager = AltimeterManager()
    @State private var motionManager = MotionManager()
    @State private var sensorsStarted = false

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
    }
}

#Preview {
    ContentView()
}
