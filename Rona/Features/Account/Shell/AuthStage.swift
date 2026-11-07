import Observation

// Signs in after consent and records it on the profile, without ever blocking the pages.
@Observable
final class AuthStage {
    private(set) var state: AuthState = .signedOut
    private(set) var failed = false
    private(set) var isReady = false

    @ObservationIgnored private let service: any AuthService
    @ObservationIgnored private let profiles: any ProfileRepository
    @ObservationIgnored private var running = false
    @ObservationIgnored private var recordedVersion: Int?

    init(service: any AuthService, profiles: any ProfileRepository) {
        self.service = service
        self.profiles = profiles
    }

    // Links Apple to the anonymous account; throws AccountLinkError.alreadyUsed if that Apple ID is taken.
    func linkApple(idToken: String, nonce: String) async throws {
        state = try await service.linkApple(idToken: idToken, nonce: nonce)
    }

    // Restores or signs in, then records consent; safe to call again, and a failed restore never makes a new user.
    func start(agreement: ConsentRecord?) async {
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
            failed = true
        }
    }
}
