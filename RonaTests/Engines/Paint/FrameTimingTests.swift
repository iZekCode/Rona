//
//  FrameTimingTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
@testable import Rona

struct FrameTimingTests {
    @Test func frameStepStaysInRange() {
        #expect(abs(FrameTiming.clampedDT(0) - Float(1) / 240) < 1e-6)
        #expect(abs(FrameTiming.clampedDT(5) - Float(1) / 20) < 1e-6)
        #expect(FrameTiming.clampedDT(0.01) == 0.01)
    }

    @Test func beatPulseIsFullOnTheBeatAndFades() {
        #expect(FrameTiming.beatPulse(beat: 4) == 1)
        #expect(FrameTiming.beatPulse(beat: 4.5) < FrameTiming.beatPulse(beat: 4.1))
    }

    @Test func energyEasesTowardMovement() {
        let up = FrameTiming.energy(0, movement: 3, dt: 0.1)
        #expect(up > 0 && up < 1)
        #expect(FrameTiming.energy(1, movement: 0, dt: 0.1) < 1)
        #expect(FrameTiming.energy(0.5, movement: 30, dt: 1) == 1)
    }
}
