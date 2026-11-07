//
//  StatsRowTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Testing
@testable import Rona

struct StatsRowTests {
    @Test func rowUsesTheColumnNamesAndTheCurrentSchemaVersion() throws {
        let row = StatsRow(SessionStats(), paintingID: UUID(), userID: UUID())
        let data = try JSONEncoder().encode(row)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(json.keys) == ["painting_id", "user_id", "schema_version", "stats"])
        #expect(json["schema_version"] as? Int == SessionStats.schemaVersion)
    }

    @Test func statsKeepTheirOwnKeyNamesInsideTheDocument() throws {
        var stats = SessionStats()
        stats.gripCycles = [.left: 3]
        let data = try JSONEncoder().encode(StatsRow(stats, paintingID: UUID(), userID: UUID()))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let document = try #require(json["stats"] as? [String: Any])

        #expect(document["gripCycles"] != nil)
    }

    @Test func rowRoundTrips() throws {
        var stats = SessionStats()
        stats.duration = 42
        stats.romDegrees = [.right: 88.5]
        let row = StatsRow(stats, paintingID: UUID(), userID: UUID())

        let back = try JSONDecoder().decode(StatsRow.self, from: JSONEncoder().encode(row))

        #expect(back == row)
    }
}
