import SwiftUI

// Shown before anything else, to the parent. Nothing is signed in or uploaded until they agree.
struct ConsentView: View {
    let consent: ConsentStore

    // Placeholder: replace with the real privacy policy address before the TestFlight build.
    static let privacyPolicyURL = URL(string: "https://rona.example/privacy")!

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            PageBackground()
            VStack(spacing: 16) {
                Text("Untuk orang tua dan wali")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 20) {
                    point("camera.fill", "Kamera depan melihat gerakan tangan dan lengan anak. Video tidak pernah keluar dari iPad.")
                    point("icloud.and.arrow.up.fill", "Yang diunggah: gambar lukisan dan angka gerakan (jangkauan, genggaman, peta gerak). Tanpa nama, email, atau foto.")
                    point("ruler.fill", "Angka gerakan adalah perkiraan 2D dari kamera, bukan ukuran medis.")
                    point("trash.fill", "Akun dan semua datanya bisa dihapus kapan saja.")
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: Theme.bigRadius, style: .continuous))

                Button { openURL(Self.privacyPolicyURL) } label: {
                    Text("Kebijakan privasi")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .underline()
                        .foregroundStyle(Theme.ink)
                        .frame(minHeight: Theme.minTap)
                }

                BigButton(title: "Saya orang tua, saya setuju", symbol: "checkmark.circle.fill", tint: Theme.paint) {
                    consent.accept()
                }
            }
            .padding(28)
        }
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.report)
                .frame(width: 40)
            Text(text)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ConsentView(consent: ConsentStore(defaults: UserDefaults(suiteName: "preview")!))
}
