import { supabase } from "@/lib/supabase";
import type { ArtistProfile, Playlist, Track } from "@/lib/types";

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
    .select("*")
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

export async function fetchUserPlaylists(userId: string): Promise<Playlist[]> {
  const { data, error } = await supabase
    .from("playlists")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []) as Playlist[];
}

export async function fetchFollowedArtists(userId: string): Promise<ArtistProfile[]> {
  const { data, error } = await supabase
    .from("follows")
    .select("artists(*)")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return ((data ?? []) as unknown as { artists: ArtistProfile | null }[])
    .map((row) => row.artists)
    .filter((a): a is ArtistProfile => a != null);
}

export async function fetchLikedTracks(userId: string): Promise<Track[]> {
  const { data, error } = await supabase
    .from("likes")
    .select(`tracks(${TRACK_SELECT})`)
    .eq("user_id", userId)
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return ((data ?? []) as unknown as { tracks: Track | null }[])
    .map((row) => row.tracks)
    .filter((t): t is Track => t != null);
}

export async function fetchPlaylist(playlistId: string): Promise<Playlist | null> {
  const { data, error } = await supabase
    .from("playlists")
    .select("*")
    .eq("id", playlistId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data as Playlist | null;
}

export async function fetchPlaylistTracks(playlistId: string): Promise<Track[]> {
  const { data, error } = await supabase
    .from("playlist_tracks")
    .select(`position, tracks(${TRACK_SELECT})`)
    .eq("playlist_id", playlistId)
    .order("position", { ascending: true });
  if (error) throw new Error(error.message);
  return ((data ?? []) as unknown as { tracks: Track | null }[])
    .map((row) => row.tracks)
    .filter((t): t is Track => t != null);
}

export interface SearchResults {
  tracks: Track[];
  artists: ArtistProfile[];
}

export async function searchContent(term: string): Promise<SearchResults> {
  const q = term.trim();
  if (q.length < 2) return { tracks: [], artists: [] };
  const pattern = `%${q}%`;
  const [tracksRes, artistsRes] = await Promise.all([
    supabase
      .from("tracks")
      .select(TRACK_SELECT)
      .eq("status", "live")
      .ilike("title", pattern)
      .limit(6),
    supabase.from("artists").select("*").ilike("artist_name", pattern).limit(6),
  ]);
  if (tracksRes.error) throw new Error(tracksRes.error.message);
  if (artistsRes.error) throw new Error(artistsRes.error.message);
  return {
    tracks: (tracksRes.data ?? []) as Track[],
    artists: (artistsRes.data ?? []) as ArtistProfile[],
  };
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
