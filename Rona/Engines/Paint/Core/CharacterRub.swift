//
//  CharacterRub.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// Rubbing a buddy over a sleeping character. Rub long and fast enough and the buddy turns into that character.
nonisolated enum CharacterRub {
    static func rubGain(dt: Float, speed: Float) -> Float {
        dt * 0.9 + min(speed, 3) * dt * 0.9
    }

    struct Perch: Equatable, Sendable {
        let tool: PaintTool
        let position: SIMD3<Float>
    }

    struct Rubber: Sendable {
        var idle: Bool
        var position: SIMD2<Float>
        var tool: PaintTool
        var speed: Float
    }

    struct Step: Equatable, Sendable {
        var target: PaintTool?
        var amount: Float
        var perch: Perch?
        var started = false
        var progress: Float = 0
        var picked = false
    }

    static func step(target: PaintTool?, amount: Float, rubber: Rubber, perches: [Perch], dt: Float) -> Step {
        guard !rubber.idle, let perch = perch(under: rubber, perches: perches) else {
            return Step(target: nil, amount: 0)
        }
        var step = Step(target: target, amount: amount, perch: perch)
        if target != perch.tool {
            step.target = perch.tool
            step.amount = 0
            step.started = true
        }
        step.amount += rubGain(dt: dt, speed: rubber.speed)
        step.progress = min(step.amount, 1)
        if step.progress >= 1 {
            step.target = nil
            step.amount = 0
            step.picked = true
        }
        return step
    }

    private static func perch(under rubber: Rubber, perches: [Perch]) -> Perch? {
        guard let perch = perches.first(where: {
            CanvasLayout.touches(rubber.position, characterAt: $0.position)
        }), perch.tool != rubber.tool else { return nil }
        return perch
    }

    // How far along the fastest rubber of this character is. 0 when nobody rubs it.
    static func progress(of tool: PaintTool, rubs: [(target: PaintTool?, amount: Float)]) -> Float {
        rubs.filter { $0.target == tool }.map(\.amount).max() ?? 0
    }
}
