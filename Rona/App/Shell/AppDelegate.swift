import UIKit

// SwiftUI has no hook for the system relaunching the app to finish a background URLSession, so this
// delegate takes the call and passes the completion handler to the uploader, which calls it once the
// events are handled.
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
