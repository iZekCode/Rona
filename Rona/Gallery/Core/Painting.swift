import Foundation

// A saved painting; deleting sets deletedAt (a tombstone) so the delete can sync.
nonisolated struct Painting: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var templateID: String?
    var paintedAt: Date
    var hasRecording: Bool
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
