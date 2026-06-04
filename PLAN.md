# Build the Library (Bibliotheek) tab with liked tracks, followed artists & playlists — DONE

## Library tab (YT Music style, Underground FM colors)

A new full Library screen replaces the current "Coming soon" placeholder on the Bibliotheek tab. Black background with yellow accents, matching the rest of the app.

**Top of screen**
- Three horizontal filter chips: **Tracks · Artiesten · Playlists**. Selected chip is filled yellow, others are dark outlined.
- A sort dropdown (only shown on the Tracks filter) with: **Onlangs afgespeeld**, **Onlangs geliket**, **A–Z**.

**Tracks section**
- List of the user's liked tracks. Each row: square cover art, title, artist name, play count (formatted like "1.2K").
- Tap a track to play it.
- Swipe left on a row to unlike (removes it instantly).
- "Onlangs afgespeeld" orders by last played using the play history; "Onlangs geliket" by like date; "A–Z" by title.

**Artiesten section**
- List of artists the user follows. Each row: round avatar, artist name, genre tags, and a founding badge when applicable.
- Tap to open that artist's public profile page.

**Playlists section**
- A **"Nieuwe playlist"** button at the top opens a sheet to create a playlist: name, description, and a public/private toggle.
- List of the user's playlists. Each shows a cover, name, track count, and a public/private badge.
  - Cover is a 2x2 collage of the first 4 track covers when the playlist has 4+ tracks.
  - With fewer than 4 tracks, it shows the first track's cover with a yellow gradient overlay and the playlist name in bold white text centered on top.
- Tap a playlist to open a **playlist detail screen** showing all its tracks with a **"Alles afspelen"** (play all) button that starts from the first track.

**Empty states**
- Friendly empty messages per section (e.g. "Nog geen gelikete tracks", "Je volgt nog geen artiesten", "Maak je eerste playlist").

## Fixes included
- Ensure the play-count increment works reliably: correct the database function so it runs, confirm it's called each time a listening session ends, and confirm listeners are allowed to record plays. (The function and call are already wired; I'll fix a small SQL syntax issue in the schema file and verify the flow.)

## Scope
- Home stays unchanged for now (the "Playlists van de scene" section is skipped per your choice).
- No changes to login, the music player engine, upload, play-tracking, or other screens.
- New database tables for playlists are documented as SQL in code comments so you can run them in Supabase.

## Design notes
- Reuses existing square cover art, avatars, genre tags, founding badge, and press-animation styles for visual consistency.
- Smooth chip switching, press feedback on rows, and a clean create-playlist sheet.