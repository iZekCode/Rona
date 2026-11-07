//
//  StatsRepository.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation

// Where movement stats are kept, one set per painting (none for a painting made by touch).
nonisolated protocol StatsRepository: Sendable {
    func stats(for id: Painting.ID) async throws -> SessionStats?
    func save(_ stats: SessionStats, for id: Painting.ID) async throws
}
