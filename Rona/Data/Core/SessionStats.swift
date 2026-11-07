import Foundation

// A person's left or right hand or arm, not a screen side (the camera is mirrored).
nonisolated enum Side: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case left, right
}

// Movement stats of one drawing session, saved as one JSON document per painting.
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

    // Stats saved before a metric existed decode with that metric empty.
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
