import Foundation

/// One saved painting. The PNG lives next to it (local store) and in Storage (`{user_id}/{id}.png`).
nonisolated struct Painting: Identifiable, Equatable, Codable, Sendable {
    /// Created on the client, so a retried upload is idempotent.
    let id: UUID
    /// A `TemplateKind` raw value or a quest id; nil for freeform. Unlocks and the quest star derive from it.
    var templateID: String?
    var paintedAt: Date
    /// Local timelapse only in v1; never uploaded.
    var hasRecording: Bool
    /// Tombstone. Set instead of removing the row so the delete reaches other devices.
    var deletedAt: Date?

    var isDeleted: Bool { deletedAt != nil }

    init(id: UUID = UUID(), templateID: String? = nil, paintedAt: Date, hasRecording: Bool = false,
         deletedAt: Date? = nil) {
        self.id = id
        self.templateID = templateID
        self.paintedAt = paintedAt
        self.hasRecording = hasRecording
        self.deletedAt = deletedAt
    }
}
