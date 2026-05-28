# Supabase koppelen: schema uitvoeren + sleutels invullen + feed live

## Stap voor stap

**1. Database klaarzetten (jij doet dit in Supabase)**
- Ik geef je het volledige SQL-script dat al klaarstaat in het project
- Jij plakt het in de Supabase SQL Editor en klikt "Run"
- Resultaat: alle tabellen (users, artists, tracks, stream_logs, subscriptions, playlists, follows, likes, payouts, invite_codes) + beveiligingsregels staan klaar

**2. Sleutels invullen (ik doe dit zodra je ze plakt)**
- Jij stuurt de Project URL + anon key
- Ik zet ze veilig in de app zodat hij weet waar je Supabase project staat
- Build wordt gecontroleerd dat alles compileert

**3. Een testaccount kunnen aanmaken**
- Korte handleiding hoe je in Supabase → Authentication → "Email" provider aanzet zodat registreren werkt
- Daarna kun je via de app een fan-account maken en inloggen

**4. Companion app op je MacBook**
- Ik geef je een korte checklist: Rork Companion installeren, inloggen, project openen, simulator starten
- Je ziet dan precies dezelfde app op je Mac als ik hier zie

## Wat je ziet na deze stap

- Login en registreren werken écht (account wordt opgeslagen in Supabase)
- Home feed laadt zonder fout, maar toont nog een lege staat per genre — pas vol zodra er tracks zijn (komt in de volgende stap: artiest upload-flow)
- Profielscherm laat jouw echte naam en emailadres zien

## Wat er nog niet werkt (volgende stappen)

- Uploaden van tracks (komt na deze stap)
- Audio afspelen (track-scherm)
- Abonnement / paywall