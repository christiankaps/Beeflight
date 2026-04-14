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

enum MapFollowMode: String, CaseIterable, Identifiable {
    case off = "off"
    case follow = "follow"
    case followWithHeading = "followWithHeading"

    var id: String { rawValue }

    /// Next state for a single-button cycle.
    var next: MapFollowMode {
        switch self {
        case .off: return .follow
        case .follow: return .followWithHeading
        case .followWithHeading: return .off
        }
    }

    var sfSymbol: String {
        switch self {
        case .off: return "location"
        case .follow: return "location.fill"
        case .followWithHeading: return "location.north.line.fill"
        }
    }
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
    private static let autoUpdateRateKey = "autoUpdateRate"
    private static let lockPortraitKey = "lockPortrait"
    private static let mapFollowModeKey = "mapFollowMode"

    var autoUpdateRate: Bool {
        didSet {
            UserDefaults.standard.set(autoUpdateRate, forKey: Self.autoUpdateRateKey)
        }
    }

    var lockPortrait: Bool {
        didSet {
            UserDefaults.standard.set(lockPortrait, forKey: Self.lockPortraitKey)
        }
    }

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
            themeColors = colorTheme.colors
        }
    }

    var unitSystem: UnitSystem {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: Self.unitSystemKey)
        }
    }

    var mapFollowMode: MapFollowMode {
        didSet {
            UserDefaults.standard.set(mapFollowMode.rawValue, forKey: Self.mapFollowModeKey)
        }
    }

    private(set) var themeColors: ThemeColors

    init() {
        if UserDefaults.standard.object(forKey: Self.autoUpdateRateKey) != nil {
            autoUpdateRate = UserDefaults.standard.bool(forKey: Self.autoUpdateRateKey)
        } else {
            autoUpdateRate = true
        }

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

        let resolvedTheme: ColorTheme
        if let stored = UserDefaults.standard.string(forKey: Self.colorThemeKey),
           let theme = ColorTheme(rawValue: stored) {
            resolvedTheme = theme
        } else {
            resolvedTheme = .bee
        }
        colorTheme = resolvedTheme
        themeColors = resolvedTheme.colors

        if let stored = UserDefaults.standard.string(forKey: Self.unitSystemKey),
           let unit = UnitSystem(rawValue: stored) {
            unitSystem = unit
        } else {
            unitSystem = .metric
        }

        lockPortrait = UserDefaults.standard.bool(forKey: Self.lockPortraitKey)

        if let stored = UserDefaults.standard.string(forKey: Self.mapFollowModeKey),
           let mode = MapFollowMode(rawValue: stored) {
            mapFollowMode = mode
        } else {
            mapFollowMode = .follow
        }
    }
}
