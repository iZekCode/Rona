import SwiftUI

// Backdrop shared by the full-screen pages.
struct PageBackground: View {
    var body: some View {
        LinearGradient(colors: [Theme.leaf, Theme.sunlight], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

#Preview {
    PageBackground()
}
