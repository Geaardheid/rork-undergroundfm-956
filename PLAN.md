# Cinematic 5-slide onboarding rework for Underground FM

## Cinematic onboarding rework

A full visual overhaul of the welcome flow, expanding it from 3 to 5 slides with a code-drawn cinematic background — no image files, all built in SwiftUI, styled like undergroundfm.nl. Stays Android-portable and keeps all existing login/register logic untouched.

### The cinematic background (new, behind every slide)
- Deep black base.
- A slow, "breathing" yellow glow from the top that gently pulses and drifts (6–8s loop), positioned slightly differently per slide so each screen feels distinct.
- A fine film-grain texture across the whole screen at low opacity — drawn once and held still (calm, battery-friendly), exactly as you chose.
- A vignette: darker edges that brighten toward the centre.
- A giant, faint "U" spray motif sitting low in the background, rotated, purely decorative.
- All layers are non-interactive so buttons always work.

### Motion
- Text and elements rise into place with a staggered fade + gentle upward move (~20px), triggered when each slide becomes active. Slow and filmic (0.6–0.9s) with increasing delays per element, echoing the website's "rise" animation.

### The 5 slides
1. **The hook** (restyled): big "ALLEEN / UNDERGROUND" headline, subtitle, and the four stat badges.
2. **What it is** (new): big heading + explanation — music and video from independent artists, no mainstream, no algorithm deciding what you hear.
3. **Fairly paid** (new): big heading + explanation — a fair share of revenue goes to creators based on what you actually play. Shows three numbers prominently: €5/month, 50% to artists, 100 founding spots.
4. **Who are you** (restyled): Fan / Artist role choice — selection logic unchanged.
5. **Be there** (restyled): Register button and Login link — logic unchanged.

### Behaviour
- The dots indicator and Next button update to cover all 5 slides.
- The Next button advances through all five slides as before.
- Free swiping between slides stays.
- Readable light text guaranteed via an extra dark gradient behind text blocks where needed.

### Text in all three languages
- New wording added for the two new slides (titles + body) in Dutch, English, and Spanish, consistent with the existing onboarding text. The three key numbers reuse existing copy where possible.

### What stays exactly the same
- All authentication logic, the login/register callbacks, the artist-role selection, and navigation — only the visuals and the two new in-between slides change.