//
//  AppleNonceTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Testing
@testable import Rona

struct AppleNonceTests {
    @Test func sha256MatchesTheKnownDigest() {
        #expect(AppleNonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func nonceHasTheRequestedLengthAndOnlySafeCharacters() {
        let nonce = AppleNonce.make(length: 40)
        #expect(nonce.count == 40)
        #expect(nonce.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "-._".contains($0)) })
    }

    @Test func noncesDiffer() {
        #expect(AppleNonce.make() != AppleNonce.make())
    }
}
