//
//  RouteTests.swift
//  RonaTests
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Foundation
import Testing
@testable import Rona

struct RouteTests {
    @Test func onlyTheCanvasPageIsTheCanvas() {
        #expect(Route.canvas(templateID: nil).isCanvas)
        #expect(Route.canvas(templateID: "cat").isCanvas)
        #expect(!Route.home.isCanvas)
        #expect(!Route.instruction(templateID: nil).isCanvas)
        #expect(!Route.review(draftID: UUID()).isCanvas)
    }

    @Test func viewOriginGoesBackToWhereItCameFrom() {
        #expect(ViewOrigin.gallery3D(index: 4).route == .gallery3D(start: 4, justHung: false))
        #expect(ViewOrigin.gallery2D.route == .gallery2D)
    }

    @Test func routesCompareByPayload() {
        let id = UUID()
        #expect(Route.review(draftID: id) == .review(draftID: id))
        #expect(Route.review(draftID: id) != .review(draftID: UUID()))
        #expect(Route.canvas(templateID: "a") != .canvas(templateID: "b"))
        #expect(Route.gallery3D(start: 0, justHung: true) != .gallery3D(start: 0, justHung: false))
    }
}
