import Foundation
import Supabase

// Where the app talks to: the local stack from `supabase start` in the simulator, the hosted project on a
// device and in release builds. The environment variables SUPABASE_URL and SUPABASE_KEY (Edit Scheme, Run,
// Arguments) override both, for example to point a device at the local stack.
nonisolated enum SupabaseConfig {
    private static let hostedURL = "https://smbsoovlrylahmrqsryw.supabase.co"
    private static let hostedKey = "sb_publishable_HaRhCVGc7saBWibg2tJTjQ_UlUg5CBP"

    // The default publishable key of every local stack (`supabase status`).
    private static let localURL = "http://127.0.0.1:54321"
    private static let localKey = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"

    static let url: URL = {
        if let value = ProcessInfo.processInfo.environment["SUPABASE_URL"], let url = URL(string: value) {
            return url
        }
        #if targetEnvironment(simulator)
        return URL(string: localURL)!
        #else
        return URL(string: hostedURL)!
        #endif
    }()

    // Publishable keys are made to ship inside the app: row level security protects the data.
    static let key: String = {
        if let value = ProcessInfo.processInfo.environment["SUPABASE_KEY"] { return value }
        #if targetEnvironment(simulator)
        return localKey
        #else
        return hostedKey
        #endif
    }()

    static func makeClient() -> SupabaseClient {
        SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
