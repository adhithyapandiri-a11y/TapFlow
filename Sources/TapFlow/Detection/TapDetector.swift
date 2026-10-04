import Foundation
import AppKit
import simd

@MainActor
final class TapDetector: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusText = "Starting motion sensor..."
    @Published private(set) var isCalibrating = false

    var sensitivity = 0.16
    var sequenceWindow = 0.72
    private let accelerometer = AccelerometerReader()
    private var actions: [Int: () -> Void] = [:]
    private var tapTimes: [Date] = []
    private var lastImpact = Date.distantPast
    private var settleTask: Task<Void, Never>?
    private var gravity = SIMD3<Double>(0, 0, 1)
    private var sampleCount = 0
    private var previousImpulse = 0.0
    private var impactArmed = true
    private var calibrationImpulses: [Double] = []
    private var calibrationTask: Task<Void, Never>?

    func configure(actions: [Int: () -> Void]) { self.actions = actions }

    func start(sensitivity: Double) {
        self.sensitivity = sensitivity
        guard !isRunning else { return }
        accelerometer.start(onSample: { [weak self] x, y, z in
            Task { @MainActor in self?.process(x, y, z) }
        }, onStateChange: { [weak self] running, status in
            Task { @MainActor in
                self?.isRunning = running
                self?.statusText = status
            }
        })
        isRunning = true
        statusText = accelerometer.status
    }

    func stop() {
        accelerometer.stop()
        settleTask?.cancel()
        isRunning = false
        statusText = "Tap detection is off"
    }

    func calibrate(completion: @escaping (Double) -> Void) {
        guard isRunning, !isCalibrating else { return }
        isCalibrating = true
        calibrationImpulses.removeAll(keepingCapacity: true)
        statusText = "Calibrating - keep your MacBook still"
        calibrationTask?.cancel()
        calibrationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, let self else { return }
            self.finishCalibration(completion: completion)
        }
    }

    private func process(_ x: Double, _ y: Double, _ z: Double) {
        let sample = SIMD3<Double>(x, y, z)
        // Track slow movement (such as tilting the laptop) as baseline gravity.
        gravity = gravity * 0.94 + sample * 0.06
        let impulse = simd_length(sample - gravity)
        let now = Date()
        if isCalibrating {
            calibrationImpulses.append(impulse)
            return
        }
        sampleCount += 1
        if sampleCount.isMultiple(of: 20) {
            statusText = String(format: "Listening - motion %.2fg", impulse)
        }
        if impulse < sensitivity * 0.5 { impactArmed = true }
        let rise = impulse - previousImpulse
        previousImpulse = impulse
        // A tap must be a distinct motion pulse, while sensitivity remains tunable for gentle taps.
        guard impactArmed,
              impulse >= sensitivity,
              rise >= sensitivity * 0.1,
              now.timeIntervalSince(lastImpact) > 0.22 else { return }

        impactArmed = false
        lastImpact = now
        tapTimes.append(now)
        let count = tapTimes.count
        statusText = "\(count) tap\(count == 1 ? "" : "s") detected - continue or wait"
        settleTask?.cancel()
        let delay = sequenceWindow
        settleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.fireTapSequence()
        }
    }

    private func fireTapSequence() {
        let count = min(tapTimes.count, 3)
        tapTimes.removeAll()
        guard count > 0 else { return }
        if let action = actions[count] {
            statusText = "\(count) tap\(count == 1 ? "" : "s") detected - running action"
            action()
        } else {
            statusText = "\(count) tap\(count == 1 ? "" : "s") detected - no action enabled"
        }
    }

    private func finishCalibration(completion: @escaping (Double) -> Void) {
        isCalibrating = false
        let sorted = calibrationImpulses.sorted()
        let percentile = sorted.isEmpty ? 0 : sorted[Int(Double(sorted.count - 1) * 0.95)]
        // Keep a meaningful floor: a quiet desk should still require a deliberate impact.
        let recommended = min(max(0.12, percentile * 4), 0.6)
        sensitivity = recommended
        completion(recommended)
        statusText = String(format: "Calibrated - tap sensitivity %.2fg", recommended)
    }
}
