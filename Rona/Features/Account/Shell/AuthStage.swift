//
//  AuthStage.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Observation

// Logs in after the parent agrees and saves that agreement, without ever holding up the pages.
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

    // Connects an Apple account; fails with alreadyUsed if that Apple account is taken.
    func linkApple(idToken: String, nonce: String) async throws {
        state = try await service.linkApple(idToken: idToken, nonce: nonce)
    }

    // Logs in and saves the agreement; safe to call again, and a failed login never creates a new user.
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
