import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var onRateChanged: () -> Void

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.autoUpdateRate) {
                    Label("settingsAutoUpdateRate", systemImage: "bolt.batteryblock")
                }
                .accessibilityIdentifier("autoUpdateRateToggle")

                Picker(selection: $settings.updateRate) {
                    ForEach(UpdateRate.allCases) { rate in
                        VStack(alignment: .leading) {
                            Text(rate.labelKey)
                            Text(rate.descriptionKey)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(rate)
                    }
                } label: {
                    Label("settingsUpdateRate", systemImage: "gauge.with.dots.needle.33percent")
                }
                .pickerStyle(.navigationLink)
                .disabled(settings.autoUpdateRate)
                .onChange(of: settings.updateRate) {
                    onRateChanged()
                }
            } header: {
                Text("settingsSectionSensors")
            }

            Section {
                Picker(selection: $settings.unitSystem) {
                    ForEach(UnitSystem.allCases) { unit in
                        Text(unit.labelKey)
                            .tag(unit)
                    }
                } label: {
                    Label("settingsUnitSystem", systemImage: "ruler")
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("settingsSectionUnits")
            }

            Section {
                Toggle(isOn: $settings.lockPortrait) {
                    Label("settingsLockPortrait", systemImage: "lock.rotation")
                }

                Picker(selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.labelKey)
                            .tag(mode)
                    }
                } label: {
                    Label("settingsAppearance", systemImage: "circle.lefthalf.filled")
                }
                .pickerStyle(.navigationLink)

                Picker(selection: $settings.colorTheme) {
                    ForEach(ColorTheme.allCases) { theme in
                        HStack(spacing: 6) {
                            Text(theme.labelKey)
                            Spacer()
                            ForEach(Array(theme.swatchColors.enumerated()), id: \.offset) { _, color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .tag(theme)
                    }
                } label: {
                    Label("settingsColorTheme", systemImage: "paintpalette")
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("settingsSectionAppearance")
            }

            Section {
                Link(destination: URL(string: "https://www.naturalearthdata.com")!) {
                    HStack {
                        Label("creditsNaturalEarth", systemImage: "globe")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("settingsSectionCredits")
            } footer: {
                Text("creditsNaturalEarthFooter")
            }
        }
        .navigationTitle("settingsTitle")
        .tint(settings.themeColors.tint)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .id(settings.colorTheme)
    }
}

// MARK: - Localized labels for UpdateRate

extension UpdateRate {
    var labelKey: LocalizedStringKey {
        switch self {
        case .maximum: return "rateMaximum"
        case .high: return "rateHigh"
        case .medium: return "rateMedium"
        case .low: return "rateLow"
        }
    }

    var descriptionKey: LocalizedStringKey {
        switch self {
        case .maximum: return "rateMaximumDesc"
        case .high: return "rateHighDesc"
        case .medium: return "rateMediumDesc"
        case .low: return "rateLowDesc"
        }
    }
}

extension AppearanceMode {
    var labelKey: LocalizedStringKey {
        switch self {
        case .system: return "appearanceSystem"
        case .light: return "appearanceLight"
        case .dark: return "appearanceDark"
        }
    }
}

extension UnitSystem {
    var labelKey: LocalizedStringKey {
        switch self {
        case .metric: return "unitMetric"
        case .imperial: return "unitImperial"
        case .aviation: return "unitAviation"
        }
    }
}

extension ColorTheme {
    var labelKey: LocalizedStringKey {
        switch self {
        case .bee: return "themeBee"
        case .lava: return "themeLava"
        case .ocean: return "themeOcean"
        case .forest: return "themeForest"
        case .slate: return "themeSlate"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: AppSettings(), onRateChanged: {})
    }
}
