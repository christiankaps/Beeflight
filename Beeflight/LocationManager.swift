import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var speed: Double = 0.0 // m/s from CLLocation
    var altitude: Double = 0.0 // meters
    var course: Double = 0.0 // degrees
    var heading: Double = 0.0 // magnetic heading degrees
    var horizontalAccuracy: Double = -1.0

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var speedEMA = EMAFilter(timeConstant: 2.0)
    private let speedHysteresis: Double = 0.5 // m/s (~1.8 km/h)

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

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        course = location.course
        horizontalAccuracy = location.horizontalAccuracy
        altitude = location.altitude

        // Time-aware EMA speed smoothing with hysteresis
        let rawSpeed = location.speed
        if rawSpeed >= 0, location.speedAccuracy >= 0 {
            let clamped = min(rawSpeed, 500.0) // cap at 500 m/s (~1800 km/h)
            let smoothed = speedEMA.update(raw: clamped)
            if abs(smoothed - speed) >= speedHysteresis {
                speed = smoothed
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer trueHeading when a valid location fix is available,
        // fall back to magneticHeading otherwise
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
        } else {
            heading = newHeading.magneticHeading
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location errors are expected when GPS is unavailable (e.g. indoors)
    }
}
