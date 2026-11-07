//
//  HandPose.swift
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

// One hand as the game sees it, placed on the screen.
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

// What the camera reads from one palm.
nonisolated struct PalmReading: Sendable {
    var palm: SIMD2<Float>
    var extendedFingers: Int

    init(palm: SIMD2<Float>, extendedFingers: Int) {
        self.palm = palm
        self.extendedFingers = extendedFingers
    }
}

// Turns jumpy finger counts into a steady open or fist, so the hand does not flicker.
nonisolated struct PoseFilter: Sendable {
    private(set) var pose: HandPose
    private var candidateFrames = 0

    init(pose: HandPose) { self.pose = pose }

    mutating func feed(_ reading: PalmReading) {
        let raw: HandPose
        if pose == .fist {
            raw = reading.extendedFingers >= 2 ? .open : .fist
        } else {
            raw = reading.extendedFingers == 0 ? .fist : .open
        }
        let needed = raw == .fist ? 2 : 3
        if raw != pose {
            candidateFrames += 1
            if candidateFrames >= needed {
                pose = raw
                candidateFrames = 0
            }
        } else {
            candidateFrames = 0
        }
    }
}
