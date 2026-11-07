import Foundation
import Observation

// What the parent agreed to, kept on the device.
@Observable
final class ConsentStore {
    private(set) var acceptedVersion: Int?
    private(set) var acceptedAt: Date?

    @ObservationIgnored private let defaults: UserDefaults
    private static let versionKey = "consent.version"
    private static let dateKey = "consent.acceptedAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        acceptedVersion = defaults.object(forKey: Self.versionKey) as? Int
        acceptedAt = (defaults.object(forKey: Self.dateKey) as? Double).map(Date.init(timeIntervalSince1970:))
    }

    var needsConsent: Bool { ConsentPolicy.needsConsent(acceptedVersion: acceptedVersion) }

    var agreement: ConsentRecord? {
        guard !needsConsent, let acceptedVersion, let acceptedAt else { return nil }
        return ConsentRecord(acceptedAt: acceptedAt, version: acceptedVersion)
    }

    func accept(at date: Date = Date()) {
        acceptedVersion = ConsentPolicy.currentVersion
        acceptedAt = date
        defaults.set(ConsentPolicy.currentVersion, forKey: Self.versionKey)
        defaults.set(date.timeIntervalSince1970, forKey: Self.dateKey)
    }
}
