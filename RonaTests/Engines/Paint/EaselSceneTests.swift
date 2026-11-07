//
//  EaselSceneTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import Testing
import simd
@testable import Rona

struct EaselSceneTests {
    private func makeEasel() -> EaselScene {
        let easel = EaselScene(scene: SCNScene(), paint: SCNNode())
        easel.fit(size: CGSize(width: 1600, height: 1000))
        return easel
    }

    @Test func castsNoShadowsAndHasNoContactShading() {
        let easel = makeEasel()
        var lights: [SCNLight] = []
        easel.scene.rootNode.enumerateHierarchy { node, _ in
            if let light = node.light { lights.append(light) }
        }
        #expect(lights.count == 2)
        #expect(lights.allSatisfy { !$0.castsShadow })
        #expect(easel.cameraNode.camera?.screenSpaceAmbientOcclusionIntensity == 0)
    }

    @Test func fittingMovesTheCameraBackForAWiderOrTallerWindow() {
        let easel = makeEasel()
        let before = easel.cameraNode.simdPosition.z
        #expect(before == easel.layout.cameraDistance)
        easel.fit(size: CGSize(width: 1000, height: 1600))
        #expect(easel.cameraNode.simdPosition.z != before)
        easel.fit(size: .zero)
        #expect(easel.cameraNode.simdPosition.z == easel.layout.cameraDistance)
    }

    @Test func shakingKeepsTheCameraNearRest() {
        let easel = makeEasel()
        easel.shakeCamera(0.05)
        let p = easel.cameraNode.simdPosition
        #expect(abs(p.x) <= 0.05)
        #expect(abs(p.y - CanvasLayout.cameraY) <= 0.05)
        easel.shakeCamera(0)
        #expect(easel.cameraNode.simdPosition == SIMD3(0, CanvasLayout.cameraY, easel.layout.cameraDistance))
    }

    @Test func linenBoardSitsBehindThePaint() {
        let easel = makeEasel()
        let paint = SCNNode()
        let booth = easel.photoBooth(paint: paint)
        #expect(booth != nil)
        #expect(booth!.board.simdWorldPosition.z < CanvasLayout.canvasZ)
    }
}
