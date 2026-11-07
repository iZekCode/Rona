import Foundation

// Decides whether the parent must agree again; raise currentVersion when the text changes.
nonisolated enum ConsentPolicy {
    static let currentVersion = 1

    static func needsConsent(acceptedVersion: Int?, currentVersion: Int = ConsentPolicy.currentVersion) -> Bool {
        guard let acceptedVersion else { return true }
        return acceptedVersion < currentVersion
    }

    // Writes the profile consent only when it has none or an older version.
    static func needsProfileUpdate(storedVersion: Int?, agreedVersion: Int) -> Bool {
        guard let storedVersion else { return true }
        return storedVersion < agreedVersion
    }
}
