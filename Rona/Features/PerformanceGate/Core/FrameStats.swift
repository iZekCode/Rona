//
//  FrameStats.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation

// The last few hundred timings in milliseconds, with the average, the slow tail and the worst one.
nonisolated struct FrameStats: Sendable {
    let capacity: Int
    private(set) var samples: [Double] = []

    init(capacity: Int = 300) {
        self.capacity = max(capacity, 1)
    }

    var count: Int { samples.count }
    var average: Double { samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count) }
    var worst: Double { samples.max() ?? 0 }

    mutating func add(_ milliseconds: Double) {
        samples.append(milliseconds)
        if samples.count > capacity { samples.removeFirst(samples.count - capacity) }
    }

    mutating func add(_ many: [Double]) {
        for value in many { add(value) }
    }

    mutating func reset() { samples.removeAll() }

    // The time that `fraction` of the samples stay under, for example 0.95 for the slowest one in twenty.
    func percentile(_ fraction: Double) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sorted = samples.sorted()
        let index = Int((Double(sorted.count - 1) * min(max(fraction, 0), 1)).rounded(.up))
        return sorted[index]
    }

    func share(over limit: Double) -> Double {
        guard !samples.isEmpty else { return 0 }
        return Double(samples.filter { $0 > limit }.count) / Double(samples.count)
    }
}
