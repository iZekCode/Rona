import Foundation
import QuartzCore
import simd

// Touch and Pencil fallback: a finger or the Pencil drags one always-closed hand.
final class PointerInput {
    private var tracker = PointerTracker()

    var isTouching: Bool { tracker.isTouching }

    func touch(at uv: SIMD2<Float>) { tracker.touch(at: uv) }
    func lift() { tracker.lift() }

    // This frame's pointer hand, or nil while nothing touches.
    func hand(now: Double = CACurrentMediaTime()) -> HandState? { tracker.hand(now: now) }
}
