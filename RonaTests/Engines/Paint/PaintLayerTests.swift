//
//  PaintLayerTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation
import Testing
import simd
@testable import Rona

struct PaintLayerTests {
    private func layer() -> PaintLayer {
        PaintLayer(center: CanvasLayout.canvasCenter, size: CanvasLayout.canvasSize, z: CanvasLayout.canvasZ,
                   pixelsAcross: 256)
    }

    @Test func setsUpOnThisDevice() {
        #expect(layer().isAvailable)
    }

    @Test func paintsClearsAndSettlesWithoutTrouble() {
        let paint = layer()
        paint.update(dt: 1.0 / 60)
        for tool in PaintTool.allCases {
            for dab in tool.dabs(from: SIMD2(0, 0), to: SIMD2(0.3, 0.1), radius: 0.1, speed: 1) {
                paint.stamp(from: dab.from, to: dab.to, radius: dab.radius, color: tool.color, speed: dab.speed,
                            seed: 0.5, style: dab.style, ncaModel: tool.colorIndex)
            }
        }
        for _ in 0..<30 { paint.update(dt: 1.0 / 60) }
        paint.clear()
        paint.update(dt: 1.0 / 60)
        #expect(paint.isAvailable)
    }

    @Test func bundleCarriesTheTextureModelAndShaders() {
        #expect(Bundle.main.url(forResource: "nca", withExtension: "bin") != nil)
        #expect(Bundle.main.url(forResource: "default", withExtension: "metallib") != nil)
    }
}
