import Foundation

enum SensorFormatters {
    /// Format coordinate as degrees with 6 decimal places
    static func formatCoordinate(_ value: Double) -> String {
        String(format: "%.6f°", value)
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

    /// Format heading/course as degrees with 0 decimal places
    static func formatDegrees(_ degrees: Double) -> String {
        String(format: "%.0f°", degrees)
    }

    /// Format compass heading degrees only (normalized to 0–359)
    static func formatHeadingDegrees(_ degrees: Double) -> String {
        let normalized = Int(degrees.rounded()) % 360
        return "\(normalized)°"
    }

    /// Format compass heading with cardinal direction (legacy)
    static func formatHeading(_ degrees: Double) -> String {
        let cardinal = cardinalDirection(for: degrees)
        return String(format: "%.0f° %@", degrees, cardinal)
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
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let adjusted = normalized < 0 ? normalized + 360 : normalized
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((adjusted + 22.5) / 45.0) % 8
        return directions[index]
    }
}
