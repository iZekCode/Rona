import Testing
import simd
@testable import Rona

struct PoseFilterTests {
    private func reading(fingers: Int) -> PalmReading {
        PalmReading(palm: SIMD2(0.5, 0.5), extendedFingers: fingers)
    }

    @Test func fistEntersAfterTwoFramesAndLeavesAfterThree() {
        var filter = PoseFilter(pose: .open)
        filter.feed(reading(fingers: 0))
        #expect(filter.pose == .open)
        filter.feed(reading(fingers: 0))
        #expect(filter.pose == .fist)
        filter.feed(reading(fingers: 3))
        filter.feed(reading(fingers: 3))
        #expect(filter.pose == .fist)
        filter.feed(reading(fingers: 3))
        #expect(filter.pose == .open)
    }

    @Test func looseFistKeepsPainting() {
        var filter = PoseFilter(pose: .fist)
        for fingers in [1, 1, 4, 1, 0, 4, 4, 1, 1] {
            filter.feed(reading(fingers: fingers))
            #expect(filter.pose == .fist)
        }
    }

    @Test func pointerIsAnAlwaysTrackedFist() {
        let hand = HandState.pointer(at: SIMD2(0.6, 0.5), previous: SIMD2(0.5, 0.5), dt: 0.1)
        #expect(hand.pose == .fist && hand.tracking && hand.isPointer && hand.slot == 0)
        #expect(abs(hand.velocity.x - 1) < 1e-5 && abs(hand.velocity.y) < 1e-5)
    }
}
