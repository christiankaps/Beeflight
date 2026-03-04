import SwiftUI

struct DashboardView: View {
    var locationManager: LocationManager
    var altimeterManager: AltimeterManager
    var motionManager: MotionManager
    @Bindable var settings: AppSettings

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let theme = settings.themeColors

        NavigationStack {
            ScrollView {
                // UTC Time & Date (full width)
                UTCTimeCardView(themeColors: theme)
                    .padding(.horizontal)
                    .padding(.top)

                LazyVGrid(columns: columns, spacing: 12) {
                    // GPS Position
                    SensorCardView(
                        title: "sensorLatitude",
                        value: SensorFormatters.formatCoordinate(locationManager.latitude),
                        unit: "unitDegrees",
                        icon: "location",
                        themeColors: theme
                    )

                    SensorCardView(
                        title: "sensorLongitude",
                        value: SensorFormatters.formatCoordinate(locationManager.longitude),
                        unit: "unitDegrees",
                        icon: "location",
                        themeColors: theme
                    )

                    // Speed
                    SensorCardView(
                        title: "sensorSpeed",
                        value: SensorFormatters.formatSpeed(locationManager.speedKph),
                        unit: "unitKph",
                        icon: "speedometer",
                        themeColors: theme
                    )

                    // Altitude
                    SensorCardView(
                        title: "sensorAltitude",
                        value: SensorFormatters.formatAltitude(locationManager.altitude),
                        unit: "unitMeters",
                        icon: "mountain.2",
                        themeColors: theme
                    )

                    // Climbing Speed
                    SensorCardView(
                        title: "sensorClimbingSpeed",
                        value: SensorFormatters.formatClimbingSpeed(locationManager.climbingSpeed),
                        unit: "unitMps",
                        icon: "arrow.up.arrow.down",
                        themeColors: theme
                    )

                    // Heading (Compass)
                    SensorCardView(
                        title: "sensorHeading",
                        value: SensorFormatters.formatHeading(locationManager.heading),
                        unit: "unitDegrees",
                        icon: "safari",
                        themeColors: theme
                    )

                    // Course (Ground Track)
                    SensorCardView(
                        title: "sensorCourse",
                        value: SensorFormatters.formatHeading(locationManager.course >= 0 ? locationManager.course : 0),
                        unit: "unitDegrees",
                        icon: "arrow.triangle.turn.up.right.diamond",
                        themeColors: theme
                    )

                    // Barometric Pressure
                    SensorCardView(
                        title: "sensorPressure",
                        value: SensorFormatters.formatPressure(altimeterManager.pressureHpa),
                        unit: "unitHpa",
                        icon: "barometer",
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
                        value: gpsQualityLabel,
                        unit: "unitSatellites",
                        icon: "antenna.radiowaves.left.and.right",
                        themeColors: theme
                    )
                }
                .padding()
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
    }

    /// GPS quality estimate based on horizontal accuracy
    private var gpsQualityLabel: String {
        let accuracy = locationManager.horizontalAccuracy
        if accuracy < 0 {
            return String(localized: "gpsNoSignal")
        } else if accuracy <= 5 {
            return String(localized: "gpsExcellent")
        } else if accuracy <= 10 {
            return String(localized: "gpsGood")
        } else if accuracy <= 25 {
            return String(localized: "gpsFair")
        } else {
            return String(localized: "gpsPoor")
        }
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
