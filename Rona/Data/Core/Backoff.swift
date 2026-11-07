import Foundation

// How long to wait before trying again, doubling after each failure up to a ceiling.
nonisolated struct Backoff: Equatable, Sendable {
    var first: TimeInterval = 2
    var ceiling: TimeInterval = 300

    static let standard = Backoff()

    // `failures` counts tries failed in a row (1 after the first).
    func delay(afterFailures failures: Int) -> TimeInterval {
        guard failures > 0 else { return 0 }
        let doublings = min(failures - 1, 30)
        return min(ceiling, first * pow(2, Double(doublings)))
    }
}
