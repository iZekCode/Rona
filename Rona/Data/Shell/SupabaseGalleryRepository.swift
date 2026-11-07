import Foundation
import Supabase

// Paintings on Supabase: the PNG in the private bucket, one row in `paintings`; only the sync engine calls it.
nonisolated struct SupabaseGalleryRepository: GalleryRepository {
    let client: SupabaseClient
    var now: @Sendable () -> Date = { Date() }

    private static let bucket = "paintings"

    private struct Tombstone: Encodable {
        let deletedAt: Date

        enum CodingKeys: String, CodingKey { case deletedAt = "deleted_at" }
    }

    func paintings() async throws -> [Painting] {
        let rows: [PaintingRow] = try await client.from("paintings")
            .select()
            .is("deleted_at", value: nil)
            .order("painted_at", ascending: false)
            .execute()
            .value
        return rows.map(\.painting)
    }

    func imageData(for id: Painting.ID) async throws -> Data {
        let userID = try await currentUserID()
        return try await client.storage.from(Self.bucket)
            .download(path: StoragePath.image(userID: userID, paintingID: id))
    }

    // Every painting including tombstones, newest first.
    func allPaintings() async throws -> [Painting] {
        let rows: [PaintingRow] = try await client.from("paintings")
            .select()
            .order("painted_at", ascending: false)
            .execute()
            .value
        return rows.map(\.painting)
    }

    // PNG first, then the row, so no row points at a missing file; both steps are idempotent.
    func save(_ painting: Painting, png: Data) async throws {
        let userID = try await currentUserID()
        let path = StoragePath.image(userID: userID, paintingID: painting.id)
        try await client.storage.from(Self.bucket)
            .upload(path, data: png, options: FileOptions(contentType: "image/png", upsert: true))
        try await pushRow(painting)
    }

    // The row alone, for a PNG the background uploader already sent.
    func pushRow(_ painting: Painting) async throws {
        let row = PaintingRow(painting, userID: try await currentUserID())
        try await client.from("paintings")
            .upsert(row, onConflict: "id", returning: .minimal)
            .execute()
    }

    // A tombstone, not a removal; the cleanup job deletes old ones.
    func delete(id: Painting.ID) async throws {
        let rows: [PaintingRow] = try await client.from("paintings")
            .update(Tombstone(deletedAt: now()))
            .eq("id", value: id)
            .execute()
            .value
        if rows.isEmpty { throw GalleryStoreError.notFound(id) }
    }

    private func currentUserID() async throws -> UUID {
        try await client.auth.session.user.id
    }
}
