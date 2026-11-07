//
//  AuthPlan.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

nonisolated enum AuthStep: Equatable, Sendable {
    case waitForConsent
    case signInAnonymously
    case ready
}

// Decides what to do at launch, with no I/O: nothing happens before consent
nonisolated enum AuthPlan {
    static func nextStep(needsConsent: Bool, state: AuthState) -> AuthStep {
        if needsConsent { return .waitForConsent }
        switch state {
        case .signedOut: return .signInAnonymously
        case .signedIn: return .ready
        }
    }
}
