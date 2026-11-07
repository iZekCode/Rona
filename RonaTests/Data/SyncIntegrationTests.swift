import Foundation
import Testing
@testable import Rona

// Two devices of one account on a real Supabase; needs `supabase start` and TEST_RUNNER_SUPABASE_INTEGRATION=1.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SUPABASE_INTEGRATION"] != nil))
struct SyncIntegrationTests {
    private struct Device {
        let store: LocalGalleryStore
        let engine: SyncEngine
        let folder: URL
    }

    private func makeDevice(service: SupabaseAuthService, remote: SupabaseRemoteGallery) async -> Device {
        let folder = FileManager.default.temporaryDirectory.appending(path: "rona-sync-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store = LocalGalleryStore(folder: folder)
        let uploader = BackgroundImageUploader(baseURL: SupabaseConfig.url, apiKey: SupabaseConfig.key,
                                               identifier: "test.\(UUID().uuidString)") { try await service.uploadCredentials() }
        let engine = SyncEngine(local: store, remote: remote, uploader: uploader,
                                backoff: Backoff(first: 1, ceiling: 2), maxAttempts: 3)
        uploader.setOnFinish { id, success in Task { await engine.imageUploadFinished(id, success: success) } }
        await engine.enable()
        return Device(store: store, engine: engine, folder: folder)
    }

    // Runs the engine until the condition holds, or fails after about 30 seconds.
    private func syncUntil(_ device: Device, _ what: String, _ condition: () async throws -> Bool) async throws {
        for _ in 0..<30 {
            await device.engine.run()
            if try await condition() { return }
            try await Task.sleep(for: .seconds(1))
        }
        Issue.record("timed out waiting for: \(what)")
    }

    @Test func aPaintingAndItsDeleteTravelBetweenTwoDevices() async throws {
        let client = SupabaseConfig.makeClient()
        let service = SupabaseAuthService(client: client)
        let state = try await service.signInAnonymously()
        guard case .signedIn(let userID, _) = state else { Issue.record("not signed in"); return }
        try await SupabaseProfileRepository(client: client)
            .record(ConsentRecord(acceptedAt: Date(timeIntervalSince1970: 1_000), version: 1), for: userID)

        let remote = SupabaseRemoteGallery(gallery: SupabaseGalleryRepository(client: client),
                                           stats: SupabaseStatsRepository(client: client))
        let a = await makeDevice(service: service, remote: remote)
        let b = await makeDevice(service: service, remote: remote)
        defer {
            try? FileManager.default.removeItem(at: a.folder)
            try? FileManager.default.removeItem(at: b.folder)
        }

        let png = try #require(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
        let painting = Painting(templateID: "cat", paintedAt: Date(timeIntervalSince1970: 1_762_300_000))
        var stats = SessionStats()
        stats.duration = 42
        stats.gripCycles = [.left: 3]

        try await a.store.save(painting, png: png)
        try await a.store.save(stats, for: painting.id)
        try await syncUntil(a, "A's painting and stats on the server") {
            try await a.store.syncSnapshot().first?.sync == SyncState(imageUploaded: true, imageInFlight: false, statsPushed: true)
        }

        try await syncUntil(b, "B to download the painting") { try await b.store.paintings().count == 1 }
        #expect(try await b.store.paintings() == [painting])
        #expect(try await b.store.imageData(for: painting.id) == png)
        #expect(try await b.store.stats(for: painting.id) == stats)

        try await a.store.delete(id: painting.id)
        try await syncUntil(a, "A's delete on the server") { true }
        try await syncUntil(b, "B to apply the delete") { try await b.store.paintings().isEmpty }
        #expect(try await b.store.allPaintings().first?.isDeleted == true)
    }
}
