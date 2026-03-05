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
                        value: SensorFormatters.formatSpeed(locationManager.speedKph, unitSystem: settings.unitSystem),
                        unit: speedUnitKey,
                        icon: "speedometer",
                        themeColors: theme
                    )

                    // Altitude
                    SensorCardView(
                        title: "sensorAltitude",
                        value: SensorFormatters.formatAltitude(locationManager.altitude, unitSystem: settings.unitSystem),
                        unit: altitudeUnitKey,
                        icon: "mountain.2",
                        themeColors: theme
                    )

                    // Climbing Speed
                    SensorCardView(
                        title: "sensorClimbingSpeed",
                        value: SensorFormatters.formatClimbingSpeed(altimeterManager.climbingSpeed, unitSystem: settings.unitSystem),
                        unit: climbUnitKey,
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
                        value: locationManager.course >= 0 ? SensorFormatters.formatHeading(locationManager.course) : "--",
                        unit: "unitDegrees",
                        icon: "arrow.triangle.turn.up.right.diamond",
                        themeColors: theme
                    )

                    // Barometric Pressure
                    SensorCardView(
                        title: "sensorPressure",
                        value: SensorFormatters.formatPressure(altimeterManager.pressureHpa, unitSystem: settings.unitSystem),
                        unit: pressureUnitKey,
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
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.headline)
                                .foregroundStyle(theme.cardAccent)
                            Text("sensorSatellites")
                                .font(.caption)
                                .foregroundStyle(theme.cardAccent)
                        }

                        Text(gpsQualityPercentage)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .fontDesign(.monospaced)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(theme.valueText)

                        ProgressView(value: gpsQualityProgress)
                            .tint(theme.cardAccent)

                        Text("unitSatellites")
                            .font(.caption2)
                            .foregroundStyle(theme.unitText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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

    /// GPS quality as a percentage string
    private var gpsQualityPercentage: String {
        let pct = Int(gpsQualityProgress * 100)
        return "\(pct)%"
    }

    /// GPS quality as a 0–1 progress value
    private var gpsQualityProgress: Double {
        let accuracy = locationManager.horizontalAccuracy
        if accuracy < 0 { return 0.0 }
        if accuracy <= 5 { return 1.0 }
        if accuracy <= 10 { return 0.75 }
        if accuracy <= 25 { return 0.5 }
        return 0.25
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
