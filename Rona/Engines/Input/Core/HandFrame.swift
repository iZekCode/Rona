import simd

/// The hand joints the app cares about.
nonisolated enum HandJoint: Int, CaseIterable, Sendable {
    case wrist
    case thumbCMC, thumbMP, thumbIP, thumbTip
    case indexMCP, indexPIP, indexTip
    case middleMCP, middlePIP, middleTip
    case ringMCP, ringPIP, ringTip
    case littleMCP, littlePIP, littleTip
}

/// One detected hand. Joints are in the upright, mirrored camera image:
/// x grows to the right, y grows downward, both in 0...1.
nonisolated struct HandObservation: Sendable {
    var joints: [SIMD2<Float>?]
    var confidence: Float

    subscript(_ joint: HandJoint) -> SIMD2<Float>? { joints[joint.rawValue] }
}

nonisolated struct HandFrame: Sendable {
    var hands: [HandObservation]
    /// Width / height of the camera image.
    var imageAspect: Float
}

/// The upper-body joints the app cares about, named as Vision names them. Vision reads the camera image
/// as a plain photo, so on the mirrored image its left and right are swapped; the session recorder works
/// out the person's sides from where the shoulders sit instead.
nonisolated enum BodyJoint: Int, CaseIterable, Sendable {
    case neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
}

nonisolated struct BodyPoint: Sendable {
    /// Upright, mirrored camera image like `HandObservation`: x right, y down, both in 0...1.
    var location: SIMD2<Float>
    var confidence: Float
}

/// One detected upper body, or none when nobody is in view.
nonisolated struct BodyFrame: Sendable {
    var points: [BodyPoint?]
    /// Width / height of the camera image.
    var imageAspect: Float

    subscript(_ joint: BodyJoint) -> BodyPoint? { points[joint.rawValue] }

    /// Shoulder distance and midpoint as fractions of the image width, when both shoulders are seen.
    var shoulders: (width: Float, centerX: Float)? {
        guard let left = self[.leftShoulder], let right = self[.rightShoulder] else { return nil }
        return (abs(left.location.x - right.location.x), (left.location.x + right.location.x) / 2)
    }
}

extension PalmReading {
    /// Reads the palm and counts extended fingers from one hand observation.
    nonisolated init?(_ hand: HandObservation, aspect: Float) {
        guard let wrist = hand[.wrist] else { return nil }
        let knuckles = [hand[.indexMCP], hand[.middleMCP], hand[.ringMCP], hand[.littleMCP]].compactMap { $0 }
        guard knuckles.count >= 2 else { return nil }
        let points = [wrist] + knuckles
        let palm = points.reduce(SIMD2<Float>.zero, +) / Float(points.count)

        let scale = SIMD2<Float>(aspect, 1)
        func distance(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float { simd_distance(a * scale, b * scale) }
        var count = 0
        let fingers: [(HandJoint, HandJoint)] = [(.indexTip, .indexPIP), (.middleTip, .middlePIP),
                                                 (.ringTip, .ringPIP), (.littleTip, .littlePIP)]
        for (tip, pip) in fingers {
            // A finger is out when its tip is clearly further from the wrist than its middle joint.
            if let t = hand[tip], let p = hand[pip], distance(t, wrist) > distance(p, wrist) * 1.12 {
                count += 1
            }
        }
        self.init(palm: palm, extendedFingers: count)
    }
}
