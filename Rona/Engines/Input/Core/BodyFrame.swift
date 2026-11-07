//
//  BodyFrame.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import simd

// Points on the upper body; the camera's left and right are swapped because the picture is mirrored.
nonisolated enum BodyJoint: Int, CaseIterable, Sendable {
    case neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
}

// One point on the body and how sure the camera is about it.
nonisolated struct BodyPoint: Sendable {
    var location: SIMD2<Float>
    var confidence: Float
}

// One upper body the camera found, or none when nobody is in view.
nonisolated struct BodyFrame: Sendable {
    var points: [BodyPoint?]
    var imageAspect: Float

    subscript(_ joint: BodyJoint) -> BodyPoint? { points[joint.rawValue] }

    var shoulders: (width: Float, centerX: Float)? {
        guard let left = self[.leftShoulder], let right = self[.rightShoulder] else { return nil }
        return (abs(left.location.x - right.location.x), (left.location.x + right.location.x) / 2)
    }
}
