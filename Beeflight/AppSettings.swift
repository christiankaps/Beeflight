import Foundation
import SwiftUI
import Observation

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric = "metric"
    case imperial = "imperial"
    case aviation = "aviation"

    var id: String { rawValue }
}

enum UpdateRate: String, CaseIterable, Identifiable {
    case maximum = "maximum"
    case high = "high"
    case medium = "medium"
    case low = "low"

    var id: String { rawValue }

    /// Distance filter in meters for CLLocationManager
    var distanceFilter: Double {
        switch self {
        case .maximum: return -1 // kCLDistanceFilterNone
        case .high: return 2
        case .medium: return 5
        case .low: return 10
        }
    }

    /// Heading filter in degrees for CLLocationManager
    var headingFilter: Double {
        switch self {
        case .maximum: return -1 // kCLHeadingFilterNone
        case .high: return 1
        case .medium: return 3
        case .low: return 5
        }
    }
}

@Observable
final class AppSettings {
    private static let updateRateKey = "updateRate"
    private static let appearanceModeKey = "appearanceMode"
    private static let colorThemeKey = "colorTheme"
    private static let unitSystemKey = "unitSystem"

    var updateRate: UpdateRate {
        didSet {
            UserDefaults.standard.set(updateRate.rawValue, forKey: Self.updateRateKey)
        }
    }

    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.appearanceModeKey)
        }
    }

    var colorTheme: ColorTheme {
        didSet {
            UserDefaults.standard.set(colorTheme.rawValue, forKey: Self.colorThemeKey)
        }
    }

    var unitSystem: UnitSystem {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: Self.unitSystemKey)
        }
    }

    var themeColors: ThemeColors {
        colorTheme.colors
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.updateRateKey),
           let rate = UpdateRate(rawValue: stored) {
            updateRate = rate
        } else {
            updateRate = .high
        }

        if let stored = UserDefaults.standard.string(forKey: Self.appearanceModeKey),
           let mode = AppearanceMode(rawValue: stored) {
            appearanceMode = mode
        } else {
            appearanceMode = .system
        }

        if let stored = UserDefaults.standard.string(forKey: Self.colorThemeKey),
           let theme = ColorTheme(rawValue: stored) {
            colorTheme = theme
        } else {
            colorTheme = .bee
        }

        if let stored = UserDefaults.standard.string(forKey: Self.unitSystemKey),
           let unit = UnitSystem(rawValue: stored) {
            unitSystem = unit
        } else {
            unitSystem = .metric
        }
    }
}
