import Foundation
import Testing
@testable import Rona

// Talks to a real Supabase: the simulator uses the local stack, so run `supabase start` first, then
//   TEST_RUNNER_SUPABASE_INTEGRATION=1 xcodebuild test -scheme Rona -only-testing:RonaTests/SupabaseRepositoriesIntegrationTests ...
// Skipped otherwise (Xcode Cloud has no Docker). Each run leaves one anonymous user; the cleanup job removes it.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SUPABASE_INTEGRATION"] != nil))
struct SupabaseRepositoriesIntegrationTests {
    @Test func paintingAndStatsRoundTripThroughSupabase() async throws {
        let client = SupabaseConfig.makeClient()
        let state = try await SupabaseAuthService(client: client).signInAnonymously()
        guard case .signedIn(let userID, _) = state else { Issue.record("not signed in"); return }
        try await SupabaseProfileRepository(client: client)
            .record(ConsentRecord(acceptedAt: Date(timeIntervalSince1970: 1_000), version: 1), for: userID)
        let gallery = SupabaseGalleryRepository(client: client)
        let statsRepository = SupabaseStatsRepository(client: client)

        // A 1x1 PNG.
        let png = try #require(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
        let painting = Painting(templateID: "cat", paintedAt: Date(timeIntervalSince1970: 1_762_300_000))
        var stats = SessionStats()
        stats.duration = 42
        stats.gripCycles = [.left: 3, .right: 5]
        stats.romDegrees = [.right: 88.5]

        try await gallery.save(painting, png: png)
        try await gallery.save(painting, png: png)                    // a retry is safe
        try await statsRepository.save(stats, for: painting.id)

        let listed = try await gallery.paintings()
        #expect(listed == [painting])
        #expect(try await gallery.imageData(for: painting.id) == png)
        #expect(try await statsRepository.stats(for: painting.id) == stats)
        #expect(try await statsRepository.stats(for: UUID()) == nil)

        try await gallery.delete(id: painting.id)
        #expect(try await gallery.paintings().isEmpty)
        let unknown = UUID()
        await #expect(throws: GalleryStoreError.notFound(unknown)) { try await gallery.delete(id: unknown) }
    }
}
