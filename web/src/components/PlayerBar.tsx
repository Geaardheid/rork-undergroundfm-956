import { ChevronUp, Play, Pause, SkipBack, SkipForward, Volume2, VolumeX, Music } from "lucide-react";
import { useState } from "react";
import { usePlayer } from "@/contexts/PlayerContext";
import { formatTime } from "@/lib/queries";

export function PlayerBar() {
  const {
    current,
    isPlaying,
    currentTime,
    duration,
    volume,
    isFullscreen,
    openFullscreen,
    togglePlay,
    next,
    prev,
    seek,
    setVolume,
  } = usePlayer();
  const [lastVolume, setLastVolume] = useState<number>(1);

  if (!current || isFullscreen) return null;

  const toggleMute = () => {
    if (volume > 0) {
      setLastVolume(volume);
      setVolume(0);
    } else {
      setVolume(lastVolume || 1);
    }
  };

  return (
    <div className="fixed inset-x-0 bottom-0 z-40 animate-slide-up border-t border-border bg-card/95 backdrop-blur-lg">
      <div className="mx-auto flex max-w-6xl items-center gap-3 px-3 py-2.5 sm:gap-4 sm:px-4">
        {/* Track info */}
        <button
          type="button"
          onClick={openFullscreen}
          aria-label="Open speler"
          className="group flex min-w-0 flex-1 items-center gap-3 text-left sm:flex-none sm:w-56"
        >
          <div className="relative h-12 w-12 shrink-0 overflow-hidden rounded-md bg-secondary">
            {current.thumbnail_url ? (
              <img src={current.thumbnail_url} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                <Music className="h-5 w-5" />
              </div>
            )}
            <div className="absolute inset-0 flex items-center justify-center bg-black/50 opacity-0 transition-opacity group-hover:opacity-100">
              <ChevronUp className="h-5 w-5 text-white" />
            </div>
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold text-foreground">{current.title}</p>
            <p className="truncate text-xs text-muted-foreground">
              {current.artists?.artist_name ?? "Unknown"}
            </p>
          </div>
        </button>

        {/* Controls + seek */}
        <div className="flex flex-1 flex-col items-center gap-1">
          <div className="flex items-center gap-4">
            <button type="button" onClick={prev} aria-label="Vorige" className="text-muted-foreground transition-colors hover:text-foreground">
              <SkipBack className="h-5 w-5 fill-current" />
            </button>
            <button
              type="button"
              onClick={togglePlay}
              aria-label={isPlaying ? "Pauzeer" : "Speel af"}
              className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground transition-transform hover:scale-105"
            >
              {isPlaying ? <Pause className="h-5 w-5 fill-current" /> : <Play className="h-5 w-5 fill-current" />}
            </button>
            <button type="button" onClick={next} aria-label="Volgende" className="text-muted-foreground transition-colors hover:text-foreground">
              <SkipForward className="h-5 w-5 fill-current" />
            </button>
          </div>
          <div className="flex w-full max-w-md items-center gap-2">
            <span className="w-9 text-right text-[10px] tabular-nums text-muted-foreground">
              {formatTime(currentTime)}
            </span>
            <input
              type="range"
              min={0}
              max={duration || 0}
              value={currentTime}
              onChange={(e) => seek(Number(e.target.value))}
              aria-label="Zoek"
              className="h-1 flex-1"
              style={{
                background: `linear-gradient(to right, hsl(55 100% 50%) ${
                  duration ? (currentTime / duration) * 100 : 0
                }%, hsl(0 0% 25%) 0%)`,
              }}
            />
            <span className="w-9 text-[10px] tabular-nums text-muted-foreground">
              {formatTime(duration)}
            </span>
          </div>
        </div>

        {/* Volume */}
        <div className="hidden items-center gap-2 sm:flex sm:w-32">
          <button type="button" onClick={toggleMute} aria-label="Geluid" className="text-muted-foreground transition-colors hover:text-foreground">
            {volume > 0 ? <Volume2 className="h-5 w-5" /> : <VolumeX className="h-5 w-5" />}
          </button>
          <input
            type="range"
            min={0}
            max={1}
            step={0.01}
            value={volume}
            onChange={(e) => setVolume(Number(e.target.value))}
            aria-label="Volume"
            className="h-1 flex-1"
            style={{
              background: `linear-gradient(to right, hsl(55 100% 50%) ${volume * 100}%, hsl(0 0% 25%) 0%)`,
            }}
          />
        </div>
      </div>
    </div>
  );
}
