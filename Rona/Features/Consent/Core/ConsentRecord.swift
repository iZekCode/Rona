//
//  ConsentRecord.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// What the parent agreed to: when, and which version of the text.
nonisolated struct ConsentRecord: Equatable, Sendable {
    let acceptedAt: Date
    let version: Int
}
