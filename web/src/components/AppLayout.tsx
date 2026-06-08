import { Outlet, Navigate } from "react-router-dom";
import { Loader2 } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { Header } from "@/components/Header";
import { PlayerBar } from "@/components/PlayerBar";

export function AppLayout() {
  const { session, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!session) return <Navigate to="/auth" replace />;

  return (
    <div className="min-h-screen pb-24">
      <Header />
      <main>
        <Outlet />
      </main>
      <PlayerBar />
    </div>
  );
}
