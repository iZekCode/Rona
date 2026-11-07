//
//  PointerInput.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import QuartzCore
import simd

// Lets a finger or Pencil paint when the camera is not used.
final class PointerInput {
    private var tracker = PointerTracker()

    var isTouching: Bool { tracker.isTouching }

    func touch(at uv: SIMD2<Float>) { tracker.touch(at: uv) }
    func lift() { tracker.lift() }

    // The touch hand for this frame, or nothing while no one touches.
    func hand(now: Double = CACurrentMediaTime()) -> HandState? { tracker.hand(now: now) }
}
