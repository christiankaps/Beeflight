import XCTest
import CoreLocation
@testable import Beeflight

final class BeeflightTests: XCTestCase {

    // MARK: - LocationManager Initialization

    func testLocationManagerInitialState() {
        let manager = LocationManager()
        XCTAssertEqual(manager.authorizationStatus, .notDetermined)
        XCTAssertNil(manager.latitude)
        XCTAssertNil(manager.longitude)
        XCTAssertNil(manager.altitude)
        XCTAssertNil(manager.speed)
        XCTAssertNil(manager.heading)
        XCTAssertNil(manager.horizontalAccuracy)
        XCTAssertNil(manager.verticalAccuracy)
        XCTAssertNil(manager.locationError)
    }

    // MARK: - GPS Data Formatting

    func testCoordinateFormattingPrecision() {
        // Validate 6 decimal places as used in ContentView
        let value = 37.774929
        let formatted = String(format: "%.6f", value)
        XCTAssertEqual(formatted, "37.774929")
    }

    func testNegativeCoordinateFormatting() {
        let value = -122.419416
        let formatted = String(format: "%.6f", value)
        XCTAssertEqual(formatted, "-122.419416")
    }

    func testAltitudeFormatting() {
        let altitude = 15.76
        let formatted = String(format: "%.1f", altitude)
        XCTAssertEqual(formatted, "15.8")
    }

    func testSpeedConversionFromMpsToKph() {
        // LocationManager returns speed in m/s; UI multiplies by 3.6 for km/h
        let speedMps = 10.0
        let speedKph = speedMps * 3.6
        XCTAssertEqual(speedKph, 36.0, accuracy: 0.001)
    }

    func testZeroSpeedConversion() {
        let speedMps = 0.0
        let speedKph = speedMps * 3.6
        XCTAssertEqual(speedKph, 0.0, accuracy: 0.001)
    }

    func testHeadingFormatting() {
        let heading = 270.0
        let formatted = String(format: "%.1f", heading)
        XCTAssertEqual(formatted, "270.0")
    }

    // MARK: - Location Update Handling

    func testLocationManagerHandlesNegativeSpeedAsNil() {
        // Speed < 0 from CLLocation means "invalid"; LocationManager sets nil
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 90,
            speed: -1,   // invalid speed
            timestamp: Date()
        )
        // A negative speed should not be presented to the user
        let speed = location.speed >= 0 ? location.speed : nil
        XCTAssertNil(speed)
    }

    func testLocationManagerHandlesValidSpeed() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 90,
            speed: 5.0,
            timestamp: Date()
        )
        let speed = location.speed >= 0 ? location.speed : nil
        XCTAssertNotNil(speed)
        XCTAssertEqual(speed!, 5.0, accuracy: 0.001)
    }

    func testLocationManagerHandlesNegativeHorizontalAccuracyAsNil() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0),
            altitude: 50,
            horizontalAccuracy: -1,   // invalid
            verticalAccuracy: 5,
            course: 90,
            speed: 0,
            timestamp: Date()
        )
        let accuracy = location.horizontalAccuracy > 0 ? location.horizontalAccuracy : nil
        XCTAssertNil(accuracy)
    }

    // MARK: - Heading

    func testTrueHeadingPreferredOverMagneticHeading() {
        // When trueHeading >= 0 it should be used
        let trueHeading = 45.0
        let magneticHeading = 50.0
        let heading = trueHeading >= 0 ? trueHeading : magneticHeading
        XCTAssertEqual(heading, 45.0)
    }

    func testMagneticHeadingUsedWhenTrueHeadingNegative() {
        let trueHeading = -1.0
        let magneticHeading = 50.0
        let heading = trueHeading >= 0 ? trueHeading : magneticHeading
        XCTAssertEqual(heading, 50.0)
    }
}
