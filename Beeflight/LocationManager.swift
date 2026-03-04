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
    var verticalAccuracy: Double = -1.0
    var horizontalAccuracy: Double = -1.0
    var previousAltitude: Double?
    var previousAltitudeTimestamp: Date?
    var climbingSpeed: Double = 0.0 // m/s
    private var smoothedClimbingSpeed: Double = 0.0
    private let climbSmoothingFactor: Double = 0.15
    private let climbHysteresis: Double = 0.02

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

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
        speed = location.speed
        course = location.course
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy

        // Calculate climbing speed from altitude changes
        let newAltitude = location.altitude
        if let prevAlt = previousAltitude, let prevTime = previousAltitudeTimestamp {
            let timeDelta = location.timestamp.timeIntervalSince(prevTime)
            if timeDelta > 0 {
                let raw = (newAltitude - prevAlt) / timeDelta
                smoothedClimbingSpeed += climbSmoothingFactor * (raw - smoothedClimbingSpeed)
                if abs(smoothedClimbingSpeed - climbingSpeed) >= climbHysteresis {
                    climbingSpeed = smoothedClimbingSpeed
                }
            }
        }
        previousAltitude = newAltitude
        previousAltitudeTimestamp = location.timestamp
        altitude = newAltitude
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
