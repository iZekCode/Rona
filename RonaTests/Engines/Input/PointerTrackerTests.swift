//
//  PointerTrackerTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Testing
import simd
@testable import Rona

struct PointerTrackerTests {
    @Test func nothingTouchingGivesNoHand() {
        var tracker = PointerTracker()
        #expect(tracker.hand(now: 0) == nil)
        #expect(!tracker.isTouching)
    }

    @Test func aTouchIsAnAlwaysClosedPointerHand() throws {
        var tracker = PointerTracker()
        tracker.touch(at: SIMD2(0.4, 0.6))
        let frame = tracker.hand(now: 1)
        let hand = try #require(frame)
        #expect(hand.pose == .fist && hand.isPointer && hand.tracking && hand.slot == 0)
        #expect(hand.position == SIMD2(0.4, 0.6))
    }

    @Test func theFirstFrameOfATouchHasNoVelocity() throws {
        var tracker = PointerTracker()
        tracker.touch(at: SIMD2(0.4, 0.6))
        let frame = tracker.hand(now: 1)
        let hand = try #require(frame)
        #expect(hand.velocity == .zero)
    }

    @Test func velocityIsDistanceOverTheFrameTime() throws {
        var tracker = PointerTracker()
        tracker.touch(at: SIMD2(0.2, 0.5))
        _ = tracker.hand(now: 1)
        tracker.touch(at: SIMD2(0.3, 0.5))
        let frame = tracker.hand(now: 1.1)
        let hand = try #require(frame)
        #expect(abs(hand.velocity.x - 1) < 1e-4 && abs(hand.velocity.y) < 1e-4)
    }

    @Test func aStillFingerHasNoVelocity() throws {
        var tracker = PointerTracker()
        tracker.touch(at: SIMD2(0.2, 0.5))
        _ = tracker.hand(now: 1)
        let frame = tracker.hand(now: 1.02)
        let hand = try #require(frame)
        #expect(hand.velocity == .zero)
    }

    @Test func liftingEndsTheHandAndTheNextTouchStartsFresh() throws {
        var tracker = PointerTracker()
        tracker.touch(at: SIMD2(0.1, 0.1))
        _ = tracker.hand(now: 1)
        tracker.lift()
        #expect(tracker.hand(now: 1.1) == nil)
        tracker.touch(at: SIMD2(0.9, 0.9))
        let frame = tracker.hand(now: 2)
        let hand = try #require(frame)
        #expect(hand.velocity == .zero, "a new touch must not streak from where the last one ended")
    }

    @Test func positionsOutsideTheViewAreHeldAtTheEdge() throws {
        var tracker = PointerTracker()
        tracker.touch(at: SIMD2(-0.2, 1.4))
        let frame = tracker.hand(now: 1)
        let hand = try #require(frame)
        #expect(hand.position == SIMD2(0, 1))
    }
}
