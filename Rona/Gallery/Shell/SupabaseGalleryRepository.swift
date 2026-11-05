import Foundation
import Supabase

// Paintings on Supabase: the PNG in the private bucket and one row in `paintings`.
// Row level security and the bucket policies keep every user to their own paintings. The sync engine (E4)
// is the only caller; the pages read the local store.
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

    // Every painting of the account including tombstones, newest first: what the sync engine compares with
    // the device.
    func allPaintings() async throws -> [Painting] {
        let rows: [PaintingRow] = try await client.from("paintings")
            .select()
            .order("painted_at", ascending: false)
            .execute()
            .value
        return rows.map(\.painting)
    }

    // The PNG goes first and the row second, so no row ever points at a file that is not there. Both steps
    // are idempotent (upload with upsert, row upsert on the client-made id), so a retry after a failure
    // halfway is safe.
    func save(_ painting: Painting, png: Data) async throws {
        let userID = try await currentUserID()
        let path = StoragePath.image(userID: userID, paintingID: painting.id)
        try await client.storage.from(Self.bucket)
            .upload(path, data: png, options: FileOptions(contentType: "image/png", upsert: true))
        try await pushRow(painting)
    }

    // The row alone, for when the PNG went up by itself (the sync engine uploads it in the background).
    func pushRow(_ painting: Painting) async throws {
        let row = PaintingRow(painting, userID: try await currentUserID())
        try await client.from("paintings")
            .upsert(row, onConflict: "id", returning: .minimal)
            .execute()
    }

    // A tombstone, not a removal: the cleanup job deletes old tombstones and their files (A6).
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
