//
//  FakePainterTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
import simd
@testable import Rona

struct FakePainterTests {
    @Test func everyPointIsOnTheCanvas() {
        for slot in 0..<4 {
            for step in 0..<2000 {
                let p = FakePainter.point(slot: slot, at: Double(step) * 0.05)
                #expect(CanvasLayout.isOnCanvas(p))
            }
        }
    }

    @Test func brushesMoveAndDifferFromEachOther() {
        #expect(FakePainter.point(slot: 0, at: 0) != FakePainter.point(slot: 0, at: 1))
        #expect(FakePainter.point(slot: 0, at: 1) != FakePainter.point(slot: 1, at: 1))
    }

    @Test func brushesKeepAPaintablePace() {
        let a = FakePainter.point(slot: 0, at: 0)
        let b = FakePainter.point(slot: 0, at: 1.0 / 60)
        let speed = simd_distance(a, b) * 60
        #expect(speed > 0.1 && speed < 6)
    }
}
