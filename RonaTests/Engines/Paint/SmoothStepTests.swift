//
//  SmoothStepTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
@testable import Rona

struct SmoothStepTests {
    @Test func stopsAtBothEnds() {
        #expect(smoothStep(1, 3, 0) == 0)
        #expect(smoothStep(1, 3, 1) == 0)
        #expect(smoothStep(1, 3, 3) == 1)
        #expect(smoothStep(1, 3, 9) == 1)
    }

    @Test func halfwayIsHalf() {
        #expect(abs(smoothStep(0, 2, 1) - 0.5) < 1e-6)
    }

    @Test func risesWithoutGoingBack() {
        let values = (0...10).map { smoothStep(0, 1, Float($0) / 10) }
        #expect(values == values.sorted())
    }
}
