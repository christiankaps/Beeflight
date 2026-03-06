import Foundation
import CoreMotion
import Observation

@Observable
final class MotionManager {
    var gForce: Double = 1.0

    private let motionManager = CMMotionManager()
    private var smoothed: Double = 1.0
    private var lastTimestamp: Date?
    private let timeConstant: Double = 2.0 // seconds for ~63% response

    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 1.0 / 10.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            let a = data.acceleration
            let raw = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            let now = Date()
            if let lastTime = self.lastTimestamp {
                let dt = now.timeIntervalSince(lastTime)
                let alpha = 1.0 - exp(-dt / self.timeConstant)
                self.smoothed += alpha * (raw - self.smoothed)
            } else {
                self.smoothed = raw
            }
            self.lastTimestamp = now
            self.gForce = self.smoothed
        }
    }

    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}
