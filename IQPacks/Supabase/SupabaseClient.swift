import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://lwynbkpmizbymgixrmgt.supabase.co")!,
    supabaseKey: "sb_publishable_VDC8Gh3yBv9kv_mU4HhRRg_f5_jmxmE",
    options: .init(
        auth: .init(emitLocalSessionAsInitialSession: true)
    )
)
