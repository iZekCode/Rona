//
//  StudioTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import UIKit
import Testing
import simd
@testable import Rona

struct StudioTests {
    @Test func linenIsTiledAcrossTheCanvas() {
        let material = Studio.canvasMaterial(repeats: SIMD2(32, 20))
        #expect(material.diffuse.wrapS == .repeat && material.normal.wrapT == .repeat)
        #expect(material.diffuse.contents is UIImage && material.normal.contents is UIImage)
    }

    @Test func weaveTileMatchesThePaintShaderPitch() {
        let pitch = Studio.weaveTileSize / Float(Studio.threadsPerTile)
        #expect(abs(pitch - PaintLayer.defaultWeaveThreadPitch) < 1e-6)
    }

    @Test func environmentLightIsDrawn() {
        #expect(Studio.environment() != nil)
    }
}
