import Foundation
import CoreMotion
import Observation

@Observable
final class MotionManager {
    var gForce: Double = 1.0

    private let motionManager = CMMotionManager()
    private var emaFilter = EMAFilter(timeConstant: 1.0, initialValue: 1.0)

    func startUpdates() {
        guard motionManager.isAccelerometerAvailable,
              !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = 1.0 / 10.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            let a = data.acceleration
            let raw = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            self.gForce = self.emaFilter.update(raw: raw)
        }
    }

    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        emaFilter.reset(to: 1.0)
    }
}
