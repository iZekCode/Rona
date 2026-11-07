//
//  HandState.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import simd

// Only big, easy hand shapes: open or fist.
nonisolated enum HandPose: Equatable, Sendable {
    case open
    case fist
}

// One hand as the game sees it, placed on the screen; this is what every page reads.
nonisolated struct HandState: Sendable {
    var slot: Int
    var pose: HandPose
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var tracking: Bool
    var isPointer = false

    // A finger or Pencil touch acting as the left hand, always painting.
    static func pointer(at p: SIMD2<Float>, previous: SIMD2<Float>, dt: Float) -> HandState {
        HandState(slot: 0, pose: .fist, position: p, velocity: (p - previous) / dt, tracking: true, isPointer: true)
    }
}
