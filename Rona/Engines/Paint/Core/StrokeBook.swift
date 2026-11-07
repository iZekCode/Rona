//
//  StrokeBook.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// What has been painted so far, stroke by stroke, and the stroke each hand has in progress.
nonisolated struct StrokeBook: Sendable {
    struct Stroke: Sendable {
        let id: Int
        let color: SIMD3<Float>
        let brush: CritterKind
        var points: [StrokePoint]
    }

    enum PaintEvent: Equatable, Sendable {
        case started
        case blip
    }

    private(set) var strokes: [Stroke] = []
    private var active: [Int: Int] = [:]
    private var lastBead: [Int: SIMD2<Float>] = [:]
    private var lastStamp: [Int: SIMD2<Float>] = [:]
    private var blipDistance: [Int: Float] = [:]
    private var nextID = 0

    var isEmpty: Bool { strokes.isEmpty }
    var count: Int { strokes.count }
    var activeSlots: [Int] { Array(active.keys) }

    func stampStart(slot: Int, at p: SIMD2<Float>) -> SIMD2<Float> { lastStamp[slot] ?? p }

    mutating func stamped(slot: Int, at p: SIMD2<Float>) { lastStamp[slot] = p }

    // Grows the hand's stroke to p, or starts one there. Beads are laid `spacing` apart.
    mutating func paint(slot: Int, at p: SIMD2<Float>, now: Double, color: SIMD3<Float>, brush: CritterKind,
                        spacing: Float) -> PaintEvent? {
        if let id = active[slot], let index = strokes.firstIndex(where: { $0.id == id }), let last = lastBead[slot] {
            let beads = StrokePath.beads(from: last, to: p, spacing: spacing)
            guard !beads.isEmpty else { return nil }
            strokes[index].points += beads.map { StrokePoint(p: $0, born: now) }
            lastBead[slot] = p
            blipDistance[slot, default: 0] += simd_distance(p, last)
            guard blipDistance[slot, default: 0] > 0.16 else { return nil }
            blipDistance[slot] = 0
            return .blip
        }
        let stroke = Stroke(id: takeID(), color: color, brush: brush, points: [StrokePoint(p: p, born: now)])
        strokes.append(stroke)
        active[slot] = stroke.id
        lastBead[slot] = p
        return .started
    }

    // Ends the hand's stroke. True when one was in progress.
    @discardableResult
    mutating func finish(slot: Int) -> Bool {
        let wasPainting = active[slot] != nil
        active[slot] = nil
        lastBead[slot] = nil
        lastStamp[slot] = nil
        return wasPainting
    }

    // Wipes the paths under a round eraser, splitting strokes into the pieces that survive. True when anything was hit.
    mutating func erase(at p: SIMD2<Float>, radius: Float) -> Bool {
        var erasedAny = false
        var kept: [Stroke] = []
        for var stroke in strokes {
            guard let runs = StrokePath.cut(stroke.points, at: p, radius: radius) else {
                kept.append(stroke)
                continue
            }
            erasedAny = true
            if let first = runs.first {
                stroke.points = first
                kept.append(stroke)
                for run in runs.dropFirst() {
                    kept.append(Stroke(id: takeID(), color: stroke.color, brush: stroke.brush, points: run))
                }
            } else {
                for (slot, id) in active where id == stroke.id { active[slot] = nil }
            }
        }
        strokes = kept
        return erasedAny
    }

    mutating func clear() {
        strokes.removeAll()
        active = [:]
        lastBead = [:]
        lastStamp = [:]
    }

    private mutating func takeID() -> Int {
        defer { nextID += 1 }
        return nextID
    }
}
