//
//  FrameBudget.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Foundation

// How much time one frame may cost, and whether the measured paint cost fits. The limits are a first proposal.
nonisolated enum FrameBudget {
    static let frameMilliseconds = 1000.0 / 60
    static let paintGood = 6.0
    static let paintLimit = 10.0
    static let frameTail = 18.0
    static let frameTailLimit = 25.0

    enum Verdict: String, Sendable {
        case good, tight, over
    }

    static func verdict(paintAverage: Double, frameTail tail: Double) -> Verdict {
        if paintAverage > paintLimit || tail > frameTailLimit { return .over }
        if paintAverage > paintGood || tail > frameTail { return .tight }
        return .good
    }

    // How many times slower the GPU could be and still keep the paint step inside its limit.
    static func headroom(paintAverage: Double) -> Double {
        paintAverage > 0 ? paintLimit / paintAverage : 0
    }
}
