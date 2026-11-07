//
//  GPUTimeMeter.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation

// Collects how long the GPU spent on each paint step. The GPU reports from its own thread, so access is locked.
nonisolated final class GPUTimeMeter: @unchecked Sendable {
    private let lock = NSLock()
    private var times: [Double] = []

    func record(milliseconds: Double) {
        lock.lock()
        times.append(milliseconds)
        if times.count > 600 { times.removeFirst(times.count - 600) }
        lock.unlock()
    }

    func drain() -> [Double] {
        lock.lock()
        defer { lock.unlock() }
        let out = times
        times.removeAll(keepingCapacity: true)
        return out
    }
}
