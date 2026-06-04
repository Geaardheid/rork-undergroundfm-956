# Spotify-style full player, richer feed cards, and live play counts

## Full player redesign (Spotify-style)

- **Pure black background** with a large square cover art, centered, rounded corners and a soft drop shadow.
- **Track title** (bold white) with the **artist name** below in yellow — tapping the artist name closes the player and opens that artist's public profile page.
- **Action row** under the title: a heart "like" button on the left, an explicit 🅴 badge in the middle when the track is explicit, and a share button on the right that opens the native iOS share sheet with the track title and artist.
- **Yellow scrubber bar** with the current time on the left and total time on the right.
- **Controls row**: shuffle, previous, a large yellow circular play/pause button, next, and repeat. (Shuffle and repeat are visual toggles for now; previous/next/play/pause stay wired to existing playback.)
- **Tab switch at the top**: "🎧 Audio" and "🎬 Clip". The Clip tab only appears when the track has a video. Tapping Clip shows a "Clip komt binnenkort" coming-soon message (video playback wired up later).
- **Chevron-down** at the top to dismiss the player.

## Feed card improvements

- Cover art in the trending/genre rows made **slightly smaller** for a tighter, more polished layout.
- When a track is the one currently playing, show an **animated play/pause icon overlay** on its cover art so users can see what's active at a glance.

## Live play counts

- Each time a listening session is saved, the track's play count is **incremented** in the database (reusing the existing count field).
- The actual play count is shown on **feed cards and in the player**, formatted nicely (e.g. "1.2K" for numbers above a thousand).
- A small play-count badge appears on cards and in the player metadata.

## Notes

- Playback engine, login, uploads, and listening-session tracking behavior stay exactly as they are — only the count increment is added on top of the existing save step.
- App icon already exists; no icon work needed.

