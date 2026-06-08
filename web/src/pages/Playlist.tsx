import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import { Loader2, ListMusic, Music, Play, Pause } from "lucide-react";
import { usePlayer } from "@/contexts/PlayerContext";
import { usePlayback } from "@/contexts/PlaybackContext";
import { fetchPlaylist, fetchPlaylistTracks, formatTime } from "@/lib/queries";

export default function Playlist() {
  const { id } = useParams<{ id: string }>();
  const { current, isPlaying } = usePlayer();
  const { requestPlay } = usePlayback();

  const playlist = useQuery({
    queryKey: ["playlist", id],
    queryFn: () => fetchPlaylist(id as string),
    enabled: !!id,
  });
  const tracks = useQuery({
    queryKey: ["playlist-tracks", id],
    queryFn: () => fetchPlaylistTracks(id as string),
    enabled: !!id,
  });

  if (playlist.isLoading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!playlist.data) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-16 text-center">
        <p className="text-lg font-semibold">Playlist niet gevonden</p>
      </div>
    );
  }

  const pl = playlist.data;
  const list = tracks.data ?? [];

  return (
    <div className="mx-auto max-w-5xl px-4 py-6">
      {/* Header */}
      <div className="mb-8 flex flex-col items-center gap-4 sm:flex-row sm:items-end">
        <div className="flex h-44 w-44 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-secondary shadow-2xl">
          {pl.cover_url ? (
            <img src={pl.cover_url} alt="" className="h-full w-full object-cover" />
          ) : (
            <ListMusic className="h-16 w-16 text-muted-foreground" />
          )}
        </div>
        <div className="text-center sm:text-left">
          <p className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Playlist</p>
          <h1 className="mt-1 font-display text-3xl font-extrabold tracking-tight">{pl.name}</h1>
          {pl.description && <p className="mt-2 text-sm text-muted-foreground">{pl.description}</p>}
          <p className="mt-2 text-sm text-muted-foreground">
            {pl.track_count} {pl.track_count === 1 ? "nummer" : "nummers"}
          </p>
          {list.length > 0 && (
            <button
              type="button"
              onClick={() => requestPlay(list[0], list)}
              className="mt-4 inline-flex items-center gap-2 rounded-full bg-primary px-6 py-2.5 text-sm font-bold text-primary-foreground transition-transform hover:scale-105 glow-yellow"
            >
              <Play className="h-4 w-4 fill-current" /> Afspelen
            </button>
          )}
        </div>
      </div>

      {/* Tracks */}
      {tracks.isLoading ? (
        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
      ) : list.length === 0 ? (
        <p className="text-sm text-muted-foreground">Deze playlist is nog leeg.</p>
      ) : (
        <div className="flex flex-col gap-1">
          {list.map((track, i) => {
            const isCurrent = current?.id === track.id;
            return (
              <button
                key={track.id}
                type="button"
                onClick={() => requestPlay(track, list)}
                className="group flex items-center gap-3 rounded-lg px-2 py-2 text-left transition-colors hover:bg-secondary"
              >
                <span className="w-5 text-center text-sm text-muted-foreground">{i + 1}</span>
                <span className="relative flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded bg-secondary text-muted-foreground">
                  {track.thumbnail_url ? (
                    <img src={track.thumbnail_url} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <Music className="h-4 w-4" />
                  )}
                  <span className="absolute inset-0 flex items-center justify-center bg-black/50 opacity-0 transition-opacity group-hover:opacity-100">
                    {isCurrent && isPlaying ? (
                      <Pause className="h-4 w-4 fill-white text-white" />
                    ) : (
                      <Play className="h-4 w-4 fill-white text-white" />
                    )}
                  </span>
                </span>
                <span className="min-w-0 flex-1">
                  <span className={`block truncate text-sm font-semibold ${isCurrent ? "text-primary" : "text-foreground"}`}>
                    {track.title}
                  </span>
                  <span className="block truncate text-xs text-muted-foreground">
                    {track.artists?.artist_name ?? "Unknown"}
                  </span>
                </span>
                <span className="hidden text-xs tabular-nums text-muted-foreground sm:block">
                  {track.duration ? formatTime(track.duration) : ""}
                </span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
