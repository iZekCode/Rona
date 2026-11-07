import UIKit

// Passes the system's background URLSession relaunch to the uploader.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping @MainActor @Sendable () -> Void) {
        guard identifier == BackgroundImageUploader.sessionIdentifier else {
            completionHandler()
            return
        }
        AppServices.shared.uploader.handleSystemEvents(completion: completionHandler)
    }
}
