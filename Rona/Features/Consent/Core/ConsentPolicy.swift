//
//  ConsentPolicy.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Decides if the parent must agree again; raise currentVersion when the agreement text changes.
nonisolated enum ConsentPolicy {
    static let currentVersion = 1

    static func needsConsent(acceptedVersion: Int?, currentVersion: Int = ConsentPolicy.currentVersion) -> Bool {
        guard let acceptedVersion else { return true }
        return acceptedVersion < currentVersion
    }

    // Updates the profile only when it has no agreement or an older one.
    static func needsProfileUpdate(storedVersion: Int?, agreedVersion: Int) -> Bool {
        guard let storedVersion else { return true }
        return storedVersion < agreedVersion
    }
}
