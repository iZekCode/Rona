import Foundation

// Decides whether the parent has to agree (again). Raise currentVersion when the consent text or
// what is uploaded changes, and every device asks once more.
nonisolated enum ConsentPolicy {
    static let currentVersion = 1

    static func needsConsent(acceptedVersion: Int?, currentVersion: Int = ConsentPolicy.currentVersion) -> Bool {
        guard let acceptedVersion else { return true }
        return acceptedVersion < currentVersion
    }

    // The profile row holds the consent of this account. It is written when it has none, or an older
    // version, and left alone otherwise so the first date of a version is kept.
    static func needsProfileUpdate(storedVersion: Int?, agreedVersion: Int) -> Bool {
        guard let storedVersion else { return true }
        return storedVersion < agreedVersion
    }
}
