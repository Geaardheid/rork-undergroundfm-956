# Redesign the search empty state with floating covers + genre tiles

## Overview
Give the search screen a bold Underground FM look before you start typing, while keeping all existing search behaviour exactly as-is.

## Empty state (before typing)
- **Floating cover wall** — Show 5 of the most-played track covers from the catalogue, scattered across the upper half of the screen. Each cover is medium-sized (120×120), slightly rotated at a random angle (between -8° and +8°), overlapping its neighbours, with a strong yellow glow behind it for that signature Underground FM energy.
- These load quietly in the background; if none are available yet, the area simply stays empty (no error).

- **Genre tiles** — Below the covers, a 2-column grid of large square tiles. Each tile has a dark background, a yellow border, and a big genre emoji above a bold white genre name, centred. The genres match the app's existing home feed set (🔥 Rap, ⚡ Drill, 🌍 Afro, 💎 Trap, 🎵 R&B, 🏠 House).
- Tapping a tile opens that genre's full track list (the same genre list screen already used from Home), with a back button to return to search.
- The whole empty state scrolls so the tiles are always reachable.

## Search results (while typing) — visual polish only
- **Track rows** — Prominent square cover art, bold title, artist name shown in yellow, and a play-count badge. Tapping plays the track (unchanged).
- **Artist rows** — Large round avatar, bold name, genre tags, and a founding-artist star badge when applicable (unchanged behaviour, refined look).

## Out of scope (left untouched)
- Search logic, the music player, sign-in/auth, and every other screen stay exactly as they are.
