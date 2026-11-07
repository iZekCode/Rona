//
//  CanvasLayout.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation
import simd

// Where things sit in the scene and how a point on the screen maps into the world. The canvas fills the whole window.
nonisolated struct CanvasLayout: Sendable {
    static let canvasSize = SIMD2<Float>(6.4, 4.0)
    static let canvasCenter = SIMD2<Float>(0, 0.1)
    static let canvasZ: Float = 0.04
    static let strokeRadius: Float = 0.085
    static let paintHoverZ: Float = 0.24
    static let brushSizeRange: ClosedRange<Float> = 0.6...2.4
    static let cameraY: Float = 0.1
    static let tanHalfFOV = Float(tan(17.0 * Double.pi / 180))

    static let characterScale: Float = 1.0
    static let characterZ: Float = 0.3
    static let characterRadius: Float = 0.3
    static let characterWakeRadius: Float = 0.9
    static let characterBottomMargin: Float = 0.1
    static let characterMaxSpacing: Float = 1.0

    private(set) var aspect: Float = 16.0 / 10.0
    private(set) var cameraDistance: Float = 7

    // Pulls the camera in until the canvas just covers the window, edge to edge.
    mutating func fit(width: Float, height: Float) {
        guard width > 0, height > 0 else { return }
        aspect = width / height
        let halfH = Self.canvasSize.y * 0.5
        let halfW = Self.canvasSize.x * 0.5
        cameraDistance = Self.canvasZ + min(halfH / Self.tanHalfFOV, halfW / (Self.tanHalfFOV * aspect))
    }

    func visibleHalfSize(atZ z: Float) -> SIMD2<Float> {
        let halfH = (cameraDistance - z) * Self.tanHalfFOV
        return SIMD2(halfH * aspect, halfH)
    }

    // A point on the screen (0 to 1, y down) to a point in the world at depth z.
    func worldPoint(_ uv: SIMD2<Float>, z: Float) -> SIMD3<Float> {
        let h = visibleHalfSize(atZ: z)
        return SIMD3((uv.x * 2 - 1) * h.x, Self.cameraY + (1 - uv.y * 2) * h.y, z)
    }

    func pan(forX x: Float) -> Float {
        max(-1, min(1, x / max(visibleHalfSize(atZ: 0.5).x, 0.1)))
    }

    func idleTarget(slot: Int, clock: Float, z: Float) -> SIMD3<Float> {
        let h = visibleHalfSize(atZ: z)
        let t = clock * 0.35 + Float(slot) * 3.1
        return SIMD3(sin(t) * h.x * 0.6, Self.cameraY - h.y * 0.3 + sin(t * 2.3) * 0.15, z)
    }

    // How high a buddy hovers: low while painting so its legs reach the canvas, higher for a bigger brush.
    static func buddyZ(painting: Bool, brushSize: Float?) -> Float {
        guard painting else { return 0.42 }
        return canvasZ + (paintHoverZ - canvasZ) * max(brushSize ?? 1, 1)
    }

    // Where the sleeping characters float, left to right in a row along the bottom edge.
    func characterSlots(count: Int) -> [SIMD2<Float>] {
        let h = visibleHalfSize(atZ: Self.characterZ)
        let spacing = max(0, min(Self.characterMaxSpacing, (h.x - Self.characterRadius) * 2 / Float(max(count - 1, 1))))
        let y = Self.cameraY - h.y + Self.characterBottomMargin
        return (0..<count).map { SIMD2((Float($0) - Float(count - 1) / 2) * spacing, y) }
    }

    static func touches(_ p: SIMD2<Float>, characterAt center: SIMD3<Float>) -> Bool {
        simd_distance(p, SIMD2(center.x, center.y)) < characterRadius
    }

    // Where a brush at p lays paint, kept inside the canvas edge. Nil when it is off the canvas.
    static func brushPoint(_ p: SIMD2<Float>) -> SIMD2<Float>? {
        let half = canvasSize * 0.5 - SIMD2(repeating: strokeRadius)
        guard abs(p.x - canvasCenter.x) <= half.x + 0.05, abs(p.y - canvasCenter.y) <= half.y + 0.12 else { return nil }
        return simd_clamp(p, canvasCenter - half, canvasCenter + half)
    }

    static func isOnCanvas(_ p: SIMD2<Float>) -> Bool {
        abs(p.x - canvasCenter.x) <= canvasSize.x / 2 && abs(p.y - canvasCenter.y) <= canvasSize.y / 2
    }

    // A world point to a spot on the canvas (0 to 1, y down). Nil when it is off the canvas.
    static func canvasUV(_ p: SIMD3<Float>) -> SIMD2<Float>? {
        let uv = SIMD2((p.x - canvasCenter.x + canvasSize.x * 0.5) / canvasSize.x,
                       (canvasCenter.y + canvasSize.y * 0.5 - p.y) / canvasSize.y)
        guard uv.x >= 0, uv.x <= 1, uv.y >= 0, uv.y <= 1 else { return nil }
        return uv
    }

    // Height on the canvas, 0 at the bottom edge and 1 at the top, used for the pitch of a paint blip.
    static func blipHeight(_ p: SIMD2<Float>) -> Float {
        (p.y - canvasCenter.y) / canvasSize.y + 0.5
    }
}
