//
//  StrokePoint.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// One point of a stroke: where it was laid and when.
nonisolated struct StrokePoint: Sendable {
    var p: SIMD2<Float>
    var born: Double
}
