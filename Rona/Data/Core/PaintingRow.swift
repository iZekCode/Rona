//
//  PaintingRow.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// A painting in the shape the online `paintings` table expects; empty fields are skipped so nothing is wiped.
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

    // Builds the table row for this user's painting.
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
