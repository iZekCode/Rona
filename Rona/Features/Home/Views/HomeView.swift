//
//  HomeView.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import SwiftUI

// The home page: paint, see the gallery or the report; uses touch, since hands are not tracked here.
struct HomeView: View {
    let router: AppRouter
    let auth: AuthStage

    @State private var showAccount = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageBackground()
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("Rona")
                        .font(.system(size: 76, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.titleGradient)
                        .shadow(color: .white, radius: 0, x: 0, y: 3)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    Text("Melukis dengan tanganmu")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                }
                BigButton(title: "Mulai menggambar", symbol: "paintbrush.pointed.fill", tint: Theme.paint) {
                    router.go(.modePicker)
                }
                HStack(spacing: 24) {
                    BigButton(title: "Lihat galeri", symbol: "building.columns.fill", tint: Theme.gallery) {
                        router.go(.gallery3D(start: 0, justHung: false))
                    }
                    BigButton(title: "Laporan", symbol: "calendar", tint: Theme.report) {
                        router.go(.report)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button { showAccount = true } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .frame(width: Theme.minTap, height: Theme.minTap)
            }
            .accessibilityLabel("Akun")
            .padding(20)
        }
        .sheet(isPresented: $showAccount) { LinkAccountView(auth: auth) }
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView(router: AppRouter(), auth: .preview)
}
