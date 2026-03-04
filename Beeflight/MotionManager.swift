import Foundation
import CoreMotion
import Observation

@Observable
final class MotionManager {
    var gForce: Double = 0.0

    private let motionManager = CMMotionManager()
    /// Smoothing factor for low-pass filter (0–1). Lower = smoother.
    private let smoothingFactor: Double = 0.1

    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 1.0 / 30.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            let a = data.acceleration
            let raw = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            self.gForce = self.gForce + self.smoothingFactor * (raw - self.gForce)
        }
    }

    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}
