import Foundation

/// Calculates sunrise and sunset times using the NOAA solar position algorithm.
enum SolarCalculator {

    /// Returns (sunrise, sunset) as Dates for the given location and date, or nil if the sun doesn't rise/set.
    static func sunriseSunset(latitude: Double, longitude: Double, date: Date = Date()) -> (sunrise: Date?, sunset: Date?) {
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        let dayOfYear = utcCalendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Fractional year in radians
        let gamma = 2.0 * .pi / 365.0 * (Double(dayOfYear) - 1.0)

        // Equation of time (minutes)
        let eqTime = 229.18 * (0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma))

        // Solar declination (radians)
        let decl = 0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)

        let latRad = latitude * .pi / 180.0

        // Hour angle for sunrise/sunset (solar zenith = 90.833°)
        let zenith = 90.833 * .pi / 180.0
        let cosHA = (cos(zenith) / (cos(latRad) * cos(decl))) - tan(latRad) * tan(decl)

        // Sun doesn't rise or set at this location on this date
        guard cosHA >= -1.0 && cosHA <= 1.0 else {
            return (nil, nil)
        }

        let ha = acos(cosHA) * 180.0 / .pi // in degrees

        // Sunrise and sunset in minutes from midnight UTC
        let sunriseMinutes = 720.0 - 4.0 * (longitude + ha) - eqTime
        let sunsetMinutes = 720.0 - 4.0 * (longitude - ha) - eqTime

        // Build Date objects for midnight UTC of the given date
        let startOfDay = utcCalendar.startOfDay(for: date)

        let sunrise = startOfDay.addingTimeInterval(sunriseMinutes * 60.0)
        let sunset = startOfDay.addingTimeInterval(sunsetMinutes * 60.0)

        return (sunrise, sunset)
    }
}
