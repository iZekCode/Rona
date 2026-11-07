import AuthenticationServices
import SwiftUI

// For the parent: keeps the paintings on an Apple account, asking for no name or email.
struct LinkAccountView: View {
    let auth: AuthStage

    @Environment(\.dismiss) private var dismiss
    @State private var nonce = ""
    @State private var message: String?

    var body: some View {
        ZStack {
            PageBackground()
            VStack(spacing: 24) {
                Text("Simpan akun")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                content
                if let message {
                    Text(message)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                Button("Tutup") { dismiss() }
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .frame(minHeight: Theme.minTap)
            }
            .padding(40)
            .frame(maxWidth: 640)
        }
    }

    @ViewBuilder private var content: some View {
        switch auth.state {
        case .signedIn(_, isAnonymous: false):
            Label("Akun sudah tersimpan di Apple", systemImage: "checkmark.seal.fill")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
        case .signedIn(_, isAnonymous: true):
            Text("Masuk dengan Apple supaya lukisan tidak hilang kalau iPad diganti.")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            SignInWithAppleButton(.continue, onRequest: prepare, onCompletion: finish)
                .frame(height: 64)
                .frame(maxWidth: 360)
        case .signedOut:
            Text("Belum tersambung. Coba lagi nanti.")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
        }
    }

    private func prepare(_ request: ASAuthorizationAppleIDRequest) {
        message = nil
        nonce = AppleNonce.make()
        request.requestedScopes = []
        request.nonce = AppleNonce.sha256(nonce)
    }

    private func finish(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled { message = "Gagal masuk dengan Apple." }
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
                message = "Gagal masuk dengan Apple."
                return
            }
            let nonce = nonce
            Task {
                do {
                    try await auth.linkApple(idToken: token, nonce: nonce)
                } catch AccountLinkError.alreadyUsed {
                    message = "Akun Apple ini sudah dipakai di akun lain."
                } catch {
                    message = "Gagal menyimpan akun. Coba lagi nanti."
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    LinkAccountView(auth: .preview)
}
