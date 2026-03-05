import Foundation
import CoreMotion
import Observation

@Observable
final class AltimeterManager {
    var pressure: Double = 0.0 // kilopascals from CMAltimeter
    var climbingSpeed: Double = 0.0 // m/s from barometric altitude
    var isAvailable: Bool = false

    /// Pressure in hectopascals (hPa), which equals millibars
    var pressureHpa: Double {
        pressure * 10.0 // CMAltimeter reports kPa, convert to hPa
    }

    private let altimeter = CMAltimeter()
    private var previousRelativeAltitude: Double?
    private var previousTimestamp: Date?
    private var smoothedClimbingSpeed: Double = 0.0
    private let climbSmoothingFactor: Double = 0.15
    private let climbHysteresis: Double = 0.02

    init() {
        isAvailable = CMAltimeter.isRelativeAltitudeAvailable()
    }

    func startUpdates() {
        guard isAvailable else { return }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            self.pressure = data.pressure.doubleValue

            let relAlt = data.relativeAltitude.doubleValue
            let now = Date()

            if let prevAlt = self.previousRelativeAltitude, let prevTime = self.previousTimestamp {
                let timeDelta = now.timeIntervalSince(prevTime)
                if timeDelta >= 0.5 {
                    let raw = (relAlt - prevAlt) / timeDelta
                    let clamped = max(-50, min(50, raw))
                    self.smoothedClimbingSpeed += self.climbSmoothingFactor * (clamped - self.smoothedClimbingSpeed)
                    if abs(self.smoothedClimbingSpeed - self.climbingSpeed) >= self.climbHysteresis {
                        self.climbingSpeed = self.smoothedClimbingSpeed
                    }
                    self.previousRelativeAltitude = relAlt
                    self.previousTimestamp = now
                }
            } else {
                self.previousRelativeAltitude = relAlt
                self.previousTimestamp = now
            }
        }
    }

    func stopUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}
