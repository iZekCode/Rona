//
//  AuthState.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Who the app is signed in as. Anonymous until till the parent links Sign in with Apple
nonisolated enum AuthState: Equatable, Sendable {
    case signedOut
    case signedIn(userID: UUID, isAnonymous: Bool)
}

// What the app needs from sign-in. SupabaseAuthService implement it
nonisolated protocol AuthService: Sendable {
    // The saved session, refreshed if needed; .signedOut when there is none.
    func restore() async throws -> AuthState
    func signInAnonymously() async throws -> AuthState
    // Links Apple to the current anonymous user. The user id stays the same, so no data moves.
    func linkApple(idToken: String, nonce: String) async throws -> AuthState
}
