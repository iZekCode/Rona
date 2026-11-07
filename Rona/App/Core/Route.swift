//
//  Route.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation

// Remembers which page opened a painting, so the back button returns there.
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

// Every full-screen page in the app; each one carries only ids, not pictures.
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

    var isCanvas: Bool {
        if case .canvas = self { return true }
        return false
    }
}
