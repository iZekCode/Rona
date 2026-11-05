import CryptoKit
import Foundation

// One sign-in attempt with Apple uses a random nonce: Apple gets its SHA-256 and signs it into the ID
// token, Supabase gets the original and checks the two match. This stops a stolen token from being replayed.
nonisolated enum AppleNonce {
    private static let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")

    static func make(length: Int = 32) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
