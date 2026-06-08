import { createContext, useCallback, useContext, useState, type ReactNode } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { usePlayer } from "@/contexts/PlayerContext";
import { PaywallModal } from "@/components/PaywallModal";
import type { Track } from "@/lib/types";

interface PlaybackContextValue {
  /** Attempts to play a track, gating behind the subscription paywall. */
  requestPlay: (track: Track, queue?: Track[]) => void;
}

const PlaybackContext = createContext<PlaybackContextValue | undefined>(undefined);

export function PlaybackProvider({ children }: { children: ReactNode }) {
  const { isActive } = useAuth();
  const { playTrack } = usePlayer();
  const [paywallOpen, setPaywallOpen] = useState<boolean>(false);

  const requestPlay = useCallback(
    (track: Track, queue?: Track[]) => {
      if (!isActive) {
        setPaywallOpen(true);
        return;
      }
      playTrack(track, queue);
    },
    [isActive, playTrack],
  );

  return (
    <PlaybackContext.Provider value={{ requestPlay }}>
      {children}
      <PaywallModal open={paywallOpen} onClose={() => setPaywallOpen(false)} />
    </PlaybackContext.Provider>
  );
}

export function usePlayback(): PlaybackContextValue {
  const ctx = useContext(PlaybackContext);
  if (!ctx) throw new Error("usePlayback must be used within PlaybackProvider");
  return ctx;
}
