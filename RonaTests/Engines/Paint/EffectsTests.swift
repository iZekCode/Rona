//
//  EffectsTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import Testing
import simd
@testable import Rona

struct EffectsTests {
    @Test func firefliesAreAlive() {
        let flies = Effects.fireflies()
        #expect(flies.birthRate > 0)
        #expect(flies.particleLifeSpan > 1)
    }

    @Test func aPopAddsThingsThatFlyAwayAndLeave() {
        let scene = SCNScene()
        let effects = Effects(scene: scene)
        effects.pop(at: SIMD3(0, 0, 0.3), radius: 0.3, colors: [Paint.colors[0]], eyeRadius: 0.05,
                    eyes: [SIMD3(-0.1, 0, 0.3), SIMD3(0.1, 0, 0.3)])
        let during = scene.rootNode.childNodes.count
        #expect(during > 16)
        for _ in 0..<200 { effects.update(dt: 1.0 / 60) }
        #expect(scene.rootNode.childNodes.count < during)
    }

    @Test func aColorSplashSplashesDroplets() {
        let scene = SCNScene()
        let effects = Effects(scene: scene)
        effects.colorSplash(at: SIMD3(0, 0, 0.3), color: Paint.colors[1])
        #expect(scene.rootNode.childNodes.count >= 8)
        for _ in 0..<120 { effects.update(dt: 1.0 / 60) }
        #expect(scene.rootNode.childNodes.allSatisfy { $0.geometry == nil })
    }
}
