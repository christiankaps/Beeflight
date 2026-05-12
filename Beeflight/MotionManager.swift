import Foundation
import CoreMotion
import Observation
import os

@Observable
final class MotionManager {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Beeflight", category: "MotionManager")

    var gForce: Double = 1.0
    private(set) var isAvailable: Bool

    private let motionManager = CMMotionManager()
    private var emaFilter = EMAFilter(timeConstant: 1.0, initialValue: 1.0)

    init() {
        isAvailable = motionManager.isAccelerometerAvailable
    }

    func startUpdates() {
        isAvailable = motionManager.isAccelerometerAvailable
        guard isAvailable, !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = 1.0 / 10.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            if let error {
                Self.logger.warning("Accelerometer update failed: \(error.localizedDescription)")
                return
            }
            guard let self, let data else { return }
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
