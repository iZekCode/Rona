//
//  AppleNonce.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import CryptoKit
import Foundation

// A one-time random code for Sign in with Apple, so a stolen login cannot be reused.
nonisolated enum AppleNonce {
    private static let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")

    static func make(length: Int = 32) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
