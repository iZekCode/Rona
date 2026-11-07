//
//  StatsRow.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Movement stats in the shape the online `painting_stats` table expects.
nonisolated struct StatsRow: Codable, Equatable, Sendable {
    let paintingID: UUID
    let userID: UUID
    let schemaVersion: Int
    let stats: SessionStats

    enum CodingKeys: String, CodingKey {
        case paintingID = "painting_id"
        case userID = "user_id"
        case schemaVersion = "schema_version"
        case stats
    }

    init(_ stats: SessionStats, paintingID: UUID, userID: UUID) {
        self.paintingID = paintingID
        self.userID = userID
        schemaVersion = SessionStats.schemaVersion
        self.stats = stats
    }
}
