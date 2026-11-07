import Foundation

// Where a painting's PNG lives in the private bucket `paintings` (docs/data-model.md).
nonisolated enum StoragePath {
    // Lowercase on purpose: the Storage policy compares it with auth.uid(), which is lowercase.
    static func image(userID: UUID, paintingID: UUID) -> String {
        "\(userID.uuidString.lowercased())/\(paintingID.uuidString.lowercased()).png"
    }
}
