//
//  PoseFilter.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

// Turns jumpy finger counts into a steady open or fist, so the hand does not flicker.
nonisolated struct PoseFilter: Sendable {
    private(set) var pose: HandPose
    private var candidateFrames = 0

    init(pose: HandPose) { self.pose = pose }

    mutating func feed(_ reading: PalmReading) {
        let raw: HandPose
        if pose == .fist {
            raw = reading.extendedFingers >= 2 ? .open : .fist
        } else {
            raw = reading.extendedFingers == 0 ? .fist : .open
        }
        let needed = raw == .fist ? 2 : 3
        if raw != pose {
            candidateFrames += 1
            if candidateFrames >= needed {
                pose = raw
                candidateFrames = 0
            }
        } else {
            candidateFrames = 0
        }
    }
}
