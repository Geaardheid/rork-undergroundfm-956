import { memo } from "react";
import { Play, Pause, Music } from "lucide-react";
import { useNavigate } from "react-router-dom";
import type { Track } from "@/lib/types";
import { usePlayer } from "@/contexts/PlayerContext";

interface TrackCardProps {
  track: Track;
  queue: Track[];
  onPlay: (track: Track, queue: Track[]) => void;
}

function TrackCardBase({ track, queue, onPlay }: TrackCardProps) {
  const navigate = useNavigate();
  const { current, isPlaying } = usePlayer();
  const isCurrent = current?.id === track.id;

  return (
    <div className="group w-40 shrink-0 sm:w-44">
      <div className="relative aspect-square overflow-hidden rounded-xl bg-secondary">
        {track.thumbnail_url ? (
          <img
            src={track.thumbnail_url}
            alt={track.title}
            loading="lazy"
            className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-muted-foreground">
            <Music className="h-10 w-10" />
          </div>
        )}
        <button
          type="button"
          onClick={() => onPlay(track, queue)}
          aria-label={isCurrent && isPlaying ? "Pauzeer" : "Speel af"}
          className="absolute bottom-2 right-2 flex h-11 w-11 translate-y-2 items-center justify-center rounded-full bg-primary text-primary-foreground opacity-0 shadow-lg transition-all duration-200 group-hover:translate-y-0 group-hover:opacity-100 glow-yellow"
        >
          {isCurrent && isPlaying ? (
            <Pause className="h-5 w-5 fill-current" />
          ) : (
            <Play className="h-5 w-5 fill-current" />
          )}
        </button>
      </div>
      <p className="mt-2 truncate text-sm font-semibold text-foreground" title={track.title}>
        {track.title}
      </p>
      <button
        type="button"
        onClick={() => navigate(`/artist/${track.artist_id}`)}
        className="truncate text-left text-xs text-muted-foreground transition-colors hover:text-primary"
      >
        {track.artists?.artist_name ?? "Unknown"}
      </button>
    </div>
  );
}

export const TrackCard = memo(TrackCardBase);
