import Foundation

// Paintings and their stats kept as files on the device, one folder per painting:
// {id}/painting.json (the record), image.png, stats.json and sync.json (what is known about its trip to
// the server, see SyncState).
// The record is written last, so a folder without one is a save that never finished and is ignored.
// A delete keeps the record with its tombstone, and removes the image and stats.
actor LocalGalleryStore: GalleryRepository, StatsRepository, LocalSyncStore {
    private let folder: URL
    private let now: @Sendable () -> Date

    init(folder: URL? = nil, now: @escaping @Sendable () -> Date = { Date() }) {
        self.folder = folder ?? URL.applicationSupportDirectory.appending(path: "Gallery", directoryHint: .isDirectory)
        self.now = now
    }

    // MARK: GalleryRepository

    func paintings() async throws -> [Painting] {
        try await allPaintings().filter { !$0.isDeleted }
    }

    // Every record including tombstones, newest first. The sync engine reads this to push deletes.
    func allPaintings() async throws -> [Painting] {
        let entries = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return entries
            .compactMap { UUID(uuidString: $0.lastPathComponent) }
            .compactMap { try? record(of: $0) }
            .sorted { ($0.paintedAt, $1.id.uuidString) > ($1.paintedAt, $0.id.uuidString) }
    }

    func imageData(for id: Painting.ID) async throws -> Data {
        try requireLive(id)
        return try Data(contentsOf: imageURL(id))
    }

    func save(_ painting: Painting, png: Data) async throws {
        try FileManager.default.createDirectory(at: directory(painting.id), withIntermediateDirectories: true)
        try png.write(to: imageURL(painting.id), options: .atomic)
        try writeSyncState(SyncState(), for: painting.id)
        try JSONEncoder().encode(painting).write(to: recordURL(painting.id), options: .atomic)
    }

    func delete(id: Painting.ID) async throws {
        var painting = try record(of: id)
        guard !painting.isDeleted else { return }
        painting.deletedAt = now()
        try FileManager.default.removeItem(at: imageURL(id))
        try? FileManager.default.removeItem(at: statsURL(id))
        try JSONEncoder().encode(painting).write(to: recordURL(id), options: .atomic)
    }

    // MARK: StatsRepository

    func stats(for id: Painting.ID) async throws -> SessionStats? {
        guard let painting = try? record(of: id), !painting.isDeleted,
              let data = try? Data(contentsOf: statsURL(id)) else { return nil }
        return try JSONDecoder().decode(SessionStats.self, from: data)
    }

    func save(_ stats: SessionStats, for id: Painting.ID) async throws {
        try requireLive(id)
        try JSONEncoder().encode(stats).write(to: statsURL(id), options: .atomic)
        var state = syncState(of: id)
        state.statsPushed = false
        try writeSyncState(state, for: id)
    }

    // MARK: LocalSyncStore

    func syncSnapshot() async throws -> [LocalPaintingState] {
        try await allPaintings().map {
            LocalPaintingState(painting: $0, hasStats: FileManager.default.fileExists(atPath: statsURL($0.id).path),
                               sync: syncState(of: $0.id))
        }
    }

    func imageFileURL(for id: Painting.ID) async -> URL { imageURL(id) }

    func setImageInFlight(_ inFlight: Bool, for id: Painting.ID) async throws {
        _ = try record(of: id)
        var state = syncState(of: id)
        state.imageInFlight = inFlight
        try writeSyncState(state, for: id)
    }

    func markImageUploaded(for id: Painting.ID) async throws {
        _ = try record(of: id)
        var state = syncState(of: id)
        state.imageUploaded = true
        state.imageInFlight = false
        try writeSyncState(state, for: id)
    }

    func markStatsPushed(for id: Painting.ID) async throws {
        _ = try record(of: id)
        var state = syncState(of: id)
        state.statsPushed = true
        try writeSyncState(state, for: id)
    }

    func saveFromRemote(_ painting: Painting, png: Data, stats: SessionStats?) async throws {
        try FileManager.default.createDirectory(at: directory(painting.id), withIntermediateDirectories: true)
        try png.write(to: imageURL(painting.id), options: .atomic)
        if let stats { try JSONEncoder().encode(stats).write(to: statsURL(painting.id), options: .atomic) }
        try writeSyncState(SyncState(imageUploaded: true, imageInFlight: false, statsPushed: true), for: painting.id)
        try JSONEncoder().encode(painting).write(to: recordURL(painting.id), options: .atomic)
    }

    func applyRemoteTombstone(for id: Painting.ID) async throws {
        try await delete(id: id)
    }

    // MARK: Files

    private func directory(_ id: UUID) -> URL { folder.appending(path: id.uuidString, directoryHint: .isDirectory) }
    private func recordURL(_ id: UUID) -> URL { directory(id).appending(path: "painting.json") }
    private func imageURL(_ id: UUID) -> URL { directory(id).appending(path: "image.png") }
    private func statsURL(_ id: UUID) -> URL { directory(id).appending(path: "stats.json") }

    private func syncURL(_ id: UUID) -> URL { directory(id).appending(path: "sync.json") }

    // A missing or unreadable file means nothing is known yet, which only costs a repeated upload.
    private func syncState(of id: UUID) -> SyncState {
        guard let data = try? Data(contentsOf: syncURL(id)),
              let state = try? JSONDecoder().decode(SyncState.self, from: data) else { return SyncState() }
        return state
    }

    private func writeSyncState(_ state: SyncState, for id: UUID) throws {
        try JSONEncoder().encode(state).write(to: syncURL(id), options: .atomic)
    }

    private func record(of id: UUID) throws -> Painting {
        guard let data = try? Data(contentsOf: recordURL(id)) else { throw GalleryStoreError.notFound(id) }
        return try JSONDecoder().decode(Painting.self, from: data)
    }

    private func requireLive(_ id: UUID) throws {
        guard try !record(of: id).isDeleted else { throw GalleryStoreError.notFound(id) }
    }
}
