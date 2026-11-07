//
//  GalleryRepository.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation

// Where paintings are kept; pages use the copy on the iPad, the backup uses the one online.
nonisolated protocol GalleryRepository: Sendable {
    // Paintings that are not deleted, newest first.
    func paintings() async throws -> [Painting]
    func imageData(for id: Painting.ID) async throws -> Data
    func save(_ painting: Painting, png: Data) async throws
    // Marks a painting as deleted instead of erasing it, so other devices hear about it.
    func delete(id: Painting.ID) async throws
}
