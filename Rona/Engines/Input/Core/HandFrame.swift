//
//  HandFrame.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import simd

// The points on a hand that the app looks at.
nonisolated enum HandJoint: Int, CaseIterable, Sendable {
    case wrist
    case thumbCMC, thumbMP, thumbIP, thumbTip
    case indexMCP, indexPIP, indexTip
    case middleMCP, middlePIP, middleTip
    case ringMCP, ringPIP, ringTip
    case littleMCP, littlePIP, littleTip
}

// One hand the camera found, with its points placed on the mirrored camera picture.
nonisolated struct HandObservation: Sendable {
    var joints: [SIMD2<Float>?]
    var confidence: Float

    subscript(_ joint: HandJoint) -> SIMD2<Float>? { joints[joint.rawValue] }
}

// All the hands the camera found in one picture.
nonisolated struct HandFrame: Sendable {
    var hands: [HandObservation]
    var imageAspect: Float
}
