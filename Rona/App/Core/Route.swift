import Foundation

// Where a painting was opened from, so the viewing page can go back there.
nonisolated enum ViewOrigin: Hashable, Sendable {
    case gallery3D(index: Int)
    case gallery2D

    var route: Route {
        switch self {
        case .gallery3D(let index): .gallery3D(start: index, justHung: false)
        case .gallery2D: .gallery2D
        }
    }
}

// Every full-screen page of the app. Payloads are ids only; the images and stats of a draft live
// in the stage that owns it, so a route stays small and comparable.
nonisolated enum Route: Hashable, Sendable {
    case home
    case modePicker
    case templates
    case instruction(templateID: String?)
    case canvas(templateID: String?)
    case review(draftID: UUID)
    case gallery3D(start: Int, justHung: Bool)
    case gallery2D
    case viewPainting(id: UUID, origin: ViewOrigin)
    case report

    // The easel is live (hands paint) only on the canvas page.
    var isCanvas: Bool {
        if case .canvas = self { return true }
        return false
    }
}
