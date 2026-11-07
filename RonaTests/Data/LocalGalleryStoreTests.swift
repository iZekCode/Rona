//
//  LocalGalleryStoreTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Testing
@testable import Rona

struct LocalGalleryStoreTests {
    private func makeFolder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "rona-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func painting(at seconds: TimeInterval, templateID: String? = nil) -> Painting {
        Painting(templateID: templateID, paintedAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func startsEmptyWhenTheFolderDoesNotExist() async throws {
        let store = LocalGalleryStore(folder: makeFolder())
        #expect(try await store.paintings().isEmpty)
    }

    @Test func savedPaintingComesBackWithItsImage() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let saved = painting(at: 100, templateID: "cat")
        let png = Data([1, 2, 3, 4])

        try await store.save(saved, png: png)

        #expect(try await store.paintings() == [saved])
        #expect(try await store.imageData(for: saved.id) == png)
    }

    @Test func paintingsAreNewestFirst() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let old = painting(at: 100)
        let new = painting(at: 300)
        let middle = painting(at: 200)
        for p in [old, new, middle] { try await store.save(p, png: Data([0])) }

        #expect(try await store.paintings().map(\.id) == [new.id, middle.id, old.id])
    }

    @Test func savedPaintingsSurviveANewStoreOnTheSameFolder() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let saved = painting(at: 100)
        try await LocalGalleryStore(folder: folder).save(saved, png: Data([9]))

        #expect(try await LocalGalleryStore(folder: folder).paintings() == [saved])
    }

    @Test func savingTheSameIdTwiceReplacesIt() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        var p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        p.templateID = "fish"
        try await store.save(p, png: Data([2]))

        #expect(try await store.paintings() == [p])
        #expect(try await store.imageData(for: p.id) == Data([2]))
    }

    @Test func deleteHidesThePaintingAndKeepsATombstone() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let deletedAt = Date(timeIntervalSince1970: 500)
        let store = LocalGalleryStore(folder: folder, now: { deletedAt })
        let keep = painting(at: 100)
        let gone = painting(at: 200)
        try await store.save(keep, png: Data([1]))
        try await store.save(gone, png: Data([2]))

        try await store.delete(id: gone.id)

        #expect(try await store.paintings() == [keep])
        let all = try await store.allPaintings()
        #expect(all.count == 2)
        #expect(all.first { $0.id == gone.id }?.deletedAt == deletedAt)
        await #expect(throws: GalleryStoreError.notFound(gone.id)) { try await store.imageData(for: gone.id) }
    }

    @Test func deleteRemovesTheImageAndStatsFromDisk() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        try await store.save(SessionStats(), for: p.id)

        try await store.delete(id: p.id)

        let files = try FileManager.default.contentsOfDirectory(atPath: folder.appending(path: p.id.uuidString).path)
        #expect(files.sorted() == ["painting.json", "sync.json"])
    }

    @Test func deletingTwiceKeepsTheFirstTombstoneDate() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let clock = Clock()
        let store = LocalGalleryStore(folder: folder, now: { clock.next() })
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))

        try await store.delete(id: p.id)
        try await store.delete(id: p.id)

        #expect(try await store.allPaintings().first?.deletedAt == Date(timeIntervalSince1970: 1))
    }

    @Test func deletingAnUnknownPaintingFails() async throws {
        let store = LocalGalleryStore(folder: makeFolder())
        let id = UUID()
        await #expect(throws: GalleryStoreError.notFound(id)) { try await store.delete(id: id) }
    }

    @Test func statsRoundTripAndAreNilWhenNeverSaved() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        #expect(try await store.stats(for: p.id) == nil)

        var stats = SessionStats()
        stats.duration = 42
        stats.gripCycles = [.left: 3, .right: 5]
        stats.romDegrees = [.right: 88.5]
        try await store.save(stats, for: p.id)

        #expect(try await store.stats(for: p.id) == stats)
    }

    @Test func statsOfADeletedOrUnknownPaintingAreNil() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        try await store.save(SessionStats(), for: p.id)
        try await store.delete(id: p.id)

        #expect(try await store.stats(for: p.id) == nil)
        #expect(try await store.stats(for: UUID()) == nil)
    }

    @Test func savingStatsForAnUnknownPaintingFails() async throws {
        let store = LocalGalleryStore(folder: makeFolder())
        let id = UUID()
        await #expect(throws: GalleryStoreError.notFound(id)) { try await store.save(SessionStats(), for: id) }
    }

    @Test func aBrokenRecordIsSkippedAndTheRestStillLoads() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let good = painting(at: 100)
        let broken = painting(at: 200)
        try await store.save(good, png: Data([1]))
        try await store.save(broken, png: Data([2]))
        try Data("not json".utf8).write(to: folder.appending(path: broken.id.uuidString).appending(path: "painting.json"))

        #expect(try await store.paintings() == [good])
    }

    // MARK: sync state

    @Test func aNewPaintingHasNothingSyncedYet() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))

        let snapshot = try await store.syncSnapshot()

        #expect(snapshot == [LocalPaintingState(painting: p, hasStats: false, sync: SyncState())])
    }

    @Test func markersAreRememberedAcrossStores() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        try await store.save(SessionStats(), for: p.id)
        try await store.setImageInFlight(true, for: p.id)

        let state = try await LocalGalleryStore(folder: folder).syncSnapshot().first
        #expect(state?.hasStats == true)
        #expect(state?.sync == SyncState(imageUploaded: false, imageInFlight: true, statsPushed: false))

        try await store.markImageUploaded(for: p.id)
        try await store.markStatsPushed(for: p.id)
        let done = try await store.syncSnapshot().first
        #expect(done?.sync == SyncState(imageUploaded: true, imageInFlight: false, statsPushed: true))
    }

    @Test func newStatsMakeThePaintingDirtyAgain() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        try await store.save(SessionStats(), for: p.id)
        try await store.markStatsPushed(for: p.id)

        var changed = SessionStats()
        changed.duration = 9
        try await store.save(changed, for: p.id)

        #expect(try await store.syncSnapshot().first?.sync.statsPushed == false)
    }

    @Test func savingAPaintingAgainForgetsThatItsImageWasSent() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))
        try await store.markImageUploaded(for: p.id)

        try await store.save(p, png: Data([2]))

        #expect(try await store.syncSnapshot().first?.sync.imageUploaded == false)
    }

    @Test func aPaintingFromTheServerIsStoredAsSynced() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100, templateID: "fish")
        var stats = SessionStats()
        stats.duration = 5

        try await store.saveFromRemote(p, png: Data([7]), stats: stats)

        #expect(try await store.paintings() == [p])
        #expect(try await store.imageData(for: p.id) == Data([7]))
        #expect(try await store.stats(for: p.id) == stats)
        #expect(try await store.syncSnapshot().first?.sync == SyncState(imageUploaded: true, imageInFlight: false, statsPushed: true))
    }

    @Test func aRemoteTombstoneDeletesLocally() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let p = painting(at: 100)
        try await store.save(p, png: Data([1]))

        try await store.applyRemoteTombstone(for: p.id)

        #expect(try await store.paintings().isEmpty)
        #expect(try await store.allPaintings().first?.isDeleted == true)
    }

    @Test func markersForAnUnknownPaintingFail() async throws {
        let store = LocalGalleryStore(folder: makeFolder())
        let id = UUID()
        await #expect(throws: GalleryStoreError.notFound(id)) { try await store.markImageUploaded(for: id) }
        await #expect(throws: GalleryStoreError.notFound(id)) { try await store.setImageInFlight(true, for: id) }
    }

    @Test func aFolderWithoutARecordIsIgnored() async throws {
        let folder = makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalGalleryStore(folder: folder)
        let id = UUID()
        let half = folder.appending(path: id.uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: half, withIntermediateDirectories: true)
        try Data([1]).write(to: half.appending(path: "image.png"))

        #expect(try await store.paintings().isEmpty)
    }
}

// A pretend clock that moves one second each time it is read.
private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var seconds: TimeInterval = 0

    func next() -> Date {
        lock.lock()
        defer { lock.unlock() }
        seconds += 1
        return Date(timeIntervalSince1970: seconds)
    }
}
