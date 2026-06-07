# Genre-voorkeuren voor fans + gefilterde home-feed

## Wat we bouwen

Fans kiezen tijdens registratie welke muziekstijlen ze willen horen. Die keuze wordt veilig opgeslagen en de home-feed toont daarna alleen die genres. Artiesten zien deze stap niet — hun flow blijft exact hetzelfde.

## Database

- Aan de gebruikersgegevens wordt een veld toegevoegd voor de gekozen genres (standaard leeg).
- De beveiligingsregels worden uitgebreid zodat elke gebruiker alleen z'n eigen voorkeuren kan lezen en aanpassen — geen nieuwe conflicterende regels, de bestaande worden netjes uitgebreid.

## Nieuwe stap in de registratie (alleen voor fans)

- **Wanneer**: direct na het invullen van naam, e-mail en wachtwoord, voordat het account wordt aangemaakt.
- **Vraag**: "Wat luister je?" met een korte uitleg eronder.
- **Grid**: de zes stijlen (Rap, Drill, Afro, Trap, R&B, House) als tegels in 2 kolommen, iets compacter zodat alle zes zonder veel scrollen passen. Exact dezelfde visuele taal als het zoekscherm: emoji, kleurtint per genre en cover-art.
- **Selectie**: tik om te kiezen/ontkiezen (meerdere mag). Een gekozen tegel krijgt een gele rand met een vinkje.
- **Achtergrond**: de cinematische achtergrond van de onboarding eronder.
- **Knoppen**: "Doorgaan" wordt pas actief zodra minstens één genre is gekozen; daaronder een subtiele "Overslaan" voor wie niets wil kiezen (dan worden geen voorkeuren opgeslagen).

## Opslaan

- De gekozen stijlen worden bij het aanmaken van het fan-account opgeslagen. Werkt ook netjes als het account pas na e-mailbevestiging wordt afgerond — de keuze blijft bewaard tot de registratie rond is.
- Geen keuze of overslaan = leeg, geen filter.

## Home-feed filteren

- Heeft een fan genres gekozen, dan laadt de home-feed alleen die secties.
- Heeft een fan niets gekozen, dan laadt de feed gewoon alles (nooit een lege feed).
- De uitgelichte banner bovenaan blijft altijd laden, ongeacht de voorkeuren.

## Later aanpassen (Instellingen)

- In Instellingen komt een nieuwe optie "Mijn genres" waarmee een fan z'n voorkeuren op elk moment kan bijwerken, met hetzelfde tegel-grid. Wijzigingen werken meteen door in de home-feed.

## Taal

- Alle nieuwe teksten (titel "Wat luister je?", uitleg, "Doorgaan", "Overslaan", en de Instellingen-optie) komen in Nederlands, Engels en Spaans, in lijn met de bestaande teksten.

## Wat onveranderd blijft

- De artiest-flow, de invite-code-stap, de betaal-logica en de bestaande genre-definities. De werkende registratie blijft intact. Alles blijft geschikt voor zowel iOS als een latere Android-versie.
