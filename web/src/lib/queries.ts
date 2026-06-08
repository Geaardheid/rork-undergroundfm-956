import { supabase } from "@/lib/supabase";
import type { ArtistProfile, Track } from "@/lib/types";

const TRACK_SELECT = "*,artists(artist_name)";

export async function fetchGenreTracks(
  genre: string,
  orderBy: "trending" | "newest",
  limit = 12,
): Promise<Track[]> {
  let query = supabase
    .from("tracks")
    .select(TRACK_SELECT)
    .eq("status", "live")
    .contains("genre_tags", [genre])
    .limit(limit);

  if (orderBy === "trending") {
    query = query.order("weighted_minutes_total", { ascending: false, nullsFirst: false });
  } else {
    query = query.order("created_at", { ascending: false });
  }

  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return (data ?? []) as Track[];
}

export async function fetchArtist(artistId: string): Promise<ArtistProfile | null> {
  const { data, error } = await supabase
    .from("artists")
    .select("id,user_id,artist_name,bio,genre_tags,instagram_url,instagram_handle,banner_url,avatar_url,verified")
    .eq("id", artistId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data as ArtistProfile | null;
}

export async function fetchArtistTracks(artistId: string): Promise<Track[]> {
  const { data, error } = await supabase
    .from("tracks")
    .select(TRACK_SELECT)
    .eq("artist_id", artistId)
    .eq("status", "live")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []) as Track[];
}

export function normalizeInstagram(raw: string | null): string | null {
  if (!raw) return null;
  let s = raw.trim();
  for (const prefix of ["https://", "http://", "www.", "instagram.com/", "instagr.am/"]) {
    if (s.toLowerCase().startsWith(prefix)) s = s.slice(prefix.length);
  }
  s = s.replace(/^[@/ ]+|[/ ]+$/g, "");
  const slash = s.indexOf("/");
  if (slash >= 0) s = s.slice(0, slash);
  return s || null;
}

export function formatTime(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return "0:00";
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}
