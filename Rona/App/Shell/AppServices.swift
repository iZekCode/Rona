//
//  AppServices.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 05/11/26.
//

import Foundation
import Network

// The parts that live as long as the app does; there is only one Supabase connection so logins never clash.
@MainActor
final class AppServices {
    static let shared = AppServices()

    let auth: AuthStage
    let localStore: LocalGalleryStore
    let uploader: BackgroundImageUploader
    let sync: SyncEngine

    private let monitor = NWPathMonitor()

    private init() {
        let client = SupabaseConfig.makeClient()
        let service = SupabaseAuthService(client: client)
        auth = AuthStage(service: service, profiles: SupabaseProfileRepository(client: client))
        localStore = LocalGalleryStore()
        uploader = BackgroundImageUploader(baseURL: SupabaseConfig.url, apiKey: SupabaseConfig.key) {
            try await service.uploadCredentials()
        }
        let engine = SyncEngine(
            local: localStore,
            remote: SupabaseRemoteGallery(gallery: SupabaseGalleryRepository(client: client),
                                          stats: SupabaseStatsRepository(client: client)),
            uploader: uploader)
        sync = engine
        uploader.setOnFinish { id, success in
            Task { await engine.imageUploadFinished(id, success: success) }
        }
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied { Task { await engine.run() } }
        }
        monitor.start(queue: DispatchQueue(label: "rona.network"))
        Task { await bootstrap() }
    }

    // Logs back in (once the parent has agreed) and starts the backup.
    func bootstrap() async {
        await auth.start(agreement: ConsentStore().agreement)
        await startSyncIfReady()
    }

    func startSyncIfReady() async {
        guard auth.isReady else { return }
        await sync.enable()
        await sync.run()
    }
}
