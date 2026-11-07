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

nonisolated struct HandFrame: Sendable {
    var hands: [HandObservation]
    var imageAspect: Float
}

// Points on the upper body; the camera's left and right are swapped because the picture is mirrored.
nonisolated enum BodyJoint: Int, CaseIterable, Sendable {
    case neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
}

nonisolated struct BodyPoint: Sendable {
    var location: SIMD2<Float>
    var confidence: Float
}

// One upper body the camera found, or none when nobody is in view.
nonisolated struct BodyFrame: Sendable {
    var points: [BodyPoint?]
    var imageAspect: Float

    subscript(_ joint: BodyJoint) -> BodyPoint? { points[joint.rawValue] }

    var shoulders: (width: Float, centerX: Float)? {
        guard let left = self[.leftShoulder], let right = self[.rightShoulder] else { return nil }
        return (abs(left.location.x - right.location.x), (left.location.x + right.location.x) / 2)
    }
}

extension PalmReading {
    // Finds the palm and counts how many fingers stick out.
    nonisolated init?(_ hand: HandObservation, aspect: Float) {
        guard let wrist = hand[.wrist] else { return nil }
        let knuckles = [hand[.indexMCP], hand[.middleMCP], hand[.ringMCP], hand[.littleMCP]].compactMap { $0 }
        guard knuckles.count >= 2 else { return nil }
        let points = [wrist] + knuckles
        let palm = points.reduce(SIMD2<Float>.zero, +) / Float(points.count)

        let scale = SIMD2<Float>(aspect, 1)
        func distance(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float { simd_distance(a * scale, b * scale) }
        var count = 0
        let fingers: [(HandJoint, HandJoint)] = [(.indexTip, .indexPIP), (.middleTip, .middlePIP),
                                                 (.ringTip, .ringPIP), (.littleTip, .littlePIP)]
        for (tip, pip) in fingers {
            if let t = hand[tip], let p = hand[pip], distance(t, wrist) > distance(p, wrist) * 1.12 {
                count += 1
            }
        }
        self.init(palm: palm, extendedFingers: count)
    }
}
