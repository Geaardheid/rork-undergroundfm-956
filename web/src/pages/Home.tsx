import { useMemo } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { usePlayback } from "@/contexts/PlaybackContext";
import { GENRE_SECTIONS } from "@/lib/types";
import { GenreRow } from "@/components/GenreRow";

export default function Home() {
  const { profile } = useAuth();
  const { requestPlay } = usePlayback();

  const sections = useMemo(() => {
    const prefs = profile?.genre_preferences ?? [];
    if (prefs.length === 0) return GENRE_SECTIONS;
    const filtered = GENRE_SECTIONS.filter((s) => prefs.includes(s.genre));
    return filtered.length > 0 ? filtered : GENRE_SECTIONS;
  }, [profile]);

  return (
    <div className="mx-auto max-w-6xl px-0 py-6 sm:px-4">
      <div className="mb-6 px-4 sm:px-0">
        <h1 className="font-display text-3xl font-extrabold tracking-tight">
          Welkom{profile?.display_name ? `, ${profile.display_name}` : ""}
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">Verse underground, recht uit de scene.</p>
      </div>

      {sections.map((section) => (
        <GenreRow key={section.id} section={section} onPlay={requestPlay} />
      ))}
    </div>
  );
}
