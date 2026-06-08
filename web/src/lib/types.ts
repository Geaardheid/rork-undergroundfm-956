export interface EmbeddedArtist {
  artist_name: string;
}

export interface Track {
  id: string;
  artist_id: string;
  title: string;
  description: string | null;
  audio_url: string | null;
  thumbnail_url: string | null;
  duration: number | null;
  stream_count: number;
  like_count: number;
  genre_tags: string[];
  explicit: boolean;
  status: string;
  created_at: string | null;
  artists: EmbeddedArtist | null;
}

export interface ArtistProfile {
  id: string;
  user_id: string | null;
  artist_name: string;
  bio: string | null;
  genre_tags: string[];
  instagram_url: string | null;
  instagram_handle: string | null;
  banner_url: string | null;
  avatar_url: string | null;
  verified: boolean;
}

export interface AppUser {
  id: string;
  email: string;
  display_name: string | null;
  subscription_status: "active" | "trial" | "expired" | "inactive";
  current_streak: number | null;
  genre_preferences: string[] | null;
}

export interface GenreSection {
  id: string;
  title: string;
  emoji: string;
  genre: string;
  orderBy: "trending" | "newest";
}

export const GENRE_SECTIONS: GenreSection[] = [
  { id: "trending_rap", title: "Trending Rap", emoji: "🔥", genre: "rap", orderBy: "trending" },
  { id: "new_drill", title: "Nieuwe Drill", emoji: "⚡", genre: "drill", orderBy: "newest" },
  { id: "new_afro", title: "Nieuwe Afro", emoji: "🌍", genre: "afro", orderBy: "newest" },
  { id: "trending_trap", title: "Trending Trap", emoji: "💎", genre: "trap", orderBy: "trending" },
  { id: "new_rb", title: "Nieuwe R&B", emoji: "🎵", genre: "rb", orderBy: "newest" },
  { id: "new_house", title: "Nieuwe House", emoji: "🏠", genre: "house", orderBy: "newest" },
];

export function genreTint(genre: string): string {
  switch (genre) {
    case "rap":
      return "0 80% 55%";
    case "drill":
      return "55 100% 50%";
    case "afro":
      return "30 95% 55%";
    case "trap":
      return "200 90% 55%";
    case "rb":
      return "320 75% 60%";
    case "house":
      return "150 70% 50%";
    default:
      return "55 100% 50%";
  }
}
