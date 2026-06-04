//
//  Playlist.swift
//  UndergroundFM
//
//  Gebruikers-playlists (eigen + publiek).
//
//  Bijbehorende Supabase-tabellen (zie supabase/schema.sql):
//
//  CREATE TABLE public.playlists (
//    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
//    name TEXT NOT NULL,
//    description TEXT,
//    is_public BOOLEAN NOT NULL DEFAULT FALSE,
//    track_count INTEGER NOT NULL DEFAULT 0,
//    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
//  );
//
//  CREATE TABLE public.playlist_tracks (
//    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//    playlist_id UUID NOT NULL REFERENCES public.playlists(id) ON DELETE CASCADE,
//    track_id UUID NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
//    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
//  );
//

import Foundation

nonisolated struct Playlist: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let isPublic: Bool
    let trackCount: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case isPublic = "is_public"
        case trackCount = "track_count"
        case createdAt = "created_at"
    }
}
