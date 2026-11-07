//
//  SupabaseStatsRepository.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Supabase

// Movement stats online, one row per painting, saved after the painting itself.
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
