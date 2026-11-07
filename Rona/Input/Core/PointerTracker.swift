import Foundation
import simd

/// A finger or the Apple Pencil standing in for the camera, when the camera is denied or unavailable.
/// It reports one always-closed hand that follows the touch, so a drag paints with the left tool.
/// Pure: the view feeds touch positions (view UV, 0…1, y down) and the page asks once per frame.
nonisolated struct PointerTracker: Sendable {
    private var position: SIMD2<Float>?
    private var previous: SIMD2<Float>?
    private var lastFrame: Double?

    var isTouching: Bool { position != nil }

    /// A touch went down or moved. Positions outside the view are held at its edge.
    mutating func touch(at uv: SIMD2<Float>) {
        let p = simd_clamp(uv, SIMD2<Float>(repeating: 0), SIMD2<Float>(repeating: 1))
        position = p
        if previous == nil { previous = p }
    }

    /// The touch ended or was cancelled.
    mutating func lift() {
        position = nil
        previous = nil
        lastFrame = nil
    }

    /// This frame's hand, or nil while nothing touches. The first frame of a touch has no velocity.
    mutating func hand(now: Double) -> HandState? {
        guard let position else { return nil }
        let dt = Float(max(now - (lastFrame ?? now - 1.0 / 60), 1.0 / 240))
        let state = HandState.pointer(at: position, previous: previous ?? position, dt: dt)
        previous = position
        lastFrame = now
        return state
    }
}
