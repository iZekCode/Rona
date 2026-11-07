//
//  Studio.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import CoreGraphics
import UIKit
import simd

// The look of the canvas: primed linen with a woven surface, and the soft light the studio sits in. All textures are drawn in code.
enum Studio {
    // MARK: Noise

    private static func hash(_ x: Int, _ y: Int, _ seed: Int = 0) -> Float {
        var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263 &+ seed &* 982_451_653)
        h = (h ^ (h >> 13)) &* 1_274_126_177
        h ^= h >> 16
        return Float(h & 0xFFFF) / 65_535
    }

    private static func noise(_ x: Float, _ y: Float, period: Int = 1 << 20, seed: Int = 0) -> Float {
        let i = Int(x.rounded(.down)), j = Int(y.rounded(.down))
        let fx = x - Float(i), fy = y - Float(j)
        let u = fx * fx * (3 - 2 * fx), v = fy * fy * (3 - 2 * fy)
        func h(_ a: Int, _ b: Int) -> Float {
            hash(((a % period) + period) % period, ((b % period) + period) % period, seed)
        }
        let a = h(i, j), b = h(i + 1, j), c = h(i, j + 1), d = h(i + 1, j + 1)
        return (a + (b - a) * u) + ((c + (d - c) * u) - (a + (b - a) * u)) * v
    }

    private static func bitmap(width: Int, height: Int, _ pixel: (Int, Int) -> SIMD4<Float>) -> CGImage? {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let c = simd_clamp(pixel(x, y), SIMD4(repeating: 0), SIMD4(repeating: 1)) * 255
                let k = (y * width + x) * 4
                bytes[k] = UInt8(c.x)
                bytes[k + 1] = UInt8(c.y)
                bytes[k + 2] = UInt8(c.z)
                bytes[k + 3] = UInt8(c.w)
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    private static func normalMap(size: Int, strength: Float, height: (Int, Int) -> Float) -> CGImage? {
        var h = [Float](repeating: 0, count: size * size)
        for y in 0..<size { for x in 0..<size { h[y * size + x] = height(x, y) } }
        func at(_ x: Int, _ y: Int) -> Float { h[((y + size) % size) * size + (x + size) % size] }
        return bitmap(width: size, height: size) { x, y in
            let n = simd_normalize(SIMD3((at(x - 1, y) - at(x + 1, y)) * strength,
                                         (at(x, y + 1) - at(x, y - 1)) * strength, 1))
            return SIMD4(n * 0.5 + 0.5, 1)
        }
    }

    // MARK: Primed linen

    static let weaveTile = 512
    static let threadsPerTile = 32
    static let weaveTileSize: Float = 0.2

    private static func weave(_ x: Int, _ y: Int) -> Float {
        let p = weaveTile / threadsPerTile
        let i = x / p, j = y / p
        let u = Float(x % p) / Float(p), v = Float(y % p) / Float(p)
        let slub = 0.85 + 0.3 * noise(Float(x) / 9, Float(j) * 3.1, period: weaveTile / 9 + 1, seed: 3)
        let warp = sin(.pi * u) * slub
        let weft = sin(.pi * v) * (0.85 + 0.3 * noise(Float(i) * 3.1, Float(y) / 9, seed: 5))
        let fiber = 0.08 * noise(Float(x) * 0.7, Float(y) * 0.7, period: weaveTile * 7 / 10, seed: 9)
        let warpOnTop = (i + j) % 2 == 0
        let top = warpOnTop ? warp * (0.75 + 0.25 * sin(.pi * v)) : weft * (0.75 + 0.25 * sin(.pi * u))
        let under = (warpOnTop ? weft : warp) * 0.55
        return max(top, under) + fiber
    }

    static func canvasMaterial(repeats: SIMD2<Float>) -> SCNMaterial {
        let size = weaveTile
        let albedo = bitmap(width: size, height: size) { x, y in
            let h = weave(x, y)
            let tone = 0.96 + 0.015 * h + 0.02 * noise(Float(x) / 40, Float(y) / 40, period: size / 40 + 1, seed: 11)
            return SIMD4(SIMD3<Float>(0.95, 0.95, 0.93) * tone, 1)
        }
        let normals = normalMap(size: size, strength: 0.8, height: weave)
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = Toybox.platformImage(albedo)
        m.normal.contents = Toybox.platformImage(normals)
        m.roughness.contents = NSNumber(value: 0.92)
        m.metalness.contents = NSNumber(value: 0.0)
        for p in [m.diffuse, m.normal] {
            p.wrapS = .repeat
            p.wrapT = .repeat
            p.contentsTransform = SCNMatrix4(simd_float4x4(diagonal: SIMD4(repeats.x, repeats.y, 1, 1)))
            p.mipFilter = .linear
        }
        return m
    }

    // MARK: Light

    private static func softBlob(_ ctx: CGContext, at c: CGPoint, radius: CGFloat, color: SIMD4<Float>,
                                 scaleY: CGFloat = 1) {
        let space = CGColorSpaceCreateDeviceRGB()
        let inner = CGColor(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w))
        guard let g = CGGradient(colorsSpace: space, colors: [inner, inner.copy(alpha: 0) ?? inner] as CFArray,
                                 locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y)
        ctx.scaleBy(x: 1, y: scaleY)
        ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: radius, options: [])
        ctx.restoreGState()
    }

    static func environment() -> UIImage? {
        Toybox.platformImage(Toybox.image(width: 512, height: 256) { ctx in
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [CGColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1),
                          CGColor(red: 0.85, green: 0.81, blue: 0.75, alpha: 1),
                          CGColor(red: 0.42, green: 0.32, blue: 0.24, alpha: 1)] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.5, 1]) {
                ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 256), end: CGPoint(x: 0, y: 0), options: [])
            }
            softBlob(ctx, at: CGPoint(x: 150, y: 165), radius: 70, color: SIMD4(1, 1, 0.97, 1), scaleY: 1.3)
            ctx.setFillColor(CGColor(red: 1, green: 1, blue: 0.98, alpha: 1))
            ctx.fill(CGRect(x: 120, y: 130, width: 60, height: 70))
        })
    }
}
