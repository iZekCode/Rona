//
//  FrameTiming.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation

// Small per-frame numbers that only depend on time: a safe frame step, the beat pulse and the music energy.
nonisolated enum FrameTiming {
    static func clampedDT(_ raw: Float) -> Float { min(max(raw, 1.0 / 240.0), 1.0 / 20.0) }

    static func beatPulse(beat: Double) -> Float {
        exp(-Float(beat - beat.rounded(.down)) * 6)
    }

    static func energy(_ energy: Float, movement: Float, dt: Float) -> Float {
        energy + (min(movement / 3, 1) - energy) * min(1, dt * 1.5)
    }
}
