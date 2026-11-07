import SwiftUI

// A big rounded pill: gradient fill, white rim, soft colored shadow.
struct BigButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.bigRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .bold))
                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(minWidth: 320, minHeight: Theme.minTap)
            .padding(.horizontal, 28)
            .background(tint.gradient, in: shape)
            .overlay(shape.stroke(.white, lineWidth: 4))
            .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BigButton(title: "Mulai menggambar", symbol: "paintbrush.pointed.fill", tint: Theme.paint) {}
}
