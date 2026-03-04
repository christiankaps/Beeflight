import Foundation

enum SensorFormatters {
    /// Format coordinate as degrees with 6 decimal places
    static func formatCoordinate(_ value: Double) -> String {
        String(format: "%.6f°", value)
    }

    /// Format speed in km/h with 1 decimal place
    static func formatSpeed(_ kph: Double) -> String {
        String(format: "%.1f", kph)
    }

    /// Format altitude in meters with 1 decimal place
    static func formatAltitude(_ meters: Double) -> String {
        String(format: "%.1f", meters)
    }

    /// Format climbing speed in m/s with 2 decimal places
    static func formatClimbingSpeed(_ mps: Double) -> String {
        let sign = mps > 0 ? "+" : mps < 0 ? "-" : ""
        return String(format: "%@%.2f", sign, abs(mps))
    }

    /// Format heading/course as degrees with 0 decimal places
    static func formatDegrees(_ degrees: Double) -> String {
        String(format: "%.0f°", degrees)
    }

    /// Format compass heading with cardinal direction
    static func formatHeading(_ degrees: Double) -> String {
        let cardinal = cardinalDirection(for: degrees)
        return String(format: "%.0f° %@", degrees, cardinal)
    }

    /// Format G-force with 2 decimal places
    static func formatGForce(_ g: Double) -> String {
        String(format: "%.2f", g)
    }

    /// Format pressure in hPa with 1 decimal place
    static func formatPressure(_ hpa: Double) -> String {
        String(format: "%.1f", hpa)
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
