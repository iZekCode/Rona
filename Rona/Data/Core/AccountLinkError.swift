//
//  AccountLinkError.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// Why connecting an Apple account failed, in words a page can show.
nonisolated enum AccountLinkError: Error, Equatable, Sendable {
    case alreadyUsed
}
