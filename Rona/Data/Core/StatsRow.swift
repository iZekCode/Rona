import Foundation

// A painting's session stats as a row of the `painting_stats` table: one JSON document per painting.
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
