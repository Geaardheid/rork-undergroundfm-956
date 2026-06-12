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
  setVideoSlot: (el: HTMLDivElement | null) => void;
  switchMedia: (mode: MediaMode) => void;
}

const PlayerContext = createContext<PlayerContextValue | undefined>(undefined);

const VIDEO_VISIBLE_CLASS = "h-full w-full bg-black object-contain";
const VIDEO_HIDDEN_CLASS = "pointer-events-none absolute h-px w-px opacity-0";

export function PlayerProvider({ children }: { children: ReactNode }) {
  // Persistent audio element — never unmounts.
  const audioRef = useRef<HTMLAudioElement | null>(null);
  if (!audioRef.current && typeof Audio !== "undefined") {
    audioRef.current = new Audio();
  }

  // Persistent video element — created once, never lives in the overlay DOM.
  // It is parked in an offscreen host and only visually relocated into the
  // overlay's slot while the video tab is open.
  const videoRef = useRef<HTMLVideoElement | null>(null);
  if (!videoRef.current && typeof document !== "undefined") {
    const v = document.createElement("video");
    v.playsInline = true;
    v.setAttribute("playsinline", "");
    v.preload = "auto";
    v.className = VIDEO_HIDDEN_CLASS;
    videoRef.current = v;
  }
  const videoHostRef = useRef<HTMLDivElement | null>(null);
  const [videoSlot, setVideoSlotState] = useState<HTMLDivElement | null>(null);

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

  // Single source of truth for the currently-active media element.
  const activeEl = useCallback((): HTMLMediaElement | null => {
    return mediaModeRef.current === "video" ? videoRef.current : audioRef.current;
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

  // Park the persistent video element in its offscreen host on mount.
  useEffect(() => {
    const host = videoHostRef.current;
    const v = videoRef.current;
    if (host && v && v.parentElement !== host) host.appendChild(v);
  }, []);

  // Relocate the (already-playing) video element into the overlay slot when the
  // video tab is open, otherwise park it back in the offscreen host. Moving the
  // node never restarts playback.
  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;
    const showInSlot = isFullscreen && mediaMode === "video" && videoSlot;
    if (showInSlot) {
      if (v.parentElement !== videoSlot) videoSlot.appendChild(v);
      v.className = VIDEO_VISIBLE_CLASS;
    } else {
      const host = videoHostRef.current;
      if (host && v.parentElement !== host) host.appendChild(v);
      v.className = VIDEO_HIDDEN_CLASS;
    }
  }, [isFullscreen, mediaMode, videoSlot]);

  // Listeners on the audio element — only drive shared state while audio is active.
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

  // Listeners on the persistent video element — only drive shared state while
  // video is active. Attached once since the element never remounts.
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    const onTime = () => {
      if (mediaModeRef.current === "video") setCurrentTime(video.currentTime);
    };
    const onMeta = () => {
      if (mediaModeRef.current !== "video") return;
      setDuration(video.duration || 0);
      if (pendingSeekRef.current != null) {
        try {
          video.currentTime = pendingSeekRef.current;
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
    video.addEventListener("timeupdate", onTime);
    video.addEventListener("loadedmetadata", onMeta);
    video.addEventListener("ended", onEnded);
    video.addEventListener("play", onPlay);
    video.addEventListener("pause", onPause);
    return () => {
      video.removeEventListener("timeupdate", onTime);
      video.removeEventListener("loadedmetadata", onMeta);
      video.removeEventListener("ended", onEnded);
      video.removeEventListener("play", onPlay);
      video.removeEventListener("pause", onPause);
    };
  }, [next]);

  // Load + play audio whenever the current track changes; always reset to audio
  // mode and prime/clear the video source. Only one element ever plays.
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio || !current?.audio_url) return;
    mediaModeRef.current = "audio";
    setMediaMode("audio");
    pendingSeekRef.current = null;

    const video = videoRef.current;
    if (video) {
      video.pause();
      if (current.video_url) {
        if (video.src !== current.video_url) video.src = current.video_url;
        if (current.thumbnail_url) video.poster = current.thumbnail_url;
      } else {
        video.removeAttribute("src");
        video.load();
      }
      video.volume = volume;
    }

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
      const fromEl = from === "video" ? videoRef.current : audioRef.current;
      const toEl = mode === "video" ? videoRef.current : audioRef.current;
      const t = fromEl?.currentTime ?? currentTime;
      const wasPlaying = fromEl ? !fromEl.paused : isPlaying;
      // Pause the outgoing element so only one source ever plays.
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
    // Closing only hides the UI. The active source (audio or video) keeps
    // playing at the same position; the persistent elements are untouched.
    setIsFullscreen(false);
  }, []);

  const setVideoSlot = useCallback((el: HTMLDivElement | null) => {
    setVideoSlotState(el);
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
    if (videoRef.current) videoRef.current.volume = v;
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
        setVideoSlot,
        switchMedia,
      }}
    >
      {children}
      {/* Offscreen host that keeps the video element alive across overlay open/close. */}
      <div
        ref={videoHostRef}
        aria-hidden
        className="pointer-events-none fixed left-0 top-0 h-px w-px overflow-hidden opacity-0"
      />
    </PlayerContext.Provider>
  );
}

export function usePlayer(): PlayerContextValue {
  const ctx = useContext(PlayerContext);
  if (!ctx) throw new Error("usePlayer must be used within PlayerProvider");
  return ctx;
}
