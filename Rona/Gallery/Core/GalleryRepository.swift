import Foundation

/// Where paintings are kept. Pages read only the local implementation; the Supabase one is used by the sync engine.
nonisolated protocol GalleryRepository: Sendable {
    /// Non-deleted paintings, newest first.
    func paintings() async throws -> [Painting]
    func imageData(for id: Painting.ID) async throws -> Data
    func save(_ painting: Painting, png: Data) async throws
    /// Tombstones the painting (sets `deletedAt`); the image may be removed.
    func delete(id: Painting.ID) async throws
}
