//
//  PaintMatte.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation
import CoreGraphics

// Lifts the paint off a photo booth shot as a see-through image, by comparing a shot over black with a shot over white.
nonisolated enum PaintMatte {
    static let sheenFloor = 0.14

    static func extract(onBlack black: CGImage, onWhite white: CGImage, blackLevel: Double = 0,
                        whiteLevel: Double = 255, floor: Double = 0) -> CGImage? {
        let width = black.width
        let height = black.height
        guard white.width == width, white.height == height, whiteLevel > blackLevel + 1,
              let dark = pixels(of: black), let light = pixels(of: white) else { return nil }

        let span = whiteLevel - blackLevel
        var out = [UInt8](repeating: 0, count: dark.count)
        for i in stride(from: 0, to: dark.count, by: 4) {
            let gap = Double(Int(light[i]) - Int(dark[i]) + Int(light[i + 1]) - Int(dark[i + 1])
                + Int(light[i + 2]) - Int(dark[i + 2])) / 3
            let see = min(max(gap / span, 0), 1)
            let raw = 1 - see
            let kept = floor > 0 ? max(raw - floor, 0) / (1 - floor) : raw
            let alpha = kept * 255
            let scale = raw > 0 ? kept / raw : 0
            for c in 0..<3 {
                let color = max(Double(dark[i + c]) - see * blackLevel, 0) * scale
                out[i + c] = UInt8(min(color, alpha).rounded())
            }
            out[i + 3] = UInt8(alpha.rounded())
        }
        return CGDataProvider(data: Data(out) as CFData).flatMap { provider in
            CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        }
    }

    static func level(of image: CGImage) -> Double? {
        guard let data = pixels(of: image), !data.isEmpty else { return nil }
        var sum = 0
        for i in stride(from: 0, to: data.count, by: 4) { sum += Int(data[i]) + Int(data[i + 1]) + Int(data[i + 2]) }
        return Double(sum) / Double(data.count / 4 * 3)
    }

    private static func pixels(of image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? data : nil
    }
}
