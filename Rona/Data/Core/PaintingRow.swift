import Foundation

// A painting as a row of the `paintings` table.
// A nil field is left out of the JSON, so an upsert never overwrites a column it does not know about:
// recording_path stays null in v1, and deleted_at is only ever set by a delete.
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

    // What the pages see. The timelapse stays on the device in v1, so a row restored from the server has none.
    var painting: Painting {
        Painting(id: id, templateID: templateID, paintedAt: paintedAt, hasRecording: recordingPath != nil,
                 deletedAt: deletedAt)
    }
}
