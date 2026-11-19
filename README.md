# Sakura Ramen & Sushi Tycoon (titolo provvisorio)

Gioco Roblox tycoon: gestisci un ristorante giapponese di ramen e sushi, cucini al bancone con un clic per ogni passaggio, rifornisci le mensole dal magazzino, assumi personale, ingrandisci il locale fino al tetto e lo arredi su una griglia da 1, 5 o 10 stud. Mondo personale con inviti agli amici, inglese e italiano.

## Aprire il gioco in Roblox Studio
1. Scarica `build/SakuraRamenTycoon.rbxlx` dal repository.
2. In Roblox Studio: **File → Open from File…** e scegli il file.
3. Controlla **Lighting → Technology = Future** (dovrebbe già esserlo) e **Workspace → StreamingEnabled = false**.
4. **Game Settings → Security → Enable Studio Access to API Services** per i salvataggi (pubblica prima il gioco, File → Publish to Roblox).
5. **Game Settings → Places → Max Players: 6**. Lascia disattivati i server privati Roblox.
6. Premi **Play**. In Studio il server è direttamente il tuo mondo (i teletrasporti al mondo personale funzionano solo nel gioco pubblicato).

**Comandi** (prima persona, si cambia in Impostazioni → Telecamera): mouse per guardarti intorno, clic o E sul pallino al centro per usare, tasto destro posa la scatola, G posa, Shift corri, Q per liberare il mouse e cliccare i pulsanti (di nuovo Q per tornare a guardare), B costruisci, O fornitore, P telefono, R regali. Mentre i noodles bollono, clicca nel verde della barra per una ciotola perfetta.

Pannello sviluppatore (pulsante 🛠️, solo in Studio o per il creatore del gioco): yen, livelli, licenze, zone, scorte, clienti, chiusura della giornata.

**🧪 Autotest**: nel pannello sviluppatore, esegue da solo tutto il ciclo di gioco (mensola, riso, kappa maki a clic, cliente servito e pagante, stoviglie lavate, regole di piazzamento) e scrive il risultato di ogni passaggio nella finestra Output (`[SelfTest] PASS/FAIL ...`). È il primo pulsante da premere dopo aver aperto il gioco.

In alternativa puoi usare [Rojo](https://rojo.space) (`rojo serve` con `default.project.json`) per sincronizzare il codice dal vivo.

## Robux, suoni, modelli
- ID di gamepass e prodotti: `src/shared/Config/Monetization.luau` (0 = disattivato, il pulsante non compare).
- Musica e suoni: `src/shared/Config/Audio.luau` (ID della libreria pubblica di Roblox: Pro Sound Effects, APM Music, suoni UI di Roblox; funzionano in qualsiasi gioco).
- Regali a tempo, codici, combo e corsa: `src/shared/Config/Rewards.luau`.
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
python3 tools/check_roblox_api.py   # dopo aver scaricato build/API-Dump.json (istruzioni nel file)
pip install lupa && python3 tools/run_logic_tests.py
python3 tools/sim.py                # il server vero su un Roblox simulato, con scenari di gioco
python3 tools/build_place.py
```

## Simulatore del server (senza Studio)
`tools/sim.py` fa girare tutti i servizi del server su un Roblox simulato (orologio virtuale, istanze,
eventi, DataStore in memoria, giocatori finti) e gioca gli scenari di `tools/sim/scenarios/`:
il server parte, entra un giocatore, l'autotest del gioco fa tutto il ciclo, arrivano clienti, si salva
all'uscita; e i casi difficili dei salvataggi. Ogni errore del gioco fa fallire la prova.
```
python3 tools/sim.py                 # tutti gli scenari
python3 tools/sim.py --verbose core  # uno scenario, con notifiche e stampe del gioco
```

## Anteprima dei modelli (senza Studio)
`tools/preview.py` costruisce i modelli procedurali con un finto ambiente Roblox (lupa) e li disegna
in un PNG con matplotlib (`pip install lupa matplotlib numpy`). Utile per controllare la grafica:
```
python3 tools/preview.py item sushi_station ramen_station out.png --view=24,58,1.6
python3 tools/preview.py category seating out.png
python3 tools/preview.py facade out.png            # facciata del ristorante
python3 tools/preview.py interior out.png --zones=dining,kitchen
python3 tools/preview.py street out.png --focus=-60,20,-40,0
python3 tools/preview.py interior out.png --basic          # locale iniziale, senza ristrutturazioni
python3 tools/preview.py interior out.png --swap=stool_wood:stool_red \
  "--place=ramenya_canopy@-6,15.6,0,c;water_pitcher@-7.5,14.6,0,t,3.5" --clip=-19,19,0.8,30 --view=14,72,2.4
```
Il testo delle insegne e le luci non vengono disegnati: l'aspetto finale va sempre verificato in Studio.
