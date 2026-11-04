import SwiftUI

// The first page: start drawing, visit the gallery, or look at the report. Touch only, since the
// hands aren't in the camera yet.
struct HomeView: View {
    let router: AppRouter

    var body: some View {
        ZStack {
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
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView(router: AppRouter())
}
