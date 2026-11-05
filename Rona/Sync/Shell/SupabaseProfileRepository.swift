import Foundation
import Supabase

// Writes the profile row through the API; row level security lets a user touch only their own row.
nonisolated struct SupabaseProfileRepository: ProfileRepository {
    let client: SupabaseClient

    private struct StoredConsent: Decodable {
        let consentVersion: Int

        enum CodingKeys: String, CodingKey { case consentVersion = "consent_version" }
    }

    private struct Row: Encodable {
        let id: UUID
        let consentedAt: Date
        let consentVersion: Int

        enum CodingKeys: String, CodingKey {
            case id
            case consentedAt = "consented_at"
            case consentVersion = "consent_version"
        }
    }

    func record(_ consent: ConsentRecord, for userID: UUID) async throws {
        let stored: [StoredConsent] = try await client.from("profiles")
            .select("consent_version")
            .eq("id", value: userID)
            .execute()
            .value
        guard ConsentPolicy.needsProfileUpdate(storedVersion: stored.first?.consentVersion,
                                               agreedVersion: consent.version) else { return }
        let row = Row(id: userID, consentedAt: consent.acceptedAt, consentVersion: consent.version)
        try await client.from("profiles").upsert(row, onConflict: "id").execute()
    }
}
