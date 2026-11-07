import Testing
import simd
@testable import Rona

struct OneEuroFilterTests {
    private let dt: Float = 1.0 / 60

    @Test func firstSampleIsPassedThrough() {
        var filter = OneEuroFilter2D()
        #expect(filter.filter(SIMD2(0.3, 0.7), dt: dt) == SIMD2(0.3, 0.7))
        #expect(filter.velocity == .zero)
    }

    @Test func aStillHandStaysPut() {
        var filter = OneEuroFilter2D()
        _ = filter.filter(SIMD2(0.5, 0.5), dt: dt)
        for _ in 0..<30 { _ = filter.filter(SIMD2(0.5, 0.5), dt: dt) }
        #expect(simd_distance(filter.value, SIMD2(0.5, 0.5)) < 1e-6)
    }

    @Test func jitterIsSmoothedMoreThanAFastMove() {
        // Small noise around a point is cut down, but a big jump is followed more closely (low lag).
        var still = OneEuroFilter2D()
        _ = still.filter(SIMD2(0.5, 0.5), dt: dt)
        let noisy = still.filter(SIMD2(0.51, 0.5), dt: dt)
        let jitterShare = (noisy.x - 0.5) / 0.01

        var fast = OneEuroFilter2D()
        _ = fast.filter(SIMD2(0.1, 0.5), dt: dt)
        let moved = fast.filter(SIMD2(0.9, 0.5), dt: dt)
        let moveShare = (moved.x - 0.1) / 0.8

        #expect(jitterShare < 0.25)
        #expect(moveShare > 2 * jitterShare)
    }

    @Test func velocityFollowsTheMotionDirection() {
        var filter = OneEuroFilter2D()
        var x: Float = 0.2
        for _ in 0..<20 {
            _ = filter.filter(SIMD2(x, 0.5), dt: dt)
            x += 0.01
        }
        #expect(filter.velocity.x > 0 && abs(filter.velocity.y) < 1e-4)
    }

    @Test func resetStartsOver() {
        var filter = OneEuroFilter2D()
        _ = filter.filter(SIMD2(0.1, 0.1), dt: dt)
        filter.reset()
        #expect(filter.filter(SIMD2(0.9, 0.9), dt: dt) == SIMD2(0.9, 0.9))
    }
}
