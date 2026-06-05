# Rework the player to switch between Audio and Video like YouTube Music

## What changes

Right now the Video tab quietly runs a second, muted copy of the video and constantly nudges the audio to stay in sync — which causes the glitches, restarts, and drift you're hearing. I'll replace that with a clean "one track, two sources" model.

## How it will work

- **Audio tab (default):** plays the song's audio with the cover art, exactly like today.
- **Video tab:** plays the actual video file *with its own sound*. The muted-mirror approach is gone — the video is a real alternative way to experience the same track.
- **Only one source ever plays at a time**, so there's never doubled or echoing audio.

## Switching feels seamless

- When you tap between Audio and Video, the player remembers exactly where you are in the track, swaps to the other source, and picks up from the same spot.
- It keeps your play/pause state — if music was playing, it keeps playing; if paused, it stays paused.
- A brief "loading" moment on switch is expected while the new source buffers.

## Everything keeps working on whichever source is active

- The scrubber, play/pause, and skip controls always control whatever is currently playing (audio or video).
- The lock screen / Now Playing controls keep working and reflect the active source.
- The 30-second preview limit for non-subscribers still applies on both audio and video.

## Behavior details (from your answers)

- Each **new track always opens on the Audio tab** by default.
- For tracks **without a video, the Video tab stays hidden** entirely.
- When a track changes or playback is cleared, **both sources are torn down cleanly** so nothing lingers in the background.

## What's being removed

- The old "muted video mirrors the audio" logic and the start/stop sync routines that ran every time the Video tab appeared or disappeared. The video player no longer fights the audio player for timing.
