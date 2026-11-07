//
//  Paint+Color.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SwiftUI
import UIKit

// Turns a paint colour into the colour types SwiftUI and UIKit use.
extension Paint {
    static func swiftUI(_ c: SIMD3<Float>) -> Color {
        Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }

    static func platform(_ c: SIMD3<Float>, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: alpha)
    }
}
