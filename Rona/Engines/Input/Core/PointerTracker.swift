import Foundation
import simd

// A finger or the Pencil as one always-closed hand, for when the camera is off.
nonisolated struct PointerTracker: Sendable {
    private var position: SIMD2<Float>?
    private var previous: SIMD2<Float>?
    private var lastFrame: Double?

    var isTouching: Bool { position != nil }

    // A touch went down or moved; positions outside the view are held at its edge.
    mutating func touch(at uv: SIMD2<Float>) {
        let p = simd_clamp(uv, SIMD2<Float>(repeating: 0), SIMD2<Float>(repeating: 1))
        position = p
        if previous == nil { previous = p }
    }

    mutating func lift() {
        position = nil
        previous = nil
        lastFrame = nil
    }

    // This frame's hand, or nil while nothing touches.
    mutating func hand(now: Double) -> HandState? {
        guard let position else { return nil }
        let dt = Float(max(now - (lastFrame ?? now - 1.0 / 60), 1.0 / 240))
        let state = HandState.pointer(at: position, previous: previous ?? position, dt: dt)
        previous = position
        lastFrame = now
        return state
    }
}
