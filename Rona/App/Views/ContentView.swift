import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    @State private var consent = ConsentStore()

    var body: some View {
        Group {
            if consent.needsConsent {
                ConsentView(consent: consent)
            } else {
                page
            }
        }
        .immersive()
    }

    @ViewBuilder private var page: some View {
        switch router.route {
        case .home:
            HomeView(router: router).transition(.opacity)
        default:
            // Pages are added by their own chunks; until then the route shows a way home.
            PlaceholderPage(router: router).transition(.opacity)
        }
    }
}

// Stand-in for a page that is not built yet.
private struct PlaceholderPage: View {
    let router: AppRouter

    var body: some View {
        ZStack {
            PageBackground()
            BigButton(title: "Beranda", symbol: "house.fill", tint: Theme.paint, action: router.home)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
