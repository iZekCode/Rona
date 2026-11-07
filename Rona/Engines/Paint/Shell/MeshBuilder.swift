//
//  MeshBuilder.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import simd

// Builds a SceneKit shape from plain arrays of points, normals, colours and triangle numbers.
enum MeshBuilder {
    static func geometry(positions: [SIMD3<Float>], normals: [SIMD3<Float>],
                         colors: [SIMD4<Float>]? = nil, indices: [UInt32]) -> SCNGeometry {
        let stride3 = MemoryLayout<SIMD3<Float>>.stride
        let positionData = positions.withUnsafeBytes { Data($0) }
        let normalData = normals.withUnsafeBytes { Data($0) }
        var sources = [
            SCNGeometrySource(data: positionData, semantic: .vertex, vectorCount: positions.count,
                              usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4,
                              dataOffset: 0, dataStride: stride3),
            SCNGeometrySource(data: normalData, semantic: .normal, vectorCount: normals.count,
                              usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4,
                              dataOffset: 0, dataStride: stride3),
        ]
        if let colors {
            let colorData = colors.withUnsafeBytes { Data($0) }
            sources.append(SCNGeometrySource(data: colorData, semantic: .color, vectorCount: colors.count,
                                             usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: 4,
                                             dataOffset: 0, dataStride: MemoryLayout<SIMD4<Float>>.stride))
        }
        let indexData = indices.withUnsafeBytes { Data($0) }
        let element = SCNGeometryElement(data: indexData, primitiveType: .triangles,
                                         primitiveCount: indices.count / 3, bytesPerIndex: 4)
        return SCNGeometry(sources: sources, elements: [element])
    }
}
