import Foundation
import Supabase

// Where the app talks to. Debug builds use the local stack from `supabase start`.
nonisolated enum SupabaseConfig {
    static let url = URL(string: "http://127.0.0.1:54321")!

    // The publishable key from `supabase status`. It is made to ship inside the app: row level security protects the data.
    static let key = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"

    static func makeClient() -> SupabaseClient {
        SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
