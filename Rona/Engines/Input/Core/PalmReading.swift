//
//  PalmReading.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// What the camera reads from one palm: where it is and how many fingers stick out.
nonisolated struct PalmReading: Sendable {
    var palm: SIMD2<Float>
    var extendedFingers: Int

    init(palm: SIMD2<Float>, extendedFingers: Int) {
        self.palm = palm
        self.extendedFingers = extendedFingers
    }

    // Finds the palm and counts how many fingers stick out.
    init?(_ hand: HandObservation, aspect: Float) {
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
