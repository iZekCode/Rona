//
//  SupabaseGalleryRepository.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Supabase

// Paintings online: the picture in private storage plus one row in `paintings`; only the backup uses this.
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

    // Every painting online, deleted ones included, newest first.
    func allPaintings() async throws -> [Painting] {
        let rows: [PaintingRow] = try await client.from("paintings")
            .select()
            .order("painted_at", ascending: false)
            .execute()
            .value
        return rows.map(\.painting)
    }

    // Sends the picture first and then the row, so a row never points at a missing picture; safe to retry.
    func save(_ painting: Painting, png: Data) async throws {
        let userID = try await currentUserID()
        let path = StoragePath.image(userID: userID, paintingID: painting.id)
        try await client.storage.from(Self.bucket)
            .upload(path, data: png, options: FileOptions(contentType: "image/png", upsert: true))
        try await pushRow(painting)
    }

    // Sends only the row, for a picture that was already uploaded in the background.
    func pushRow(_ painting: Painting) async throws {
        let row = PaintingRow(painting, userID: try await currentUserID())
        try await client.from("paintings")
            .upsert(row, onConflict: "id", returning: .minimal)
            .execute()
    }

    // Marks the painting deleted online; a cleanup job erases it for good later.
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
