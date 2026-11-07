//
//  HoverDwell.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import CoreGraphics

// A button an open hand can hover over and hold to press.
nonisolated struct HoverTarget: Equatable, Sendable {
    var id: String
    var frame: CGRect
}

// Pressing by hovering: an open hand resting on a button for a second presses it once.
nonisolated struct HoverDwell: Sendable {
    static let duration = 1.0

    private(set) var progress: (id: String, value: Double)?
    private var time = 0.0
    private var latched: String?
    private var waitingForRelease = false

    // Ignores presses until the hand moves off every button, so a new page is not pressed by accident.
    mutating func requireRelease() {
        waitingForRelease = true
        time = 0
        latched = nil
        progress = nil
    }

    // Returns the button id once a hand has rested on it long enough.
    mutating func update(hoveredID: String?, dt: Double) -> String? {
        guard let id = hoveredID else {
            waitingForRelease = false
            time = 0
            latched = nil
            progress = nil
            return nil
        }
        if waitingForRelease || latched == id { return nil }
        latched = nil
        if progress?.id != id { time = 0 }
        time += dt
        if time + 1e-9 >= Self.duration {
            latched = id
            time = 0
            progress = nil
            return id
        }
        progress = (id, time / Self.duration)
        return nil
    }
}
