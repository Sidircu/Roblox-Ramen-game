# Sakura Ramen & Sushi Tycoon (titolo provvisorio)

Gioco Roblox tycoon: gestisci un ristorante giapponese di ramen e sushi, cucini al bancone con un clic per ogni passaggio, rifornisci le mensole dal magazzino, assumi personale, ingrandisci il locale fino al tetto e lo arredi su una griglia da 1, 5 o 10 stud. Mondo personale con inviti agli amici, inglese e italiano.

## Aprire il gioco in Roblox Studio
1. Scarica `build/SakuraRamenTycoon.rbxlx` dal repository.
2. In Roblox Studio: **File → Open from File…** e scegli il file.
3. Controlla **Lighting → Technology = Future** (dovrebbe già esserlo) e **Workspace → StreamingEnabled = false**.
4. **Game Settings → Security → Enable Studio Access to API Services** per i salvataggi (pubblica prima il gioco, File → Publish to Roblox).
5. **Game Settings → Places → Max Players: 6**. Lascia disattivati i server privati Roblox.
6. Premi **Play**. In Studio il server è direttamente il tuo mondo (i teletrasporti al mondo personale funzionano solo nel gioco pubblicato).

Pannello sviluppatore (pulsante 🛠️, solo in Studio o per il creatore del gioco): yen, livelli, licenze, zone, scorte, clienti, chiusura della giornata.

In alternativa puoi usare [Rojo](https://rojo.space) (`rojo serve` con `default.project.json`) per sincronizzare il codice dal vivo.

## Robux, suoni, modelli
- ID di gamepass e prodotti: `src/shared/Config/Monetization.luau` (0 = disattivato, il pulsante non compare).
- Musica e suoni: `src/shared/Config/Audio.luau` (ID dalla libreria audio di Roblox).
- Modelli migliori: metti un Model chiamato come l'ID dell'oggetto (es. `sakura_tree`) in `ReplicatedStorage/AssetOverrides`.

## Documenti
1. [Game Design](docs/01-GAME-DESIGN.md) — cosa c'è nel gioco e come si gioca
2. [Piano tecnico](docs/02-PIANO-TECNICO.md) — architettura e sistemi
3. [Bilanciamento](docs/03-BILANCIAMENTO.md) — prezzi, ricette, sblocchi, formule

## Struttura
- `src/server` — servizi del server (dati, mondo, clienti, cucina, personale, economia…)
- `src/client` — controller e interfaccia
- `src/shared` — configurazione, logica pura, modelli procedurali, lingue
- `src/first` — schermata di caricamento
- `tests/` — test della logica · `tools/` — controlli e compilazione del file di gioco
- `graphify-out/` — grafo della conoscenza del codice ([graphify](https://pypi.org/project/graphifyy/))

## Controlli
```
python3 tools/check_luau.py
python3 tools/check_api.py
pip install lupa && python3 tools/run_logic_tests.py
python3 tools/build_place.py
```
