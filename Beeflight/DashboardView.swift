import SwiftUI
import UIKit

struct DashboardView: View {
    var locationManager: LocationManager
    var altimeterManager: AltimeterManager
    var motionManager: MotionManager
    @Bindable var settings: AppSettings
    @State private var orientationOffset: Double = 0.0
    @State private var hasTriggeredThemeSwitch = false
    @State private var pullOverscroll: CGFloat = 0
    @State private var cachedCountryName: String?
    @State private var cachedCountryLat: Double = .nan
    @State private var cachedCountryLon: Double = .nan

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var speedUnitKey: LocalizedStringKey {
        switch settings.unitSystem {
        case .metric: return "unitKph"
        case .imperial: return "unitMph"
        case .aviation: return "unitKnots"
        }
    }

    private var altitudeUnitKey: LocalizedStringKey {
        switch settings.unitSystem {
        case .metric: return "unitMeters"
        case .imperial, .aviation: return "unitFeet"
        }
    }

    private var climbUnitKey: LocalizedStringKey {
        switch settings.unitSystem {
        case .metric: return "unitMps"
        case .imperial, .aviation: return "unitFtMin"
        }
    }

    private var pressureUnitKey: LocalizedStringKey {
        switch settings.unitSystem {
        case .metric, .aviation: return "unitHpa"
        case .imperial: return "unitInHg"
        }
    }

    var body: some View {
        let theme = settings.themeColors

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // UTC Time & Date (full width)
                    UTCTimeCardView(latitude: locationManager.latitude, longitude: locationManager.longitude, themeColors: theme)

                    // GPS Position (full width)
                    PositionCardView(latitude: locationManager.latitude, longitude: locationManager.longitude, countryName: cachedCountryName, themeColors: theme)

                    LazyVGrid(columns: columns, spacing: 12) {
                        // Altitude
                        SensorCardView(
                            title: "sensorAltitude",
                            value: SensorFormatters.formatAltitude(locationManager.altitude, unitSystem: settings.unitSystem),
                            unit: altitudeUnitKey,
                            icon: "mountain.2",
                            themeColors: theme
                        )

                        // Barometric Pressure
                        SensorCardView(
                            title: "sensorPressure",
                            value: altimeterManager.isAvailable ? SensorFormatters.formatPressure(altimeterManager.pressureHpa, unitSystem: settings.unitSystem) : "--",
                            unit: pressureUnitKey,
                            icon: "barometer",
                            themeColors: theme
                        )

                        // Speed
                        SensorCardView(
                            title: "sensorSpeed",
                            value: SensorFormatters.formatSpeed(locationManager.speedKph, unitSystem: settings.unitSystem),
                            unit: speedUnitKey,
                            icon: "speedometer",
                            themeColors: theme
                        )

                        // Climbing Speed
                        SensorCardView(
                            title: "sensorClimbingSpeed",
                            value: altimeterManager.isAvailable ? SensorFormatters.formatClimbingSpeed(altimeterManager.climbingSpeed, unitSystem: settings.unitSystem) : "--",
                            unit: climbUnitKey,
                            icon: "arrow.up.arrow.down",
                            themeColors: theme
                        )

                        // Heading (Compass)
                        CompassCardView(
                            title: "sensorHeading",
                            degrees: locationManager.heading,
                            arrowRotation: -locationManager.heading + orientationOffset,
                            icon: "safari",
                            isValid: true,
                            themeColors: theme
                        )

                        // Course (Ground Track)
                        let courseValid = locationManager.course >= 0
                        CompassCardView(
                            title: "sensorCourse",
                            degrees: locationManager.course,
                            arrowRotation: courseValid ? locationManager.course - locationManager.heading + orientationOffset : 0,
                            icon: "arrow.triangle.turn.up.right.diamond",
                            isValid: courseValid,
                            themeColors: theme
                        )

                        // G-Force
                        SensorCardView(
                            title: "sensorGForce",
                            value: SensorFormatters.formatGForce(motionManager.gForce),
                            unit: "unitG",
                            icon: "gauge.with.dots.needle.33percent",
                            themeColors: theme
                        )

                        // GPS Signal Quality
                        SensorCardView(
                            title: "sensorSatellites",
                            value: gpsQualityPercentage,
                            unit: "unitSatellites",
                            icon: "antenna.radiowaves.left.and.right",
                            themeColors: theme
                        )
                    }
                }
                .padding()
            }
            .overlay(alignment: .top) {
                Image(systemName: hasTriggeredThemeSwitch ? "checkmark.circle.fill" : "paintpalette.fill")
                    .font(.title3)
                    .foregroundStyle(theme.tint)
                    .opacity(pullOverscroll > 20 ? min(1, Double(pullOverscroll - 20) / 60) : 0)
                    .offset(y: max(0, pullOverscroll - 40))
                    .allowsHitTesting(false)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                -(geo.contentOffset.y + geo.contentInsets.top)
            } action: { _, overscroll in
                pullOverscroll = max(0, overscroll)
                let threshold: CGFloat = 80
                if overscroll > threshold && !hasTriggeredThemeSwitch {
                    hasTriggeredThemeSwitch = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        settings.colorTheme = settings.colorTheme.next
                    }
                }
                if overscroll < 10 && hasTriggeredThemeSwitch {
                    hasTriggeredThemeSwitch = false
                }
            }
            .navigationTitle("dashboardTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(settings: settings) {
                            locationManager.applySettings(settings)
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .tint(settings.themeColors.tint)
        .onAppear {
            updateOrientationOffset()
            updateCountryIfNeeded()
        }
        .onChange(of: locationManager.latitude) { updateCountryIfNeeded() }
        .onChange(of: locationManager.longitude) { updateCountryIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientationOffset()
        }
    }

    /// Degrees to add to arrow rotations to compensate for interface rotation.
    /// CoreLocation heading is always relative to the physical top edge (short side),
    /// but SwiftUI rotationEffect uses the screen coordinate system which rotates with the UI.
    private func updateOrientationOffset() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        switch scene.interfaceOrientation {
        case .landscapeLeft:
            orientationOffset = 90
        case .landscapeRight:
            orientationOffset = -90
        case .portraitUpsideDown:
            orientationOffset = 180
        default:
            orientationOffset = 0
        }
    }

    /// Re-detect the country only when the position has moved significantly (~11 km).
    private func updateCountryIfNeeded() {
        let lat = locationManager.latitude
        let lon = locationManager.longitude
        if abs(lat - cachedCountryLat) < 0.1 && abs(lon - cachedCountryLon) < 0.1 {
            return
        }
        cachedCountryLat = lat
        cachedCountryLon = lon
        if let country = CountryDetector.country(at: lat, longitude: lon) {
            cachedCountryName = CountryDetector.localizedCountryName(for: country)
        } else {
            cachedCountryName = nil
        }
    }

    /// GPS quality as a percentage string
    private var gpsQualityPercentage: String {
        let accuracy = locationManager.horizontalAccuracy
        if accuracy < 0 { return "0%" }
        if accuracy <= 5 { return "100%" }
        if accuracy <= 10 { return "75%" }
        if accuracy <= 25 { return "50%" }
        return "25%"
    }
}

#Preview {
    DashboardView(
        locationManager: LocationManager(),
        altimeterManager: AltimeterManager(),
        motionManager: MotionManager(),
        settings: AppSettings()
    )
}
