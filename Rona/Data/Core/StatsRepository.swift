import Foundation

// Where session stats are kept, one document per painting (nil for a painting made by touch).
nonisolated protocol StatsRepository: Sendable {
    func stats(for id: Painting.ID) async throws -> SessionStats?
    func save(_ stats: SessionStats, for id: Painting.ID) async throws
}
