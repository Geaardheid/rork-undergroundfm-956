import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";

import { AuthProvider } from "@/contexts/AuthContext";
import { PlayerProvider } from "@/contexts/PlayerContext";
import { PlaybackProvider } from "@/contexts/PlaybackContext";
import { AppLayout } from "@/components/AppLayout";

import Auth from "./pages/Auth";
import Home from "./pages/Home";
import Artist from "./pages/Artist";
import Library from "./pages/Library";
import Playlist from "./pages/Playlist";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <AuthProvider>
          <PlayerProvider>
            <PlaybackProvider>
              <Routes>
                <Route path="/auth" element={<Auth />} />
                <Route element={<AppLayout />}>
                  <Route path="/" element={<Home />} />
                  <Route path="/library" element={<Library />} />
                  <Route path="/playlist/:id" element={<Playlist />} />
                  <Route path="/artist/:id" element={<Artist />} />
                </Route>
                <Route path="*" element={<NotFound />} />
              </Routes>
            </PlaybackProvider>
          </PlayerProvider>
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
