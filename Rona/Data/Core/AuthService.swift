//
//  AuthService.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

// What the app needs to log in; SupabaseAuthService does the real work.
nonisolated protocol AuthService: Sendable {
    // Picks up the last login, or says nobody is logged in.
    func restore() async throws -> AuthState
    func signInAnonymously() async throws -> AuthState
    // Connects an Apple account to the guest account, keeping the same user.
    func linkApple(idToken: String, nonce: String) async throws -> AuthState
}
