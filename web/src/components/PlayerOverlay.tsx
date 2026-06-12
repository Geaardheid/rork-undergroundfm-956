import { useNavigate } from "react-router-dom";
import {
  ChevronDown,
  Play,
  Pause,
  SkipBack,
  SkipForward,
  Volume2,
  VolumeX,
  Music,
} from "lucide-react";
import { usePlayer } from "@/contexts/PlayerContext";
import { formatTime } from "@/lib/queries";
import { cn } from "@/lib/utils";

export function PlayerOverlay() {
  const navigate = useNavigate();
  const {
    current,
    isPlaying,
    currentTime,
    duration,
    volume,
    isFullscreen,
    mediaMode,
    hasVideo,
    closeFullscreen,
    togglePlay,
    next,
    prev,
    seek,
    setVolume,
    setVideoSlot,
    switchMedia,
  } = usePlayer();

  if (!isFullscreen || !current) return null;

  const toggleMute = () => {
    if (volume > 0) setVolume(0);
    else setVolume(1);
  };

  const goArtist = () => {
    closeFullscreen();
    navigate(`/artist/${current.artist_id}`);
  };

  const progress = duration ? (currentTime / duration) * 100 : 0;
  const isVideo = mediaMode === "video";

  return (
    <div className="fixed inset-x-0 top-0 bottom-[var(--player-bar-h)] z-30 flex flex-col bg-background animate-slide-up lg:left-64">
      {/* Atmospheric background derived from the cover */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        {current.thumbnail_url && (
          <img
            src={current.thumbnail_url}
            alt=""
            className="absolute inset-0 h-full w-full scale-110 object-cover opacity-25 blur-3xl"
          />
        )}
        <div className="absolute inset-0 bg-gradient-to-b from-background/40 via-background/80 to-background" />
        <div className="absolute inset-x-0 top-0 h-1/3 bg-[radial-gradient(ellipse_70%_60%_at_50%_0%,hsl(55_100%_50%/0.18),transparent_70%)]" />
      </div>

      <div className="relative flex h-full flex-col">
        {/* Top bar */}
        <div className="flex items-center justify-between px-4 py-4">
          <button
            type="button"
            onClick={closeFullscreen}
            aria-label="Minimaliseer"
            className="rounded-full p-2 text-foreground transition-colors hover:bg-secondary"
          >
            <ChevronDown className="h-6 w-6" />
          </button>

          {/* Nummer / Video tab switch */}
          <div className="flex items-center gap-1 rounded-full border border-border bg-secondary/60 p-1">
            <button
              type="button"
              onClick={() => switchMedia("audio")}
              className={cn(
                "rounded-full px-4 py-1.5 text-sm font-bold transition-colors",
                !isVideo ? "bg-primary text-primary-foreground" : "text-muted-foreground",
              )}
            >
              Nummer
            </button>
            <button
              type="button"
              onClick={() => hasVideo && switchMedia("video")}
              disabled={!hasVideo}
              className={cn(
                "rounded-full px-4 py-1.5 text-sm font-bold transition-colors",
                isVideo
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground",
                !hasVideo && "cursor-not-allowed opacity-40",
              )}
            >
              Video
            </button>
          </div>

          <div className="w-10" />
        </div>

        {/* Content */}
        <div className="flex min-h-0 flex-1 flex-col items-center justify-center overflow-y-auto px-6 py-4">
          <div className={cn("flex w-full flex-col items-center", isVideo ? "max-w-5xl" : "max-w-md")}>
            {/* Media area: cover (audio) or video. Video stays mounted to keep position when switching. */}
            <div
              className={cn(
                "aspect-square w-full max-w-sm overflow-hidden rounded-2xl bg-secondary shadow-2xl glow-yellow",
                isVideo && "hidden",
              )}
            >
              {current.thumbnail_url ? (
                <img
                  src={current.thumbnail_url}
                  alt={current.title}
                  className="h-full w-full object-cover"
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                  <Music className="h-20 w-20" />
                </div>
              )}
            </div>

            {hasVideo && (
              <div
                ref={setVideoSlot}
                className={cn(
                  "mx-auto aspect-video w-full max-w-[min(100%,calc(68vh*16/9))] overflow-hidden rounded-2xl bg-black shadow-2xl",
                  isVideo ? "block" : "hidden",
                )}
              />
            )}

            {/* Title + artist */}
            <div className="mt-6 w-full text-center">
              <h1 className="truncate font-display text-2xl font-extrabold tracking-tight">
                {current.title}
              </h1>
              <button
                type="button"
                onClick={goArtist}
                className="mt-1 truncate text-base text-muted-foreground transition-colors hover:text-primary"
              >
                {current.artists?.artist_name ?? "Unknown"}
              </button>
            </div>

            {/* Seek */}
            <div className="mt-6 w-full">
              <input
                type="range"
                min={0}
                max={duration || 0}
                value={currentTime}
                onChange={(e) => seek(Number(e.target.value))}
                aria-label="Zoek"
                className="h-1 w-full"
                style={{
                  background: `linear-gradient(to right, hsl(55 100% 50%) ${progress}%, hsl(0 0% 25%) 0%)`,
                }}
              />
              <div className="mt-1 flex justify-between text-[11px] tabular-nums text-muted-foreground">
                <span>{formatTime(currentTime)}</span>
                <span>{formatTime(duration)}</span>
              </div>
            </div>

            {/* Controls */}
            <div className="mt-4 flex items-center justify-center gap-8">
              <button
                type="button"
                onClick={prev}
                aria-label="Vorige"
                className="text-foreground transition-colors hover:text-primary"
              >
                <SkipBack className="h-8 w-8 fill-current" />
              </button>
              <button
                type="button"
                onClick={togglePlay}
                aria-label={isPlaying ? "Pauzeer" : "Speel af"}
                className="flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground transition-transform hover:scale-105 glow-yellow"
              >
                {isPlaying ? (
                  <Pause className="h-8 w-8 fill-current" />
                ) : (
                  <Play className="ml-1 h-8 w-8 fill-current" />
                )}
              </button>
              <button
                type="button"
                onClick={next}
                aria-label="Volgende"
                className="text-foreground transition-colors hover:text-primary"
              >
                <SkipForward className="h-8 w-8 fill-current" />
              </button>
            </div>

            {/* Volume */}
            <div className="mt-6 flex w-full max-w-xs items-center gap-3">
              <button
                type="button"
                onClick={toggleMute}
                aria-label="Geluid"
                className="text-muted-foreground transition-colors hover:text-foreground"
              >
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
      </div>
    </div>
  );
}
