import Foundation
import QuartzCore
import simd

/// The touch and Apple Pencil fallback for a hand: a finger or the Pencil drags one always-closed hand.
/// The page asks for it once per frame, next to the camera hands from `HandInput`.
final class PointerInput {
    private var tracker = PointerTracker()

    var isTouching: Bool { tracker.isTouching }

    func touch(at uv: SIMD2<Float>) { tracker.touch(at: uv) }
    func lift() { tracker.lift() }

    /// This frame's pointer hand, or nil while nothing touches.
    func hand(now: Double = CACurrentMediaTime()) -> HandState? { tracker.hand(now: now) }
}
