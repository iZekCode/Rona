import Foundation
import Network

// App-lifetime services; one Supabase client only, since every client shares the Keychain session.
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

    // Signs in from the saved session (after consent) and starts the sync.
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
