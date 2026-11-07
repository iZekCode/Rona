//
//  SessionStats.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation

// The child's own left or right hand or arm, not the left or right of the screen.
nonisolated enum Side: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case left, right
}

// How the child moved during one painting, saved together with that painting.
nonisolated struct SessionStats: Codable, Equatable, Sendable {
    static let schemaVersion = 1
    static let heatmapColumns = 32
    static let heatmapRows = 20

    var duration: TimeInterval = 0
    var romDegrees: [Side: Double] = [:]
    var heatmap: [UInt16] = Array(repeating: 0, count: heatmapColumns * heatmapRows)
    var pinchSeconds: [Side: Double] = [:]
    var elbowExtension: [Side: Double] = [:]
    var reachHeight: [Side: Double] = [:]
    var reachArea: [Side: Double] = [:]
    var gripCycles: [Side: Int] = [:]
    var maxTrunkLean: Double = 0

    init() {}

    // Older saved stats that miss a newer number still load, with that number left empty.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        duration = try c.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        romDegrees = try c.decodeIfPresent([Side: Double].self, forKey: .romDegrees) ?? [:]
        heatmap = try c.decodeIfPresent([UInt16].self, forKey: .heatmap) ?? heatmap
        pinchSeconds = try c.decodeIfPresent([Side: Double].self, forKey: .pinchSeconds) ?? [:]
        elbowExtension = try c.decodeIfPresent([Side: Double].self, forKey: .elbowExtension) ?? [:]
        reachHeight = try c.decodeIfPresent([Side: Double].self, forKey: .reachHeight) ?? [:]
        reachArea = try c.decodeIfPresent([Side: Double].self, forKey: .reachArea) ?? [:]
        gripCycles = try c.decodeIfPresent([Side: Int].self, forKey: .gripCycles) ?? [:]
        maxTrunkLean = try c.decodeIfPresent(Double.self, forKey: .maxTrunkLean) ?? 0
    }
}
