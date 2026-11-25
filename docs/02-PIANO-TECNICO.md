# Piano tecnico — architettura e implementazione

> Come verrà costruito il gioco descritto in [`01-GAME-DESIGN.md`](01-GAME-DESIGN.md) con i numeri di [`03-BILANCIAMENTO.md`](03-BILANCIAMENTO.md).

---

## 1. Strumenti e flusso di lavoro

| Strumento | Uso |
|---|---|
| `tools/build_place.py` | Compila `src/` (convenzioni Rojo) in `build/SakuraRamenTycoon.rbxlx`, da aprire in Studio |
| `tools/check_luau.py` | Controllo statico: blocchi e parentesi, variabili non dichiarate, percorsi `require`, parità delle lingue e chiavi mancanti |
| `tools/check_api.py` | Ogni chiamata `Core.S.X.f` / `Core.C.X.f` deve esistere nel modulo chiamato |
| `tools/run_logic_tests.py` | Esegue i moduli puri (`Logic`, `Config`) in un runtime Lua 5.1 (lupa) con i test di `tests/` |
| **Rojo** (facoltativo) | `rojo serve` + plugin per la sincronizzazione dal vivo in Studio (`default.project.json`) |
| **graphify** | Grafo della conoscenza (`graphify-out/`), aggiornato con `graphify update .` |
| **Roblox Studio** | Sul tuo PC: apri il `.rbxlx`, provi, pubblichi |

> Rojo, Lune e l'analizzatore di tipi Luau non sono stati usati: nella sessione cloud lo scaricamento ed esecuzione di binari esterni è bloccato dai controlli automatici. Per questo il codice è scritto senza annotazioni di tipo (`--!nonstrict`) e verificato con i controlli in `tools/`.

### Come lo userai tu
1. Scarichi `build/SakuraRamenTycoon.rbxlx` dal repository.
2. In Studio: **File → Open from File** → **Play** per provarlo (in Studio funziona tutto tranne gli acquisti reali con Robux).
3. **File → Publish to Roblox** per pubblicarlo (i passaggi completi sono nel README, «Pubblicare il gioco»).
4. In **Game Settings**: *Security → Enable Studio Access to API Services* (salvataggi in Studio), *Places → Max Players: 4*, server privati Roblox disattivati.
5. Per i Robux: crei gamepass e prodotti nella dashboard Creator e copi gli ID in `src/shared/Config/Monetization.luau`, poi ricompili.

## 2. Struttura del progetto

```
Roblox-Ramen-game/
├─ default.project.json          # mappa Rojo: cartelle → servizi Roblox
├─ build/                        # .rbxl compilato (incluso per comodità)
├─ docs/                         # questo piano
├─ tests/                        # test della logica pura (tools/run_logic_tests.py)
├─ graphify-out/                 # grafo graphify (aggiornato)
└─ src/
   ├─ first/                     # ReplicatedFirst: schermata di caricamento
   │  └─ Loading.client.luau
   ├─ shared/                    # ReplicatedStorage/Shared
   │  ├─ Config/                 # TUTTI i dati di bilanciamento (vedi §3)
   │  ├─ Locale/                 # en.luau, it.luau, init.luau
   │  ├─ Net/                    # definizione remoti + validazione argomenti
   │  ├─ Logic/                  # logica pura testabile: Formulas, Grid, Footprint,
   │  │                          #   Ambience, Pricing, Review, Leveling, Pathgrid
   │  ├─ Models/                 # generatori procedurali dei modelli
   │  │  ├─ Kit.luau             # primitive: part, wedge, cylinder, ball, weld, label
   │  │  ├─ Palette.luau         # colori e materiali del tema
   │  │  ├─ Registry.luau        # id → builder, con override da AssetOverrides
   │  │  └─ Builders/            # Furniture/, Kitchen/, Decor/, Food/, Building/, Street/
   │  └─ Util/                   # Signal, Trove (pulizia), Promise-lite, TableUtil, RateLimit
   ├─ server/                    # ServerScriptService/Server
   │  ├─ Main.server.luau        # avvio: carica e avvia i servizi in ordine
   │  └─ Services/               # (vedi §4)
   └─ client/                    # StarterPlayer/StarterPlayerScripts/Client
      ├─ Main.client.luau
      ├─ Controllers/            # (vedi §5)
      └─ UI/
         ├─ Kit.luau             # tema (colori, caratteri), costruttore dichiarativo e componenti
         ├─ Base.luau            # finestre modali (open, close, refresh)
         ├─ Icons.luau, Pointer.luau # icone; frecce del tutorial e dei consigli
         └─ Screens/             # HUD, Phone, Shop (miglioramenti, ricette, personale, spazi,
                                 #   ristrutturazioni), Supplier, Build, Menu, Goals, Gifts,
                                 #   Codes, Invite, Premium, Settings, Daily, Offline,
                                 #   DayReport, Guide, Sign, Dev
```

`ReplicatedStorage/AssetOverrides` (cartella vuota creata da Rojo): se ci metti un Model chiamato come un ID (es. `sakura_tree`), il gioco usa quello al posto del modello generato.

**Versione base e versione rifinita.** I builder mettono i dettagli facoltativi in sotto-modelli `Detail_<stile>` (`Kit.detail(model, "counter")`). `Registry.build(id, { styles = Expansions.styles(data.zones) })` elimina i gruppi il cui stile non è ancora stato comprato con una ristrutturazione; senza `styles` (anteprime) tiene tutto. Il guscio dell'edificio legge direttamente gli ID `reno_*` posseduti in `Scene.shell`. Comprare una ristrutturazione ricostruisce guscio e oggetti come le altre espansioni. In Studio i comandi Dev *All renovations* / *Plain look* passano da un aspetto all'altro.

### Convenzioni
- Ogni servizio/controller è un ModuleScript con `Init()` (preparazione, nessuna attesa) e `Start()` (avvio); l'avvio li chiama in ordine e segnala gli errori senza fermare gli altri.
- Nessuna libreria esterna: le poche utilità (Signal, Trove, RateLimit, validazione tipi) sono scritte nel progetto.
- Tutti i testi visibili passano da `Locale.t("chiave", {param})`; nessun testo scritto direttamente nell'interfaccia.
- Tutti i numeri di gioco stanno in `Config/`; il codice non contiene prezzi o tempi "a mano".
- Lo stato della partita lo decide **solo il server**; il client mostra e chiede.

---

## 3. Configurazione (dati)

| Modulo | Contenuto |
|---|---|
| `GameConfig` | costanti generali: durata giornata, orari dei picchi, distanze di interazione, limiti NPC, autosalvataggio |
| `Ingredients` | id, nome (chiave locale), icona, scatola (porzioni, prezzo), conservazione, licenza, colore/forma del modello |
| `Recipes` | id, postazione, ingredienti, passaggi dei minigiochi, prezzo base, XP, tempo per mangiare, licenza, categoria |
| `Licenses` | albero: requisiti (livello, yen, licenze, valutazione), ricette e postazioni sbloccate |
| `Items` | catalogo piazzabili: categoria, prezzo, livello, piazzamento, dimensioni, ambiente, comfort, funzione (seduta, mensola, apparecchio…), set |
| `Surfaces` | stili di pavimento e parete |
| `Upgrades` / `Ads` | livelli, costi, effetti |
| `Staff` | ruoli, costi, stipendi, velocità, addestramento |
| `Expansions` | zone: rettangoli, piano, tipo d'area (sala/cucina/magazzino/esterno/tatami), aperture (porte), requisiti |
| `Customers` | tipi, pesi, pazienza, mance, preferenze, gruppi |
| `Leveling` | curva XP e ricompense |
| `Quests` / `Achievements` / `DailyRewards` / `Events` / `Franchise` | meta |
| `Monetization` | ID gamepass/prodotti (0 = disattivato) ed effetti |
| `Audio` | ID dei suoni e della musica (0 = silenzio, con suoni di base di Roblox dove possibile) |
| `NpcLooks` | colori di pelle, capelli, abiti; ID opzionali di accessori del catalogo |
| `Signs` | insegna del ristorante: 12 colori (tavola e lettere), 5 stili, lunghezza del nome (2–24), insegna iniziale, scritta classica, posizione e misure sulla facciata, secondi tra due modifiche |

Un test controlla l'integrità: ogni ingrediente usato esiste, ogni licenza punta a ricette esistenti, ogni oggetto ha un builder e le chiavi di traduzione in entrambe le lingue.

---

## 4. Servizi del server

| Servizio | Responsabilità |
|---|---|
| `PlotsService` | la strada di `Config/Plots.Count` lotti: assegna il primo lotto libero a chi entra, lo libera quando esce, ruoli (proprietario, co-gestore, aiutante, visitatore), locale in cui lavora ogni giocatore, rinomina gli id salvati che si sovrappongono (§6); ogni mezzo secondo conta chi lavora nel locale di un altro e tiene aggiornato il **bonus squadra** (`plot.coopBonus` e attributo `CoopBonus` del lotto, `GameConfig.Coop`: +10% per aiutante, massimo +30%), che `EconomyService.multiplier` applica a vendite e mance del proprietario |
| `DataService` | caricamento/salvataggio con blocco di sessione, autosalvataggio, migrazioni, replica dei dati al client (§7) |
| `WorldService` | costruisce la strada (una volta, con un lotto per ogni plot) e l'edificio di ogni ristorante dalle zone sbloccate dal suo proprietario; il lotto vuoto ha recinto e cartello; ricostruisce dopo un'espansione (§8); `World.paintSign` rifà solo l'insegna sopra la porta (e il nome sull'insegna gigante del tetto) |
| `PlacementService` | piazzamento, spostamento, vendita, inventario, verniciatura; validazione (§11) |
| `InteractionService` | riceve i clic, controlla distanza e stato, smista all'azione giusta; gestisce cosa ha in mano ogni giocatore |
| `SupplyService` | ordini al fornitore, furgone, scatole nel magazzino, mensole e slot. Ripiani a scacchiera (`Logic/ShelfGrid`: colonne × file per ingrediente, caselle libere segnate), aggiornati un ripiano e una casella alla volta; `Fx("stock")` fa volare i prodotti dalla scatola alle caselle (il ripiano si ridisegna quando atterra l'ultimo), `Fx("take")` dalla casella alla mano. Le scatole in mano sono aperte con alcuni prodotti visibili. Il furgone lascia le scatole a terra nella `Expansions.DropZone` (posti a griglia, due livelli; le scatole a terra nello stesso punto si impilano) e la capienza è scaffali del magazzino + posti a terra |
| `ApplianceService` | rice cooker, pentoloni, lavello, lavastoviglie: lotti, timer, porzioni. Lavello: pila di piatti sporchi disegnata nella vasca, sessioni "tieni premuto" (remote `Wash(uid, on)`, un piatto ogni `Washing.Time` finché il giocatore tiene premuto, è vicino e ha le mani libere), attributi `Washing`/`WashStart`/`WashTime`/`Washer` per l'animazione sul client (`SinkController`) |
| `CookingService` | biglietti d'ordine, sessioni di preparazione, risultati dei minigiochi, piatti pronti. Il tagliere mostra le sagome (materiale ForceField) degli ingredienti mancanti della ricetta obiettivo (ordine più vecchio compatibile con quanto posato) e pubblica l'attributo `Need`; gli ingredienti posati volano al loro posto |
| `CustomerService` | arrivo, scelta del posto, ordini, pazienza, pasto, pagamento, recensione; intelligenza dei clienti. Si ordinano solo i piatti che si possono cucinare (`availableMenu`): ogni ingrediente sugli scaffali, oppure in una scatola che ha posto su uno scaffale (`Supply.canShelve`); se le mensole sono piene di altri prodotti quei piatti spariscono dal menu finché non si libera un ripiano o si compra una mensola, invece di far andare via i clienti con una stella |
| `SeatingService` | posti attivi (sgabello davanti al bancone, sedia vicino al tavolo), prenotazioni, punto dove appoggiare il piatto |
| `StaffService` | assunzione, stipendi, addestramento, intelligenza del personale tramite bacheca dei compiti (§10) |
| `TaskBoard` | elenco dei lavori da fare (prendere ordine, servire, raccogliere, lavare, rifornire, cucinare) usato dal personale e dai suggerimenti al giocatore |
| `DayCycleService` | fasi della giornata, orologio, picchi, resoconto, giornata automatica |
| `EconomyService` | yen, gettoni, moltiplicatori (VIP, franchise, eventi), registro delle transazioni del giorno; barattolo delle mance (`tipJar` nei dati, parte `Coins` che cresce, ritiro con clic o a fine giornata) |
| `ProgressionService` | XP, livelli, licenze, upgrade, espansioni, maestrie, valutazione |
| `MetaService` | missioni giornaliere, obiettivi, premio giornaliero (`ClaimDaily`, serie di 7 giorni), guadagni offline (per tutti la prima ora al 5%, la cassaforte allunga; la media oraria viene dalla durata vera di una giornata in `GameConfig.Day`), set di decorazioni |
| `RewardsService` | Mi piace dei visitatori (remote `Like`, una volta al giorno per ristorante, `stats.likes`, attributo `Likes` del workspace, classifica `LB_Likes_v1`), regali a tempo della sessione (`JoinedAt`, `GiftsClaimed` come attributi del giocatore, `ClaimGift`), codici (`RedeemCode`, usati in `meta.codes`), leaderstats ¥ e ⭐ |
| `FranchiseService` | rinascita e città (l'insegna resta) |
| `SignsService` | insegna del ristorante (remote `SetSign({ name, style, board, text })`): solo proprietario e co-gestori, stile e colori dalla lista di `Config/Signs`, nome ripulito (una riga, spazi singoli) di 2–24 lettere o vuoto, una modifica ogni `MinSecondsBetweenChanges` secondi per giocatore (conta anche un tentativo che il filtro non ha potuto controllare). Il nome passa dal filtro di Roblox per i testi visti da tutti (`TextService:FilterStringAsync(…, PublicChat)` → `GetNonChatStringForBroadcastAsync`) e si salva come `sign.name` (scritto dal giocatore: resta sul server, `Data` lo toglie da tutto quello che manda ai client) e `sign.shown` (filtrato, l'unico che si mostra e che l'editor riceve); se il filtro non risponde il nome nuovo non si salva (solo in Studio, `RunService:IsStudio()`, si mostra com'è scritto, per poter provare l'insegna in un luogo non pubblicato). A ogni apertura del ristorante (`Plots.Claimed`) il nome si filtra di nuovo, perché il filtro cambia nel tempo |
| `MonetizationService` | gamepass, `ProcessReceipt` con registro anti-doppio-acquisto |
| `LeaderboardService` | classifiche globali (OrderedDataStore `LB_Dishes_v1`, `LB_Earned_v1`, `LB_Likes_v1`): legge i primi `Rows` al massimo ogni `CacheSeconds` (funzione `GetLeaderboard`) e scrive i numeri dei giocatori ogni `SubmitEvery` secondi e all'uscita (`GameConfig.Leaderboard`); le bacheche della strada le scrive ogni client (§8) |
| `DevService` | solo in Studio o per il proprietario del gioco: pannello sviluppatore (yen, livello, salta tempo, genera clienti, il premio giornaliero del giorno dopo per provare il calendario) |

---

## 5. Controller del client

| Controller | Responsabilità |
|---|---|
| `DataController` | copia locale dei dati del giocatore + eventi di cambiamento |
| `InteractionController` | raggio dal cursore/tocco (dal centro dello schermo in prima persona), evidenziazione (`Highlight`) ed etichetta sull'oggetto se il giocatore è abbastanza vicino, clic/tocco/E → richiesta al server. Il `ProximityPrompt` locale ha `Style = Custom` (prende ancora E e ButtonX): al suo posto un `BillboardGui` «UseButton» in legno scuro sopra l'oggetto, 230×72 da toccare su telefono, 220×50 con il tasto (E, o X con il gamepad) su computer; premerlo equivale a premere E (tenerlo premuto tiene premuto, per il lavello) |
| `ShelfTagsController` | cartellini locali sul bordo di ogni ripiano (icona e nome del prodotto nella lingua del giocatore), aggiornati quando cambia l'attributo `G` dello slot |
| `TimingController` | barra del tempismo dei noodles (`Fx("timing")` durante il passaggio "boil" di chi cucina; il clic invia `TimingHit(uid, k)`, il server accetta k nella parte verde se vicino al suo tempo e segna la ciotola come perfetta) |
| `FirstPersonController` | mirino e testo dell'azione al centro, oggetti in mano copiati davanti alla telecamera (attributo `Held` sui modelli in mano; una pila alta di piatti o scatole scende in modo che il pezzo più alto resti sotto il mirino), mouse libero con un `GuiButton.Modal` visibile (menu aperto, costruzione, Alt), scorciatoie B/U/P/R da `UserInputService` e **O** sia con `ContextActionService:BindActionAtPriority` (sopra `High`) sia con `UserInputService` anche se il tasto è già «processato» (la telecamera di Roblox usa I e O per lo zoom e può prendersi la pressione): apre o chiude il fornitore alla pressione, o al rilascio se la pressione non è arrivata; lo stesso `InputObject` visto da due strade e la ripetizione di un tasto tenuto premuto contano una volta sola; niente se stai scrivendo nella chat o in costruzione, corsa (Shift o 🏃, attributo `WalkSpeed`), pulsante ✋ su touch |
| `CarryVisualController` | posa delle braccia quando si porta qualcosa, pila di oggetti in mano |
| `BuildController` | modalità costruzione: anteprima, griglia 1/5/10, rotazione, colori valido/non valido, vista dall'alto; gli oggetti da parete prendono il punto da `Logic/Placement.wallSpot` (il muro della pianta sotto il puntatore, appoggiati alla parete a metà spessore del muro + metà profondità dell'oggetto; puntando la cima del muro dalla vista dall'alto, sul lato in cui sei e a `GameConfig.WallItemY`) |
| `GridVisualizer` | linee della griglia disegnate solo attorno al cursore (poche parti, solo in costruzione) |
| `CameraController` | modalità `first` (prima persona, `LockFirstPerson`), `game` (orbita morbida) e `roblox`; vista dall'alto in costruzione; nasconde il tetto solo in orbita quando sei dentro; la Sensibilità (`GameConfig.Sensitivity`: Alta 2,4, Media 1,6, Bassa 1) in prima persona e con la telecamera di Roblox moltiplica ogni fotogramma la rotazione appena fatta dalla telecamera di Roblox (`Camera.scaleTurn` legato a `RenderPriority.Camera + 2`; vale per mouse, gamepad e touch, i salti oltre 45° come un teletrasporto restano come sono, `MouseDeltaSensitivity` resta 1 perché in prima persona non arriva alla telecamera), e scala l'orbita rispetto a Media |
| `LightingController` | transizione di luce durante la giornata (ora d'oro lunga 15:30–20:30, alba rosata 5–7:30), accensione lanterne e neon (non dentro i locali nascosti da `Neighbours`) |
| `NeighboursController` | Impostazioni → Altri locali «Solo fuori» (`settings.others = "hide"`): ogni secondo, i ristoranti a 150 stud o più lungo la strada hanno gli oggetti di `Items` e `Dynamic` con `LocalTransparencyModifier` 1, le lampade (non notturne) e le scritte sulle superfici spente, e le persone dentro nascoste; resta l'edificio. Tutto solo sul tuo schermo, e torna com'era con «Mostra tutto» o avvicinandosi |
| `AmbientController` | treno, petali, animazioni decorative (maneki-neko, koi, shishi-odoshi) solo lato client |
| `AudioController` | effetti con prese casuali e intonazione variata (2D o posizionali), sequenze dei passaggi di cucina (`Fx("step")`: colpi di coltello a ritmo, versare, scolare, sfrigolare), anelli d'ambiente mescolati da posizione e clienti, pentole che bollono, treno, playlist giorno/sera |
| `UIController` | apre/chiude schermate, scala e profilo per telefono/tablet/PC (§12), nasconde i comandi touch quando serve, notifiche (`UI.toast`) e pop-up con icona e suono (`UI.popup`, consegne), dispositivo in uso (`UI.inputMode`: `pc`, `touch`, `pad`, dall'ultimo input) |
| `TutorialController` | tutorial di due minuti (§12): scheda in alto, passi con controlli e azioni, regali chiesti al server (`TutorialReward`), frecce di `UI/Pointer` (raggio e ⬇ nel mondo, mano e anello sui pulsanti); testi per dispositivo (`tut.<passo>_pc` / `_touch` / `_pad`, cambiano con `LastInputTypeChanged`); la prima scheda aspetta che la schermata `Loading` sparisca e il lotto sia `Ready` (al massimo `StartWait` s, intanto `Tutorial.active()` è vero e i consigli aspettano); ogni scheda resta almeno `MinStepSeconds` |
| `HintsController` | consigli della prima volta dopo il tutorial (scaffali, piatti, negozio, personale, cartello OPEN dopo 3 piatti), uno alla volta, ricordati dal server (`HintSeen`, `meta.hints`) |

---

## 6. La strada dei ristoranti e gli aiutanti

Ogni server è una strada con `Config/Plots.Count` (4) lotti lungo l'asse X, a `Plots.Spacing` (240) stud l'uno dall'altro (`OriginsX` = −360, −120, 120, 360). Niente teletrasporti né server riservati: tutti giocano nello stesso place pubblico (Max Players = 4).

**Coordinate**: ogni ristorante è costruito e calcolato in **coordinate locali** (le stesse di prima, con l'ingresso a z = 0), poi spostato sul suo lotto (`Plots.shift` aggiunge l'origine alle parti). Geometria, zone, piazzamento e posti lavorano in coordinate locali; `Plots.toWorld`/`toLocal` convertono. Gli oggetti dei salvataggi restano in coordinate locali, quindi un ristorante si può costruire su qualsiasi lotto.

**Stato per ristorante**: ogni plot (`{ id, origin, cf, owner, ownerId, folder }`) porta anche lo stato che gli altri servizi gli appendono (biglietti, registro del giorno, geometria, posti, scorte, pila del lavello, coda, combo, ambiente, resoconto…). Le entità hanno `e.plot` e l'attributo `PlotId`; `Entities.ofKind(kind, plot)` e `Entities.ofPlot(plot)` filtrano per ristorante. Nel workspace: `workspace.Plots.PlotN` con le cartelle `Shell`, `Items`, `Dynamic` e gli attributi `PlotId`, `OriginX`, `OwnerId`, `OwnerName`, `City`, `Ready`.

**Ingresso e uscita**:
1. `Data.Loaded` → `claim`: primo lotto libero (se non ce n'è: `msg.no_plot`), `dedupe` rinomina gli id salvati (oggetti, scatole, personale) già usati da un altro ristorante, `Plots.Claimed` fa costruire il locale a `World`, ai clienti, al personale; il personaggio va alla porta (`Plots.sendHome`, anche a ogni respawn e con il remote `GoHome`).
2. `PlayerRemoving` → `Plots.Released`: clienti e personale spariscono, il lotto torna vuoto, gli aiutanti che lavoravano lì tornano al proprio locale.
3. `Plots.rebuild(plot)` (franchise, strumenti di sviluppo) = rilascio + nuova costruzione dallo stesso profilo.

**Ruoli** (`Plots.role(player, plot)`): `owner`; `comanager` o `helper` se il proprietario lo ha deciso (`perms` nei suoi dati, remote `SetPermission(userId, "helper"|"comanager"|"none")`); `helper` anche per gli amici Roblox del proprietario o per tutti se `settings.coop == "everyone"`; altrimenti `visitor`. `canWork` = owner/comanager/helper, `canBuild` = owner/comanager. In Studio tutti contano come amici (per provare con più giocatori in locale).

**Locale di lavoro**: ogni 0,5 s il server sceglie per ogni giocatore il locale in cui lavora: quello in cui si trova (`Plots.at(pos)`, metà larghezza del lotto) se ci può lavorare, altrimenti il suo. Al cambio parte `Plots.WorkChanged`: il client riceve `Session` (lotto, casa, origine, ruolo, elenco dei lotti) e `WorldSnapshot` (le chiavi dei dati del proprietario che servono a disegnare il locale: mensole, oggetti, zone, menu…). Finché ci lavora, i cambiamenti di quelle chiavi arrivano anche a lui. L'interazione rifiuta le azioni di chi non può lavorare in quel locale (`msg.not_your_restaurant`).

**Guadagni degli aiutanti**: chi serve in un locale non suo riceve XP e una quota in yen nel proprio salvataggio, pagata dal gioco; il proprietario incassa il conto per intero.

## 7. Salvataggi

### Schema (versione 1)
```lua
{
  v = 1,
  yen = 500, sakura = 0, xp = 0, level = 1,
  reviews = { recent = {…ultime 50}, total = 0, sum = 0 },
  stats = { dishes = 0, customers = 0, earned = 0, days = 0, perfects = 0, … },
  licenses = { lic_base = true },
  menu = { [recipeId] = { on = true, price = 1.0 } },
  mastery = { [recipeId] = servedCount },
  upgrades = { [upgradeId] = level },
  zones = { zone_base = true },
  surfaces = { [zoneId] = { floor = "floor_wood_light", wall = "wall_plaster" } },
  placed = { { u = "a1", i = "stool_wood", x = 0, y = 0, z = 0, r = 0, s = "f", p = nil }, … },
  inventory = { [itemId] = count },
  storage = { boxes = { { g = "salmon", n = 12, r = "rack1", k = 1 }, … } },
  shelves = { [shelfUid] = { [slot] = { g = "salmon", n = 8 } } },
  appliances = { [uid] = { g = "broth_shoyu", n = 6 } },   -- lotti pronti
  dishes = { clean = 12, total = 12 },
  staff = { { u = "s1", role = "staff_waiter", lvl = 1, name = "Kenji" }, … },
  meta = { quests = {…}, achievements = {…}, daily = { streak = 0, last = 0 }, lastSeen = 0, sets = {…} },
  franchise = { stars = 0, city = "tokyo" },
  perms = { [userId] = "helper" | "comanager" },
  sign = { name = "", shown = "", style = "wood", board = "hinoki", text = "ink" },  -- shown = nome filtrato (name non va ai client)
  settings = { lang = "auto", grid = 1, rot = 90, music = 0.5, sfx = 0.8, lowGfx = false },
  receipts = { …ultimi 50 PurchaseId },
}
```

### Regole
- DataStore `Profiles_v1`, chiave `u_<userId>`; scrittura sempre con `UpdateAsync`.
- **Blocco di sessione**: il salvataggio contiene `{ jobId, time }`. Chi entra aspetta che l'altro server lo liberi (finisce lì l'ultimo salvataggio); dopo `LockWaitSeconds` (40 s) lo prende comunque, perché un giocatore non può stare in due server. Un salvataggio non scrive mai sopra un profilo il cui blocco è passato a un altro server.
- **Mai un profilo vuoto al posto di quello vero**: se il profilo non si riesce a leggere (servizio dati di Roblox fuori uso), il giocatore viene espulso con un messaggio («rientra tra un minuto») invece di giocare su un profilo nuovo che potrebbe poi sovrascrivere quello vero.
- Autosalvataggio ogni 120 s, all'uscita e in `game:BindToClose`; tentativi con attesa crescente. **Un salvataggio alla volta per giocatore**: quello chiesto mentre un altro è in corso aspetta e poi salva di nuovo, così l'ultimo salvataggio all'uscita (con lo sblocco) non viene mai saltato. `BindToClose` aspetta anche i salvataggi iniziati da chi è appena uscito; se un giocatore rientra nello stesso server mentre il suo salvataggio d'uscita è in corso, il caricamento aspetta che finisca.
- `migrate(data)` porta i salvataggi vecchi alla versione corrente; i campi mancanti si riempiono dai valori predefiniti. Versione 2: locale ingrandito; versione 3: bancone da 12 sgabelli, mensole grandi e prima persona; versione 4: cucina componibile e mensole a scacchiera; versione 5: il sushi di base passa alla licenza `lic_sushi0` (chi aveva già giocato la riceve); versione 6: mensole vicino alla porta del magazzino, barattolo delle mance, licenza `lic_sashimi`, pentolone e cuociriso pieni nella cucina ricostruita; versione 7: bancone basso e profondo in moduli da 3 stud con un posto ciascuno; versione 8: cucina profonda 14 stud con tutto sul muro di fondo (gli oggetti comprati tornano nell'inventario, le scorte delle mensole tornano nelle scatole); versione 9: il funnel di onboarding conta solo i giocatori nuovi (`meta.onboarding`); versione 10: ristorante aperto da subito e telecamera automatica; versione 11: nuovo tutorial di due minuti (chi era a metà ricomincia); versione 12: la Sensibilità diventa Alta/Media/Bassa più veloce (`settings.camSpeed`: le vecchie scelte lenta/media/veloce passano a bassa/media/alta).
- Lo stato "in corso" (clienti seduti, piatti in mano) **non** si salva: alla riapertura il locale riparte pulito in fase di preparazione; le scorte (scatole, mensole, lotti pronti) invece si salvano.

### Replica al client
Il server manda una copia iniziale e poi solo i cambiamenti (`DataChanged(percorso, valore)`); il `DataController` aggiorna l'interfaccia.

---

## 8. Costruzione del mondo

- **Strada**: generata una volta, con le misure in `Expansions.Street` (marciapiede, viale a 4 corsie, palazzi di fronte, cavalcavia, corsia del furgone): asfalto con linee, marciapiedi, edifici di sfondo (facciate con finestre illuminate, insegne verticali con kanji, tende), pali e fili della luce, distributori, biciclette, ciliegi, cavalcavia con treno (animato dal client).
- **Edificio a zone**: ogni zona è un rettangolo su una griglia di celle da 2 stud, con piano e tipo d'area. Algoritmo:
  1. Unione delle celle di tutte le zone sbloccate (per piano).
  2. Per ogni bordo tra una cella interna e una esterna (o tra due "stanze" diverse, es. magazzino) → segmento di muro; i segmenti allineati vengono uniti in parti lunghe.
  3. Le **aperture** definite nella configurazione (ingresso, porta del magazzino, porta della terrazza, scala) diventano porte con cornice in legno.
  4. Pavimento per zona (materiale dello stile scelto), soffitto con travi a vista, tettoia giapponese con tegole sulla facciata, tetto piano con parapetto (diventa la terrazza sul tetto).
  5. Le zone esterne hanno pedana in legno o ghiaia e una staccionata di bambù invece dei muri.
- Le parti dei muri hanno l'attributo `WallId` (per gli oggetti da parete) e i soffitti il tag `Ceiling`.
- **Cartelli "in vendita"** (`Scene.forSale`): per ogni stanza del piano terra non ancora comprata con le stanze precedenti già tue, un cartello al centro della sua area (tag `Interactable` e `ForSale`, attributi `Kind = "forsale"`, `Expansion`, `Price`, `Level`, `PlotId`). Il testo lo scrive ogni client nella sua lingua (`WorldUIController`); usarlo manda `BuyExpansion`. Si ricostruiscono con il locale.
- **Cartello OPEN / CLOSED** (`Building.ledSign`, `Expansions.OpenSign`): un'insegna LED su un palo sul marciapiede, subito a destra della porta, con la scritta su entrambi i lati (tag `Interactable`, `Kind = "opensign"`, `Uid` `fixed_opensign_<lotto>`). Usarlo manda `ToggleOpen`; il server (`Plots`) accetta solo proprietario e co-gestori vicini al cartello, cambia `plot.closed` (falso a ogni nuovo proprietario, non si salva), e `World.paintOpenSign` scrive OPEN verde o CLOSED rosso, colora la luce e mette l'attributo `Open` del lotto. Da chiuso `Customers` non fa entrare nessuno (chi è dentro viene servito); l'HUD scrive «🔴 Chiuso» accanto all'orologio.
- **Insegna del ristorante** (`Building.shopSign`, `Config/Signs`): sopra la porta, in cinque stili (legno, lacca con cornice d'oro, noren a tre teli, neon con tubo e `SurfaceLight`, tavola tra due lanterne con `PointLight`), con i colori scelti e una `SurfaceGui` "Letters" (nome nel carattere dello stile, riga らーめん ・ 寿司 sotto) sulla sua `PrimaryPart`. È un `Model` "ShopSign" con tag `Interactable`, `Kind = "shopsign"`, `Uid` `fixed_shopsign_<lotto>`: usarlo apre `Screens/Sign` (solo a chi può costruire nel proprio locale). `World.paintSign` la ricostruisce da sola quando cambia; l'insegna gigante del tetto (`GiantName`) usa lo stesso nome e il colore delle lettere.
- **Consegne** (`Supply.deliver`): il furgone si ferma a `Expansions.TruckStop` (un po' prima del piazzale) e le scatole vanno nella `DropZone`, appena fuori dalla porta di carico del magazzino, a sinistra del passaggio. A chi lavora nel ristorante arrivano due `Fx("delivery")` (`stage = "arriving"` quando il furgone parcheggia, `"arrived"` quando le scatole sono a terra) che diventano pop-up con suono (`UI.popup`).
- **Bacheche delle classifiche** (`Street.rankingBoard`, tag `RankingBoard`): una sul marciapiede di fronte alla porta di ogni lotto, rivolta verso i ristoranti, con tre pannelli `Panel_dishes`, `Panel_earned`, `Panel_likes`. Lampioni, alberi e biciclette di quel marciapiede le lasciano libere. Il `WorldUIController` chiede `GetLeaderboard` ogni `CacheSeconds`, crea su ogni pannello una `SurfaceGui` "Ranking" (titolo, 10 righe con 🥇🥈🥉, la tua riga in oro, il tuo numero in fondo) e la ridisegna ogni 5 s (per le bacheche che arrivano dopo) e quando cambia la lingua.
- Le zone di cucina hanno un `PathfindingModifier` con etichetta `StaffOnly` (i clienti non ci passano).
- Dopo un'espansione: animazione di cantiere, ricostruzione, gli oggetti che non sono più validi vanno nell'inventario (mai persi).

---

## 9. Modelli procedurali e grafica

- `Kit` offre primitive con valori predefiniti curati (bordi `SmoothPlastic`, `CastShadow` solo dove serve, `Anchored`, `CanCollide` coerente) e saldature. `Kit.cyl`, `Kit.cylH` e `Kit.ball` lavorano su una **copia** delle opzioni (`withShape`): i builder usano spesso una tabella comune (`NC`) per molte parti e la forma non deve passare alle parti fatte dopo (prima le ringhiere delle scale e i teli del noren diventavano palline; lo scenario `floors` controlla che le palle siano rotonde e i cilindri circolari).
- `Palette`: legno chiaro `#C89F6E`, legno scuro `#5B3A24`, lacca rossa `#B3262E`, carta washi `#F4EBDD`, inchiostro `#2B2320`, oro `#D4A23C`, matcha `#7A9A4A`, indaco `#2E3A5C`, pietra `#8C8C88`.
- Ogni builder restituisce un `Model` con `PrimaryPart`, attributi (`ItemId`, `Uid`) e punti speciali (`Attachment` per mani, posto a sedere, appoggio piatto, slot delle mensole).
- **Forme cave** (ciotole, pentole) e **mezze sfere** (uovo, mochi) con `GeometryService:SubtractAsync` al primo uso, poi salvate in una cache e clonate.
- **Cibo**: ogni ingrediente e ogni piatto ha un modello (nigiri con fetta a strisce, maki tagliati, ciotole con brodo del colore giusto, noodles, toppings). I piatti vengono creati in base agli ingredienti, quindi anche i passaggi intermedi si vedono sul tagliere.
- **Testi giapponesi** su insegne e lanterne con `SurfaceGui` + `TextLabel`.
- **Luci**: `PointLight`/`SurfaceLight` nelle lanterne e nei neon, accese la sera; modalità grafica ridotta che spegne ombre e luci secondarie.
- **Particelle**: vapore, bolle, scintille, petali con le texture incluse in Roblox (`rbxasset://textures/particles/…`).
- **Illuminazione**: `Lighting.Technology = Future`, `Atmosphere`, `BloomEffect`, `ColorCorrectionEffect`, `SunRaysEffect`; curve di colore per ora del giorno.
- **Personaggi NPC**: `Players:CreateHumanoidModelFromDescription` (R15) con colori casuali di pelle e abiti, accessori costruiti con parti (capelli, cappelli, occhiali, zaino, cartella, macchina fotografica, fascia hachimaki e grembiule per il personale), animazioni standard di Roblox (camminata, inattivo, seduto, presa) caricate da un piccolo animatore.

---

## 10. Sistemi di gioco

### Interazione
- Ogni oggetto interattivo ha il tag `Interactable` e l'attributo `Uid`; `InteractionService` ha un gestore per tipo (scatola, mensola, apparecchio, postazione, cliente, piatto, stoviglie, lavello, tablet, lavagna menu).
- **Bersaglio sul client** (`Controllers/Interaction`): in prima persona l'oggetto al centro dello schermo; in terza persona quello sotto il mouse o, senza mouse, il più vicino davanti al personaggio (distanza e direzione). Sul bersaglio il client crea (solo per sé) un **ProximityPrompt** con il testo di cosa succede (`Exclusivity = OneGlobally`, un solo prompt acceso alla volta): E, ButtonX o un tocco lo attivano, `TriggerEnded` ferma il lavaggio.
- Il client invia `Interact(uid)`; il server controlla distanza (≤ 11 stud più metà dell'oggetto), permessi, cosa ha in mano il giocatore e lo stato dell'oggetto; risponde con l'azione eseguita o con un messaggio ("Hai le mani piene").
- Ciò che si porta in mano è uno stack sul server (`{ tipo, id, quantità }`); il modello viene saldato alla mano e si vede anche dagli amici.

### Preparazione a pressioni
1. `Cooking.nextOrder(stazione)`: il biglietto più vecchio di quel tipo di postazione che nessuno sta già preparando (conta i piatti in cottura, pronti sui piatti e in mano a qualcuno). `Cooking.missing(ricetta)`: ingredienti non sugli scaffali, riso, brodo, piatti puliti. Ogni postazione pubblica `Next` e `Missing` come attributi (aggiornati ogni 0,5 s) per il prompt del client.
2. A tagliere vuoto la prima pressione prende gli ingredienti dagli scaffali (`Supply.takeIngredient`, il ripiano più vicino), li fa volare ognuno dal suo ripiano al tagliere e fa subito il primo passaggio; ogni pressione successiva fa il passaggio dopo con un'animazione sul server (coltello, stuoia, bollitore, mestolo). Riso e brodo si prendono da soli dal cuociriso e dal pentolone.
3. Durante un'animazione le pressioni vengono ignorate; la durata dipende da attrezzi, maestria e livello del personale.
4. Dopo l'ultimo passaggio il piatto è un oggetto fisico sulla postazione, pronto da prendere e servire. I cuochi del personale usano le postazioni allo stesso modo.

### Clienti (macchina a stati)
`Arriva → (Aspetta in coda) → Va al posto → Legge il menu → Ordina da solo (biglietto) → Aspetta → Servito: paga subito → Mangia → Recensisce → Esce`
- Prenotazione del posto al momento della scelta; percorso con `PathfindingService` (costo infinito sulle zone `StaffOnly`), ricalcolo se bloccato.
- Stati superflui degli Humanoid disattivati (arrampicata, nuoto, caduta) per risparmiare CPU; proprietà fisica al server.
- Massimo 40 NPC in totale; i clienti vengono riutilizzati (pool) invece di essere ricreati.

### Personale (bacheca dei compiti)
- Il `TaskBoard` genera compiti dallo stato del mondo: *prendi ordine*, *servi piatto*, *raccogli stoviglie*, *lava*, *rifornisci mensola X con ingrediente Y*, *cucina biglietto Z*, *prepara brodo*.
- Ogni NPC del personale prende il compito libero più vicino adatto al suo ruolo, lo prenota, lo esegue con gli stessi gestori usati dal giocatore (stesse regole, stesse animazioni) e lo rilascia se fallisce.
- I compiti presi da un giocatore vengono tolti dalla bacheca, così personale e giocatori non si ostacolano.

### Giornata ed economia
- `Day`: il locale è sempre aperto; l'orologio avanza in continuo (`GameConfig.Day`: 45 s per ora, 15 s di notte); alle `DayStartHour` (6:00) `Day.finish` chiude la giornata (stipendi, statistiche, missioni, mance del barattolo, messaggio di riepilogo, salvataggio) senza fermare il gioco.
- `DayCycleService` controlla `Lighting.ClockTime`; i client interpolano tra i valori per una transizione fluida.
- Ogni guadagno passa da `EconomyService.add(player, amount, reason)` che applica i moltiplicatori e registra la voce per il resoconto della giornata.

---

## 11. Costruzione e griglia

- **Aggancio alla griglia**: per oggetti a terra, l'angolo minimo dell'impronta (dopo la rotazione) viene arrotondato a multipli della griglia `g ∈ {1, 5, 10}` rispetto all'origine del lotto; il centro = angolo + metà dimensione. Per la parete l'aggancio è lungo il muro (orizzontale) e in altezza.
- **Rotazione**: passi di 90°, 45° o 15°; l'impronta per la collisione usa il riquadro orientato.
- **Validazione (sul server, sempre)**:
  1. Il giocatore può costruire, possiede l'oggetto (o ha gli yen), livello sufficiente.
  2. Impronta tutta dentro zone del tipo giusto (sala, cucina, esterno, tatami) e sul piano giusto.
  3. Nessuna sovrapposizione: `workspace:GetPartBoundsInBox` sulle parti degli oggetti piazzati e dei muri.
  4. Passaggi liberi: una griglia di occupazione da 1 stud e una ricerca in ampiezza dall'ingresso a ogni posto attivo e dal magazzino alla cucina; se un passaggio si chiude → non valido.
  5. Riaggancio della posizione sul server (il client non può mandare coordinate fuori griglia).
- Lo stesso modulo `Logic/Footprint` e `Logic/Pathgrid` è usato dal client per colorare l'anteprima (verde/rosso) e dal server per decidere.
- Oggetti sopra il bancone o sui tavoli hanno un genitore (`p`): se sposti il tavolo, si spostano con lui.

---

## 12. Interfaccia e lingue

- `UI/Thumbs.luau`: immagini 3D per le carte (catalogo della costruzione, ricette del negozio): il modello vero dell'oggetto (`Registry.build`) o del piatto (`Registry.food("dish")`) in un `ViewportFrame`, visto di fronte un po' dall'alto e inquadrato sulla sua sfera; ogni modello si costruisce una volta (senza luci, particelle e scritte) e si copia per ogni carta; `Thumbs.later` ne fa quattro per fotogramma mostrando l'emoji finché sono pronte; con la grafica leggera restano le emoji.
- `UI/Kit.luau`: crea istanze con proprietà e figli (stile dichiarativo), più `Theme` con colori e caratteri (titoli FredokaOne, testi BuilderSans) e i componenti: pulsanti (con `Kit.press`: si schiacciano premuti e crescono un poco sotto il mouse; stile per tipo di azione: `buy` verde, `close` rosso, `reward` oro, `secondary` beige, `selected` legno scuro per l'opzione scelta e la scheda aperta), pannelli, finestre (`Kit.window`, sopra l'HUD, quasi a schermo intero sul telefono), schede con pallino rosso (`Kit.tabs`, `Kit.badge`), barre, liste; animazioni `Kit.popIn` (apertura con rimbalzo) e `Kit.bump`.
- `UI/Base.luau`: schermate modali con `open()`, `close()`, `refresh()`. Il contenuto si ricostruisce a ogni cambiamento dei dati, al massimo ogni 0,2 s, e le liste tengono la posizione di scorrimento.
- **Scala per tipo di schermo** (`Controllers/UI`): le schermate sono disegnate in "unità"; `UI.rescale` sceglie il profilo `phone` (lato corto dell'area sotto la barra di Roblox < 520 punti), `tablet` (touch) o `desktop` e una `UIScale` = area / misura di progetto (telefono 960×400, scala 0,68–1; tablet 1180×760, 0,8–1,15; computer 1400×800, 0,72–1,3), così un testo da 16 unità resta di almeno 11 punti. `UI.ProfileChanged` avvisa le schermate (l'HUD cambia misure, il telefono cambia posizione).
- **HUD** (`Screens/HUD`): portafoglio, orologio e obiettivo, ristorante in cui sei (il tuo o quello di un altro, con Mi piace e A casa), ordini a destra, quattro pulsanti in basso (negozio con il numero di acquisti possibili, costruisci, fornitore, altro). Sui touch i pulsanti stanno poco a destra del centro: il joystick dinamico di Roblox prende il 40% sinistro dello schermo, il salto l'angolo in basso a destra. Con una finestra aperta (o il catalogo di costruzione) `GuiService.TouchControlsEnabled` è falso (`UI.blockTouch`).
- **Negozio** (`Screens/Shop`): cinque schede di carte; lo stato di ogni cosa in vendita viene da `Logic/Shop` (puro, con test): `buy`, `poor` (con quanto manca), `locked` (con cosa serve prima), `owned`/`max`/`active`, e il conteggio per scheda usato anche dal pulsante dell'HUD. Il server ricontrolla tutto all'acquisto.
- **Tutorial** (`Controllers/Tutorial`): passi in una tabella (`STEPS`: testo, icona, cosa indicare nel mondo o nell'interfaccia, controllo o azione che lo chiude, timer, regalo). Il passo raggiunto si salva in `meta.tutorial` (−1 = finito o saltato; dalla versione 11 dei dati chi era a metà ricomincia). I regali (`TutorialReward`: "serve" dopo `stats.dishes ≥ 1`, "done" dopo `stats.washed ≥ 1`) li dà `MetaService`, una volta sola (`meta.tutorialGifts`), e "done" registra `tutorial_done` nelle statistiche. Le frecce sono di `UI/Pointer`, usato anche dai consigli (`Controllers/Hints`, `meta.hints`, numeri in `Config/Tutorial`).
- **Calendario del premio giornaliero** (`Screens/Daily`): sette carte che si dividono la larghezza (passati con la spunta, oggi dorato, i prossimi con il premio) e un solo pulsante **Riscuoti** che manda `ClaimDaily` e chiude la finestra. Lo apre il `TutorialController` (`offerDaily`): all'ingresso se il premio di oggi c'è ancora e il tutorial non è in corso, dopo la finestra dei guadagni offline; per un giocatore nuovo `PopupAfterTutorial` secondi dopo la fine del tutorial; sempre solo quando nessun'altra finestra è aperta (aspetta al massimo `PopupWait` secondi), una volta per sessione.
- **Pop-up sul telefono** (profilo `phone`): `UI.toast` e `UI.popup` usano un contenitore largo 340 invece di 460 (testi 15, 16/14 invece di 18, 21/16, pop-up alto 54 invece di 74), il consiglio (`Controllers/Hints`) è largo 330 con testo 15, la scheda del tutorial (`Tutorial.layout`, anche a ogni `UI.ProfileChanged`) è 360×68 con icona da 44 e pulsanti da 64 (lo spazio per il testo non cambia), la scritta della combo 300×50.
- **Insegna** (`Screens/Sign`, app 🏮 del telefono o il prompt sull'insegna): anteprima dal vivo (tavola, cornice dello stile, tagli del noren, lanterne, nome nel carattere dello stile con un alone per il neon; più bassa sul telefono), casella del nome (tagliata a 24 lettere, contatore), 🎲 Idea, cinque pulsanti di stile, due griglie di colori, nota sul filtro, ↺ Classica e 💾 Salva (`SetSign`); chi non può costruire vede 🔒. La bozza si azzera a ogni apertura.
- **Scritte nel mondo** (`WorldUIController`): sopra postazioni, pentoloni, cuociriso, piatti sporchi, barattolo delle mance, aiutanti e clienti solo parole, bianche (crema la seconda riga) con un `UIStroke` scuro sul testo e nessun riquadro; i clienti hanno ancora icona e barra della pazienza (sottile, su una traccia scura con il bordo).
- Ordine di disegno nella `ScreenGui` (ZIndex dei figli): HUD 1, guida dell'ordine 5, consigli 6, tutorial 7, telefono 9, finestre 10, messaggi 20, frecce 30.
- Icone: emoji nei testi (🍣 🍜 🔨 📦 🏮) + spazi per ID immagine opzionali.
- **Lingue**: `Locale/en.luau` e `Locale/it.luau` con le stesse chiavi; lingua automatica da `player.LocaleId` (italiano se inizia con `it`, altrimenti inglese), modificabile; `AutoLocalize = false` su tutta la UI per evitare traduzioni automatiche di Roblox. Un test verifica che le due lingue abbiano le stesse chiavi e gli stessi parametri.

---

## 13. Rete e sicurezza

- Tutti i remoti sono definiti in `Net/` con il tipo di ogni argomento; gli argomenti sbagliati vengono scartati prima di arrivare ai servizi.
- Limite di frequenza per giocatore e per remoto, anche sulle RemoteFunction (`GetSnapshot`, `GetLeaderboard`: le chiamate in più ricevono `nil`); i contatori di chi esce vengono liberati.
- Il client non manda mai prezzi, quantità guadagnate o risultati finali: manda intenzioni ("clicco questo", "piazza questo oggetto qui", "compra questa licenza").
- Acquisti Robux: `ProcessReceipt` concede il premio solo dopo averlo salvato, e registra il `PurchaseId` per non concederlo due volte.
- **Testi scritti dai giocatori** (il nome dell'insegna): si mostrano solo dopo il filtro di Roblox per i testi visti da tutti, filtrati dal server con l'`UserId` di chi li ha scritti; il testo non filtrato non lascia mai il server (`Data` lo toglie dai dati mandati ai client, anche a chi l'ha scritto).

Remoti (`Shared/Net`): `Interact`, `DropHands`, `OrderSupplies`, `BuyDishes`, `PlaceItem`, `MoveItem`, `RemoveItem`, `PaintSurface`, `BuyLicense`, `BuyUpgrade`, `BuyExpansion`, `BuyAd`, `HireStaff`, `TrainStaff`, `FireStaff`, `SetMenu`, `ClaimQuest`, `ClaimAchievement`, `ClaimDaily`, `ClaimOffline`, `Wash`, `TimingHit`, `Like`, `ClaimGift`, `RedeemCode`, `SetSetting`, `SetPermission`, `GoHome`, `ToggleOpen`, `SetSign`, `Franchise`, `BuyWithRobux`, `TutorialStep`, `TutorialReward`, `HintSeen`, `Dev`; funzioni `GetSnapshot` e `GetLeaderboard`; dal server: `DataChanged`, `WorldSnapshot`, `Notify`, `Tickets`, `Fx`, `DayState`, `Session`.

### Statistiche (Roblox Analytics)
Servizio `Analytics` (impostazioni in `Config/Analytics.luau`), ogni chiamata è protetta e non può rompere il gioco:
- **Funnel di onboarding** (`LogOnboardingFunnelStepEvent`), una volta per giocatore nuovo: profilo creato → primo ordine → primo piatto cucinato → primo cliente servito → tutorial finito → primo acquisto → 10 clienti → livello 3 → livello 5. Si legge nella dashboard Creator: mostra a che punto escono i giocatori nuovi.
- **Economia** (`LogEconomyEvent`): ogni spesa in yen con il codice di cosa si compra (`upgrade:up_tray`, `license:lic_sashimi`, `item:stool_wood`…); premi (regali, giornaliero, missioni, offline, Robux) uno per uno; vendite e mance sommate ogni 2 minuti.
- **Progressione** (`LogProgressionCompleteEvent`): ogni livello raggiunto.

---

## 14. Prestazioni

Misurate dallo scenario `perf` (`python3 tools/sim.py perf`) con la strada piena (quattro ristoranti nuovi aperti, clienti in arrivo): se un numero supera il limite, la prova fallisce.

| Voce | Oggi | Limite |
|---|---|---|
| Parti della strada (costruita una volta) | ~7.810 (con i petali dei ciliegi) | 8.500 |
| Luci della strada | 70 (nessuna con ombre) | 80 |
| Parti decorative della strada che i raggi devono controllare | 0 | 50 |
| Parti di un ristorante nuovo (edificio + oggetti) | ~2.240 (lanterne e listelli del soffitto, bambù e lanterne iniziali) | 2.600 |
| Luci di un ristorante nuovo | 31 (+1 con l'insegna neon, +2 con quella a lanterne) | 40 |
| Clienti e personale di tutta la strada | ~760 parti | 1.500 |
| Tutta la strada | ~17.700 parti, 196 luci | 20.000 parti, 260 luci |
| NPC contemporanei | — | 60 in tutta la strada (`GameConfig.MaxNpcs`), al massimo 14 clienti per ristorante |
| Ricalcolo percorsi | — | al massimo 10 al secondo (coda) |

- **Parti silenziose**: dopo aver costruito strada, edificio e lotti vuoti, `World.quiet` toglie `CanQuery` e `CanTouch` alle parti decorative che non hanno collisione (tranne pavimenti, pareti, soffitti, tetti e le cose che si usano). I raggi del client (telecamera che non passa i muri, mira e clic, costruzione) le attraversano: meno lavoro e la telecamera non salta più davanti a lanterne e fili.
- **Ombre**: le parti piccole non fanno ombra (`CastShadow = false` nei costruttori); nessuna luce proietta ombre.
- **Grafica ridotta** (Impostazioni): spegne bloom, raggi del sole, ombre globali e i faretti della strada di notte.
- **`StreamingEnabled`**: resta disattivato. Con quattro ristoranti la strada sta sotto le 20.000 parti, che i telefoni di fascia media reggono. Attivarlo richiederebbe modelli "atomici" per tutto ciò che si usa e attese su ogni oggetto lato client; si valuta se i test su un telefono economico mostrano problemi. Il guadagno più grande viene prima dai modelli veri al posto di quelli procedurali (`docs/04-ASSET.md`): per esempio il bancone, 12 moduli da 51 parti per locale.

Animazioni decorative, treno e particelle girano solo sul client.

---

## 15. Test e controlli

- **Test della logica** (`tests/logic_spec.lua`, eseguiti con lupa): formule (XP, prezzi, mance, recensioni), griglia 1/5/10, sovrapposizioni, muri e porte, validità del layout iniziale, piazzamento a terra/parete/soffitto/su bancone, blocco dei passaggi, locale completo su tre piani, ambiente, integrità della configurazione.
- **Controllo statico** (`tools/check_luau.py`, `tools/check_api.py`): blocchi, variabili non dichiarate, require, parità delle lingue, chiamate tra servizi.
- **Simulatore del server** (`tools/sim.py`): esegue il codice vero del server (tutti i servizi, `Init` e `Start`) su un Roblox simulato in Lua 5.4: orologio virtuale con `task.wait/spawn/delay`, istanze con proprietà, figli, attributi, tag ed eventi, i servizi usati dal gioco, DataStore in memoria che rifiutano i valori che Roblox non salverebbe (array con buchi, tabelle miste, NaN), giocatori finti con personaggio. Gli scenari in `tools/sim/scenarios/` aggiungono giocatori, mandano remoti, fanno passare il tempo e controllano il risultato: `core` (avvio, autotest del gioco, clienti per 3 minuti, statistiche, salvataggio all'uscita), `loop` (un giocatore nuovo gioca il ciclo base con i remoti veri e ne misura i tempi: primo ordine entro 20 s, servito e pagato entro 35 s, una giornata intera senza premere nulla; una scatola di tonno senza posto sulle mensole piene non mette i piatti di tonno nel menu, un ripiano libero sì), `saves` (profilo bloccato da un altro server, uscita durante un salvataggio, spegnimento del server, guasto dei DataStore), `street` (quattro giocatori con un locale ciascuno, id salvati in comune rinominati, un quinto giocatore senza lotto, ordini in ogni locale, un amico cucina e serve nel locale di un altro e riceve la quota mentre il locale guadagna il bonus squadra, un estraneo viene rifiutato, il proprietario esce e il lotto si svuota), `client` (gira anche il **client vero** di un giocatore su un telefono simulato: l'ordine compare sullo schermo, la postazione si usa con il suo pulsante, il cliente si serve con il suo, il negozio si apre dalla barra in basso e una carta compra un miglioramento), `perf` (la strada piena entro i limiti di parti e luci del §14), `tutorial` (un giocatore nuovo su telefono fa tutto il tutorial facendo solo quello che dice la scheda; controlla i due regali, che non si possono chiedere due volte, il passo `tutorial_done` delle statistiche, la durata e un consiglio della prima volta), `retention` (un giocatore che torna dopo 3 ore al terzo giorno di fila: prima la finestra dei guadagni offline con la cifra giusta, poi il calendario che si apre da solo, il premio del giorno 3 pagato una volta sola, le bacheche delle classifiche in italiano con il primo giocatore e il proprio numero, il pass Personale extra che aggiunge due posti, la Sensibilità che moltiplica la rotazione della telecamera), `franchise` (il primo franchise a Kyoto: si azzerano livello, yen, licenze, stanze, personale, miglioramenti e la storia degli incassi usata dai guadagni offline; i mobili vanno nell'inventario, i piatti serviti restano, il locale ricostruito funziona, la stella paga il 25% in più, la città dopo non è subito disponibile), `neighbours` (Impostazioni → Altri locali: con «Solo fuori» gli interni e le lampade dell'altro ristorante spariscono dal tuo schermo ma l'edificio resta, il tuo resta completo, entrando nell'altro si invertono, «Mostra tutto» rimette tutto com'era, un valore inventato viene rifiutato), `floors` (secondo piano e tetto: gradini regolari e bassi fino al piano di sopra, pianerottolo a metà, protezioni invisibili su tutti i lati, corrimano e colonnine su entrambi i lati, palle e cilindri davvero rotondi, pavimento aperto sopra la scala con ringhiere su tre lati e libero dove si scende, il tavolo che stava dove va la scala torna nell'inventario, un tavolo al piano di sopra), `sign` (l'insegna: quella classica all'inizio, l'editor sul telefono scrive il nome, sceglie neon, tavola indaco e lettere sakura e salva; il nome compare sopra la porta con i tubi al neon; il filtro trasforma una parola vietata in #### e ai client arriva solo il nome filtrato; nomi troppo corti o lunghi, stili inventati, un aiutante entrato nel locale e il filtro fuori uso su un server vero non cambiano nulla, in Studio il nome si vede lo stesso; una modifica ogni pochi secondi; due luci con le lanterne; tre teli con il noren; l'insegna gigante del tetto; il nome dopo essere usciti e rientrati), e lo scenario lento `progression` (`python3 tools/sim.py progression --hours=4`, escluso dal giro normale): un giocatore automatico gioca ore a velocità umana con i remoti veri (cucina, serve, lava, rifornisce, riscuote missioni e regali, compra la cosa più economica, mette da parte i soldi per il primo aiutante di ogni ruolo e per le stanze) e stampa quando arrivano livelli e acquisti, il primo aiutante, quanto a lungo il negozio non ha niente di comprabile, i requisiti del franchise, gli yen incassati per punto XP con gli incassi delle ultime giornate, le notifiche ricevute e lo stato finale (scatole, piatti puliti, scorte degli scaffali); con `--status` scrive ogni 20 minuti livello, yen, valutazione, personale, scatole, piatti, biglietti e scaffali vuoti. Le partite simulate partono sempre dallo stesso seme casuale (`--seed=N` per cambiarlo); restano piccole differenze tra due partite perché l'ordine delle tabelle di Lua cambia, quindi per il bilanciamento conviene guardare più semi.
- **Client simulato** (`tools/sim/client.lua`, `tools/sim/gui.lua`): `Sim.startClient(player, "phone" | "tablet" | "laptop" | "desktop")` esegue `src/first` e `src/client` con una cache dei moduli separata (`RunService:IsClient()` è vero per il loro codice), remoti in entrambe le direzioni, telecamera, input e servizi dell'interfaccia del dispositivo e una disposizione dell'interfaccia come quella di Roblox (UDim2, AnchorPoint, UIScale, UIPadding, UIListLayout, UIGridLayout, vincoli di misura, AutomaticSize, ScrollingFrame), che dà `AbsolutePosition`/`AbsoluteSize`. Gli scenari possono cliccare pulsanti (`Sim.click`), premere tasti (`Sim.press`: le azioni di `ContextActionService` ricevono il tasto prima, in ordine di priorità, e come in Roblox la telecamera si prende I e O), usare i ProximityPrompt (`Sim.trigger`) e cercare testi sullo schermo (`Sim.findText`). Lo scenario `client` prova anche il cartello OPEN/CLOSED (chiude, nessun nuovo cliente per 30 s, riapre, un aiutante non può chiuderlo), le consegne (due pop-up, scatole fuori dalla porta del magazzino) e i tasti O e U (anche quando la telecamera di Roblox si prende la pressione di O e allo script arriva solo il rilascio, o quando O resta premuto), e che in prima persona tre piatti in mano restano sotto il mirino; il giocatore su telefono cucina e serve toccando il pulsante grande sopra la postazione e sopra il cliente; i test di logica provano `Placement.wallSpot` (parete, cima del muro, fuori dall'edificio, griglia da 5).
- **Anteprima dell'interfaccia** (`tools/ui_preview.py`): gioca uno script di `tools/sim/ui/` e disegna in PNG lo schermo del client a ogni `Sim.snapshot("nome")`, con la barra di Roblox e, sui touch, joystick e salto disegnati sopra per vedere le sovrapposizioni. I `ViewportFrame` (le immagini 3D delle carte) sono disegnati con una proiezione semplice dei pezzi (ogni pezzo come una scatola ombreggiata, dal fondo verso la telecamera): basta per vedere se un oggetto è inquadrato bene. Qualsiasi errore del gioco fa fallire la prova.
- **Costruzione**: `tools/build_place.py` produce il `.rbxlx`.
- **Asset**: `tools/asset_list.py` riscrive `docs/04-ASSET.md` costruendo ogni oggetto e contandone le parti (cosa sostituire per primo e come).
- **In Studio** (tu): lista di controllo di gioco per la prima giornata, la costruzione, le espansioni e il personale, più il pannello sviluppatore per arrivare velocemente ai livelli alti.
- **graphify**: `graphify update .` alla fine di ogni blocco di lavoro, così il grafo `graphify-out/` resta allineato al codice.

---

## 16. Ordine di implementazione

Tutto in un'unica sessione di lavoro, a blocchi, con un commit per blocco:

| Blocco | Contenuto | Pronto quando |
|---|---|---|
| **B0 Base** | progetto Rojo, avvio servizi/controller, Net, utilità, Locale, Config completi, DataService, tema UI | `rojo build` ok, test della configurazione verdi |
| **B1 Mondo** | Kit e Palette, strada, edificio a zone, illuminazione e giornata, modelli dei mobili iniziali | il mondo si vede bello di giorno e di sera |
| **B2 Ciclo base** | interazione a clic, oggetti in mano, fornitore e furgone, magazzino, mensole, rice cooker, pentoloni, 3 ricette con i passaggi a clic, clienti, pagamento, stoviglie, resoconto | una giornata completa giocabile |
| **B3 Costruzione** | modalità costruzione, griglia 1/5/10, rotazione, validazione, vendita, inventario, pavimenti e pareti, catalogo completo dei modelli | si arreda il locale e si salva |
| **B4 Progressione** | livelli, licenze, tutte le ricette e postazioni, upgrade, pubblicità, espansioni, valutazione, prezzi del menu, maestrie | si arriva al livello 20 con il pannello sviluppatore senza blocchi |
| **B5 Personale** | bacheca dei compiti, tutti i ruoli, stipendi, addestramento, tavoli e gruppi, sala tatami e VIP | il locale va avanti da solo con il personale |
| **B6 Meta** | missioni, obiettivi, premio giornaliero, guadagni offline, set, classifiche, franchise e città, eventi | ciclo a lungo termine completo |
| **B7 Sessioni & Robux** | strada con 4 ristoranti, inviti, permessi, monetizzazione, impostazioni, tutorial | flusso completo dall'ingresso al tutorial |
| **B8 Rifinitura** | suoni, particelle, bilanciamento, test finali, `.rbxl` compilato, `graphify update .` | consegna |

---

## 17. Rischi tecnici

| Rischio | Soluzione |
|---|---|
| Non posso aprire Studio dal cloud: errori visibili solo in gioco | logica pura testata con lupa, controlli statici propri, avvio robusto che isola gli errori dei singoli servizi, log chiari; tu fai la prova finale in Studio |
| Modelli da sole parti meno dettagliati di quelli fatti in Blender | proporzioni e colori curati, luci e particelle; cartella `AssetOverrides` per sostituirli senza toccare il codice |
| Suoni e musica richiedono ID dalla libreria Roblox | spazi già pronti in `Config/Audio`; suoni di base inclusi in Roblox dove disponibili |
| ID delle animazioni standard | uso delle animazioni R15 di Roblox; se un ID non carica, l'NPC si muove comunque (solo senza quella animazione) |
| Percorsi degli NPC bloccati da oggetti piazzati | controllo dei passaggi al piazzamento + ricalcolo e teletrasporto di emergenza dell'NPC se resta bloccato più di 8 s |
| Molti NPC pesanti per il server | limite di 40, pool, stati Humanoid ridotti, coda dei percorsi |
