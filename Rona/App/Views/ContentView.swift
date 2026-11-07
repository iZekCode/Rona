//
//  ContentView.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import SwiftUI

struct ContentView: View {
    let auth: AuthStage
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
        .task(id: consent.agreement) { await auth.start(agreement: consent.agreement) }
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
        case .performanceGate:
            PerformanceGateView(router: router).transition(.opacity)
        default:
            PlaceholderPage(router: router).transition(.opacity)
        }
    }
}

// Fills in for a page we have not built yet.
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
