import Foundation

/// Time-aware Exponential Moving Average filter.
/// Smooths noisy sensor data using alpha = 1 - exp(-dt / tau).
struct EMAFilter {
    let timeConstant: Double
    private(set) var value: Double
    private var lastTimestamp: Date?

    init(timeConstant: Double, initialValue: Double = 0.0) {
        self.timeConstant = timeConstant
        self.value = initialValue
    }

    /// Feed a new raw sample. Returns the smoothed value.
    @discardableResult
    mutating func update(raw: Double, at timestamp: Date = Date()) -> Double {
        if let lastTime = lastTimestamp {
            let dt = timestamp.timeIntervalSince(lastTime)
            let alpha = 1.0 - exp(-dt / timeConstant)
            value += alpha * (raw - value)
        } else {
            value = raw
        }
        lastTimestamp = timestamp
        return value
    }

    /// Reset the filter state.
    mutating func reset(to initialValue: Double = 0.0) {
        value = initialValue
        lastTimestamp = nil
    }
}
