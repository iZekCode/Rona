//
//  AppDelegate.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import UIKit

// Lets the uploader finish its work when iPadOS wakes the app for an upload that ended.
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
