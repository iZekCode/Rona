//
//  BrushDab.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// One bit of paint a character lays in one frame, from one spot to the next.
nonisolated struct BrushDab: Sendable {
    var from: SIMD2<Float>
    var to: SIMD2<Float>
    var radius: Float
    var speed: Float
    var style: BrushStyle = .brush
    var drag: SIMD2<Float>?
}
