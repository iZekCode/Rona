//
//  ToyboxTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import Testing
import simd
@testable import Rona

struct ToyboxTests {
    @Test func blinkClosesThenOpens() {
        #expect(Toybox.blinkScale(-1) == 1)
        #expect(Toybox.blinkScale(1) == 1)
        #expect(abs(Toybox.blinkScale(0.07) - 0.1) < 1e-5)
        #expect(Toybox.blinkScale(0.03) < 1 && Toybox.blinkScale(0.03) > 0.1)
        #expect(Toybox.blinkScale(0.12) > 0.1 && Toybox.blinkScale(0.12) < 1)
    }

    @Test func pupilLooksTowardTheDirectionAndStaysOnTheEye() {
        let eye = Toybox.eye(radius: 0.1)
        Toybox.look(eye, toward: SIMD2(1, 0))
        #expect(eye.pupil.simdPosition.x > 0)
        Toybox.look(eye, toward: SIMD2(50, 50))
        let p = eye.pupil.simdPosition
        #expect(simd_length(SIMD2(p.x, p.y)) <= eye.radius * 0.33)
    }

    @Test func balloonWobbleCanBeChanged() {
        let material = Toybox.balloon(SIMD3(1, 0, 0), wobble: 0.01)
        #expect((material.value(forKey: "wobbleAmount") as? NSNumber)?.floatValue == 0.01)
        Toybox.setWobble(material, 0)
        #expect((material.value(forKey: "wobbleAmount") as? NSNumber)?.floatValue == 0)
    }

    @Test func aBurstAddsAnEmitterThatCleansItselfUp() {
        let scene = SCNScene()
        Toybox.burst(in: scene, at: .zero, color: Paint.colors[0])
        #expect(scene.rootNode.childNodes.count == 1)
        Toybox.confetti(in: scene, at: .zero)
        #expect(scene.rootNode.childNodes.count == 1 + Paint.colors.count)
    }

    @Test func meshBuilderMakesATriangle() {
        let mesh = MeshBuilder.geometry(positions: [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(0, 1, 0)],
                                        normals: Array(repeating: SIMD3(0, 0, 1), count: 3), indices: [0, 1, 2])
        #expect(mesh.sources(for: .vertex).first?.vectorCount == 3)
        #expect(mesh.elements.first?.primitiveCount == 1)
    }
}
