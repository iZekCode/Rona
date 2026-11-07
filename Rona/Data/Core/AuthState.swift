//
//  AuthState.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Who the app is logged in as; a guest until the parent connects an Apple account.
nonisolated enum AuthState: Equatable, Sendable {
    case signedOut
    case signedIn(userID: UUID, isAnonymous: Bool)
}

// What the app needs to log in; SupabaseAuthService does the real work.
nonisolated protocol AuthService: Sendable {
    // Picks up the last login, or says nobody is logged in.
    func restore() async throws -> AuthState
    func signInAnonymously() async throws -> AuthState
    // Connects an Apple account to the guest account, keeping the same user.
    func linkApple(idToken: String, nonce: String) async throws -> AuthState
}
