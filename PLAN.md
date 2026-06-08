# Fix web header logo and artist page lookup

Two fixes for the **web app** only.

**1. Real logo in the header**
- Copy the actual UndergroundFM spray-U logo from the iOS app into the web app's public assets.
- Replace the generic yellow "U" box in the top header with that real logo image, kept at the same spot and size, right next to the "UNDERGROUNDFM" text.

**2. Artist page "Artist not found"**
- The artist page currently fails to load and shows "Artiest niet gevonden".
- Fix the lookup so it fetches the artist directly by the id from the page address (matching the artist's own id, not their user account), and pull all their fields (name, bio, avatar, banner, Instagram, verified badge) plus all their tracks.
- This makes artist pages open correctly when tapping an artist.