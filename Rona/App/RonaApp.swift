import SwiftUI

@main
struct RonaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView(auth: AppServices.shared.auth, sync: AppServices.shared.sync)
        }
    }
}
