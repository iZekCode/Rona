//
//  Theme.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import SwiftUI

// The app's colours and sizes for the treehouse garden look, made for iPad.
enum Theme {
    static let ink = Color(red: 0.25, green: 0.2, blue: 0.35)

    static let leaf = Color(red: 0.88, green: 0.97, blue: 0.84)
    static let sunlight = Color(red: 1, green: 0.96, blue: 0.86)

    static let paint = Color.pink
    static let gallery = Color.orange
    static let report = Color.indigo

    static let titleGradient = LinearGradient(
        colors: [Color(red: 1, green: 0.45, blue: 0.3),
                 Color(red: 0.95, green: 0.35, blue: 0.65),
                 Color(red: 0.4, green: 0.55, blue: 1)],
        startPoint: .leading, endPoint: .trailing)

    static let bigRadius: CGFloat = 38

    static let minTap: CGFloat = 84
}

extension View {
    // Hides the status bar and home bar, since every page fills the screen.
    func immersive() -> some View {
        statusBarHidden().persistentSystemOverlays(.hidden)
    }
}
