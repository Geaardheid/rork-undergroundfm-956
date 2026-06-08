# YouTube Music-stijl player-overlay + vaste sidebar, zoekbalk en bibliotheek (web)

Alles hieronder is alleen voor de **web-app**. De iOS-app blijft ongemoeid. De bestaande audio-logica, de player-balk onderaan en de paywall-check blijven werken.

## Nieuwe app-layout (overal)
- **Vaste linker zijbalk** in heel de ingelogde app, in plaats van de huidige losse bovenbalk:
  - **Home** en **Bibliotheek** als hoofdnavigatie (klikbaar, actieve staat gemarkeerd in geel).
  - Daaronder een lijst met **de playlists van de ingelogde gebruiker** (uit de playlists-tabel). Klikbaar.
  - Onderin het logo + naam, en uitloggen.
- **Bovenbalk** krijgt een **zoekbalk** die tracks én artiesten doorzoekt. Resultaten verschijnen in een dropdown; klik op een track speelt 'm af, klik op een artiest gaat naar de artiestenpagina.
- Op mobiel klapt de sidebar in tot een uitschuifbaar menu (hamburger), zodat het netjes blijft op kleine schermen.

## Player-overlay (zoals YouTube Music)
- Opent als een **full-screen overlay** zodra je op een track klikt om af te spelen. Sluit met een **pijl-omlaag** bovenin (de player-balk onderaan blijft gewoon bestaan en kun je gebruiken om 'm weer te openen).
- Bovenaan een **tab-switch met "Nummer" en "Video"**, net als YouTube Music:
  - **Nummer**: grote cover-art in het midden, daaronder tracktitel + artiestennaam (artiestennaam klikbaar naar de artiestenpagina), en daaronder de afspeel-controls: play/pause, vorige/volgende, seek-bar met tijd, en volume.
  - **Video**: nu nog leeg en uitgeschakeld met de tekst **"Binnenkort"**. De structuur wordt zo opgezet dat hier later makkelijk een videospeler in past zonder de layout te herbouwen.
- Achtergrond in de underground-stijl: diep zwart met een subtiele gele gloed afgeleid van de cover.
- **Niet gebouwd** (zoals gevraagd): songtekst-tab, gerelateerde nummers, zichtbare wachtrij, cast/airplay.

## Nieuwe Bibliotheek-pagina
- Toont in drie blokken de data van de ingelogde gebruiker:
  - **Mijn playlists**
  - **Gevolgde artiesten**
  - **Gelikete tracks**
- Tracks zijn afspeelbaar; artiesten en playlists zijn klikbaar. Lege blokken tonen een nette "nog niks hier"-tekst.

## Branding & gedrag
- Geel #FFE000 / zwart #0A0A0A, bold underground-look, consistent met de rest van de web-app.
- De **paywall-check** (subscription_status) blijft gelden: zonder actief abonnement opent bij afspelen de bestaande paywall in plaats van de track.