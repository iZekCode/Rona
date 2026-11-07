import Foundation
import Testing
@testable import Rona

struct SyncEngineTests {
    private struct Offline: Error {}

    private func painting(_ seconds: TimeInterval = 100, deleted: Bool = false) -> Painting {
        Painting(paintedAt: Date(timeIntervalSince1970: seconds),
                 deletedAt: deleted ? Date(timeIntervalSince1970: seconds + 1) : nil)
    }

    // Builds the fakes in the body: an actor init cannot run in a default argument.
    private func makeEngine(local: FakeLocal, remote: FakeRemote, uploader: FakeUploader? = nil,
                            sleeps: SleepLog? = nil) -> SyncEngine {
        let uploader = uploader ?? FakeUploader()
        let sleeps = sleeps ?? SleepLog()
        return SyncEngine(local: local, remote: remote, uploader: uploader, backoff: Backoff(first: 2, ceiling: 300),
                          maxAttempts: 3, sleep: { await sleeps.record($0) })
    }

    // MARK: sending

    @Test func nothingRunsUntilTheEngineIsEnabled() async {
        let p = painting()
        let local = FakeLocal([p])
        let uploader = FakeUploader()
        let engine = makeEngine(local: local, remote: FakeRemote(), uploader: uploader)

        await engine.run()

        #expect(await uploader.started.isEmpty)
    }

    @Test func aNewPaintingsImageIsHandedToTheUploaderAndMarkedInFlight() async {
        let p = painting()
        let local = FakeLocal([p])
        let uploader = FakeUploader()
        let engine = makeEngine(local: local, remote: FakeRemote(), uploader: uploader)
        await engine.enable()

        await engine.run()

        #expect(await uploader.started == [p.id])
        #expect(await local.state(p.id).imageInFlight)
    }

    @Test func theImageIsNotStartedAgainWhileItIsInFlight() async {
        let p = painting()
        let local = FakeLocal([p])
        let uploader = FakeUploader()
        let engine = makeEngine(local: local, remote: FakeRemote(), uploader: uploader)
        await engine.enable()

        await engine.run()
        await engine.run()

        #expect(await uploader.started == [p.id])
    }

    @Test func whenTheImageIsUpTheRowAndTheStatsFollow() async {
        let p = painting()
        let local = FakeLocal([p], stats: [p.id: SessionStats()])
        let remote = FakeRemote()
        let uploader = FakeUploader()
        let engine = makeEngine(local: local, remote: remote, uploader: uploader)
        await engine.enable()
        await engine.run()

        await engine.imageUploadFinished(p.id, success: true)

        #expect(await remote.rows.map(\.id) == [p.id])
        #expect(await remote.stats[p.id] != nil)
        #expect(await local.state(p.id) == SyncState(imageUploaded: true, imageInFlight: false, statsPushed: true))
    }

    @Test func aFailedUploadIsRetriedAfterAWait() async {
        let p = painting()
        let local = FakeLocal([p])
        let uploader = FakeUploader()
        let sleeps = SleepLog()
        let engine = makeEngine(local: local, remote: FakeRemote(), uploader: uploader, sleeps: sleeps)
        await engine.enable()
        await engine.run()

        await engine.imageUploadFinished(p.id, success: false)

        #expect(await sleeps.values == [2])
        #expect(await uploader.started == [p.id, p.id])
    }

    @Test func anUploadTheSystemLostIsStartedAgain() async {
        let p = painting()
        let local = FakeLocal([p], states: [p.id: SyncState(imageInFlight: true)])
        let uploader = FakeUploader()
        let engine = makeEngine(local: local, remote: FakeRemote(), uploader: uploader)
        await engine.enable()

        await engine.run()

        #expect(await uploader.started == [p.id])
    }

    @Test func anUploadStillRunningIsLeftAlone() async {
        let p = painting()
        let local = FakeLocal([p], states: [p.id: SyncState(imageInFlight: true)])
        let uploader = FakeUploader(active: [p.id])
        let engine = makeEngine(local: local, remote: FakeRemote(), uploader: uploader)
        await engine.enable()

        await engine.run()

        #expect(await uploader.started.isEmpty)
    }

    // MARK: deleting

    @Test func aLocalDeleteReachesTheServer() async {
        let p = painting(deleted: true)
        var live = p
        live.deletedAt = nil
        let local = FakeLocal([p])
        let remote = FakeRemote(rows: [live])
        let engine = makeEngine(local: local, remote: remote)
        await engine.enable()

        await engine.run()

        #expect(await remote.tombstoned == [p.id])
    }

    @Test func aDeleteFromAnotherDeviceIsAppliedLocally() async {
        let p = painting()
        var gone = p
        gone.deletedAt = Date(timeIntervalSince1970: 500)
        let local = FakeLocal([p])
        let engine = makeEngine(local: local, remote: FakeRemote(rows: [gone]))
        await engine.enable()

        await engine.run()

        #expect(await local.tombstoned == [p.id])
    }

    // MARK: fetching

    @Test func aPaintingOnlyTheServerHasIsDownloadedWithItsStats() async {
        let p = painting()
        var stats = SessionStats()
        stats.duration = 12
        let local = FakeLocal([])
        let remote = FakeRemote(rows: [p], images: [p.id: Data([9, 9])], stats: [p.id: stats])
        let engine = makeEngine(local: local, remote: remote)
        await engine.enable()

        await engine.run()

        let saved = await local.downloaded
        #expect(saved.map(\.painting) == [p])
        #expect(saved.first?.png == Data([9, 9]))
        #expect(saved.first?.stats == stats)
    }

    // MARK: failing

    @Test func aFailedRunIsRepeatedWithGrowingWaitsThenGivesUp() async {
        let local = FakeLocal([])
        let remote = FakeRemote(failing: true)
        let sleeps = SleepLog()
        let engine = makeEngine(local: local, remote: remote, sleeps: sleeps)
        await engine.enable()

        await engine.run()

        #expect(await remote.listCalls == 3)
        #expect(await sleeps.values == [2, 4])
    }

    @Test func aRunThatRecoversStops() async {
        let local = FakeLocal([])
        let remote = FakeRemote(failing: true, recoversAfter: 1)
        let sleeps = SleepLog()
        let engine = makeEngine(local: local, remote: remote, sleeps: sleeps)
        await engine.enable()

        await engine.run()

        #expect(await remote.listCalls == 2)
        #expect(await sleeps.values == [2])
    }
}

// MARK: fakes

private actor SleepLog {
    private(set) var values: [TimeInterval] = []
    func record(_ seconds: TimeInterval) { values.append(seconds) }
}

private actor FakeUploader: ImageUploader {
    private(set) var started: [Painting.ID] = []
    private var active: Set<Painting.ID>

    init(active: Set<Painting.ID> = []) { self.active = active }

    func start(paintingID: Painting.ID, fileURL: URL) async throws {
        started.append(paintingID)
        active.insert(paintingID)
    }
    func activePaintingIDs() async -> Set<Painting.ID> { active }
}

private actor FakeRemote: RemoteGallery {
    private(set) var rows: [Painting]
    private(set) var stats: [Painting.ID: SessionStats]
    private(set) var tombstoned: [Painting.ID] = []
    private(set) var listCalls = 0
    private let images: [Painting.ID: Data]
    private var failing: Bool
    private let recoversAfter: Int?

    init(rows: [Painting] = [], images: [Painting.ID: Data] = [:], stats: [Painting.ID: SessionStats] = [:],
         failing: Bool = false, recoversAfter: Int? = nil) {
        self.rows = rows
        self.images = images
        self.stats = stats
        self.failing = failing
        self.recoversAfter = recoversAfter
    }

    func allPaintings() async throws -> [Painting] {
        listCalls += 1
        if let recoversAfter, listCalls > recoversAfter { failing = false }
        if failing { throw URLError(.notConnectedToInternet) }
        return rows
    }

    func pushRow(_ painting: Painting) async throws { rows.append(painting) }
    func pushStats(_ stats: SessionStats, for id: Painting.ID) async throws { self.stats[id] = stats }
    func pushTombstone(for id: Painting.ID) async throws { tombstoned.append(id) }
    func imageData(for id: Painting.ID) async throws -> Data { images[id] ?? Data() }
    func stats(for id: Painting.ID) async throws -> SessionStats? { stats[id] }
}

private actor FakeLocal: LocalSyncStore {
    struct Downloaded: Equatable {
        let painting: Painting
        let png: Data
        let stats: SessionStats?
    }

    private var paintings: [Painting]
    private var statsByID: [Painting.ID: SessionStats]
    private var states: [Painting.ID: SyncState]
    private(set) var tombstoned: [Painting.ID] = []
    private(set) var downloaded: [Downloaded] = []

    init(_ paintings: [Painting], stats: [Painting.ID: SessionStats] = [:], states: [Painting.ID: SyncState] = [:]) {
        self.paintings = paintings
        self.statsByID = stats
        self.states = states
    }

    func state(_ id: Painting.ID) -> SyncState { states[id] ?? SyncState() }

    func syncSnapshot() async throws -> [LocalPaintingState] {
        paintings.map { LocalPaintingState(painting: $0, hasStats: statsByID[$0.id] != nil, sync: state($0.id)) }
    }

    func imageFileURL(for id: Painting.ID) async -> URL { URL(fileURLWithPath: "/tmp/\(id).png") }
    func stats(for id: Painting.ID) async throws -> SessionStats? { statsByID[id] }

    func setImageInFlight(_ inFlight: Bool, for id: Painting.ID) async throws {
        var s = state(id)
        s.imageInFlight = inFlight
        states[id] = s
    }

    func markImageUploaded(for id: Painting.ID) async throws {
        var s = state(id)
        s.imageUploaded = true
        s.imageInFlight = false
        states[id] = s
    }

    func markStatsPushed(for id: Painting.ID) async throws {
        var s = state(id)
        s.statsPushed = true
        states[id] = s
    }

    func saveFromRemote(_ painting: Painting, png: Data, stats: SessionStats?) async throws {
        downloaded.append(Downloaded(painting: painting, png: png, stats: stats))
    }

    func applyRemoteTombstone(for id: Painting.ID) async throws { tombstoned.append(id) }
}
