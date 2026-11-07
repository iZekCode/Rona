//
//  SwipeDetector.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import simd

// Spots an open hand swiping sideways to go to the next or previous painting.
nonisolated struct SwipeDetector: Sendable {
    enum Swipe: Equatable, Sendable {
        case next
        case previous
    }

    static let minTravel: Float = 0.3
    static let window = 0.7
    static let straightness: Float = 1.8
    static let cooldown = 0.7

    private struct Sample {
        var time: Double
        var position: SIMD2<Float>
    }

    private var history: [Int: [Sample]] = [:]
    private var cooldownUntil = -Double.infinity

    // Looks at this frame's hands and returns a swipe when one just ended.
    mutating func feed(_ hands: [HandState], now: Double) -> Swipe? {
        let open = hands.filter { $0.tracking && $0.pose == .open && !$0.isPointer }
        for slot in history.keys where !open.contains(where: { $0.slot == slot }) { history[slot] = nil }
        guard now >= cooldownUntil else {
            history.removeAll()
            return nil
        }

        for hand in open {
            var samples = history[hand.slot, default: []]
            samples.append(Sample(time: now, position: hand.position))
            samples.removeAll { now - $0.time > Self.window }
            history[hand.slot] = samples

            if let swipe = Self.swipe(ending: hand.position, after: samples) {
                history.removeAll()
                cooldownUntil = now + Self.cooldown
                return swipe
            }
        }
        return nil
    }

    private static func swipe(ending end: SIMD2<Float>, after samples: [Sample]) -> Swipe? {
        func straight(from origin: Sample, travel: Float) -> Bool {
            travel >= minTravel && abs(end.y - origin.position.y) * straightness <= travel
        }
        if let right = samples.max(by: { $0.position.x < $1.position.x }),
           straight(from: right, travel: right.position.x - end.x) {
            return .next
        }
        if let left = samples.min(by: { $0.position.x < $1.position.x }),
           straight(from: left, travel: end.x - left.position.x) {
            return .previous
        }
        return nil
    }

    mutating func reset() {
        history.removeAll()
        cooldownUntil = -Double.infinity
    }
}
