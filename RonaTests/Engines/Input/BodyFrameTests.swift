//
//  BodyFrameTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
import simd
@testable import Rona

struct BodyFrameTests {
    @Test func shouldersNeedBothSides() {
        var points = [BodyPoint?](repeating: nil, count: BodyJoint.allCases.count)
        points[BodyJoint.leftShoulder.rawValue] = BodyPoint(location: SIMD2(0.40, 0.5), confidence: 1)
        #expect(BodyFrame(points: points, imageAspect: 1.33).shoulders == nil)
        points[BodyJoint.rightShoulder.rawValue] = BodyPoint(location: SIMD2(0.60, 0.5), confidence: 1)
        let shoulders = BodyFrame(points: points, imageAspect: 1.33).shoulders
        #expect(shoulders.map { abs($0.width - 0.2) < 1e-5 && abs($0.centerX - 0.5) < 1e-5 } == true)
    }
}
