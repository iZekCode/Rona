import Foundation
import Supabase

// Sign-in through Supabase Auth. The session is kept in the Keychain by the library.
nonisolated struct SupabaseAuthService: AuthService {
    let client: SupabaseClient

    func restore() async throws -> AuthState {
        do {
            return Self.state(of: try await client.auth.session)
        } catch AuthError.sessionMissing {
            return .signedOut
        }
    }

    func signInAnonymously() async throws -> AuthState {
        Self.state(of: try await client.auth.signInAnonymously())
    }

    func linkApple(idToken: String, nonce: String) async throws -> AuthState {
        let credentials = OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        do {
            return Self.state(of: try await client.auth.linkIdentityWithIdToken(credentials: credentials))
        } catch let error as AuthError where error.errorCode == .identityAlreadyExists {
            throw AccountLinkError.alreadyUsed
        }
    }

    private static func state(of session: Session) -> AuthState {
        .signedIn(userID: session.user.id, isAnonymous: session.user.isAnonymous)
    }
}
