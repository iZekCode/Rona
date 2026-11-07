//
//  BackoffTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import Testing
@testable import Rona

struct BackoffTests {
    @Test func noFailuresMeansNoWait() {
        #expect(Backoff.standard.delay(afterFailures: 0) == 0)
    }

    @Test func theWaitDoublesAfterEachFailure() {
        let backoff = Backoff(first: 2, ceiling: 300)
        #expect([1, 2, 3, 4].map { backoff.delay(afterFailures: $0) } == [2, 4, 8, 16])
    }

    @Test func theWaitStopsAtTheCeiling() {
        let backoff = Backoff(first: 2, ceiling: 300)
        #expect(backoff.delay(afterFailures: 20) == 300)
        #expect(backoff.delay(afterFailures: 10_000) == 300)
    }
}
