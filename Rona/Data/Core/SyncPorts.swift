import Foundation

// What the sync engine needs from the device and from the server. The engine knows only these, so a test
// can stand in for each with a fake.

// The paintings on this device, plus what is remembered about their trip to the server.
nonisolated protocol LocalSyncStore: Sendable {
    // Every painting including tombstones, newest first.
    func syncSnapshot() async throws -> [LocalPaintingState]
    func imageFileURL(for id: Painting.ID) async -> URL
    func stats(for id: Painting.ID) async throws -> SessionStats?
    func setImageInFlight(_ inFlight: Bool, for id: Painting.ID) async throws
    // The image reached the server; clears the in-flight mark.
    func markImageUploaded(for id: Painting.ID) async throws
    func markStatsPushed(for id: Painting.ID) async throws
    // A painting fetched from the server: stored as already synced.
    func saveFromRemote(_ painting: Painting, png: Data, stats: SessionStats?) async throws
    // The server says it is deleted: tombstone it here without anything left to push.
    func applyRemoteTombstone(for id: Painting.ID) async throws
}

// The server side of the sync.
nonisolated protocol RemoteGallery: Sendable {
    // Every painting of this account including tombstones.
    func allPaintings() async throws -> [Painting]
    func pushRow(_ painting: Painting) async throws
    func pushStats(_ stats: SessionStats, for id: Painting.ID) async throws
    func pushTombstone(for id: Painting.ID) async throws
    func imageData(for id: Painting.ID) async throws -> Data
    func stats(for id: Painting.ID) async throws -> SessionStats?
}

// Sends a painting's PNG to the server in the background, so it can finish after the app is closed.
// It reports back through the handler the engine sets, which may be called after a relaunch.
nonisolated protocol ImageUploader: Sendable {
    func start(paintingID: Painting.ID, fileURL: URL) async throws
    // Paintings with an upload still running or waiting in the system.
    func activePaintingIDs() async -> Set<Painting.ID>
}
