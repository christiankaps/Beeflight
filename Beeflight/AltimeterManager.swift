import Foundation
import CoreMotion
import Observation

@Observable
final class AltimeterManager {
    var pressure: Double = 0.0 // kilopascals from CMAltimeter
    var isAvailable: Bool = false

    /// Pressure in hectopascals (hPa), which equals millibars
    var pressureHpa: Double {
        pressure * 10.0 // CMAltimeter reports kPa, convert to hPa
    }

    private let altimeter = CMAltimeter()

    init() {
        isAvailable = CMAltimeter.isRelativeAltitudeAvailable()
    }

    func startUpdates() {
        guard isAvailable else { return }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            self.pressure = data.pressure.doubleValue
        }
    }

    func stopUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}
