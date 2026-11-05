import Foundation
import Supabase

// Session stats on Supabase: one row per painting in `painting_stats` with the stats as a JSON document.
// The composite foreign key (painting_id, user_id) makes the database refuse stats for a painting of
// another user, and the painting row must exist first.
nonisolated struct SupabaseStatsRepository: StatsRepository {
    let client: SupabaseClient

    func stats(for id: Painting.ID) async throws -> SessionStats? {
        let rows: [StatsRow] = try await client.from("painting_stats")
            .select()
            .eq("painting_id", value: id)
            .limit(1)
            .execute()
            .value
        return rows.first?.stats
    }

    func save(_ stats: SessionStats, for id: Painting.ID) async throws {
        let userID = try await client.auth.session.user.id
        let row = StatsRow(stats, paintingID: id, userID: userID)
        try await client.from("painting_stats")
            .upsert(row, onConflict: "painting_id", returning: .minimal)
            .execute()
    }
}
