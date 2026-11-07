//
//  SyncEngine.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Keeps the iPad and the online copy matching in the background; it retries a few times, then waits.
actor SyncEngine {
    private let local: any LocalSyncStore
    private let remote: any RemoteGallery
    private let uploader: any ImageUploader
    private let backoff: Backoff
    private let maxAttempts: Int
    private let sleep: @Sendable (TimeInterval) async -> Void

    private var enabled = false
    private var running = false
    private var again = false
    private var uploadFailures: [Painting.ID: Int] = [:]

    init(local: any LocalSyncStore, remote: any RemoteGallery, uploader: any ImageUploader,
         backoff: Backoff = .standard, maxAttempts: Int = 6,
         sleep: @escaping @Sendable (TimeInterval) async -> Void = { seconds in
             try? await Task.sleep(for: .seconds(seconds))
         }) {
        self.local = local
        self.remote = remote
        self.uploader = uploader
        self.backoff = backoff
        self.maxAttempts = maxAttempts
        self.sleep = sleep
    }

    // Nothing is backed up until the app is logged in and the agreement is saved.
    func enable() {
        enabled = true
    }

    // Backs up now, or asks the current backup to do one more round; safe to call any time.
    func run() async {
        guard enabled else { return }
        if running {
            again = true
            return
        }
        running = true
        defer { running = false }
        var failures = 0
        repeat {
            again = false
            if await syncOnce() {
                failures = 0
            } else {
                failures += 1
                if failures >= maxAttempts { break }
                await sleep(backoff.delay(afterFailures: failures))
                again = true
            }
        } while again
    }

    // Hears that a picture finished uploading, even if the app was just woken up for it.
    func imageUploadFinished(_ id: Painting.ID, success: Bool) async {
        if success {
            uploadFailures[id] = nil
            try? await local.markImageUploaded(for: id)
        } else {
            let failures = (uploadFailures[id] ?? 0) + 1
            uploadFailures[id] = failures
            try? await local.setImageInFlight(false, for: id)
            await sleep(backoff.delay(afterFailures: failures))
        }
        await run()
    }

    // MARK: One pass

    // Does one round of backup; true when everything went through.
    private func syncOnce() async -> Bool {
        do {
            let theirs = try await remote.allPaintings()
            let snapshot = try await currentSnapshot()
            var succeeded = true
            for action in SyncPlan.actions(local: snapshot, remote: theirs) {
                do {
                    try await perform(action, snapshot: snapshot, remote: theirs)
                } catch {
                    succeeded = false
                }
            }
            return succeeded
        } catch {
            return false
        }
    }

    // Forgets uploads that iPadOS dropped (for example after a force quit) so they are sent again.
    private func currentSnapshot() async throws -> [LocalPaintingState] {
        let snapshot = try await local.syncSnapshot()
        let stale = snapshot.filter(\.sync.imageInFlight)
        guard !stale.isEmpty else { return snapshot }
        let active = await uploader.activePaintingIDs()
        let lost = stale.filter { !active.contains($0.painting.id) }
        guard !lost.isEmpty else { return snapshot }
        for item in lost { try await local.setImageInFlight(false, for: item.painting.id) }
        return try await local.syncSnapshot()
    }

    private func perform(_ action: SyncAction, snapshot: [LocalPaintingState], remote theirs: [Painting]) async throws {
        switch action {
        case .uploadImage(let id):
            try await local.setImageInFlight(true, for: id)
            do {
                try await uploader.start(paintingID: id, fileURL: await local.imageFileURL(for: id))
            } catch {
                try? await local.setImageInFlight(false, for: id)
                throw error
            }
        case .pushRow(let id):
            guard let item = snapshot.first(where: { $0.painting.id == id }) else { return }
            try await remote.pushRow(item.painting)
        case .pushStats(let id):
            guard let stats = try await local.stats(for: id) else { return }
            try await remote.pushStats(stats, for: id)
            try await local.markStatsPushed(for: id)
        case .pushTombstone(let id):
            try await remote.pushTombstone(for: id)
        case .applyRemoteTombstone(let id):
            try await local.applyRemoteTombstone(for: id)
        case .download(let id):
            guard let painting = theirs.first(where: { $0.id == id }) else { return }
            let png = try await remote.imageData(for: id)
            let stats = try await remote.stats(for: id)
            try await local.saveFromRemote(painting, png: png, stats: stats)
        }
    }
}
