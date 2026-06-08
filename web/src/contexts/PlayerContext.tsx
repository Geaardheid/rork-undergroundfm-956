import {
  createContext,
  useContext,
  useRef,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from "react";
import { supabase } from "@/lib/supabase";
import type { Track } from "@/lib/types";

interface PlayerContextValue {
  current: Track | null;
  queue: Track[];
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  volume: number;
  isFullscreen: boolean;
  openFullscreen: () => void;
  closeFullscreen: () => void;
  playTrack: (track: Track, queue?: Track[]) => void;
  togglePlay: () => void;
  next: () => void;
  prev: () => void;
  seek: (seconds: number) => void;
  setVolume: (v: number) => void;
}

const PlayerContext = createContext<PlayerContextValue | undefined>(undefined);

export function PlayerProvider({ children }: { children: ReactNode }) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  if (!audioRef.current && typeof Audio !== "undefined") {
    audioRef.current = new Audio();
  }

  const [current, setCurrent] = useState<Track | null>(null);
  const [queue, setQueue] = useState<Track[]>([]);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [currentTime, setCurrentTime] = useState<number>(0);
  const [duration, setDuration] = useState<number>(0);
  const [volume, setVolumeState] = useState<number>(1);
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const countedRef = useRef<string | null>(null);

  const openFullscreen = useCallback(() => setIsFullscreen(true), []);
  const closeFullscreen = useCallback(() => setIsFullscreen(false), []);

  const next = useCallback(() => {
    setQueue((q) => {
      setCurrent((cur) => {
        if (!cur) return cur;
        const idx = q.findIndex((t) => t.id === cur.id);
        return idx >= 0 && idx < q.length - 1 ? q[idx + 1] : cur;
      });
      return q;
    });
  }, []);

  const prev = useCallback(() => {
    setQueue((q) => {
      setCurrent((cur) => {
        if (!cur) return cur;
        const idx = q.findIndex((t) => t.id === cur.id);
        return idx > 0 ? q[idx - 1] : cur;
      });
      return q;
    });
  }, []);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;
    const onTime = () => setCurrentTime(audio.currentTime);
    const onDuration = () => setDuration(audio.duration || 0);
    const onEnded = () => next();
    const onPlay = () => setIsPlaying(true);
    const onPause = () => setIsPlaying(false);
    audio.addEventListener("timeupdate", onTime);
    audio.addEventListener("loadedmetadata", onDuration);
    audio.addEventListener("ended", onEnded);
    audio.addEventListener("play", onPlay);
    audio.addEventListener("pause", onPause);
    return () => {
      audio.removeEventListener("timeupdate", onTime);
      audio.removeEventListener("loadedmetadata", onDuration);
      audio.removeEventListener("ended", onEnded);
      audio.removeEventListener("play", onPlay);
      audio.removeEventListener("pause", onPause);
    };
  }, [next]);

  // Load + play whenever the current track changes.
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio || !current?.audio_url) return;
    audio.src = current.audio_url;
    audio.volume = volume;
    setCurrentTime(0);
    countedRef.current = null;
    audio.play().catch((e) => console.error("[player] play failed", e));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current]);

  // Count a stream once we've passed ~30s of a track.
  useEffect(() => {
    if (current && currentTime > 30 && countedRef.current !== current.id) {
      countedRef.current = current.id;
      supabase.rpc("increment_stream_count", { track_id_input: current.id }).then(({ error }) => {
        if (error) console.error("[player] stream count failed", error.message);
      });
    }
  }, [current, currentTime]);

  const playTrack = useCallback((track: Track, newQueue?: Track[]) => {
    if (newQueue && newQueue.length > 0) setQueue(newQueue);
    else setQueue([track]);
    setCurrent(track);
    setIsFullscreen(true);
  }, []);

  const togglePlay = useCallback(() => {
    const audio = audioRef.current;
    if (!audio) return;
    if (audio.paused) audio.play().catch(() => undefined);
    else audio.pause();
  }, []);

  const seek = useCallback((seconds: number) => {
    const audio = audioRef.current;
    if (!audio) return;
    audio.currentTime = seconds;
    setCurrentTime(seconds);
  }, []);

  const setVolume = useCallback((v: number) => {
    setVolumeState(v);
    if (audioRef.current) audioRef.current.volume = v;
  }, []);

  return (
    <PlayerContext.Provider
      value={{
        current,
        queue,
        isPlaying,
        currentTime,
        duration,
        volume,
        isFullscreen,
        openFullscreen,
        closeFullscreen,
        playTrack,
        togglePlay,
        next,
        prev,
        seek,
        setVolume,
      }}
    >
      {children}
    </PlayerContext.Provider>
  );
}

export function usePlayer(): PlayerContextValue {
  const ctx = useContext(PlayerContext);
  if (!ctx) throw new Error("usePlayer must be used within PlayerProvider");
  return ctx;
}
