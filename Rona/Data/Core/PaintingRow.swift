import Foundation

// A `paintings` table row; nil fields are left out, so an upsert never overwrites them.
nonisolated struct PaintingRow: Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var templateID: String?
    var paintedAt: Date
    var imagePath: String
    var recordingPath: String?
    var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case templateID = "template_id"
        case paintedAt = "painted_at"
        case imagePath = "image_path"
        case recordingPath = "recording_path"
        case deletedAt = "deleted_at"
    }

    // The row to write for a painting of this user.
    init(_ painting: Painting, userID: UUID) {
        id = painting.id
        self.userID = userID
        templateID = painting.templateID
        paintedAt = painting.paintedAt
        imagePath = StoragePath.image(userID: userID, paintingID: painting.id)
        recordingPath = nil
        deletedAt = nil
    }

    var painting: Painting {
        Painting(id: id, templateID: templateID, paintedAt: paintedAt, hasRecording: recordingPath != nil,
                 deletedAt: deletedAt)
    }
}
