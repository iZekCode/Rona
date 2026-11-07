import Foundation

// Who the app is signed in as; anonymous until the parent links Sign in with Apple.
nonisolated enum AuthState: Equatable, Sendable {
    case signedOut
    case signedIn(userID: UUID, isAnonymous: Bool)
}

// What the app needs from sign-in; SupabaseAuthService implements it.
nonisolated protocol AuthService: Sendable {
    // The saved session, refreshed if needed; .signedOut when there is none.
    func restore() async throws -> AuthState
    func signInAnonymously() async throws -> AuthState
    // Links Apple to the anonymous user; the user id stays the same.
    func linkApple(idToken: String, nonce: String) async throws -> AuthState
}
