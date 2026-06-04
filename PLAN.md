# Add a first-launch onboarding flow for Underground FM

## What this adds

A swipeable, three-slide welcome experience that appears only the very first time the app is installed. Once the user finishes it, it never shows again — they go straight to the normal login screen on future launches.

## Behavior

- **Shows once:** A flag is saved when onboarding is finished. On first install the flow appears; after that the app skips it and goes directly to the login screen.
- The existing login and registration screens, sign-in/sign-up logic, music player, and all other screens stay exactly the same.
- The role you pick on Slide 2 (Fan or Artist) is remembered and pre-selects the matching option when you reach the registration screen.

## Design

- Full black background, bold white and yellow text matching the Underground FM brand.
- Horizontal swipe between the three slides with yellow dot indicators at the bottom.
- Text follows the app's current language (Dutch by default, with English as well). No language picker on these screens — kept clean.

## Slides

**Slide 1 — Alleen Underground**
- Large bold white "ALLEEN" above large bold yellow "UNDERGROUND".
- Subtitle about being the first streaming platform exclusively for independent Dutch artists, fair payout, no mainstream.
- A row of four small stat badges: "€5/maand", "50% naar artiesten", "100 founding spots", "0× mainstream".
- Yellow "Volgende" button in the bottom right that advances to the next slide.

**Slide 2 — Kies je rol**
- Title "Wie ben jij?".
- Two large tappable cards: "🎧 Ik ben een Fan" and "🎤 Ik ben een Artiest", with the selected one highlighted in yellow.
- Small helper text under the artist card ("Artiesten hebben nu nog een invite code nodig.") and under the fan card ("Je kunt later ook artiest worden.").
- Yellow "Volgende" button bottom right.

**Slide 3 — Aan de slag**
- Small yellow badge "PRE-ALPHA · VERSIE 0.1".
- Title "Wees er bij." with subtitle explaining the app is in pre-alpha and they're one of the first users.
- Large yellow "Registreren" button that finishes onboarding and opens the registration screen (pre-set to the role chosen on Slide 2).
- A text button below: "Heb je al een account? Inloggen" that finishes onboarding and goes to the login screen.

## Screens involved

- New onboarding screen (the three slides above).
- The app's launch flow is updated so it decides between showing onboarding or the login screen on startup.
- Registration screen gets a small tweak so it can open with the chosen role already selected.
- Brand copy for all slides added to the app's translation list (Dutch + English).
