import Testing
@testable import Beeflight

struct SensorFormattersTests {

    // MARK: - formatLatitude / formatLongitude

    @Test func formatLatitudePositive() {
        let result = SensorFormatters.formatLatitude(48.123456)
        #expect(result == "48.123456°N")
    }

    @Test func formatLatitudeNegative() {
        let result = SensorFormatters.formatLatitude(-33.868820)
        #expect(result == "33.868820°S")
    }

    @Test func formatLatitudeZero() {
        let result = SensorFormatters.formatLatitude(0.0)
        #expect(result == "0.000000°N")
    }

    @Test func formatLongitudePositive() {
        let result = SensorFormatters.formatLongitude(11.582000)
        #expect(result == "11.582000°E")
    }

    @Test func formatLongitudeNegative() {
        let result = SensorFormatters.formatLongitude(-122.987654)
        #expect(result == "122.987654°W")
    }

    @Test func formatLongitudeZero() {
        let result = SensorFormatters.formatLongitude(0.0)
        #expect(result == "0.000000°E")
    }

    // MARK: - formatSpeed

    @Test func formatSpeedNormal() {
        let result = SensorFormatters.formatSpeed(120.5, unitSystem: .metric)
        #expect(result == "120.5")
    }

    @Test func formatSpeedZero() {
        let result = SensorFormatters.formatSpeed(0.0, unitSystem: .metric)
        #expect(result == "0.0")
    }

    // MARK: - formatAltitude

    @Test func formatAltitudePositive() {
        let result = SensorFormatters.formatAltitude(1234.5, unitSystem: .metric)
        #expect(result == "1234.5")
    }

    @Test func formatAltitudeNegative() {
        let result = SensorFormatters.formatAltitude(-10.3, unitSystem: .metric)
        #expect(result == "-10.3")
    }

    // MARK: - formatClimbingSpeed

    @Test func formatClimbingSpeedPositive() {
        let result = SensorFormatters.formatClimbingSpeed(2.45, unitSystem: .metric)
        #expect(result == "+2.45")
    }

    @Test func formatClimbingSpeedNegative() {
        let result = SensorFormatters.formatClimbingSpeed(-1.30, unitSystem: .metric)
        #expect(result == "-1.30")
    }

    @Test func formatClimbingSpeedZero() {
        let result = SensorFormatters.formatClimbingSpeed(0.0, unitSystem: .metric)
        #expect(result == "0.00")
    }

    // MARK: - formatDegrees

    @Test func formatDegreesNormal() {
        let result = SensorFormatters.formatDegrees(180.7)
        #expect(result == "181°")
    }

    @Test func formatDegreesZero() {
        let result = SensorFormatters.formatDegrees(0.0)
        #expect(result == "0°")
    }

    // MARK: - formatHeadingDegrees

    @Test func formatHeadingNorth() {
        let result = SensorFormatters.formatHeadingDegrees(0.0)
        #expect(result == "0°")
    }

    @Test func formatHeadingEast() {
        let result = SensorFormatters.formatHeadingDegrees(90.0)
        #expect(result == "90°")
    }

    @Test func formatHeadingSouth() {
        let result = SensorFormatters.formatHeadingDegrees(180.0)
        #expect(result == "180°")
    }

    @Test func formatHeadingWest() {
        let result = SensorFormatters.formatHeadingDegrees(270.0)
        #expect(result == "270°")
    }

    // MARK: - formatPressure

    @Test func formatPressureNormal() {
        let result = SensorFormatters.formatPressure(1013.2, unitSystem: .metric)
        #expect(result == "1013.2")
    }

    @Test func formatPressureZero() {
        let result = SensorFormatters.formatPressure(0.0, unitSystem: .metric)
        #expect(result == "0.0")
    }

    // MARK: - cardinalDirection

    @Test func cardinalDirectionAllDirections() {
        #expect(SensorFormatters.cardinalDirection(for: 0) == "N")
        #expect(SensorFormatters.cardinalDirection(for: 22) == "N")
        #expect(SensorFormatters.cardinalDirection(for: 23) == "NE")
        #expect(SensorFormatters.cardinalDirection(for: 45) == "NE")
        #expect(SensorFormatters.cardinalDirection(for: 90) == "E")
        #expect(SensorFormatters.cardinalDirection(for: 135) == "SE")
        #expect(SensorFormatters.cardinalDirection(for: 180) == "S")
        #expect(SensorFormatters.cardinalDirection(for: 225) == "SW")
        #expect(SensorFormatters.cardinalDirection(for: 270) == "W")
        #expect(SensorFormatters.cardinalDirection(for: 315) == "NW")
        #expect(SensorFormatters.cardinalDirection(for: 350) == "N")
    }

    @Test func cardinalDirectionWrapsAt360() {
        #expect(SensorFormatters.cardinalDirection(for: 360) == "N")
        #expect(SensorFormatters.cardinalDirection(for: 450) == "E")
    }

    @Test func cardinalDirectionNaN() {
        #expect(SensorFormatters.cardinalDirection(for: .nan) == "--")
        #expect(SensorFormatters.cardinalDirection(for: .infinity) == "--")
    }

    // MARK: - NaN / Infinity guards

    @Test func formatLatitudeNaN() {
        #expect(SensorFormatters.formatLatitude(.nan) == "--")
        #expect(SensorFormatters.formatLatitude(.infinity) == "--")
    }

    @Test func formatLongitudeNaN() {
        #expect(SensorFormatters.formatLongitude(.nan) == "--")
        #expect(SensorFormatters.formatLongitude(.infinity) == "--")
    }

    @Test func formatHeadingNaN() {
        #expect(SensorFormatters.formatHeadingDegrees(.nan) == "--")
        #expect(SensorFormatters.formatHeadingDegrees(.infinity) == "--")
    }

    @Test func formatHeadingNegative() {
        #expect(SensorFormatters.formatHeadingDegrees(-10.0) == "350°")
        #expect(SensorFormatters.formatHeadingDegrees(-90.0) == "270°")
    }
}

struct LocationManagerTests {

    @Test func speedKphConvertsCorrectly() {
        let manager = LocationManager()
        manager.speed = 10.0 // 10 m/s
        #expect(manager.speedKph == 36.0) // 36 km/h
    }

    @Test func speedKphReturnsZeroForNegativeSpeed() {
        let manager = LocationManager()
        manager.speed = -1.0 // invalid speed
        #expect(manager.speedKph == 0.0)
    }

    @Test func speedKphZero() {
        let manager = LocationManager()
        manager.speed = 0.0
        #expect(manager.speedKph == 0.0)
    }

    @Test func initialValues() {
        let manager = LocationManager()
        #expect(manager.latitude == 0.0)
        #expect(manager.longitude == 0.0)
        #expect(manager.speed == 0.0)
        #expect(manager.altitude == 0.0)
        #expect(manager.course == -1.0)
        #expect(manager.heading == 0.0)
    }
}

struct AltimeterManagerTests {

    @Test func pressureHpaConversion() {
        let manager = AltimeterManager()
        manager.pressure = 101.325 // kPa (standard atmosphere)
        let expected = 1013.25 // hPa
        #expect(abs(manager.pressureHpa - expected) < 0.01)
    }

    @Test func pressureHpaZero() {
        let manager = AltimeterManager()
        manager.pressure = 0.0
        #expect(manager.pressureHpa == 0.0)
    }
}

struct CountryDetectorTests {

    @Test func detectGermany() {
        let country = CountryDetector.country(at: 51.1657, longitude: 10.4515)
        #expect(country != nil)
        #expect(country?.isoCode == "DE")
    }

    @Test func detectUnitedStates() {
        let country = CountryDetector.country(at: 38.8951, longitude: -77.0364)
        #expect(country != nil)
        #expect(country?.isoCode == "US")
    }

    @Test func detectJapan() {
        let country = CountryDetector.country(at: 35.6762, longitude: 139.6503)
        #expect(country != nil)
        #expect(country?.isoCode == "JP")
    }

    @Test func detectAustralia() {
        let country = CountryDetector.country(at: -25.2744, longitude: 133.7751)
        #expect(country != nil)
        #expect(country?.isoCode == "AU")
    }

    @Test func detectBrazil() {
        let country = CountryDetector.country(at: -14.2350, longitude: -51.9253)
        #expect(country != nil)
        #expect(country?.isoCode == "BR")
    }

    @Test func oceanReturnsNil() {
        let country = CountryDetector.country(at: 0.0, longitude: -30.0)
        #expect(country == nil)
    }

    @Test func localizedNameWithISOCode() {
        let country = CountryDetector.Country(isoCode: "DE", name: "Germany")
        let name = CountryDetector.localizedCountryName(for: country)
        #expect(!name.isEmpty)
    }

    @Test func localizedNameFallbackForEmptyISO() {
        let country = CountryDetector.Country(isoCode: "", name: "Somaliland")
        let name = CountryDetector.localizedCountryName(for: country)
        #expect(name == "Somaliland")
    }
}
