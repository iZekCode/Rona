//
//  SyncContracts.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// What the backup needs from the iPad and from the server; tests can swap in pretend versions.

// The paintings on this iPad and how far each one is in its backup.
nonisolated protocol LocalSyncStore: Sendable {
    // Every painting, deleted ones included, newest first.
    func syncSnapshot() async throws -> [LocalPaintingState]
    func imageFileURL(for id: Painting.ID) async -> URL
    func stats(for id: Painting.ID) async throws -> SessionStats?
    func setImageInFlight(_ inFlight: Bool, for id: Painting.ID) async throws
    func markImageUploaded(for id: Painting.ID) async throws
    func markStatsPushed(for id: Painting.ID) async throws
    // Saves a painting that came from the server as already backed up.
    func saveFromRemote(_ painting: Painting, png: Data, stats: SessionStats?) async throws
    // The server says this painting was deleted, so delete it here too.
    func applyRemoteTombstone(for id: Painting.ID) async throws
}

// The online side of the backup.
nonisolated protocol RemoteGallery: Sendable {
    // Every painting of this account online, deleted ones included.
    func allPaintings() async throws -> [Painting]
    func pushRow(_ painting: Painting) async throws
    func pushStats(_ stats: SessionStats, for id: Painting.ID) async throws
    func pushTombstone(for id: Painting.ID) async throws
    func imageData(for id: Painting.ID) async throws -> Data
    func stats(for id: Painting.ID) async throws -> SessionStats?
}

// Sends a picture in the background, so it can finish even after the app is closed.
nonisolated protocol ImageUploader: Sendable {
    func start(paintingID: Painting.ID, fileURL: URL) async throws
    // Paintings whose picture is still being sent.
    func activePaintingIDs() async -> Set<Painting.ID>
}
