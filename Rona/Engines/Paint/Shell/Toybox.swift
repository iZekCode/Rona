//
//  Toybox.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import CoreGraphics
import UIKit
import simd


// A kit for building 3D toys: glossy balloon materials, googly eyes, lips and bursts of confetti.
enum Toybox {
    static let wobbleShader = """
    #pragma arguments
    float wobbleAmount;
    float wobbleSpeed;
    #pragma body
    float t = scn_frame.time * wobbleSpeed;
    float3 p = _geometry.position.xyz;
    float w = sin(t + p.y * 7.0 + p.x * 3.0) * 0.6 + sin(t * 1.37 + p.x * 6.0 - p.z * 4.0) * 0.4;
    _geometry.position.xyz += _geometry.normal * (w * wobbleAmount);
    """

    static func balloon(_ color: SIMD3<Float>, wobble: Float = 0.006, speed: Float = 3,
                        roughness: CGFloat = 0.28) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = Paint.platform(color)
        m.roughness.contents = NSNumber(value: Double(roughness))
        m.metalness.contents = NSNumber(value: 0.0)
        m.clearCoat.contents = NSNumber(value: 1.0)
        m.clearCoatRoughness.contents = NSNumber(value: 0.08)
        m.shaderModifiers = [.geometry: wobbleShader]
        m.setValue(NSNumber(value: wobble), forKey: "wobbleAmount")
        m.setValue(NSNumber(value: speed), forKey: "wobbleSpeed")
        return m
    }

    static func setWobble(_ material: SCNMaterial, _ amount: Float) {
        material.setValue(NSNumber(value: amount), forKey: "wobbleAmount")
    }

    static func plain(_ color: SIMD3<Float>, roughness: CGFloat = 0.6) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = Paint.platform(color)
        m.roughness.contents = NSNumber(value: Double(roughness))
        m.metalness.contents = NSNumber(value: 0.0)
        return m
    }

    static func node(_ geometry: SCNGeometry, _ material: SCNMaterial,
                     at position: SIMD3<Float> = .zero, scale: SIMD3<Float> = SIMD3(1, 1, 1)) -> SCNNode {
        geometry.materials = [material]
        let n = SCNNode(geometry: geometry)
        n.simdPosition = position
        n.simdScale = scale
        return n
    }

    // MARK: - Googly eyes

    struct Eye {
        let root: SCNNode
        let pupil: SCNNode
        let radius: Float
    }

    static func eye(radius r: Float) -> Eye {
        let root = SCNNode()
        let white = node(SCNSphere(radius: CGFloat(r)), balloon(SIMD3(1, 1, 1), wobble: 0, roughness: 0.15))
        white.simdScale = SIMD3(1, 1, 0.8)
        root.addChildNode(white)

        let pupil = SCNNode()
        let iris = node(SCNSphere(radius: CGFloat(r * 0.5)), balloon(SIMD3(0.04, 0.04, 0.06), wobble: 0, roughness: 0.1))
        iris.simdScale = SIMD3(1, 1, 0.45)
        pupil.addChildNode(iris)
        let glint = SCNNode(geometry: SCNSphere(radius: CGFloat(r * 0.13)))
        let glintMaterial = SCNMaterial()
        glintMaterial.lightingModel = .constant
        glintMaterial.diffuse.contents = UIColor.white
        glint.geometry?.materials = [glintMaterial]
        glint.simdPosition = SIMD3(r * 0.17, r * 0.2, r * 0.22)
        pupil.addChildNode(glint)
        pupil.simdPosition = SIMD3(0, 0, r * 0.66)
        root.addChildNode(pupil)
        return Eye(root: root, pupil: pupil, radius: r)
    }

    static func look(_ eye: Eye, toward direction: SIMD2<Float>) {
        let d = simd_length(direction) > 1 ? simd_normalize(direction) : direction
        let x = d.x * eye.radius * 0.32
        let y = d.y * eye.radius * 0.32
        let z = sqrt(max(eye.radius * eye.radius - x * x - y * y, 0)) * 0.66
        eye.pupil.simdPosition = SIMD3(x, y, z)
    }

    static func blinkScale(_ t: Float) -> Float {
        guard t >= 0, t < 0.16 else { return 1 }
        return t < 0.07 ? 1 - 0.9 * (t / 0.07) : 0.1 + 0.9 * ((t - 0.07) / 0.09)
    }

    static func lips(radius: Float, color: SIMD3<Float>) -> SCNNode {
        let torus = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: CGFloat(radius * 0.48))
        let n = node(torus, balloon(color, wobble: 0.002, roughness: 0.2))
        n.simdEulerAngles = SIMD3(Float.pi / 2, 0, 0)
        n.simdScale = SIMD3(1.15, 1, 0.8)
        let container = SCNNode()
        container.addChildNode(n)
        return container
    }

    static func blush() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = UIColor(red: 1, green: 0.45, blue: 0.55, alpha: 0.45)
        m.writesToDepthBuffer = false
        return m
    }

    // MARK: - Generated images

    static func image(width: Int, height: Int, draw: (CGContext) -> Void) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        draw(ctx)
        return ctx.makeImage()
    }

    static func platformImage(_ cg: CGImage?) -> UIImage? {
        guard let cg else { return nil }
                return UIImage(cgImage: cg)
            }

    static func dot(ring: Bool = false) -> UIImage? {
        platformImage(image(width: 64, height: 64) { ctx in
            if ring {
                ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
                ctx.setLineWidth(5)
                ctx.strokeEllipse(in: CGRect(x: 6, y: 6, width: 52, height: 52))
                ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
                ctx.fillEllipse(in: CGRect(x: 18, y: 36, width: 12, height: 10))
            } else {
                ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
                ctx.fillEllipse(in: CGRect(x: 4, y: 4, width: 56, height: 56))
            }
        })
    }

    // MARK: - Particles

    private static let dotImage = dot()

    static func burst(in scene: SCNScene, at position: SIMD3<Float>, color: SIMD3<Float>,
                      count: CGFloat = 60, speed: CGFloat = 2.2, size: CGFloat = 0.05, gravity: Float = -3) {
        let p = SCNParticleSystem()
        p.particleImage = dotImage
        p.birthRate = count / 0.06
        p.emissionDuration = 0.06
        p.loops = false
        p.particleLifeSpan = 0.9
        p.particleLifeSpanVariation = 0.35
        p.particleVelocity = speed
        p.particleVelocityVariation = speed * 0.6
        p.spreadingAngle = 180
        p.particleSize = size
        p.particleSizeVariation = size * 0.6
        p.particleColor = Paint.platform(color)
        p.acceleration = SCNVector3(0, CGFloat(gravity), 0)
        p.dampingFactor = 1.2
        p.blendMode = .alpha
        p.isLightingEnabled = false
        let fade = CAKeyframeAnimation()
        fade.values = [1.0, 1.0, 0.0]
        fade.keyTimes = [0, 0.6, 1]
        p.propertyControllers = [.opacity: SCNParticlePropertyController(animation: fade)]

        let emitter = SCNNode()
        emitter.simdPosition = position
        emitter.addParticleSystem(p)
        scene.rootNode.addChildNode(emitter)
        emitter.runAction(.sequence([.wait(duration: 2.0), .removeFromParentNode()]))
    }

    static func confetti(in scene: SCNScene, at position: SIMD3<Float>) {
        for color in Paint.colors {
            burst(in: scene, at: position, color: color, count: 22, speed: 3.0, size: 0.06)
        }
    }
}
