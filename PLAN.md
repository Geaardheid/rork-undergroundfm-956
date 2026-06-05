# Fix 5 profile & feed UI bugs

Five focused fixes in existing screens only — no new screens or features.

**1. Bell icon does nothing (home header)**
- Remove the non-working bell button from the top of the home screen. The search icon stays. Notifications aren't built yet, so hiding it is the cleanest fix.

**2. Artist name not editable (profile)**
- In the artist profile, add an editable "Artist name" field next to the existing bio editor (toggled by the same Edit button).
- Saving updates the artist's display name everywhere it appears, keeping the account name and artist name in sync.
- New label text added in Dutch ("Artiestennaam"), English ("Artist name") and Spanish ("Nombre artístico").

**3. Instagram handle not editable (profile)**
- Add an editable Instagram field in the same profile edit section, using the existing Instagram label.
- Saving updates the artist's Instagram link, which then shows as a tappable handle on the profile.

**4. "Loading failed" on empty genre sections**
- When a genre row simply has no tracks (not an actual error), show the friendly "no tracks yet" empty state instead of an error. Real network/server errors will still show the error state.

**5. Mini player covers the "Become artist" button**
- On the "Become artist" form, add bottom spacing so the submit button always sits above the persistent mini player and stays fully tappable. The mini player is not hidden.

After the changes I'll run the iOS build checks to confirm everything compiles.