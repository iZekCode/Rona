import Foundation

// The account's profile row, which holds the consent (ADR 0001, decision 4).
nonisolated protocol ProfileRepository: Sendable {
    // Records this consent unless the row already holds this version or a newer one.
    func record(_ consent: ConsentRecord, for userID: UUID) async throws
}
