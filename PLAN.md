# Add a UndergroundFM web player (listen-only, shared Supabase backend)

A brand-new, separate web app that lets fans log in and listen to UndergroundFM. It reuses the same accounts, artists, and tracks as the iOS app — nothing about the iOS app changes.

## Look & feel

- Dark underground aesthetic: deep black (#0A0A0A) background with bold electric yellow (#FFE000) accents, matching the iOS app.
- Genre sections labelled with the same emojis (🔥 rap, ⚡ drill, 🌍 afro, 💎 trap, 🎵 R&B, 🏠 house).
- A persistent player bar pinned to the bottom of every screen (Spotify-style) showing cover art, title, artist, and controls.
- Smooth hover states on cards, subtle animations on the player bar, fully responsive for desktop and mobile browsers.

## Screens

- [x] All screens built and validated (build passes, live preview up)

1. **Login / Register** — email + password. Login for existing accounts; Register creates a fan (listener) account. Friendly error messages.
2. **Home feed** — genre sections, each a horizontal row of track cards (cover art, title, artist name). If the logged-in fan has saved favourite genres, only those sections show; otherwise all genres show.
3. **Artist page** (public) — banner image, avatar, name, bio, Instagram link, and a list of that artist's tracks. Reachable by tapping an artist name.
4. **Player bar** (always visible at the bottom) — play/pause, seek bar with elapsed/total time, volume slider, and previous/next within the current list.

## Listening & paywall

- Browsing the whole catalogue is free — anyone logged in can scroll feeds and artist pages.
- Pressing play checks the account's subscription status. If it's not active, a simple paywall screen appears explaining a subscription is needed, with a single button linking to [https://undergroundfm.nl](https://undergroundfm.nl). No payments are handled in the web app.
- If active, the track streams from its existing audio URL and plays in the bottom bar.

## What it will NOT include

No uploading, no video/clips, no invite codes, no payout dashboard, no notifications, no settings, no admin. Strictly a listening MVP.

## Notes

- This is a standalone web app in its own folder; the Swift app and database are untouched.
- It connects to the existing Supabase project using the same public credentials the iOS app already uses.

