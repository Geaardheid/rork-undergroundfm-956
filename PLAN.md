# Autoplay queue, share sheet, and featured banner empty-state fix

Three additions to the music app, all wired through the existing player and feed.

**Feature 1 — Autoplay queue**
- The player now remembers a list of tracks (a "queue") and which one is playing.
- When you tap a track in a genre section (on the home feed or the full genre list), the whole section becomes the queue automatically — so when one song ends, the next one starts playing on its own.
- Tapping a single track elsewhere still works exactly as before (it just plays that one track).
- When a track finishes, it automatically advances to the next track in the queue. If it's the last one, playback stops as it does today.
- The lock-screen / control-center "next" and "previous" buttons now move through the queue instead of just skipping 15 seconds.

**Feature 2 — Share sheet**
- The share button on the full-screen player now shares a friendly message — "Listen to [title] by [artist] on UndergroundFM" — together with a link to the track.
- The link uses the app's own address format so that tapping it on a device opens the app.
- When someone opens a shared track link, the app fetches that track and starts playing it right away.

**Feature 3 — Featured banner empty state**
- On the home feed, when there's no featured track to show (and it's finished loading), the featured banner is hidden completely instead of leaving an empty gap at the top.

**Notes**
- No new screens, no payment or unrelated changes.
- All texts already exist in Dutch, English, and Spanish.
- I'll run the build checks when done.