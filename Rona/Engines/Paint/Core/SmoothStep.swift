//
//  SmoothStep.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

// Eases from 0 to 1 as x goes from edge0 to edge1, with no jump at either end.
nonisolated func smoothStep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}
