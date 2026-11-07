import CryptoKit
import Foundation

// Random nonce for Sign in with Apple, so a stolen ID token cannot be replayed.
nonisolated enum AppleNonce {
    private static let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")

    static func make(length: Int = 32) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
