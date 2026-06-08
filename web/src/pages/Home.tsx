import { useCallback, useMemo, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { usePlayer } from "@/contexts/PlayerContext";
import { GENRE_SECTIONS, type Track } from "@/lib/types";
import { GenreRow } from "@/components/GenreRow";
import { PaywallModal } from "@/components/PaywallModal";

export default function Home() {
  const { profile, isActive } = useAuth();
  const { playTrack } = usePlayer();
  const [paywallOpen, setPaywallOpen] = useState<boolean>(false);

  const sections = useMemo(() => {
    const prefs = profile?.genre_preferences ?? [];
    if (prefs.length === 0) return GENRE_SECTIONS;
    const filtered = GENRE_SECTIONS.filter((s) => prefs.includes(s.genre));
    return filtered.length > 0 ? filtered : GENRE_SECTIONS;
  }, [profile]);

  const handlePlay = useCallback(
    (track: Track, queue: Track[]) => {
      if (!isActive) {
        setPaywallOpen(true);
        return;
      }
      playTrack(track, queue);
    },
    [isActive, playTrack],
  );

  return (
    <div className="mx-auto max-w-6xl px-0 py-6 sm:px-4">
      <div className="mb-6 px-4 sm:px-0">
        <h1 className="font-display text-3xl font-extrabold tracking-tight">
          Welkom{profile?.display_name ? `, ${profile.display_name}` : ""}
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">Verse underground, recht uit de scene.</p>
      </div>

      {sections.map((section) => (
        <GenreRow key={section.id} section={section} onPlay={handlePlay} />
      ))}

      <PaywallModal open={paywallOpen} onClose={() => setPaywallOpen(false)} />
    </div>
  );
}
