//
//  PaintToolTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
import simd
@testable import Rona

struct PaintToolTests {
    @Test func eachToolHasItsOwnColour() {
        #expect(PaintTool.allCases.map(\.colorIndex) == [0, 1, 4, 3])
        #expect(Set(PaintTool.allCases.map(\.colorIndex)).count == 4)
    }

    @Test func toolAndCharacterShareTheColour() {
        for tool in PaintTool.allCases {
            #expect(tool.color == tool.critterKind.signatureColor)
        }
    }

    @Test func castFollowsToolOrder() {
        #expect(CritterKind.gardenCast == PaintTool.allCases.map(\.critterKind))
    }

    @Test func snailPaintsBroaderThanLadybug() {
        let a = SIMD2<Float>(0, 0), b = SIMD2<Float>(1, 0)
        let ladybug = PaintTool.ladybug.dabs(from: a, to: b, radius: 0.1, speed: 1)
        let snail = PaintTool.snail.dabs(from: a, to: b, radius: 0.1, speed: 1)
        #expect(ladybug.count == 1 && snail.count == 1)
        #expect(snail[0].radius > ladybug[0].radius)
        #expect(ladybug[0].style == .wash)
    }
}
