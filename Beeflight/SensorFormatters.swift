import Foundation

enum SensorFormatters {
    /// Format latitude as degrees with a N/S suffix
    static func formatLatitude(_ value: Double) -> String {
        guard value.isFinite else { return "--" }
        let suffix = value >= 0 ? "N" : "S"
        return String(format: "%.6f°%@", abs(value), suffix)
    }

    /// Format longitude as degrees with an E/W suffix
    static func formatLongitude(_ value: Double) -> String {
        guard value.isFinite else { return "--" }
        let suffix = value >= 0 ? "E" : "W"
        return String(format: "%.6f°%@", abs(value), suffix)
    }

    /// Format speed for the given unit system (input: km/h)
    static func formatSpeed(_ kph: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f", kph)
        case .imperial:
            return String(format: "%.1f", kph / 1.60934)
        case .aviation:
            return String(format: "%.1f", kph / 1.852)
        }
    }

    /// Format altitude for the given unit system (input: meters)
    static func formatAltitude(_ meters: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f", meters)
        case .imperial, .aviation:
            return String(format: "%.0f", meters * 3.28084)
        }
    }

    /// Format climbing speed for the given unit system (input: m/s)
    static func formatClimbingSpeed(_ mps: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            let rounded = (abs(mps) * 100).rounded() / 100
            if rounded == 0 { return "0.00" }
            let sign = mps > 0 ? "+" : "-"
            return String(format: "%@%.2f", sign, rounded)
        case .imperial, .aviation:
            let ftMin = mps * 196.85039
            let rounded = (abs(ftMin)).rounded()
            if rounded == 0 { return "0" }
            let sign = ftMin > 0 ? "+" : "-"
            return String(format: "%@%.0f", sign, rounded)
        }
    }

    /// Format compass heading degrees only (normalized to 0–359)
    static func formatHeadingDegrees(_ degrees: Double) -> String {
        guard degrees.isFinite else { return "--" }
        var normalized = Int(degrees.rounded()) % 360
        if normalized < 0 { normalized += 360 }
        return "\(normalized)°"
    }

    /// Format G-force with 1 decimal place
    static func formatGForce(_ g: Double) -> String {
        String(format: "%.1f", g)
    }

    /// Format pressure for the given unit system (input: hPa)
    static func formatPressure(_ hpa: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric, .aviation:
            return String(format: "%.1f", hpa)
        case .imperial:
            return String(format: "%.2f", hpa * 0.02953)
        }
    }

    /// Convert degrees to cardinal direction string
    static func cardinalDirection(for degrees: Double) -> String {
        guard degrees.isFinite else { return "--" }
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let adjusted = normalized < 0 ? normalized + 360 : normalized
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((adjusted + 22.5) / 45.0) % 8
        return directions[index]
    }
}
