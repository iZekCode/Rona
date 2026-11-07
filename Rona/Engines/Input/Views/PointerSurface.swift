import SwiftUI

extension View {
    // Lets a finger or the Pencil drag a hand here; put it only over the canvas, not buttons.
    func pointerInput(_ input: PointerInput) -> some View {
        overlay {
            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let size = proxy.size
                                guard size.width > 0, size.height > 0 else { return }
                                input.touch(at: SIMD2(Float(value.location.x / size.width),
                                                      Float(value.location.y / size.height)))
                            }
                            .onEnded { _ in input.lift() }
                    )
            }
        }
    }
}
