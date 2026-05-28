//
//  SupabaseConfig.swift
//  UndergroundFM
//
//  Vul hier je Supabase project URL en anon key in.
//  Beide vind je in Supabase dashboard → Project Settings → API.
//
//  URL formaat:     https://[project-ref].supabase.co
//  Anon key formaat: eyJhbGciOi...  (lange JWT token, publiek veilig)
//

import Foundation

enum SupabaseConfig {
    /// Bijv. "https://abcdefgh.supabase.co"
    static let url = "https://qpawgtxbjatyfngvaayy.supabase.co"

    /// De "anon public" key uit Project Settings → API
    static let anonKey = "sb_publishable_TpvrAYhloJQ7MNg7JJ6csg_kimv9HG1"
}
