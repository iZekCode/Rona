import SwiftUI

// Shared visual tokens of the treehouse garden look. Sizes are iPad sizes: the app has no other device.
enum Theme {
    // Text on light pages.
    static let ink = Color(red: 0.25, green: 0.2, blue: 0.35)

    // Soft leaf-green and sunlight page backdrop.
    static let leaf = Color(red: 0.88, green: 0.97, blue: 0.84)
    static let sunlight = Color(red: 1, green: 0.96, blue: 0.86)

    // Button tints.
    static let paint = Color.pink
    static let gallery = Color.orange
    static let report = Color.indigo

    static let titleGradient = LinearGradient(
        colors: [Color(red: 1, green: 0.45, blue: 0.3),
                 Color(red: 0.95, green: 0.35, blue: 0.65),
                 Color(red: 0.4, green: 0.55, blue: 1)],
        startPoint: .leading, endPoint: .trailing)

    // Corner radius of big buttons and cards.
    static let bigRadius: CGFloat = 38

    // Smallest tap target for a child's finger.
    static let minTap: CGFloat = 84
}

extension View {
    // Hides the status bar and home indicator hint; every page of the app is full screen.
    func immersive() -> some View {
        statusBarHidden().persistentSystemOverlays(.hidden)
    }
}
