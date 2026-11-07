import Foundation

// The account's profile row, which holds the consent (ADR 0001, decision 4).
nonisolated protocol ProfileRepository: Sendable {
    // Makes sure the row of this user holds this consent. Does nothing when it already holds this
    // version or a newer one.
    func record(_ consent: ConsentRecord, for userID: UUID) async throws
}
