import CoreGraphics

// A button an open hand can hover over and hold to press, in view UV.
nonisolated struct HoverTarget: Equatable, Sendable {
    var id: String
    var frame: CGRect
}

// Hover-and-hold: an open hand resting on a button for a second presses it once.
nonisolated struct HoverDwell: Sendable {
    static let duration = 1.0

    private(set) var progress: (id: String, value: Double)?
    private var time = 0.0
    private var latched: String?
    private var waitingForRelease = false

    // Ignores holds until the hand leaves every button, so a page change under a resting hand presses nothing.
    mutating func requireRelease() {
        waitingForRelease = true
        time = 0
        latched = nil
        progress = nil
    }

    // Returns the id when a full hold on `hoveredID` completes.
    mutating func update(hoveredID: String?, dt: Double) -> String? {
        guard let id = hoveredID else {
            waitingForRelease = false
            time = 0
            latched = nil
            progress = nil
            return nil
        }
        if waitingForRelease || latched == id { return nil }
        latched = nil
        if progress?.id != id { time = 0 }
        time += dt
        if time + 1e-9 >= Self.duration {
            latched = id
            time = 0
            progress = nil
            return id
        }
        progress = (id, time / Self.duration)
        return nil
    }
}
