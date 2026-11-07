//
//  FrameDriver.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import QuartzCore

// Calls back once per screen refresh with the seconds since the last one.
final class FrameDriver: NSObject {
    var onFrame: ((Double) -> Void)?
    private var link: CADisplayLink?
    var framesPerSecond = 60 {
        didSet { applyRate() }
    }
    private var lastTimestamp: CFTimeInterval = 0

    func start() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        applyRate()
    }

    private func applyRate() {
        let rate = Float(framesPerSecond)
        link?.preferredFrameRateRange = CAFrameRateRange(minimum: rate, maximum: rate, preferred: rate)
    }

    func stop() {
        link?.invalidate()
        link = nil
        lastTimestamp = 0
    }

    @objc private func tick(_ link: CADisplayLink) {
        let dt = lastTimestamp == 0 ? 1.0 / 60 : link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        onFrame?(min(dt, 1.0 / 20))
    }
}
