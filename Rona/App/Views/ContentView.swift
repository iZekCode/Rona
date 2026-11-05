import SwiftUI

struct ContentView: View {
    let auth: AuthStage

    @State private var router = AppRouter()
    @State private var consent = ConsentStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if consent.needsConsent {
                ConsentView(consent: consent)
            } else {
                page
            }
        }
        .immersive()
        // Signs in once consent exists, and again when the app comes back if an earlier try failed.
        .task(id: consent.agreement) { await auth.start(agreement: consent.agreement) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await auth.start(agreement: consent.agreement) } }
        }
    }

    @ViewBuilder private var page: some View {
        switch router.route {
        case .home:
            HomeView(router: router, auth: auth).transition(.opacity)
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
    ContentView(auth: .preview)
}
