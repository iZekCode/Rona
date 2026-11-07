//
//  CanvasPhotoBooth.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Metal
import SceneKit
import simd

// Photographs the finished canvas head-on in a little booth: whole, bare canvas, and the paint alone on a clear background.
struct CanvasPhotoBooth {
    let board: SCNNode
    let paint: SCNNode
    let lights: [SCNNode]
    let studio: SCNScene
    let studioCamera: SCNCamera?

    func photos(pixels width: CGFloat = 1920) -> CanvasPhotos? {
        guard let whole = photograph(board: true, paint: true, pixels: width),
              let canvas = photograph(board: true, paint: false, pixels: width),
              let onBlack = photograph(board: false, paint: true, background: .black, pixels: width),
              let onWhite = photograph(board: false, paint: true, background: .white, pixels: width),
              let blackLevel = backdropLevel(.black), let whiteLevel = backdropLevel(.white),
              let paint = PaintMatte.extract(onBlack: onBlack, onWhite: onWhite, blackLevel: blackLevel,
                                             whiteLevel: whiteLevel, floor: PaintMatte.sheenFloor) else { return nil }
        return CanvasPhotos(whole: whole, canvas: canvas, paint: paint)
    }

    private func backdropLevel(_ color: UIColor) -> Double? {
        photograph(board: false, paint: false, background: color, pixels: 16).flatMap(PaintMatte.level)
    }

    private func photograph(board showBoard: Bool, paint showPaint: Bool, background: UIColor? = nil,
                            pixels width: CGFloat) -> CGImage? {
        let booth = SCNScene()
        if let background { booth.background.contents = background }
        booth.lightingEnvironment.contents = studio.lightingEnvironment.contents
        booth.lightingEnvironment.intensity = studio.lightingEnvironment.intensity
        if showBoard {
            let copy = board.clone()
            copy.simdTransform = board.simdWorldTransform
            booth.rootNode.addChildNode(copy)
        }
        if showPaint { booth.rootNode.addChildNode(paint.clone()) }
        for light in lights { booth.rootNode.addChildNode(light.clone()) }

        let size = CanvasLayout.canvasSize
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = Double(size.y * 0.5 * 0.99)
        camera.zNear = 0.1
        camera.zFar = 20
        if let studio = studioCamera {
            camera.wantsHDR = studio.wantsHDR
            camera.wantsExposureAdaptation = false
            camera.exposureOffset = studio.exposureOffset
            camera.minimumExposure = studio.minimumExposure
            camera.maximumExposure = studio.maximumExposure
        }
        let lens = SCNNode()
        lens.camera = camera
        lens.simdPosition = SIMD3(0, 0.1, 5)
        booth.rootNode.addChildNode(lens)

        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = booth
        renderer.pointOfView = lens
        let pixels = CGSize(width: width, height: width * CGFloat(size.y / size.x))
        return renderer.snapshot(atTime: 0, with: pixels, antialiasingMode: .multisampling4X).cgImage
    }
}
