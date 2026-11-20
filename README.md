# Sakura Ramen & Sushi Tycoon (titolo provvisorio)

Gioco Roblox tycoon: gestisci un ristorante giapponese di ramen e sushi, cucini al bancone con un clic per ogni passaggio, rifornisci le mensole dal magazzino, assumi personale, ingrandisci il locale fino al tetto e lo arredi su una griglia da 1, 5 o 10 stud. Una strada con quattro ristoranti per server: gli amici possono aiutarti nel tuo locale. Inglese e italiano.

## Aprire il gioco in Roblox Studio
1. Scarica `build/SakuraRamenTycoon.rbxlx` dal repository.
2. In Roblox Studio: **File → Open from File…** e scegli il file.
3. Controlla **Lighting → Technology = Future** (dovrebbe già esserlo) e **Workspace → StreamingEnabled = false**.
4. **Game Settings → Security → Enable Studio Access to API Services** per i salvataggi (pubblica prima il gioco, File → Publish to Roblox).
5. **Game Settings → Places → Max Players: 4** (un ristorante per giocatore lungo la strada).
6. Premi **Play**. Per provare la strada con più giocatori: **Test → Clients and Servers** con 2–4 giocatori. In Studio tutti contano come amici, quindi ognuno può aiutare negli altri locali; nel gioco pubblicato possono aiutare gli amici del proprietario (o tutti, se lo sceglie nell'app Amici).

**Comandi** (prima persona, si cambia in Impostazioni → Telecamera): mouse per guardarti intorno, clic o E sul pallino al centro per usare, tasto destro posa la scatola, G posa, Shift corri, Q per liberare il mouse e cliccare i pulsanti (di nuovo Q per tornare a guardare), U negozio, B costruisci, O fornitore, P altro, R regali. Su telefono e tablet si tocca il pulsante che compare sopra l'oggetto. Mentre i noodles bollono, clicca nel verde della barra per una ciotola perfetta. Il cartello **OPEN** accanto alla porta (fuori) apre e chiude il ristorante; la sensibilità del mouse si sceglie in Impostazioni (Alta, Media, Bassa).

Pannello sviluppatore (P → app 🛠️ Dev, solo in Studio o per il creatore del gioco): yen, livelli, licenze, zone, scorte, clienti, chiusura della giornata, premio giornaliero del giorno dopo.

**🧪 Autotest**: nel pannello sviluppatore, esegue da solo tutto il ciclo di gioco (mensola, riso, kappa maki a clic, cliente servito e pagante, stoviglie lavate, regole di piazzamento) e scrive il risultato di ogni passaggio nella finestra Output (`[SelfTest] PASS/FAIL ...`). È il primo pulsante da premere dopo aver aperto il gioco.

In alternativa puoi usare [Rojo](https://rojo.space) (`rojo serve` con `default.project.json`) per sincronizzare il codice dal vivo.

## Robux, suoni, modelli
- ID di gamepass e prodotti: `src/shared/Config/Monetization.luau` (0 = disattivato, il pulsante non compare).
- Musica e suoni: `src/shared/Config/Audio.luau` (ID della libreria pubblica di Roblox: Pro Sound Effects, APM Music, suoni UI di Roblox; funzionano in qualsiasi gioco).
- Regali a tempo, codici, combo e corsa: `src/shared/Config/Rewards.luau`.
- Modelli migliori: metti un Model chiamato come l'ID dell'oggetto (es. `sakura_tree`) in `ReplicatedStorage/AssetOverrides`; la lista con priorità e regole è in [docs/04-ASSET.md](docs/04-ASSET.md).

## Documenti
1. [Game Design](docs/01-GAME-DESIGN.md) — cosa c'è nel gioco e come si gioca
2. [Piano tecnico](docs/02-PIANO-TECNICO.md) — architettura e sistemi
3. [Bilanciamento](docs/03-BILANCIAMENTO.md) — prezzi, ricette, sblocchi, formule
4. [Asset da procurare](docs/04-ASSET.md) — modelli, icone e suoni da sostituire ai segnaposto (generato da `python3 tools/asset_list.py`)

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
all'uscita; il ciclo base con i tempi; la strada con quattro giocatori e gli aiutanti; i casi difficili dei
salvataggi; un giocatore su telefono che gioca con il client vero (postazione, cliente e negozio toccati
come sullo schermo); il tutorial completo; e chi torna a giocare (guadagni offline, calendario del premio
giornaliero, bacheche delle classifiche, pass Personale extra). Ogni errore del gioco fa fallire la prova.
```
python3 tools/sim.py                 # tutti gli scenari
python3 tools/sim.py --verbose core  # uno scenario, con notifiche e stampe del gioco
```

## Anteprima dell'interfaccia (senza Studio)
`tools/ui_preview.py` fa girare server e client nel simulatore, gioca uno script di `tools/sim/ui/`
(entra un giocatore, arriva un ordine, si apre il negozio…) e disegna lo schermo in PNG su telefono,
tablet e computer, con joystick e salto sovrapposti per vedere se qualcosa ci finisce sotto
(`pip install lupa pillow fonttools numpy`):
```
python3 tools/ui_preview.py hud shop screens visit daily           # in build/ui/
python3 tools/ui_preview.py shop --devices=phone,laptop --out=/tmp/ui
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
python3 tools/preview.py plots out.png              # la strada con i 4 lotti (2 locali e 2 lotti liberi)
python3 tools/preview.py interior out.png --basic          # locale iniziale, senza ristrutturazioni
python3 tools/preview.py interior out.png --swap=stool_wood:stool_red \
  "--place=ramenya_canopy@-6,15.6,0,c;water_pitcher@-7.5,14.6,0,t,3.5" --clip=-19,19,0.8,30 --view=14,72,2.4
```
Il testo delle insegne e le luci non vengono disegnati: l'aspetto finale va sempre verificato in Studio.
