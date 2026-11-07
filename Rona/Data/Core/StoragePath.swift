//
//  StoragePath.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Where a painting's picture is stored online.
nonisolated enum StoragePath {
    // Uses lowercase ids, because the online storage rules only accept lowercase.
    static func image(userID: UUID, paintingID: UUID) -> String {
        "\(userID.uuidString.lowercased())/\(paintingID.uuidString.lowercased()).png"
    }
}
