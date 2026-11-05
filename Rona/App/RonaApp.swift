//
//  RonaApp.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import SwiftUI

@main
struct RonaApp: App {
    @State private var auth = RonaApp.makeAuth()

    var body: some Scene {
        WindowGroup {
            ContentView(auth: auth)
        }
    }

    // One Supabase client for the whole app: every client shares the Keychain, so a second one could overwrite the session.
    private static func makeAuth() -> AuthStage {
        let client = SupabaseConfig.makeClient()
        return AuthStage(service: SupabaseAuthService(client: client),
                         profiles: SupabaseProfileRepository(client: client))
    }
}
