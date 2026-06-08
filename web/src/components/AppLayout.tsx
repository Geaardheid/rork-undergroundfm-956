import { useState } from "react";
import { Outlet, Navigate } from "react-router-dom";
import { Loader2, Menu, X } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { Sidebar } from "@/components/Sidebar";
import { SearchBar } from "@/components/SearchBar";
import { PlayerBar } from "@/components/PlayerBar";
import { PlayerOverlay } from "@/components/PlayerOverlay";

export function AppLayout() {
  const { session, loading } = useAuth();
  const [drawerOpen, setDrawerOpen] = useState<boolean>(false);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!session) return <Navigate to="/auth" replace />;

  return (
    <div className="min-h-screen">
      {/* Fixed sidebar (desktop) */}
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 border-r border-border bg-card/50 backdrop-blur-sm lg:block">
        <Sidebar />
      </aside>

      {/* Mobile drawer */}
      {drawerOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setDrawerOpen(false)}
          />
          <div className="absolute inset-y-0 left-0 w-64 border-r border-border bg-card animate-slide-up">
            <button
              type="button"
              onClick={() => setDrawerOpen(false)}
              aria-label="Sluiten"
              className="absolute right-2 top-2 z-10 rounded-full p-1.5 text-muted-foreground hover:text-foreground"
            >
              <X className="h-5 w-5" />
            </button>
            <Sidebar onNavigate={() => setDrawerOpen(false)} />
          </div>
        </div>
      )}

      <div className="lg:pl-64">
        {/* Top bar with search */}
        <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-border bg-background/80 px-3 py-3 backdrop-blur-lg sm:px-4">
          <button
            type="button"
            onClick={() => setDrawerOpen(true)}
            aria-label="Menu"
            className="shrink-0 rounded-lg p-2 text-muted-foreground hover:bg-secondary hover:text-foreground lg:hidden"
          >
            <Menu className="h-5 w-5" />
          </button>
          <SearchBar />
        </header>

        <main className="pb-28">
          <Outlet />
        </main>
      </div>

      <PlayerBar />
      <PlayerOverlay />
    </div>
  );
}
