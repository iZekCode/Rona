import Foundation
import Testing
@testable import Rona

struct ConsentPolicyTests {
    @Test func noConsentYetNeedsConsent() {
        #expect(ConsentPolicy.needsConsent(acceptedVersion: nil, currentVersion: 1))
    }

    @Test func currentVersionDoesNotAskAgain() {
        #expect(!ConsentPolicy.needsConsent(acceptedVersion: 2, currentVersion: 2))
    }

    @Test func newerVersionAsksAgain() {
        #expect(ConsentPolicy.needsConsent(acceptedVersion: 1, currentVersion: 2))
    }
}

struct ConsentStoreTests {
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "rona-tests-\(UUID().uuidString)")!
        return defaults
    }

    @Test func freshStoreNeedsConsent() {
        let store = ConsentStore(defaults: makeDefaults())
        #expect(store.needsConsent)
        #expect(store.acceptedVersion == nil)
        #expect(store.acceptedAt == nil)
    }

    @Test func acceptingRecordsVersionAndDate() {
        let store = ConsentStore(defaults: makeDefaults())
        let date = Date(timeIntervalSince1970: 1_000)

        store.accept(at: date)

        #expect(!store.needsConsent)
        #expect(store.acceptedVersion == ConsentPolicy.currentVersion)
        #expect(store.acceptedAt == date)
    }

    @Test func consentSurvivesANewStoreOnTheSameDefaults() {
        let defaults = makeDefaults()
        let date = Date(timeIntervalSince1970: 2_000)
        ConsentStore(defaults: defaults).accept(at: date)

        let again = ConsentStore(defaults: defaults)

        #expect(!again.needsConsent)
        #expect(again.acceptedAt == date)
    }

    @Test func consentFromAnOlderVersionAsksAgain() {
        let defaults = makeDefaults()
        defaults.set(ConsentPolicy.currentVersion - 1, forKey: "consent.version")

        #expect(ConsentStore(defaults: defaults).needsConsent)
    }
}
