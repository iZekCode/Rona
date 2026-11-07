import Testing
import simd
@testable import Rona

struct HandFrameTests {
    // A hand with each finger pointing up or curled.
    private func hand(extended: [HandJoint: Bool] = [:], missing: Set<HandJoint> = []) -> HandObservation {
        var joints = [SIMD2<Float>?](repeating: nil, count: HandJoint.allCases.count)
        func set(_ joint: HandJoint, _ p: SIMD2<Float>) {
            if !missing.contains(joint) { joints[joint.rawValue] = p }
        }
        set(.wrist, SIMD2(0.5, 0.9))
        let columns: [(HandJoint, HandJoint, HandJoint, Float)] = [
            (.indexMCP, .indexPIP, .indexTip, 0.44), (.middleMCP, .middlePIP, .middleTip, 0.48),
            (.ringMCP, .ringPIP, .ringTip, 0.52), (.littleMCP, .littlePIP, .littleTip, 0.56)]
        for (mcp, pip, tip, x) in columns {
            set(mcp, SIMD2(x, 0.7))
            set(pip, SIMD2(x, 0.6))
            set(tip, extended[tip] == false ? SIMD2(x, 0.62) : SIMD2(x, 0.4))
        }
        return HandObservation(joints: joints, confidence: 1)
    }

    @Test func openHandCountsFourFingers() throws {
        let reading = try #require(PalmReading(hand(), aspect: 0.75))
        #expect(reading.extendedFingers == 4)
    }

    @Test func fistCountsNone() throws {
        let curled: [HandJoint: Bool] = [.indexTip: false, .middleTip: false, .ringTip: false, .littleTip: false]
        let reading = try #require(PalmReading(hand(extended: curled), aspect: 0.75))
        #expect(reading.extendedFingers == 0)
    }

    @Test func palmIsTheMeanOfWristAndKnuckles() throws {
        let reading = try #require(PalmReading(hand(), aspect: 0.75))
        #expect(abs(reading.palm.x - 0.5) < 1e-5)
        #expect(abs(reading.palm.y - (0.9 + 4 * 0.7) / 5) < 1e-5)
    }

    @Test func noWristOrTooFewKnucklesGivesNoReading() {
        #expect(PalmReading(hand(missing: [.wrist]), aspect: 0.75) == nil)
        #expect(PalmReading(hand(missing: [.indexMCP, .middleMCP, .ringMCP]), aspect: 0.75) == nil)
    }

    @Test func shouldersNeedBothSides() {
        var points = [BodyPoint?](repeating: nil, count: BodyJoint.allCases.count)
        points[BodyJoint.leftShoulder.rawValue] = BodyPoint(location: SIMD2(0.40, 0.5), confidence: 1)
        #expect(BodyFrame(points: points, imageAspect: 1.33).shoulders == nil)
        points[BodyJoint.rightShoulder.rawValue] = BodyPoint(location: SIMD2(0.60, 0.5), confidence: 1)
        let shoulders = BodyFrame(points: points, imageAspect: 1.33).shoulders
        #expect(shoulders.map { abs($0.width - 0.2) < 1e-5 && abs($0.centerX - 0.5) < 1e-5 } == true)
    }
}
