import Foundation
import Supabase

// Local stack in the simulator, hosted project on a device; SUPABASE_URL and SUPABASE_KEY override both.
nonisolated enum SupabaseConfig {
    private static let hostedURL = "https://smbsoovlrylahmrqsryw.supabase.co"
    private static let hostedKey = "sb_publishable_HaRhCVGc7saBWibg2tJTjQ_UlUg5CBP"

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
