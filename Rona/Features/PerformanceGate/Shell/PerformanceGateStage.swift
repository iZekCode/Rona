//
//  PerformanceGateStage.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Observation
import SceneKit
import UIKit
import simd

// Paints with made-up brushes on the real canvas scene and times it, so a device can pass or fail the frame budget.
@Observable
final class PerformanceGateStage {
    struct Reading: Equatable {
        var fps = 0.0
        var frameAverage = 0.0
        var frameTail = 0.0
        var frameWorst = 0.0
        var paintAverage = 0.0
        var paintTail = 0.0
        var cpuAverage = 0.0
        var verdict = FrameBudget.Verdict.good
        var headroom = 0.0
    }

    static let resolutions = [1024, 1536, 2048, 3072]
    static let brushCounts = [1, 2, 4]
    static let frameRates = [60, 120]

    private(set) var reading = Reading()
    private(set) var sceneVersion = 0
    private(set) var resolution = 1536
    private(set) var brushes = 2
    private(set) var texture = true
    private(set) var frameRate = 60

    @ObservationIgnored private(set) var easel = EaselScene(scene: SCNScene(), paint: SCNNode())
    @ObservationIgnored private var paint: PaintLayer?
    @ObservationIgnored private let driver = FrameDriver()
    @ObservationIgnored private var frames = FrameStats()
    @ObservationIgnored private var paintTimes = FrameStats()
    @ObservationIgnored private var cpuTimes = FrameStats()
    @ObservationIgnored private var previous: [Int: SIMD2<Float>] = [:]
    @ObservationIgnored private var clock = 0.0
    @ObservationIgnored private var sincePublish = 0.0
    @ObservationIgnored private var sinceClear = 0.0
    @ObservationIgnored private var viewSize = CGSize(width: 1600, height: 1000)

    init() {
        rebuild()
    }

    func start() {
        driver.onFrame = { [weak self] dt in self?.tick(dt) }
        driver.start()
    }

    func stop() {
        driver.stop()
    }

    func fit(size: CGSize) {
        viewSize = size
        easel.fit(size: size)
    }

    func setResolution(_ pixels: Int) {
        guard pixels != resolution else { return }
        resolution = pixels
        rebuild()
    }

    func setBrushes(_ count: Int) {
        brushes = count
        previous.removeAll()
        resetTimings()
    }

    func setFrameRate(_ fps: Int) {
        frameRate = fps
        driver.framesPerSecond = fps
        resetTimings()
    }

    func setTexture(_ on: Bool) {
        texture = on
        resetTimings()
    }

    var summary: String {
        let r = reading
        let line1 = "\(Self.deviceModel) · paint \(resolution) px · \(brushes) brushes · texture \(texture ? "on" : "off") · cap \(frameRate) fps"
        let line2 = String(format: "paint GPU avg %.2f ms, p95 %.2f ms · frame avg %.1f ms, p95 %.1f ms, worst %.1f ms",
                           r.paintAverage, r.paintTail, r.frameAverage, r.frameTail, r.frameWorst)
        let line3 = String(format: "fps %.0f · main thread %.2f ms · headroom %.1fx · verdict %@",
                           r.fps, r.cpuAverage, r.headroom, r.verdict.rawValue)
        return [line1, line2, line3].joined(separator: "\n")
    }

    static var deviceModel: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return "\(simulated) (simulator)" }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    private func rebuild() {
        let layer = PaintLayer(center: CanvasLayout.canvasCenter, size: CanvasLayout.canvasSize,
                               z: CanvasLayout.canvasZ, pixelsAcross: resolution)
        paint = layer
        easel = EaselScene(scene: SCNScene(), paint: layer.node)
        easel.fit(size: viewSize)
        previous.removeAll()
        resetTimings()
        sceneVersion += 1
    }

    private func resetTimings() {
        frames.reset()
        paintTimes.reset()
        cpuTimes.reset()
        sincePublish = 0
    }

    private func tick(_ dt: Double) {
        guard let paint else { return }
        let began = ProcessInfo.processInfo.systemUptime
        clock += dt
        sinceClear += dt
        if sinceClear > 30 {
            paint.clear()
            previous.removeAll()
            sinceClear = 0
        }
        let step = Float(dt)
        for slot in 0..<brushes {
            let tool = PaintTool.allCases[slot % PaintTool.allCases.count]
            let b = FakePainter.point(slot: slot, at: clock)
            let a = previous[slot] ?? b
            previous[slot] = b
            let speed = simd_distance(a, b) / max(step, 1.0 / 240)
            for dab in tool.dabs(from: a, to: b, radius: 0.12, speed: speed) {
                var style = dab.style
                if !texture { style.nca = 0 }
                paint.stamp(from: dab.from, to: dab.to, radius: dab.radius, color: tool.color, speed: dab.speed,
                            seed: Float(clock.truncatingRemainder(dividingBy: 1)), style: style,
                            strokeSeed: Float(slot) / 4, ncaModel: tool.colorIndex)
            }
        }
        paint.update(dt: step)
        cpuTimes.add((ProcessInfo.processInfo.systemUptime - began) * 1000)
        frames.add(dt * 1000)
        paintTimes.add(paint.gpuMeter.drain())

        sincePublish += dt
        guard sincePublish >= 0.5 else { return }
        sincePublish = 0
        publish()
    }

    private func publish() {
        let tail = frames.percentile(0.95)
        reading = Reading(fps: frames.average > 0 ? 1000 / frames.average : 0,
                          frameAverage: frames.average, frameTail: tail, frameWorst: frames.worst,
                          paintAverage: paintTimes.average, paintTail: paintTimes.percentile(0.95),
                          cpuAverage: cpuTimes.average,
                          verdict: FrameBudget.verdict(paintAverage: paintTimes.average, frameTail: tail),
                          headroom: FrameBudget.headroom(paintAverage: paintTimes.average))
    }
}
