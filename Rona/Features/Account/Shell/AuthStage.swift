import Observation

// Signs the app in once the parent has agreed, records the consent on the account's profile, and keeps
// who it is signed in as. Neither step blocks the app: pages read the local store, and `failed` only
// says a retry is due.
@Observable
final class AuthStage {
    private(set) var state: AuthState = .signedOut
    private(set) var failed = false
    // Signed in and the consent is on the profile row: from here the sync can run.
    private(set) var isReady = false

    @ObservationIgnored private let service: any AuthService
    @ObservationIgnored private let profiles: any ProfileRepository
    @ObservationIgnored private var running = false
    @ObservationIgnored private var recordedVersion: Int?

    init(service: any AuthService, profiles: any ProfileRepository) {
        self.service = service
        self.profiles = profiles
    }

    // Links Apple to the anonymous account, behind the Sign in with Apple button. The user id stays the
    // same, so the paintings and the profile need no move. Throws AccountLinkError.alreadyUsed when
    // that Apple account belongs to another account.
    func linkApple(idToken: String, nonce: String) async throws {
        state = try await service.linkApple(idToken: idToken, nonce: nonce)
    }

    // Restores the saved session (or signs in anonymously when there is none), then makes sure the
    // profile row holds the consent. nil means the parent has not agreed yet, and nothing runs.
    // Safe to call again (after consent, when the app comes back): a run in flight blocks it, and each
    // step is skipped once done.
    func start(agreement: ConsentRecord?) async {
        // Before consent nothing runs, not even a restore: no sign-in and no network (ADR 0001, decision 4).
        guard let agreement, !running else { return }
        running = true
        defer { running = false }
        do {
            if state == .signedOut {
                let current = try await service.restore()
                switch AuthPlan.nextStep(needsConsent: false, state: current) {
                case .waitForConsent:
                    return
                case .signInAnonymously:
                    state = try await service.signInAnonymously()
                case .ready:
                    state = current
                }
            }
            if case .signedIn(let userID, _) = state, recordedVersion != agreement.version {
                try await profiles.record(agreement, for: userID)
                recordedVersion = agreement.version
            }
            isReady = state != .signedOut
            failed = false
        } catch {
            // A failed restore (offline, expired token) must not fall through to a new anonymous user:
            // that would orphan the child's paintings on the old one.
            failed = true
        }
    }
}
