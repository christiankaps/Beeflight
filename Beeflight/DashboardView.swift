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
            ScrollView(showsIndicators: false) {
                // UTC Time & Date (full width)
                UTCTimeCardView(latitude: locationManager.latitude, longitude: locationManager.longitude, themeColors: theme)
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
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "safari")
                                .font(.headline)
                                .foregroundStyle(theme.cardAccent)
                            Text("sensorHeading")
                                .font(.caption)
                                .foregroundStyle(theme.cardAccent)
                        }

                        ZStack {
                            Text(SensorFormatters.formatHeadingDegrees(locationManager.heading))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .fontDesign(.monospaced)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .foregroundStyle(theme.valueText)

                            HStack {
                                Image(systemName: "location.north.fill")
                                    .font(.caption)
                                    .foregroundStyle(theme.cardAccent)
                                    .rotationEffect(.degrees(-locationManager.heading))
                                Spacer()
                                Text(SensorFormatters.cardinalDirection(for: locationManager.heading))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(theme.cardAccent)
                            }
                        }

                        Text("unitDegrees")
                            .font(.caption2)
                            .foregroundStyle(theme.unitText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Course (Ground Track)
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                .font(.headline)
                                .foregroundStyle(theme.cardAccent)
                            Text("sensorCourse")
                                .font(.caption)
                                .foregroundStyle(theme.cardAccent)
                        }

                        ZStack {
                            Text(locationManager.course >= 0 ? SensorFormatters.formatHeadingDegrees(locationManager.course) : "--")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .fontDesign(.monospaced)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .foregroundStyle(theme.valueText)

                            HStack {
                                if locationManager.course >= 0 {
                                    Image(systemName: "location.north.fill")
                                        .font(.caption)
                                        .foregroundStyle(theme.cardAccent)
                                        .rotationEffect(.degrees(locationManager.course))
                                }
                                Spacer()
                                if locationManager.course >= 0 {
                                    Text(SensorFormatters.cardinalDirection(for: locationManager.course))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(theme.cardAccent)
                                }
                            }
                        }

                        Text("unitDegrees")
                            .font(.caption2)
                            .foregroundStyle(theme.unitText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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
                    SensorCardView(
                        title: "sensorSatellites",
                        value: gpsQualityPercentage,
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
