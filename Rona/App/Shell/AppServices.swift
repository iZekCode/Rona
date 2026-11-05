import Foundation
import Network

// The pieces that live as long as the app: one Supabase client (every client shares the Keychain, so a second
// one could overwrite the session), the sign-in, the local store, the background uploader and the sync engine.
//
// It is built once and also by the system, when it relaunches the app in the background to report a finished
// upload; `bootstrap` then signs in from the saved session and starts the sync without any page on screen.
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
        // A sync starts whenever the network comes back.
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied { Task { await engine.run() } }
        }
        monitor.start(queue: DispatchQueue(label: "rona.network"))
        Task { await bootstrap() }
    }

    // Signs in from the saved session (if the parent has agreed) and starts the sync.
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
