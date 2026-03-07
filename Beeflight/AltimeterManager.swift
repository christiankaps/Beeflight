import Foundation
import CoreMotion
import Observation

@Observable
final class AltimeterManager {
    var pressure: Double = 0.0 // kilopascals from CMAltimeter
    var climbingSpeed: Double = 0.0 // m/s from barometric altitude
    private var isAvailable: Bool = false

    /// Pressure in hectopascals (hPa), which equals millibars
    var pressureHpa: Double {
        pressure * 10.0 // CMAltimeter reports kPa, convert to hPa
    }

    private let altimeter = CMAltimeter()
    private var isRunning = false
    private var previousRelativeAltitude: Double?
    private var previousTimestamp: Date?
    private var climbEMA = EMAFilter(timeConstant: 2.0)

    init() {
        isAvailable = CMAltimeter.isRelativeAltitudeAvailable()
    }

    func startUpdates() {
        guard isAvailable, !isRunning else { return }
        isRunning = true

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            self.pressure = data.pressure.doubleValue

            let relAlt = data.relativeAltitude.doubleValue
            let now = Date()

            if let prevAlt = self.previousRelativeAltitude, let prevTime = self.previousTimestamp {
                let dt = now.timeIntervalSince(prevTime)
                let raw = (relAlt - prevAlt) / dt
                let clamped = max(-50, min(50, raw))
                self.climbingSpeed = self.climbEMA.update(raw: clamped, at: now)
            }
            self.previousRelativeAltitude = relAlt
            self.previousTimestamp = now
        }
    }

    func stopUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
        climbEMA.reset()
    }
}
