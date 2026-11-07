//
//  CanvasPhotos.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import CoreGraphics

// The finished painting photographed three ways: whole, the bare canvas, and the paint alone.
nonisolated struct CanvasPhotos {
    let whole: CGImage
    let canvas: CGImage
    let paint: CGImage
}
