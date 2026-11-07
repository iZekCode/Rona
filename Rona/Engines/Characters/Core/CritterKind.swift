//
//  CritterKind.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// The four characters that carry the paint. The raw numbers are kept from the prototype so saved recordings still match.
nonisolated enum CritterKind: Int, CaseIterable, Equatable, Sendable {
    case snail = 1
    case ladybug = 7, butterfly = 8, frog = 10

    static let gardenCast: [CritterKind] = [.ladybug, .butterfly, .frog, .snail]

    var signatureColor: SIMD3<Float> {
        switch self {
        case .ladybug: return Paint.colors[0]
        case .butterfly: return Paint.colors[1]
        case .frog: return Paint.colors[4]
        case .snail: return Paint.colors[3]
        }
    }
}
