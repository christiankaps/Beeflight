import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        NavigationView {
            Group {
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    permissionRequestView
                case .denied, .restricted:
                    permissionDeniedView
                case .authorizedWhenInUse, .authorizedAlways:
                    gpsDataView
                @unknown default:
                    permissionRequestView
                }
            }
            .navigationTitle("Beeflight GPS")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }

    // MARK: - Subviews

    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            Text("Location Access Required")
                .font(.title2)
                .bold()
            Text("Beeflight uses your device's GPS to display location data. No internet connection is required.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button(action: { locationManager.requestPermission() }) {
                Label("Allow Location Access", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding()
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 72))
                .foregroundColor(.red)
            Text("Location Access Denied")
                .font(.title2)
                .bold()
            Text("Please enable location access for Beeflight in Settings to view GPS data.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button(action: openSettings) {
                Label("Open Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding()
    }

    private var gpsDataView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let error = locationManager.locationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    GPSDataCard(
                        title: "Latitude",
                        value: locationManager.latitude.map { formatCoordinate($0) } ?? "—",
                        unit: "°",
                        icon: "arrow.up.arrow.down",
                        color: .blue
                    )
                    GPSDataCard(
                        title: "Longitude",
                        value: locationManager.longitude.map { formatCoordinate($0) } ?? "—",
                        unit: "°",
                        icon: "arrow.left.arrow.right",
                        color: .green
                    )
                    GPSDataCard(
                        title: "Altitude",
                        value: locationManager.altitude.map { String(format: "%.1f", $0) } ?? "—",
                        unit: "m",
                        icon: "mountain.2",
                        color: .brown
                    )
                    GPSDataCard(
                        title: "Speed",
                        value: locationManager.speed.map { String(format: "%.1f", $0 * 3.6) } ?? "—",
                        unit: "km/h",
                        icon: "speedometer",
                        color: .orange
                    )
                    GPSDataCard(
                        title: "Heading",
                        value: locationManager.heading.map { String(format: "%.1f", $0) } ?? "—",
                        unit: "°",
                        icon: "safari",
                        color: .purple
                    )
                    GPSDataCard(
                        title: "Accuracy",
                        value: locationManager.horizontalAccuracy.map { String(format: "%.1f", $0) } ?? "—",
                        unit: "m",
                        icon: "scope",
                        color: .teal
                    )
                }
                .padding(.horizontal)

                if locationManager.latitude == nil && locationManager.locationError == nil {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Acquiring GPS signal…")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Helpers

    private func formatCoordinate(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - GPSDataCard

struct GPSDataCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .bold()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
