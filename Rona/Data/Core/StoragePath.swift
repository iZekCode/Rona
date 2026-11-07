import Foundation

// Where a painting's PNG lives in the private bucket `paintings` (docs/data-model.md).
nonisolated enum StoragePath {
    // Lowercase on purpose: the Storage policy compares the first folder with auth.uid()::text, which is
    // lowercase, while UUID.uuidString is uppercase. An uppercase folder is refused by the policy.
    static func image(userID: UUID, paintingID: UUID) -> String {
        "\(userID.uuidString.lowercased())/\(paintingID.uuidString.lowercased()).png"
    }
}
