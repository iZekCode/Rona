import Foundation

// What the device remembers about one painting's trip to the server, so bytes are not sent twice.
nonisolated struct SyncState: Codable, Equatable, Sendable {
    var imageUploaded = false
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
    case applyRemoteTombstone(UUID)
    case download(UUID)
}

// Works out the sync actions from the device and server lists, with no I/O; a delete always wins.
nonisolated enum SyncPlan {
    static func actions(local: [LocalPaintingState], remote: [Painting]) -> [SyncAction] {
        let remoteByID = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var actions: [SyncAction] = []

        for item in local {
            let id = item.painting.id
            let theirs = remoteByID[id]

            if item.painting.isDeleted {
                if let theirs, !theirs.isDeleted { actions.append(.pushTombstone(id)) }
                continue
            }
            guard let theirs else {
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
