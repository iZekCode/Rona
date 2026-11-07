//
//  AuthState.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Who the app is logged in as; a guest until the parent connects an Apple account.
nonisolated enum AuthState: Equatable, Sendable {
    case signedOut
    case signedIn(userID: UUID, isAnonymous: Bool)
}
