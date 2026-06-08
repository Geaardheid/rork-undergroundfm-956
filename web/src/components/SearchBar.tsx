import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { Search, X, Music, Loader2 } from "lucide-react";
import { usePlayback } from "@/contexts/PlaybackContext";
import { searchContent } from "@/lib/queries";

export function SearchBar() {
  const navigate = useNavigate();
  const { requestPlay } = usePlayback();
  const [term, setTerm] = useState<string>("");
  const [open, setOpen] = useState<boolean>(false);
  const containerRef = useRef<HTMLDivElement | null>(null);

  // Debounce the query term.
  const [debounced, setDebounced] = useState<string>("");
  useEffect(() => {
    const id = setTimeout(() => setDebounced(term), 250);
    return () => clearTimeout(id);
  }, [term]);

  const { data, isFetching } = useQuery({
    queryKey: ["search", debounced],
    queryFn: () => searchContent(debounced),
    enabled: debounced.trim().length >= 2,
  });

  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, []);

  const reset = () => {
    setTerm("");
    setDebounced("");
    setOpen(false);
  };

  const tracks = data?.tracks ?? [];
  const artists = data?.artists ?? [];
  const hasResults = tracks.length > 0 || artists.length > 0;
  const showDropdown = open && debounced.trim().length >= 2;

  return (
    <div ref={containerRef} className="relative w-full max-w-md">
      <div className="flex items-center gap-2 rounded-full border border-border bg-secondary/60 px-4 py-2 transition-colors focus-within:border-primary">
        <Search className="h-4 w-4 shrink-0 text-muted-foreground" />
        <input
          type="text"
          value={term}
          onChange={(e) => {
            setTerm(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          placeholder="Zoek tracks of artiesten"
          className="w-full bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
        />
        {term && (
          <button type="button" onClick={reset} aria-label="Wissen" className="text-muted-foreground hover:text-foreground">
            <X className="h-4 w-4" />
          </button>
        )}
      </div>

      {showDropdown && (
        <div className="absolute left-0 right-0 top-full z-50 mt-2 max-h-[70vh] overflow-y-auto rounded-xl border border-border bg-popover/95 p-2 shadow-2xl backdrop-blur-lg">
          {isFetching && !hasResults ? (
            <div className="flex items-center justify-center py-6">
              <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            </div>
          ) : !hasResults ? (
            <p className="px-3 py-6 text-center text-sm text-muted-foreground">Geen resultaten</p>
          ) : (
            <>
              {artists.length > 0 && (
                <div className="mb-1">
                  <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
                    Artiesten
                  </p>
                  {artists.map((a) => (
                    <button
                      key={a.id}
                      type="button"
                      onClick={() => {
                        navigate(`/artist/${a.id}`);
                        reset();
                      }}
                      className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left transition-colors hover:bg-secondary"
                    >
                      <span className="h-9 w-9 shrink-0 overflow-hidden rounded-full bg-secondary">
                        {a.avatar_url ? (
                          <img src={a.avatar_url} alt="" className="h-full w-full object-cover" />
                        ) : null}
                      </span>
                      <span className="truncate text-sm font-medium">{a.artist_name}</span>
                    </button>
                  ))}
                </div>
              )}
              {tracks.length > 0 && (
                <div>
                  <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
                    Tracks
                  </p>
                  {tracks.map((t) => (
                    <button
                      key={t.id}
                      type="button"
                      onClick={() => {
                        requestPlay(t, tracks);
                        reset();
                      }}
                      className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left transition-colors hover:bg-secondary"
                    >
                      <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded bg-secondary text-muted-foreground">
                        {t.thumbnail_url ? (
                          <img src={t.thumbnail_url} alt="" className="h-full w-full object-cover" />
                        ) : (
                          <Music className="h-4 w-4" />
                        )}
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-medium">{t.title}</span>
                        <span className="block truncate text-xs text-muted-foreground">
                          {t.artists?.artist_name ?? "Unknown"}
                        </span>
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}
