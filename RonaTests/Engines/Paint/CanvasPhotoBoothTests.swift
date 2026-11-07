//
//  CanvasPhotoBoothTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import Testing
import simd
@testable import Rona

struct CanvasPhotoBoothTests {
    @Test func photographsAPaintedCanvasThreeWays() throws {
        let paint = PaintLayer(center: CanvasLayout.canvasCenter, size: CanvasLayout.canvasSize,
                               z: CanvasLayout.canvasZ, pixelsAcross: 256)
        paint.stamp(from: SIMD2(-1, 0), to: SIMD2(1, 0.3), radius: 0.2, color: PaintTool.ladybug.color,
                    speed: 1, seed: 0.5)
        for _ in 0..<10 { paint.update(dt: 1.0 / 60) }
        let easel = EaselScene(scene: SCNScene(), paint: paint.node)
        let booth = try #require(easel.photoBooth(paint: paint.node))
        let photos = try #require(booth.photos(pixels: 320))
        #expect(photos.whole.width == 320)
        #expect(photos.canvas.width == 320 && photos.paint.width == 320)
        let ratio = Double(photos.whole.height) / Double(photos.whole.width)
        #expect(abs(ratio - Double(CanvasLayout.canvasSize.y / CanvasLayout.canvasSize.x)) < 0.01)
    }
}
