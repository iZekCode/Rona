//
//  SupabaseAuthService.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Supabase

// Logs in through Supabase and keeps the login safely on the iPad.
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

    // The user id and a fresh pass that a background upload needs.
    func uploadCredentials() async throws -> BackgroundImageUploader.Credentials {
        let session = try await client.auth.session
        return .init(userID: session.user.id, accessToken: session.accessToken)
    }

    private static func state(of session: Session) -> AuthState {
        .signedIn(userID: session.user.id, isAnonymous: session.user.isAnonymous)
    }
}
