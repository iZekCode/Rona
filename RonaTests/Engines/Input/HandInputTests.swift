import Testing
import simd
@testable import Rona

struct HandInputTests {
    // A frame with one hand at `palm`, fist or open.
    private func frame(palm: SIMD2<Float>, fist: Bool) -> HandFrame {
        var joints = [SIMD2<Float>?](repeating: nil, count: HandJoint.allCases.count)
        joints[HandJoint.wrist.rawValue] = palm + SIMD2(0, 0.1)
        for (mcp, pip, tip, dx) in [(HandJoint.indexMCP, HandJoint.indexPIP, HandJoint.indexTip, Float(-0.03)),
                                    (.middleMCP, .middlePIP, .middleTip, 0.0),
                                    (.ringMCP, .ringPIP, .ringTip, 0.03),
                                    (.littleMCP, .littlePIP, .littleTip, 0.06)] {
            joints[mcp.rawValue] = palm + SIMD2(dx, -0.02)
            joints[pip.rawValue] = palm + SIMD2(dx, -0.1)
            joints[tip.rawValue] = palm + SIMD2(dx, fist ? -0.08 : -0.2)
        }
        return HandFrame(hands: [HandObservation(joints: joints, confidence: 1)], imageAspect: 0.75)
    }

    @Test func aHandOnTheLeftTakesSlotZero() {
        let input = HandInput()
        input.ingest(frame(palm: SIMD2(0.3, 0.5), fist: false), now: 0)
        #expect(input.tracked.map(\.slot) == [0])
    }

    @Test func aHandOnTheRightTakesSlotOne() {
        let input = HandInput()
        input.ingest(frame(palm: SIMD2(0.7, 0.5), fist: false), now: 0)
        #expect(input.tracked.map(\.slot) == [1])
    }

    @Test func theSameHandKeepsItsIdentityAcrossFrames() {
        let input = HandInput()
        input.ingest(frame(palm: SIMD2(0.3, 0.5), fist: false), now: 0)
        input.ingest(frame(palm: SIMD2(0.32, 0.5), fist: false), now: 0.03)
        #expect(input.tracked.count == 1)
    }

    @Test func aHandThatLeavesIsForgottenAfterAMoment() {
        let input = HandInput()
        input.ingest(frame(palm: SIMD2(0.3, 0.5), fist: false), now: 0)
        input.ingest(HandFrame(hands: [], imageAspect: 0.75), now: 0.3)
        #expect(input.tracked.count == 1)
        input.ingest(HandFrame(hands: [], imageAspect: 0.75), now: 0.7)
        #expect(input.tracked.isEmpty)
    }

    @Test func aHandStopsTrackingWhenFramesStop() {
        let input = HandInput()
        input.ingest(frame(palm: SIMD2(0.3, 0.5), fist: false), now: 0)
        #expect(input.advance(dt: 1.0 / 60, now: 0.1).first?.tracking == true)
        #expect(input.advance(dt: 1.0 / 60, now: 0.4).first?.tracking == false)
    }

    @Test func aClosedHandReadsAsAFist() {
        let input = HandInput()
        for i in 0..<4 { input.ingest(frame(palm: SIMD2(0.3, 0.5), fist: true), now: Double(i) / 30) }
        #expect(input.advance(dt: 1.0 / 60, now: 0.12).first?.pose == .fist)
    }

    @Test func resetForgetsEveryHand() {
        let input = HandInput()
        input.ingest(frame(palm: SIMD2(0.3, 0.5), fist: false), now: 0)
        input.reset()
        #expect(input.tracked.isEmpty)
    }

    @Test func palmPositionMapsOntoTheViewReach() {
        let input = HandInput()
        let centre = (HandInput.reachMin + HandInput.reachMax) / 2
        input.ingest(frame(palm: centre, fist: false), now: 0)
        let hand = input.advance(dt: 1.0 / 60, now: 0.0).first
        #expect(hand != nil && abs((hand?.position.x ?? 0) - 0.5) < 0.1)
    }
}
