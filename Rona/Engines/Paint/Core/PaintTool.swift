//
//  PaintTool.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// The four paint characters. Each has one colour, one name and its own way of painting.
nonisolated enum PaintTool: Int, CaseIterable, Equatable, Sendable {
    case ladybug, butterfly, frog, snail

    var name: String {
        switch self {
        case .ladybug: return "Kepik"
        case .butterfly: return "Kupu-kupu"
        case .frog: return "Katak"
        case .snail: return "Siput"
        }
    }

    var critterKind: CritterKind {
        switch self {
        case .ladybug: return .ladybug
        case .butterfly: return .butterfly
        case .frog: return .frog
        case .snail: return .snail
        }
    }

    var colorIndex: Int {
        switch self {
        case .ladybug: return 0
        case .butterfly: return 1
        case .frog: return 4
        case .snail: return 3
        }
    }

    var color: SIMD3<Float> { Paint.colors[colorIndex] }

    // The paint for one frame's step from a to b along the character's path.
    func dabs(from a: SIMD2<Float>, to b: SIMD2<Float>, radius: Float, speed: Float) -> [BrushDab] {
        switch self {
        case .ladybug, .frog:
            return [BrushDab(from: a, to: b, radius: radius, speed: speed, style: .wash)]
        case .butterfly:
            return [BrushDab(from: a, to: b, radius: radius * 1.15, speed: speed, style: .wash)]
        case .snail:
            return [BrushDab(from: a, to: b, radius: radius * 1.3, speed: speed, style: .wash)]
        }
    }
}
