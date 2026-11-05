import Foundation

// What the device remembers about one painting's trip to the server. Kept beside the painting, so it
// survives a restart. The server's own list is the truth about what exists there; these flags only avoid
// sending the same bytes twice.
nonisolated struct SyncState: Codable, Equatable, Sendable {
    var imageUploaded = false
    // A background upload was handed to the system and has not reported back yet.
    var imageInFlight = false
    var statsPushed = false
}

// One painting as the device sees it.
nonisolated struct LocalPaintingState: Equatable, Sendable {
    let painting: Painting
    let hasStats: Bool
    let sync: SyncState
}

nonisolated enum SyncAction: Equatable, Sendable {
    case uploadImage(UUID)
    case pushRow(UUID)
    case pushStats(UUID)
    case pushTombstone(UUID)
    // The server says it was deleted (on another iPad): delete it here too.
    case applyRemoteTombstone(UUID)
    // The server has it and this device does not (a new iPad, or a reinstall).
    case download(UUID)
}

// Works out what to do from the device's paintings and the server's list (tombstones included), with no I/O.
// Paintings are almost never edited, so there is little to merge: a delete always wins, and the rest is
// "send what the server lacks, fetch what the device lacks".
nonisolated enum SyncPlan {
    static func actions(local: [LocalPaintingState], remote: [Painting]) -> [SyncAction] {
        let remoteByID = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var actions: [SyncAction] = []

        for item in local {
            let id = item.painting.id
            let theirs = remoteByID[id]

            if item.painting.isDeleted {
                // Only a painting the server holds live needs the tombstone; one it never saw needs nothing.
                if let theirs, !theirs.isDeleted { actions.append(.pushTombstone(id)) }
                continue
            }
            guard let theirs else {
                // The server lacks it: the image goes first, then the row, then the stats.
                if item.sync.imageInFlight { continue }
                if !item.sync.imageUploaded {
                    actions.append(.uploadImage(id))
                } else {
                    actions.append(.pushRow(id))
                    if item.hasStats && !item.sync.statsPushed { actions.append(.pushStats(id)) }
                }
                continue
            }
            if theirs.isDeleted {
                actions.append(.applyRemoteTombstone(id))
            } else if item.hasStats && !item.sync.statsPushed {
                actions.append(.pushStats(id))
            }
        }

        let localIDs = Set(local.map(\.painting.id))
        let missing = remote.filter { !localIDs.contains($0.id) && !$0.isDeleted }
            .sorted { ($0.paintedAt, $1.id.uuidString) > ($1.paintedAt, $0.id.uuidString) }
        actions += missing.map { .download($0.id) }
        return actions
    }
}
