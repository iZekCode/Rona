import Testing
@testable import Rona

struct AppRouterTests {
    @Test func startsOnHome() {
        #expect(AppRouter().route == .home)
    }

    @Test func goChangesThePage() {
        let router = AppRouter()
        router.go(.report)
        #expect(router.route == .report)
    }

    @Test func homeReturnsFromAnyPage() {
        let router = AppRouter(route: .gallery2D)
        router.home()
        #expect(router.route == .home)
    }
}
