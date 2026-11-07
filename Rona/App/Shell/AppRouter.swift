//
//  AppRouter.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import Observation
import SwiftUI

// Knows which page is on screen; changing it shows a different page.
@Observable
final class AppRouter {
    private(set) var route: Route

    init(route: Route = .home) {
        self.route = route
    }

    func go(_ next: Route) {
        withAnimation(.easeInOut(duration: 0.35)) { route = next }
    }

    func home() { go(.home) }
}
