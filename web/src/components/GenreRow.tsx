import { useQuery } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import type { GenreSection, Track } from "@/lib/types";
import { fetchGenreTracks } from "@/lib/queries";
import { TrackCard } from "@/components/TrackCard";

interface GenreRowProps {
  section: GenreSection;
  onPlay: (track: Track, queue: Track[]) => void;
}

export function GenreRow({ section, onPlay }: GenreRowProps) {
  const { data, isLoading } = useQuery({
    queryKey: ["genre", section.genre, section.orderBy],
    queryFn: () => fetchGenreTracks(section.genre, section.orderBy),
  });

  const tracks = data ?? [];

  if (!isLoading && tracks.length === 0) return null;

  return (
    <section className="mb-8">
      <h2 className="mb-3 flex items-center gap-2 px-4 font-display text-lg font-extrabold tracking-tight sm:px-0">
        <span>{section.emoji}</span>
        {section.title}
      </h2>
      {isLoading ? (
        <div className="flex h-44 items-center justify-center">
          <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <div className="no-scrollbar flex gap-3 overflow-x-auto px-4 pb-1 sm:px-0">
          {tracks.map((track) => (
            <TrackCard key={track.id} track={track} queue={tracks} onPlay={onPlay} />
          ))}
        </div>
      )}
    </section>
  );
}
