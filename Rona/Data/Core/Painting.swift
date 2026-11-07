//
//  Painting.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation

// One saved painting; a deleted one keeps a deleted date so the delete can be backed up.
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
