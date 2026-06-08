import { useNavigate } from "react-router-dom";
import { LogOut } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";

export function Header() {
  const navigate = useNavigate();
  const { profile, signOut } = useAuth();

  const handleSignOut = async () => {
    await signOut();
    navigate("/auth");
  };

  return (
    <header className="sticky top-0 z-30 border-b border-border bg-background/80 backdrop-blur-lg">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
        <button
          type="button"
          onClick={() => navigate("/")}
          className="flex items-center gap-2"
          aria-label="Home"
        >
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary font-display text-lg font-black text-primary-foreground">
            U
          </span>
          <span className="font-display text-lg font-extrabold tracking-tight">
            UNDERGROUND<span className="text-primary">FM</span>
          </span>
        </button>

        <div className="flex items-center gap-3">
          {profile?.display_name && (
            <span className="hidden text-sm text-muted-foreground sm:inline">
              {profile.display_name}
            </span>
          )}
          <button
            type="button"
            onClick={handleSignOut}
            aria-label="Uitloggen"
            className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:border-primary hover:text-primary"
          >
            <LogOut className="h-4 w-4" />
            <span className="hidden sm:inline">Uitloggen</span>
          </button>
        </div>
      </div>
    </header>
  );
}
