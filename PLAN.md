# Rework profile screens + tappable public artist profiles

## What I'll build

A complete redesign of the profile area, plus a brand-new public artist page that fans can open by tapping an artist's name anywhere in the app. Everything uses the existing black + neon-yellow design system.

### Database (you run this in Supabase)
- I'll add SQL for the `view_events` table (so stats work) and confirm the `follows` table, so you can paste it into the SQL Editor in one go.

### Fan profile (your own, as a listener)
- Large avatar circle with your initials or photo, tappable to change photo (picker UI now — actual upload comes later).
- Display name with email underneath.
- Subscription badge: green "Premium actief" or red "Geen abonnement".
- "Gelikte tracks" — a horizontal scroll row of tracks you've liked; tap to play.
- "Instellingen" — language selector plus a notifications on/off toggle that's remembered.
- "Uitloggen" button at the bottom, styled in red as a danger action.

### Artist profile (your own, when you're an artist)
- Same avatar + name, plus a yellow "Founding Artist" badge when that applies.
- Editable bio (tap to edit, max 280 characters, saved to your artist profile).
- Three stat cards for this month: "Actieve supporters" (unique listeners), "Scene punten" (your total score), and "Underground ranking" (your position vs other artists, e.g. "#3 in de scene").
- "Mijn tracks" — your uploaded tracks with title, play count and length. Swipe a track to delete it (removed from the library and storage). Tap a track to edit its title and description.
- "Upload nieuwe track" button linking to the upload screen.

### Public artist page (what fans see)
- Avatar, artist name, bio, and genre tags.
- Founding Artist badge when applicable.
- The same three monthly stat cards (supporters, scene punten, ranking).
- A "Volgen" button that follows the artist (saved so it stays followed).
- A list of all the artist's live tracks — tap any to start playing.

### Tappable artist names
- Artist names on track cards in the home feed become tappable and open that artist's public page.

### Design & feel
- Dark `#0A0A0A` background, `#181818` cards, neon-yellow accents, white text — matching the rest of the app.
- Stat cards use bold numbers with subtle labels; smooth press animations on buttons and the follow toggle; clean empty states ("Nog geen tracks", "Nog geen likes").
- Loading skeletons while stats and tracks load.

### Notes
- I won't touch the login flow, the music player, listening tracking, or the upload logic.
- Ranking is computed by fetching this month's listening data and ranking on-device — accurate enough for now and easy to upgrade later.