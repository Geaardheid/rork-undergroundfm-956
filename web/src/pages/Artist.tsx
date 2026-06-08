import { useCallback, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Loader2, Instagram, Play, Pause, BadgeCheck, Music } from "lucide-react";
import { fetchArtist, fetchArtistTracks, normalizeInstagram, formatTime } from "@/lib/queries";
import { useAuth } from "@/contexts/AuthContext";
import { usePlayer } from "@/contexts/PlayerContext";
import { PaywallModal } from "@/components/PaywallModal";
import type { Track } from "@/lib/types";

export default function Artist() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { isActive } = useAuth();
  const { playTrack, current, isPlaying } = usePlayer();
  const [paywallOpen, setPaywallOpen] = useState<boolean>(false);

  const { data: artist, isLoading: artistLoading } = useQuery({
    queryKey: ["artist", id],
    queryFn: () => fetchArtist(id ?? ""),
    enabled: !!id,
  });

  const { data: tracks } = useQuery({
    queryKey: ["artist-tracks", id],
    queryFn: () => fetchArtistTracks(id ?? ""),
    enabled: !!id,
  });

  const trackList = tracks ?? [];

  const handlePlay = useCallback(
    (track: Track) => {
      if (!isActive) {
        setPaywallOpen(true);
        return;
      }
      playTrack(track, trackList);
    },
    [isActive, playTrack, trackList],
  );

  if (artistLoading) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <Loader2 className="h-7 w-7 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!artist) {
    return (
      <div className="flex h-[60vh] flex-col items-center justify-center gap-4 text-center">
        <p className="text-muted-foreground">Artiest niet gevonden.</p>
        <button type="button" onClick={() => navigate("/")} className="text-sm font-semibold text-primary">
          Terug naar home
        </button>
      </div>
    );
  }

  const igHandle = normalizeInstagram(artist.instagram_handle ?? artist.instagram_url);

  return (
    <div>
      {/* Banner */}
      <div className="relative h-48 w-full overflow-hidden bg-secondary sm:h-64">
        {artist.banner_url ? (
          <img src={artist.banner_url} alt="" className="h-full w-full object-cover" />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-primary/20 to-background" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent" />
        <button
          type="button"
          onClick={() => navigate(-1)}
          aria-label="Terug"
          className="absolute left-4 top-4 flex h-10 w-10 items-center justify-center rounded-full bg-black/50 text-foreground backdrop-blur transition-colors hover:bg-black/70"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
      </div>

      <div className="mx-auto max-w-4xl px-4">
        {/* Header */}
        <div className="-mt-12 flex items-end gap-4">
          <div className="h-24 w-24 shrink-0 overflow-hidden rounded-2xl border-4 border-background bg-secondary">
            {artist.avatar_url ? (
              <img src={artist.avatar_url} alt={artist.artist_name} className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                <Music className="h-8 w-8" />
              </div>
            )}
          </div>
          <div className="pb-1">
            <h1 className="flex items-center gap-2 font-display text-2xl font-extrabold tracking-tight sm:text-3xl">
              {artist.artist_name}
              {artist.verified && <BadgeCheck className="h-6 w-6 text-primary" />}
            </h1>
            {igHandle && (
              <a
                href={`https://instagram.com/${igHandle}`}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-1 inline-flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-primary"
              >
                <Instagram className="h-4 w-4" />@{igHandle}
              </a>
            )}
          </div>
        </div>

        {artist.bio && (
          <p className="mt-4 max-w-2xl text-sm leading-relaxed text-muted-foreground">{artist.bio}</p>
        )}

        {/* Tracks */}
        <h2 className="mb-2 mt-8 font-display text-lg font-extrabold tracking-tight">Tracks</h2>
        {trackList.length === 0 ? (
          <p className="py-8 text-sm text-muted-foreground">Nog geen tracks.</p>
        ) : (
          <ul className="divide-y divide-border">
            {trackList.map((track, i) => {
              const isCurrent = current?.id === track.id;
              return (
                <li key={track.id}>
                  <button
                    type="button"
                    onClick={() => handlePlay(track)}
                    className="flex w-full items-center gap-3 py-3 text-left transition-colors hover:bg-secondary/40"
                  >
                    <div className="relative h-12 w-12 shrink-0 overflow-hidden rounded-md bg-secondary">
                      {track.thumbnail_url ? (
                        <img src={track.thumbnail_url} alt="" className="h-full w-full object-cover" />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center text-xs text-muted-foreground">
                          {i + 1}
                        </div>
                      )}
                      <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 transition-opacity hover:opacity-100">
                        {isCurrent && isPlaying ? (
                          <Pause className="h-5 w-5 fill-current text-primary" />
                        ) : (
                          <Play className="h-5 w-5 fill-current text-primary" />
                        )}
                      </div>
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className={`truncate text-sm font-semibold ${isCurrent ? "text-primary" : "text-foreground"}`}>
                        {track.title}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {track.stream_count.toLocaleString("nl-NL")} streams
                      </p>
                    </div>
                    {track.duration ? (
                      <span className="text-xs tabular-nums text-muted-foreground">
                        {formatTime(track.duration)}
                      </span>
                    ) : null}
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>

      <PaywallModal open={paywallOpen} onClose={() => setPaywallOpen(false)} />
    </div>
  );
}
