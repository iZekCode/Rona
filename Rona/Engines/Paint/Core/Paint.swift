//
//  Paint.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// The six paint colours. The order matches the texture model file, and four of them belong to the four characters.
nonisolated enum Paint {
    static let colors: [SIMD3<Float>] = [
        SIMD3(0.97, 0.38, 0.40),
        SIMD3(0.36, 0.64, 0.89),
        SIMD3(0.97, 0.82, 0.10),
        SIMD3(0.99, 0.55, 0.12),
        SIMD3(0.08, 0.66, 0.35),
        SIMD3(0.54, 0.42, 0.77),
    ]
}
