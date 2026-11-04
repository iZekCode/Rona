import Foundation

// Where paintings are kept: pages read the local one and the sync engine uses the Supabase one.
nonisolated protocol GalleryRepository: Sendable {
    // Paintings that are not deleted, newest first.
    func paintings() async throws -> [Painting]
    func imageData(for id: Painting.ID) async throws -> Data
    func save(_ painting: Painting, png: Data) async throws
    // Marks the painting as deleted instead of removing it, so the delete can sync.
    func delete(id: Painting.ID) async throws
}
