import Foundation
import Testing
@testable import Rona

struct AuthPlanTests {
    private let user = AuthState.signedIn(userID: UUID(), isAnonymous: true)

    @Test func nothingHappensBeforeConsent() {
        #expect(AuthPlan.nextStep(needsConsent: true, state: .signedOut) == .waitForConsent)
        #expect(AuthPlan.nextStep(needsConsent: true, state: user) == .waitForConsent)
    }

    @Test func consentWithoutASessionSignsInAnonymously() {
        #expect(AuthPlan.nextStep(needsConsent: false, state: .signedOut) == .signInAnonymously)
    }

    @Test func consentWithASessionIsReady() {
        #expect(AuthPlan.nextStep(needsConsent: false, state: user) == .ready)
        let linked = AuthState.signedIn(userID: UUID(), isAnonymous: false)
        #expect(AuthPlan.nextStep(needsConsent: false, state: linked) == .ready)
    }
}
