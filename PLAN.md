# Duolingo-style daily streak celebration for UndergroundFM

## What this adds

A full-screen, on-brand (yellow #FFE000 / black #0A0A0A / fire) celebration that pops up the moment a fan finishes listening to a track all the way through and their daily streak goes up — just like Duolingo's streak screen.

## Features

- **Daily streak tracking** — when a track plays fully to the end (not on skip), the app tells the server "I listened today." If that bumps the streak to a new day, a celebration plays. It only counts once per finished track.
- **Cinematic celebration overlay** — appears above everything (including the mini player):
  - Background animates from black into a fiery yellow→orange→deep-black glow with subtle film grain.
  - A glowing, pulsing flame burst in the center (drawn in code, no image files), with the UndergroundFM "U" logo popping/zooming in on top and yellow/orange sparkle particles flying out.
  - The streak number shows the previous count first, then ~0.8s later flips with a pop to the new number (large, bold, white), with "dagen op een rij" underneath.
  - A row of 7 day-circles (ma di wo do vr za zo) where the achieved days light up one after another with a checkmark.
  - Haptics: a heavy thump on the burst, a medium tap on the number flip, and a light tick for each day that lights up.
- **Buttons at the bottom**:
  - A white **"DEEL MIJLPAAL"** button that opens the normal share sheet with text like "🔥 7 dagen op rij op UndergroundFM" plus the app link.
  - A bordered, transparent **"DOORGAAN"** button that closes the celebration.

## Design

- Deep-black base bleeding into a warm fire gradient (brand yellow into orange), matching the existing cinematic look used on onboarding/login.
- Brand yellow accents, white bold streak number, rounded day-circles that fill with yellow + black checkmark as they complete.
- Everything uses the existing design tokens (colors, spacing, radius, fonts) so it feels native to the app.
- Staggered, filmic timing so elements arrive in sequence rather than all at once.

## How it behaves

- The celebration is driven by a new streak helper kept at the app root, so it can show over any screen.
- It listens for the "track finished" moment in the existing audio engine and asks the server to register today's listen.
- The server side (the `register_daily_listen` function and streak columns) will be created by you in Supabase — the app only calls it and reads back `current_streak`, `longest_streak`, and whether the streak incremented today. The week-progress row is computed locally for now (all days up to today filled), ready to be swapped for real data later.

## Notes

- The fire burst is built entirely in code (no Lottie, no image assets) so it stays portable to Android later. The "U" that zooms in reuses the existing LogoU logo asset.
- No changes to playback, auth, payments, or existing features — this only adds the streak layer and its celebration screen.
