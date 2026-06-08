import { memo } from "react";
import { useQuery } from "@tanstack/react-query";
import { useLocation, useNavigate } from "react-router-dom";
import { Home, Library, ListMusic, LogOut, Music } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { fetchUserPlaylists } from "@/lib/queries";
import { cn } from "@/lib/utils";

interface SidebarProps {
  /** Called after a navigation item is tapped (used to close the mobile drawer). */
  onNavigate?: () => void;
}

function SidebarBase({ onNavigate }: SidebarProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { session, profile, signOut } = useAuth();
  const userId = session?.user.id;

  const { data: playlists } = useQuery({
    queryKey: ["playlists", userId],
    queryFn: () => fetchUserPlaylists(userId as string),
    enabled: !!userId,
  });

  const go = (path: string) => {
    navigate(path);
    onNavigate?.();
  };

  const handleSignOut = async () => {
    await signOut();
    navigate("/auth");
  };

  const isActive = (path: string) =>
    path === "/" ? location.pathname === "/" : location.pathname.startsWith(path);

  const navItem = (path: string, label: string, Icon: typeof Home) => (
    <button
      type="button"
      onClick={() => go(path)}
      className={cn(
        "flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition-colors",
        isActive(path)
          ? "bg-primary/10 text-primary"
          : "text-muted-foreground hover:bg-secondary hover:text-foreground",
      )}
    >
      <Icon className="h-5 w-5 shrink-0" />
      {label}
    </button>
  );

  return (
    <div className="flex h-full flex-col gap-4 p-3">
      <button
        type="button"
        onClick={() => go("/")}
        className="flex items-center gap-2 px-2 pt-2"
        aria-label="Home"
      >
        <img src="/logo-u.png" alt="UndergroundFM" className="h-8 w-8 object-contain" />
        <span className="font-display text-lg font-extrabold tracking-tight">
          UNDERGROUND<span className="text-primary">FM</span>
        </span>
      </button>

      <nav className="flex flex-col gap-1">
        {navItem("/", "Home", Home)}
        {navItem("/library", "Bibliotheek", Library)}
      </nav>

      <div className="flex min-h-0 flex-1 flex-col">
        <p className="px-3 pb-1 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
          Mijn playlists
        </p>
        <div className="no-scrollbar flex-1 overflow-y-auto">
          {playlists && playlists.length > 0 ? (
            playlists.map((pl) => (
              <button
                key={pl.id}
                type="button"
                onClick={() => go(`/playlist/${pl.id}`)}
                className={cn(
                  "flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm transition-colors",
                  isActive(`/playlist/${pl.id}`)
                    ? "text-primary"
                    : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                )}
              >
                <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded bg-secondary">
                  {pl.cover_url ? (
                    <img src={pl.cover_url} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <ListMusic className="h-4 w-4" />
                  )}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-medium">{pl.name}</span>
                  <span className="block truncate text-xs text-muted-foreground">
                    {pl.track_count} {pl.track_count === 1 ? "nummer" : "nummers"}
                  </span>
                </span>
              </button>
            ))
          ) : (
            <p className="flex items-center gap-2 px-3 py-2 text-xs text-muted-foreground">
              <Music className="h-4 w-4" /> Nog geen playlists
            </p>
          )}
        </div>
      </div>

      <div className="border-t border-border pt-3">
        {profile?.display_name && (
          <p className="truncate px-3 pb-2 text-sm text-foreground">{profile.display_name}</p>
        )}
        <button
          type="button"
          onClick={handleSignOut}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground"
        >
          <LogOut className="h-5 w-5" />
          Uitloggen
        </button>
      </div>
    </div>
  );
}

export const Sidebar = memo(SidebarBase);
