import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { Loader2, ListMusic, Music, Play, Pause, BadgeCheck } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { usePlayer } from "@/contexts/PlayerContext";
import { usePlayback } from "@/contexts/PlaybackContext";
import { fetchUserPlaylists, fetchFollowedArtists, fetchLikedTracks } from "@/lib/queries";
import type { Track } from "@/lib/types";

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mb-10">
      <h2 className="mb-3 font-display text-xl font-extrabold tracking-tight">{title}</h2>
      {children}
    </section>
  );
}

export default function Library() {
  const navigate = useNavigate();
  const { session } = useAuth();
  const { current, isPlaying } = usePlayer();
  const { requestPlay } = usePlayback();
  const userId = session?.user.id as string;

  const playlists = useQuery({
    queryKey: ["playlists", userId],
    queryFn: () => fetchUserPlaylists(userId),
    enabled: !!userId,
  });
  const artists = useQuery({
    queryKey: ["followed-artists", userId],
    queryFn: () => fetchFollowedArtists(userId),
    enabled: !!userId,
  });
  const liked = useQuery({
    queryKey: ["liked-tracks", userId],
    queryFn: () => fetchLikedTracks(userId),
    enabled: !!userId,
  });

  const likedTracks = liked.data ?? [];

  return (
    <div className="mx-auto max-w-6xl px-4 py-6">
      <h1 className="mb-6 font-display text-3xl font-extrabold tracking-tight">Bibliotheek</h1>

      <Section title="Mijn playlists">
        {playlists.isLoading ? (
          <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
        ) : (playlists.data ?? []).length === 0 ? (
          <p className="text-sm text-muted-foreground">Nog geen playlists.</p>
        ) : (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
            {(playlists.data ?? []).map((pl) => (
              <button
                key={pl.id}
                type="button"
                onClick={() => navigate(`/playlist/${pl.id}`)}
                className="group text-left"
              >
                <div className="flex aspect-square items-center justify-center overflow-hidden rounded-xl bg-secondary">
                  {pl.cover_url ? (
                    <img src={pl.cover_url} alt="" className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105" />
                  ) : (
                    <ListMusic className="h-10 w-10 text-muted-foreground" />
                  )}
                </div>
                <p className="mt-2 truncate text-sm font-semibold">{pl.name}</p>
                <p className="truncate text-xs text-muted-foreground">
                  {pl.track_count} {pl.track_count === 1 ? "nummer" : "nummers"}
                </p>
              </button>
            ))}
          </div>
        )}
      </Section>

      <Section title="Gevolgde artiesten">
        {artists.isLoading ? (
          <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
        ) : (artists.data ?? []).length === 0 ? (
          <p className="text-sm text-muted-foreground">Je volgt nog geen artiesten.</p>
        ) : (
          <div className="grid grid-cols-3 gap-3 sm:grid-cols-4 md:grid-cols-6">
            {(artists.data ?? []).map((a) => (
              <button
                key={a.id}
                type="button"
                onClick={() => navigate(`/artist/${a.id}`)}
                className="group text-center"
              >
                <div className="mx-auto flex aspect-square w-full items-center justify-center overflow-hidden rounded-full bg-secondary">
                  {a.avatar_url ? (
                    <img src={a.avatar_url} alt="" className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105" />
                  ) : (
                    <Music className="h-8 w-8 text-muted-foreground" />
                  )}
                </div>
                <p className="mt-2 flex items-center justify-center gap-1 truncate text-sm font-semibold">
                  <span className="truncate">{a.artist_name}</span>
                  {a.verified && <BadgeCheck className="h-3.5 w-3.5 shrink-0 text-primary" />}
                </p>
              </button>
            ))}
          </div>
        )}
      </Section>

      <Section title="Gelikete tracks">
        {liked.isLoading ? (
          <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
        ) : likedTracks.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nog geen gelikete tracks.</p>
        ) : (
          <div className="flex flex-col gap-1">
            {likedTracks.map((track: Track, i: number) => {
              const isCurrent = current?.id === track.id;
              return (
                <button
                  key={track.id}
                  type="button"
                  onClick={() => requestPlay(track, likedTracks)}
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
                </button>
              );
            })}
          </div>
        )}
      </Section>
    </div>
  );
}
