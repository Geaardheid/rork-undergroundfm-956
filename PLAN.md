# Rework the Library tab into a visual hybrid layout

A UI-only redesign of the Library tab. All data loading stays exactly as it is — only the look and layout change. Top to bottom, the new Library screen will be:

**1. Living hero header**
- A layered "cover collage" of floating album covers pulled from your liked tracks, with the bold title "Bibliotheek" / "Library" overlaid.
- Covers fade in and gently drift, reusing the same alive-but-purposeful animation style from the Search screen.
- If you have fewer than 4 liked tracks, it falls back to a clean yellow-accented gradient header instead.
- A small "+" button stays in the header to create a new playlist.

**2. 2×2 shortcut grid**
Four large tappable cards, each with a bold label and yellow accent:
- **Geliket** (heart) — background shows your most recent liked track's cover; opens your liked songs.
- **Laatst geluisterd** (clock) — shows your most recently played track's cover; opens recently-played tracks.
- **Playlists** (list) — a small cover collage of your playlists; opens your playlists.
- **Artiesten** (two people) — a collage of followed-artist avatars; opens your followed artists.
- Cards with no content show just their icon on a card background. Each card presses down slightly when tapped.

**3. "Gelikte nummers" auto-playlist screen**
Tapping **Geliket** opens a playlist-style screen titled "Gelikte nummers" / "Liked songs" / "Canciones que te gustan" listing all your liked tracks, with an "Alles afspelen" button that plays them all as a queue.

**4. Recent tracks strip**
Below the grid, a horizontal scroll of your recently played tracks as cover cards — tap any to play instantly. Titled "Recent" / "Recientes". Hidden entirely when there's nothing recent.

**Other screens reachable from the grid**
- A liked-songs list, a recently-played list, a playlists list (with the create-new-playlist button), and a followed-artists list. Artists and individual playlists open their existing detail pages as before.

**What stays the same**
- All data comes from the existing Library data layer, untouched.
- Existing navigation to artist pages and playlist detail pages is preserved.
- New localization text "Gelikte nummers" / "Liked songs" / "Canciones que te gustan" is added in Dutch, English, and Spanish.

After the rework I'll run build checks to confirm everything compiles.