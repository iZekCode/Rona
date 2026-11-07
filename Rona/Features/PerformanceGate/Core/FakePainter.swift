//
//  FakePainter.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// Makes up brush paths that wander all over the canvas, so the paint engine can be timed without a camera.
nonisolated enum FakePainter {
    static func point(slot: Int, at time: Double) -> SIMD2<Float> {
        let t = Float(time)
        let s = Float(slot)
        let half = CanvasLayout.canvasSize * 0.5 - SIMD2(repeating: 0.4)
        let x = CanvasLayout.canvasCenter.x + half.x * sin(0.7 * t + s * 1.7)
        let y = CanvasLayout.canvasCenter.y + half.y * sin(1.1 * t + s * 0.9 + 1)
        return SIMD2(x, y)
    }
}
