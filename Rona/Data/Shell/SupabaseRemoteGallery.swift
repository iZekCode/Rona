//
//  SupabaseRemoteGallery.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// The online side of the backup, built from the painting and stats stores.
nonisolated struct SupabaseRemoteGallery: RemoteGallery {
    let gallery: SupabaseGalleryRepository
    let stats: SupabaseStatsRepository

    func allPaintings() async throws -> [Painting] {
        try await gallery.allPaintings()
    }

    func pushRow(_ painting: Painting) async throws {
        try await gallery.pushRow(painting)
    }

    func pushStats(_ stats: SessionStats, for id: Painting.ID) async throws {
        try await self.stats.save(stats, for: id)
    }

    func pushTombstone(for id: Painting.ID) async throws {
        try await gallery.delete(id: id)
    }

    func imageData(for id: Painting.ID) async throws -> Data {
        try await gallery.imageData(for: id)
    }

    func stats(for id: Painting.ID) async throws -> SessionStats? {
        try await stats.stats(for: id)
    }
}
