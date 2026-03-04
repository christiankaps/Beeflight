import Foundation
import CoreMotion
import Observation

@Observable
final class MotionManager {
    var gForce: Double = 1.0

    private let motionManager = CMMotionManager()
    /// Smoothing factor for low-pass filter (0–1). Lower = smoother.
    private let smoothingFactor: Double = 0.05
    /// Minimum change required to update the published value
    private let hysteresis: Double = 0.05
    private var smoothed: Double = 1.0

    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 1.0 / 10.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            let a = data.acceleration
            let raw = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            self.smoothed = self.smoothed + self.smoothingFactor * (raw - self.smoothed)
            if abs(self.smoothed - self.gForce) >= self.hysteresis {
                self.gForce = self.smoothed
            }
        }
    }

    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}
