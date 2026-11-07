//
//  FrameStatsTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
@testable import Rona

struct FrameStatsTests {
    @Test func startsEmpty() {
        let stats = FrameStats()
        #expect(stats.count == 0 && stats.average == 0 && stats.worst == 0 && stats.percentile(0.95) == 0)
        #expect(stats.share(over: 1) == 0)
    }

    @Test func averageAndWorst() {
        var stats = FrameStats()
        stats.add([10, 20, 30])
        #expect(stats.average == 20)
        #expect(stats.worst == 30)
    }

    @Test func keepsOnlyTheNewestSamples() {
        var stats = FrameStats(capacity: 3)
        stats.add([1, 2, 3, 4, 5])
        #expect(stats.samples == [3, 4, 5])
    }

    @Test func percentileFindsTheSlowTail() {
        var stats = FrameStats()
        stats.add((1...100).map(Double.init))
        #expect(stats.percentile(0.5) >= 50 && stats.percentile(0.5) <= 51)
        #expect(stats.percentile(0.95) >= 95)
        #expect(stats.percentile(1) == 100)
        #expect(stats.percentile(0) == 1)
    }

    @Test func shareCountsSamplesOverTheLimit() {
        var stats = FrameStats()
        stats.add([10, 10, 30, 40])
        #expect(stats.share(over: 20) == 0.5)
    }

    @Test func resetForgetsEverything() {
        var stats = FrameStats()
        stats.add([5])
        stats.reset()
        #expect(stats.count == 0)
    }
}
