//
//  SessionStatsTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation
import Testing
@testable import Rona

struct SessionStatsTests {
    @Test func defaultHeatmapCoversTheGrid() {
        let s = SessionStats()
        #expect(s.heatmap.count == SessionStats.heatmapColumns * SessionStats.heatmapRows)
        #expect(s.heatmap.allSatisfy { $0 == 0 })
    }

    @Test func codableRoundTripKeepsPerSideValues() throws {
        var s = SessionStats()
        s.duration = 42
        s.romDegrees = [.left: 80, .right: 95.5]
        s.gripCycles = [.right: 7]
        s.heatmap[5] = 300
        s.maxTrunkLean = 12
        let data = try JSONEncoder().encode(s)
        #expect(try JSONDecoder().decode(SessionStats.self, from: data) == s)
    }

    @Test func olderDocumentWithMissingMetricsDecodesWithDefaults() throws {
        let s = try JSONDecoder().decode(SessionStats.self, from: Data(#"{"duration": 30}"#.utf8))
        #expect(s.duration == 30)
        #expect(s.romDegrees.isEmpty)
        #expect(s.gripCycles.isEmpty)
        #expect(s.heatmap.count == SessionStats.heatmapColumns * SessionStats.heatmapRows)
    }

    @Test func schemaVersionStartsAtOne() {
        #expect(SessionStats.schemaVersion == 1)
    }
}
