# Add 30-second preview limit, paywall gates, and subscription management

## What this does

Free listeners can browse the whole app but only hear the first 30 seconds of any track. Once the preview ends, the paywall appears. Artists always get full access. Subscribers can manage their plan from Settings.

## Features

- **30-second preview for free users** — playback automatically stops at 30 seconds and the paywall slides up. This applies everywhere a track plays (main player, mini player, synced clip player) from one central place.
- **Artists are exempt** — anyone with an artist account always has unlimited playback and never sees the preview cutoff.
- **Preview listens don't count as plays** — a clip that's stopped before 30 seconds by a non-subscriber won't be logged as a real stream.
- **"Preview ended" paywall** — when the paywall appears because the preview ran out, a small yellow "PREVIEW VOORBIJ" label shows above the lightning bolt, so the moment feels intentional rather than abrupt.
- **Mini player lock** — as the preview reaches its end for a free user, the play button on the mini player turns into a yellow lock. Tapping the lock (or the mini player row) opens the paywall.
- **Subscription section in Settings** — a new "Abonnement" / "Subscription" section:
  - Free user: shows "Geen abonnement" with a "Word lid" button that opens the paywall.
  - Subscriber: shows "Actief" with an "Abonnement beheren" button that opens the Stripe customer portal in the browser.
  - Artist: shows "Account: Artiest" with "Volledige toegang" and no buttons.
- **Graceful for logged-out users** — if no one is signed in, the preview cutoff never triggers the paywall; the normal sign-in flow handles it.

## Design

- The "PREVIEW VOORBIJ" label is small, uppercase, yellow, with wide letter spacing, sitting just above the bolt icon — matches the existing Underground FM black/yellow look.
- The mini player lock uses a yellow filled lock icon in the same spot as the play button, so the bar layout stays identical.
- The Settings subscription section reuses the existing settings card styling (rounded card, dividers, yellow accents) so it blends in with the other sections.

## Notes

- The "Abonnement beheren" button calls a server function (Stripe customer portal). I'll build the app-side call and have it gracefully fall back to opening the paywall if the server isn't reachable yet. The actual Stripe/server function can be wired up separately later.
- All subscription logic stays centralized in one service so the future Android version only needs that one piece rebuilt.
- New wording will be added in Dutch, English, and Spanish.

## Screens touched

- Music playback engine (preview cutoff)
- Play-tracking logic (skip logging short previews)
- Paywall screen (preview-ended label)
- Mini player bar (lock state)
- Settings screen (new subscription section)  
  
The Edge Function `create-portal-session` is already deployed at `https://qpawgtxbjatyfngvaayy.supabase.co/functions/v1/create-portal-session` — wire it up directly, no fallback needed."

