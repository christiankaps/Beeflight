import Foundation
import CoreLocation
import Observation
import os

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var speed: Double = 0.0 // m/s from CLLocation
    var altitude: Double = 0.0 // meters
    var course: Double = -1.0 // degrees, -1 means invalid
    var heading: Double = 0.0 // magnetic heading degrees
    var horizontalAccuracy: Double = -1.0
    var verticalAccuracy: Double = -1.0
    var headingIsValid = false
    var locationIsFresh = false
    var speedIsValid = false
    var altitudeIsValid = false
    var courseIsValid = false

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var speedEMA = EMAFilter(timeConstant: 2.0)
    private let speedHysteresis: Double = 0.5 // m/s (~1.8 km/h)
    private let staleLocationInterval: TimeInterval = 10

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    func applySettings(_ settings: AppSettings) {
        locationManager.distanceFilter = settings.updateRate.distanceFilter < 0
            ? kCLDistanceFilterNone
            : settings.updateRate.distanceFilter
        locationManager.headingFilter = settings.updateRate.headingFilter < 0
            ? kCLHeadingFilterNone
            : settings.updateRate.headingFilter
    }

    // MARK: - Speed formatting

    /// Speed in km/h converted from m/s, returns 0 if negative (invalid)
    var speedKph: Double {
        speed >= 0 ? speed * 3.6 : 0.0
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            startUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        locationIsFresh = abs(location.timestamp.timeIntervalSinceNow) <= staleLocationInterval
        guard locationIsFresh else {
            speedIsValid = false
            altitudeIsValid = false
            courseIsValid = false
            speed = 0
            course = -1.0
            speedEMA.reset()
            return
        }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy

        altitudeIsValid = location.verticalAccuracy >= 0
        if altitudeIsValid {
            altitude = location.altitude
        }

        courseIsValid = location.course >= 0 && location.courseAccuracy >= 0
        if courseIsValid {
            course = location.course
        } else {
            course = -1.0
        }

        // Time-aware EMA speed smoothing with hysteresis
        let rawSpeed = location.speed
        if rawSpeed >= 0, location.speedAccuracy >= 0 {
            speedIsValid = true
            let clamped = min(rawSpeed, 500.0) // cap at 500 m/s (~1800 km/h)
            let smoothed = speedEMA.update(raw: clamped)
            if abs(smoothed - speed) >= speedHysteresis {
                speed = smoothed
            }
        } else {
            speedIsValid = false
            speed = 0
            speedEMA.reset()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else {
            headingIsValid = false
            return
        }

        // Prefer trueHeading when a valid location fix is available,
        // fall back to magneticHeading otherwise
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
            headingIsValid = true
        } else {
            heading = newHeading.magneticHeading
            headingIsValid = newHeading.magneticHeading >= 0
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Beeflight", category: "LocationManager")

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Self.logger.warning("Location update failed: \(error.localizedDescription)")
    }
}
