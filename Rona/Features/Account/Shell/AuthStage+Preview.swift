#if DEBUG
import Foundation

extension AuthStage {
    static var preview: AuthStage {
        AuthStage(service: PreviewAuth(), profiles: PreviewProfiles())
    }
}

private struct PreviewAuth: AuthService {
    func restore() async throws -> AuthState { .signedOut }
    func signInAnonymously() async throws -> AuthState { .signedOut }
    func linkApple(idToken: String, nonce: String) async throws -> AuthState { .signedOut }
}

private struct PreviewProfiles: ProfileRepository {
    func record(_ consent: ConsentRecord, for userID: UUID) async throws {}
}
#endif
