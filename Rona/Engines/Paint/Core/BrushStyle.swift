//
//  BrushStyle.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation

// How one dab of paint behaves: how much it lays, how it drags, and what texture it grows.
nonisolated struct BrushStyle: Equatable, Sendable {
    var amount: Float?
    var push: Float = 0.55
    var bristles: Float = 1
    var nibAngle: Float = 0
    var nibAspect: Float = 1
    var watery: Float = 0
    var knife: Float = 0
    var impasto: Float = 0
    var runs: Float = 0
    var blend: Float = 0
    var nca: Float = 0
    var ncaSeed: Float = 1

    static let brush = BrushStyle()
    static let wash = BrushStyle(push: 0.4, bristles: 0, watery: 0.9, nca: 1)
    static let blend = BrushStyle(amount: 0, push: 0.9, bristles: 0, blend: 1)
}
