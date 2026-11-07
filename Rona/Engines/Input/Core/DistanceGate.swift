import Foundation

// Decides when the person stands at the right distance, from shoulder width in the camera image.
nonisolated struct DistanceGate: Sendable {
    enum State: Equatable, Sendable {
        case noPerson, tooClose, tooFar, offCenter
        case holding(progress: Double)
        case ready
    }

    static let nearWidth: Float = 0.22
    static let farWidth: Float = 0.13
    static let centerTolerance: Float = 0.18
    static let holdDuration: TimeInterval = 1.5
    static let dropoutGrace: TimeInterval = 0.3

    private var holdStart: TimeInterval?
    private var lastSeen: TimeInterval?
    private var lastState: State = .noPerson

    mutating func update(shoulderWidth: Float?, centerX: Float?, at time: TimeInterval) -> State {
        guard let width = shoulderWidth, let centerX else {
            if let lastSeen, time - lastSeen <= Self.dropoutGrace { return lastState }
            return set(.noPerson, holdStart: nil)
        }
        lastSeen = time

        if width < Self.farWidth { return set(.tooFar, holdStart: nil) }
        if width > Self.nearWidth { return set(.tooClose, holdStart: nil) }
        if abs(centerX - 0.5) > Self.centerTolerance { return set(.offCenter, holdStart: nil) }

        let start = holdStart ?? time
        let elapsed = time - start
        return set(elapsed >= Self.holdDuration ? .ready : .holding(progress: elapsed / Self.holdDuration),
                   holdStart: start)
    }

    private mutating func set(_ state: State, holdStart: TimeInterval?) -> State {
        self.holdStart = holdStart
        lastState = state
        return state
    }
}
