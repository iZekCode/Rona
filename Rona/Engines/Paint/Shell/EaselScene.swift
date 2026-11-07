//
//  EaselScene.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import simd

// The canvas scene: camera, lights and the linen canvas that fills the window. The sleeping characters are added by the page.
final class EaselScene {
    static let keyIntensity: CGFloat = 300
    static let fillIntensity: CGFloat = 220
    static let environmentIntensity: CGFloat = 0.7
    private static let exposureOffset: CGFloat = -0.5
    static let keyPosition = SIMD3<Float>(0, 7, 6)
    static let keyTarget = SIMD3<Float>(0, 0, 0)
    static let keyInnerAngle: CGFloat = 70
    static let keyOuterAngle: CGFloat = 110

    let scene: SCNScene
    let cameraNode = SCNNode()
    private(set) var layout = CanvasLayout()
    private let canvasNode = SCNNode()
    private var canvasBoard: SCNNode?
    private var studioLights: [SCNNode] = []

    init(scene: SCNScene, paint: SCNNode) {
        self.scene = scene
        scene.background.contents = UIColor(red: 0.93, green: 0.92, blue: 0.9, alpha: 1)
        scene.lightingEnvironment.contents = Studio.environment()
        scene.lightingEnvironment.intensity = Self.environmentIntensity

        let camera = SCNCamera()
        camera.fieldOfView = 34
        camera.zNear = 0.1
        camera.zFar = 50
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = Self.exposureOffset
        camera.minimumExposure = -2
        camera.maximumExposure = 2
        camera.screenSpaceAmbientOcclusionIntensity = 0
        camera.vignettingIntensity = 0
        camera.vignettingPower = 0.9
        camera.bloomIntensity = 0.12
        camera.bloomThreshold = 0.95
        camera.bloomBlurRadius = 8
        cameraNode.camera = camera
        cameraNode.simdPosition = SIMD3(0, CanvasLayout.cameraY, layout.cameraDistance)
        scene.rootNode.addChildNode(cameraNode)

        let key = SCNLight()
        key.type = .spot
        key.intensity = Self.keyIntensity
        key.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        key.spotInnerAngle = Self.keyInnerAngle
        key.spotOuterAngle = Self.keyOuterAngle
        key.attenuationStartDistance = 4
        key.attenuationEndDistance = 40
        key.attenuationFalloffExponent = 0
        key.castsShadow = false
        key.shadowMode = .deferred
        key.shadowRadius = 14
        key.shadowSampleCount = 24
        key.shadowColor = UIColor(red: 0.12, green: 0.1, blue: 0.14, alpha: 0.45)
        key.shadowMapSize = CGSize(width: 4096, height: 4096)
        key.zNear = 1
        key.zFar = 30
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.simdPosition = Self.keyPosition
        keyNode.simdLook(at: Self.keyTarget)
        scene.rootNode.addChildNode(keyNode)
        studioLights.append(keyNode)

        let fill = SCNLight()
        fill.type = .ambient
        fill.intensity = Self.fillIntensity
        fill.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        let fillNode = SCNNode()
        fillNode.light = fill
        scene.rootNode.addChildNode(fillNode)
        studioLights.append(fillNode)

        let size = CanvasLayout.canvasSize
        let linen = Studio.canvasMaterial(repeats: size / Studio.weaveTileSize)
        let depth: Float = 0.16
        let board = Toybox.node(SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(depth),
                                       chamferRadius: 0.012), linen, at: SIMD3(0, 0, CanvasLayout.canvasZ - depth / 2))
        canvasNode.addChildNode(board)
        canvasBoard = board
        canvasNode.simdPosition = SIMD3(0, 0.1, 0)
        scene.rootNode.addChildNode(canvasNode)

        scene.rootNode.addChildNode(paint)

        fit(size: CGSize(width: 1600, height: 1000))
    }

    func fit(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        layout.fit(width: Float(size.width), height: Float(size.height))
        cameraNode.simdPosition = SIMD3(0, CanvasLayout.cameraY, layout.cameraDistance)
    }

    func shakeCamera(_ jolt: Float) {
        cameraNode.simdPosition = SIMD3(Float.random(in: -jolt...jolt),
                                        CanvasLayout.cameraY + Float.random(in: -jolt...jolt), layout.cameraDistance)
    }

    func photoBooth(paint: SCNNode) -> CanvasPhotoBooth? {
        guard let canvasBoard else { return nil }
        return CanvasPhotoBooth(board: canvasBoard, paint: paint, lights: studioLights, studio: scene,
                                studioCamera: cameraNode.camera)
    }
}
