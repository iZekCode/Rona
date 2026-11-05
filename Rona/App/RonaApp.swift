//
//  RonaApp.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

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
