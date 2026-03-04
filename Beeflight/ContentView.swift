import SwiftUI

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var altimeterManager = AltimeterManager()
    @State private var settings = AppSettings()

    var body: some View {
        DashboardView(
            locationManager: locationManager,
            altimeterManager: altimeterManager,
            settings: settings
        )
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .onAppear {
            locationManager.applySettings(settings)
            locationManager.requestAuthorization()
            locationManager.startUpdates()
            altimeterManager.startUpdates()
        }
    }

    func applyCurrentSettings() {
        locationManager.applySettings(settings)
    }
}

#Preview {
    ContentView()
}
