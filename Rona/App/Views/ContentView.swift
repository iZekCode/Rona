import SwiftUI

struct ContentView: View {
    let auth: AuthStage
    // nil in previews, which never sync.
    var sync: SyncEngine?

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
        // The sync starts once sign-in and the consent on the profile are done, and again when the app comes back.
        .task(id: auth.isReady) {
            guard auth.isReady, let sync else { return }
            await sync.enable()
            await sync.run()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await auth.start(agreement: consent.agreement)
                await sync?.run()
            }
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
