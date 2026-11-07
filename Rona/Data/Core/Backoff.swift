//
//  Backoff.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation

// How long to wait before trying again; the wait doubles after each failure, up to a limit.
nonisolated struct Backoff: Equatable, Sendable {
    var first: TimeInterval = 2
    var ceiling: TimeInterval = 300

    static let standard = Backoff()

    // `failures` is how many tries in a row went wrong.
    func delay(afterFailures failures: Int) -> TimeInterval {
        guard failures > 0 else { return 0 }
        let doublings = min(failures - 1, 30)
        return min(ceiling, first * pow(2, Double(doublings)))
    }
}
