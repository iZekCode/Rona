//
//  FrameBudgetTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
@testable import Rona

struct FrameBudgetTests {
    @Test func fastPaintAndSteadyFramesAreGood() {
        #expect(FrameBudget.verdict(paintAverage: 3, frameTail: 17) == .good)
    }

    @Test func slowerPaintOrAWobblyTailIsTight() {
        #expect(FrameBudget.verdict(paintAverage: 8, frameTail: 17) == .tight)
        #expect(FrameBudget.verdict(paintAverage: 3, frameTail: 20) == .tight)
    }

    @Test func overTheLimitIsOver() {
        #expect(FrameBudget.verdict(paintAverage: 12, frameTail: 17) == .over)
        #expect(FrameBudget.verdict(paintAverage: 3, frameTail: 30) == .over)
    }

    @Test func headroomIsTheLimitOverTheMeasuredCost() {
        #expect(FrameBudget.headroom(paintAverage: 2) == 5)
        #expect(FrameBudget.headroom(paintAverage: 0) == 0)
    }
}
