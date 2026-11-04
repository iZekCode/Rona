import Observation
import SwiftUI

// Owns the current page; ContentView swaps pages when it changes.
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
