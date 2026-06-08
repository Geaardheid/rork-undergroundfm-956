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

export type MediaMode = "audio" | "video";

interface PlayerContextValue {
  current: Track | null;
  queue: Track[];
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  volume: number;
  isFullscreen: boolean;
  mediaMode: MediaMode;
  hasVideo: boolean;
  openFullscreen: () => void;
  closeFullscreen: () => void;
  playTrack: (track: Track, queue?: Track[]) => void;
  togglePlay: () => void;
  next: () => void;
  prev: () => void;
  seek: (seconds: number) => void;
  setVolume: (v: number) => void;
  setVideoEl: (el: HTMLVideoElement | null) => void;
  switchMedia: (mode: MediaMode) => void;
}

const PlayerContext = createContext<PlayerContextValue | undefined>(undefined);

export function PlayerProvider({ children }: { children: ReactNode }) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  if (!audioRef.current && typeof Audio !== "undefined") {
    audioRef.current = new Audio();
  }
  const videoElRef = useRef<HTMLVideoElement | null>(null);
  const [videoEl, setVideoElState] = useState<HTMLVideoElement | null>(null);

  const [current, setCurrent] = useState<Track | null>(null);
  const [queue, setQueue] = useState<Track[]>([]);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [currentTime, setCurrentTime] = useState<number>(0);
  const [duration, setDuration] = useState<number>(0);
  const [volume, setVolumeState] = useState<number>(1);
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [mediaMode, setMediaMode] = useState<MediaMode>("audio");
  const mediaModeRef = useRef<MediaMode>("audio");
  mediaModeRef.current = mediaMode;
  const pendingSeekRef = useRef<number | null>(null);
  const countedRef = useRef<string | null>(null);

  const hasVideo = Boolean(current?.video_url);

  const activeEl = useCallback((): HTMLMediaElement | null => {
    return mediaModeRef.current === "video" ? videoElRef.current : audioRef.current;
  }, []);

  const openFullscreen = useCallback(() => setIsFullscreen(true), []);

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

  // Attach listeners to the audio element (active when mediaMode === "audio").
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;
    const onTime = () => {
      if (mediaModeRef.current === "audio") setCurrentTime(audio.currentTime);
    };
    const onDuration = () => {
      if (mediaModeRef.current === "audio") setDuration(audio.duration || 0);
    };
    const onEnded = () => {
      if (mediaModeRef.current === "audio") next();
    };
    const onPlay = () => {
      if (mediaModeRef.current === "audio") setIsPlaying(true);
    };
    const onPause = () => {
      if (mediaModeRef.current === "audio") setIsPlaying(false);
    };
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

  // Attach listeners to the video element whenever it mounts (active when mediaMode === "video").
  useEffect(() => {
    if (!videoEl) return;
    const onTime = () => {
      if (mediaModeRef.current === "video") setCurrentTime(videoEl.currentTime);
    };
    const onMeta = () => {
      if (mediaModeRef.current !== "video") return;
      setDuration(videoEl.duration || 0);
      if (pendingSeekRef.current != null) {
        try {
          videoEl.currentTime = pendingSeekRef.current;
        } catch {
          /* ignore */
        }
        pendingSeekRef.current = null;
      }
    };
    const onEnded = () => {
      if (mediaModeRef.current === "video") next();
    };
    const onPlay = () => {
      if (mediaModeRef.current === "video") setIsPlaying(true);
    };
    const onPause = () => {
      if (mediaModeRef.current === "video") setIsPlaying(false);
    };
    videoEl.addEventListener("timeupdate", onTime);
    videoEl.addEventListener("loadedmetadata", onMeta);
    videoEl.addEventListener("ended", onEnded);
    videoEl.addEventListener("play", onPlay);
    videoEl.addEventListener("pause", onPause);
    return () => {
      videoEl.removeEventListener("timeupdate", onTime);
      videoEl.removeEventListener("loadedmetadata", onMeta);
      videoEl.removeEventListener("ended", onEnded);
      videoEl.removeEventListener("play", onPlay);
      videoEl.removeEventListener("pause", onPause);
    };
  }, [videoEl, next]);

  // Load + play audio whenever the current track changes; always reset to audio mode.
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio || !current?.audio_url) return;
    mediaModeRef.current = "audio";
    setMediaMode("audio");
    pendingSeekRef.current = null;
    if (videoElRef.current) videoElRef.current.pause();
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

  const switchMedia = useCallback(
    (mode: MediaMode) => {
      const from = mediaModeRef.current;
      if (from === mode) return;
      const fromEl = from === "video" ? videoElRef.current : audioRef.current;
      const toEl = mode === "video" ? videoElRef.current : audioRef.current;
      const t = fromEl?.currentTime ?? currentTime;
      const wasPlaying = fromEl ? !fromEl.paused : isPlaying;
      if (fromEl) fromEl.pause();
      mediaModeRef.current = mode;
      setMediaMode(mode);
      if (!toEl) return;
      toEl.volume = volume;
      setCurrentTime(t);
      if (toEl.readyState >= 1) {
        try {
          toEl.currentTime = t;
        } catch {
          /* ignore */
        }
        if (toEl.duration) setDuration(toEl.duration);
        pendingSeekRef.current = null;
      } else {
        pendingSeekRef.current = t;
      }
      if (wasPlaying) toEl.play().catch(() => undefined);
    },
    [currentTime, isPlaying, volume],
  );

  const closeFullscreen = useCallback(() => {
    if (mediaModeRef.current === "video") switchMedia("audio");
    setIsFullscreen(false);
  }, [switchMedia]);

  const setVideoEl = useCallback((el: HTMLVideoElement | null) => {
    videoElRef.current = el;
    setVideoElState(el);
  }, []);

  const playTrack = useCallback((track: Track, newQueue?: Track[]) => {
    if (newQueue && newQueue.length > 0) setQueue(newQueue);
    else setQueue([track]);
    setCurrent(track);
    setIsFullscreen(true);
  }, []);

  const togglePlay = useCallback(() => {
    const el = activeEl();
    if (!el) return;
    if (el.paused) el.play().catch(() => undefined);
    else el.pause();
  }, [activeEl]);

  const seek = useCallback(
    (seconds: number) => {
      const el = activeEl();
      if (!el) return;
      el.currentTime = seconds;
      setCurrentTime(seconds);
    },
    [activeEl],
  );

  const setVolume = useCallback((v: number) => {
    setVolumeState(v);
    if (audioRef.current) audioRef.current.volume = v;
    if (videoElRef.current) videoElRef.current.volume = v;
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
        mediaMode,
        hasVideo,
        openFullscreen,
        closeFullscreen,
        playTrack,
        togglePlay,
        next,
        prev,
        seek,
        setVolume,
        setVideoEl,
        switchMedia,
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
