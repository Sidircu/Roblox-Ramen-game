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
2. In Studio: **File → Open from File** → **Play** per provarlo (in Studio funziona tutto tranne teletrasporti e acquisti reali).
3. **File → Publish to Roblox** per pubblicarlo.
4. In **Game Settings**: *Security → Enable Studio Access to API Services* (salvataggi in Studio), *Places → Max Players: 6*, server privati Roblox disattivati.
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
         ├─ Theme.luau, New.luau # stile + piccolo costruttore dichiarativo di UI
         ├─ Components/          # Button, Panel, Tabs, Card, Bar, Tooltip, Modal, Toast
         └─ Screens/             # HUD, Supplier, Build, Menu, Licenses, Upgrades, Staff,
                                 #   Expansions, Quests, DayReport, Inventory, Recipes,
                                 #   Shop, Invite, Settings, Daily, Offline, Tutorial
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

Un test controlla l'integrità: ogni ingrediente usato esiste, ogni licenza punta a ricette esistenti, ogni oggetto ha un builder e le chiavi di traduzione in entrambe le lingue.

---

## 4. Servizi del server

| Servizio | Responsabilità |
|---|---|
| `SessionService` | modalità del server (ingresso o mondo), proprietario, aiutanti, inviti, teletrasporti (§6) |
| `DataService` | caricamento/salvataggio con blocco di sessione, autosalvataggio, migrazioni, replica dei dati al client (§7) |
| `WorldService` | costruisce la strada e l'edificio dalle zone sbloccate; ricostruisce dopo un'espansione (§8) |
| `PlacementService` | piazzamento, spostamento, vendita, inventario, verniciatura; validazione (§11) |
| `InteractionService` | riceve i clic, controlla distanza e stato, smista all'azione giusta; gestisce cosa ha in mano ogni giocatore |
| `SupplyService` | ordini al fornitore, furgone, scatole nel magazzino, mensole e slot. Ripiani a scacchiera (`Logic/ShelfGrid`: colonne × file per ingrediente, caselle libere segnate), aggiornati un ripiano e una casella alla volta; `Fx("stock")` fa volare i prodotti dalla scatola alle caselle (il ripiano si ridisegna quando atterra l'ultimo), `Fx("take")` dalla casella alla mano. Le scatole in mano sono aperte con alcuni prodotti visibili. Il furgone lascia le scatole a terra nella `Expansions.DropZone` (posti a griglia, due livelli; le scatole a terra nello stesso punto si impilano) e la capienza è scaffali del magazzino + posti a terra |
| `ApplianceService` | rice cooker, pentoloni, lavello, lavastoviglie: lotti, timer, porzioni. Lavello: pila di piatti sporchi disegnata nella vasca, sessioni "tieni premuto" (remote `Wash(uid, on)`, un piatto ogni `Washing.Time` finché il giocatore tiene premuto, è vicino e ha le mani libere), attributi `Washing`/`WashStart`/`WashTime`/`Washer` per l'animazione sul client (`SinkController`) |
| `CookingService` | biglietti d'ordine, sessioni di preparazione, risultati dei minigiochi, piatti pronti. Il tagliere mostra le sagome (materiale ForceField) degli ingredienti mancanti della ricetta obiettivo (ordine più vecchio compatibile con quanto posato) e pubblica l'attributo `Need`; gli ingredienti posati volano al loro posto |
| `CustomerService` | arrivo, scelta del posto, ordini, pazienza, pasto, pagamento, recensione; intelligenza dei clienti |
| `SeatingService` | posti attivi (sgabello davanti al bancone, sedia vicino al tavolo), prenotazioni, punto dove appoggiare il piatto |
| `StaffService` | assunzione, stipendi, addestramento, intelligenza del personale tramite bacheca dei compiti (§10) |
| `TaskBoard` | elenco dei lavori da fare (prendere ordine, servire, raccogliere, lavare, rifornire, cucinare) usato dal personale e dai suggerimenti al giocatore |
| `DayCycleService` | fasi della giornata, orologio, picchi, resoconto, giornata automatica |
| `EconomyService` | yen, gettoni, moltiplicatori (VIP, franchise, eventi), registro delle transazioni del giorno; barattolo delle mance (`tipJar` nei dati, parte `Coins` che cresce, ritiro con clic o a fine giornata) |
| `ProgressionService` | XP, livelli, licenze, upgrade, espansioni, maestrie, valutazione |
| `MetaService` | missioni giornaliere, obiettivi, premio giornaliero, guadagni offline, set di decorazioni |
| `RewardsService` | Mi piace dei visitatori (remote `Like`, una volta al giorno per ristorante, `stats.likes`, attributo `Likes` del workspace, classifica `LB_Likes_v1`), regali a tempo della sessione (`JoinedAt`, `GiftsClaimed` come attributi del giocatore, `ClaimGift`), codici (`RedeemCode`, usati in `meta.codes`), leaderstats ¥ e ⭐ |
| `FranchiseService` | rinascita e città |
| `MonetizationService` | gamepass, `ProcessReceipt` con registro anti-doppio-acquisto |
| `LeaderboardService` | classifiche globali (OrderedDataStore) mostrate su una bacheca in strada |
| `DevService` | solo in Studio o per il proprietario del gioco: pannello sviluppatore (yen, livello, salta tempo, genera clienti) |

---

## 5. Controller del client

| Controller | Responsabilità |
|---|---|
| `DataController` | copia locale dei dati del giocatore + eventi di cambiamento |
| `InteractionController` | raggio dal cursore/tocco (dal centro dello schermo in prima persona), evidenziazione (`Highlight`) ed etichetta sull'oggetto se il giocatore è abbastanza vicino, clic/tocco/E → richiesta al server |
| `ShelfTagsController` | cartellini locali sul bordo di ogni ripiano (icona e nome del prodotto nella lingua del giocatore), aggiornati quando cambia l'attributo `G` dello slot |
| `TimingController` | barra del tempismo dei noodles (`Fx("timing")` durante il passaggio "boil" di chi cucina; il clic invia `TimingHit(uid, k)`, il server accetta k nella parte verde se vicino al suo tempo e segna la ciotola come perfetta) |
| `FirstPersonController` | mirino e testo dell'azione al centro, oggetti in mano copiati davanti alla telecamera (attributo `Held` sui modelli in mano), mouse libero con un `GuiButton.Modal` visibile (menu aperto, costruzione, Alt), scorciatoie B/O/P/R, corsa (Shift o 🏃, attributo `WalkSpeed`), pulsante ✋ su touch |
| `CarryVisualController` | posa delle braccia quando si porta qualcosa, pila di oggetti in mano |
| `BuildController` | modalità costruzione: anteprima, griglia 1/5/10, rotazione, colori valido/non valido, vista dall'alto |
| `GridVisualizer` | linee della griglia disegnate solo attorno al cursore (poche parti, solo in costruzione) |
| `CameraController` | modalità `first` (prima persona, `LockFirstPerson`), `game` (orbita morbida) e `roblox`; vista dall'alto in costruzione; nasconde il tetto solo in orbita quando sei dentro |
| `LightingController` | transizione di luce durante la giornata, accensione lanterne e neon |
| `AmbientController` | treno, petali, animazioni decorative (maneki-neko, koi, shishi-odoshi) solo lato client |
| `AudioController` | effetti con prese casuali e intonazione variata (2D o posizionali), sequenze dei passaggi di cucina (`Fx("step")`: colpi di coltello a ritmo, versare, scolare, sfrigolare), anelli d'ambiente mescolati da posizione e clienti, pentole che bollono, treno, playlist giorno/sera |
| `UIController` | apre/chiude schermate, scala per telefono/PC, notifiche |
| `TutorialController` | passi guidati con frecce (`Beam`) e fumetti |

---

## 6. Mondo personale e inviti

Un solo *place* che funziona in due modi:

**Modalità ingresso** (server pubblici):
1. Il giocatore vede la schermata di caricamento (`ReplicatedFirst`).
2. Se arriva da un invito (`player:GetJoinData().LaunchData` con l'ID del proprietario) e quel mondo è attivo (MemoryStore `LiveWorlds`) ed è amico del proprietario → viene mandato nel mondo dell'amico.
3. Altrimenti → nel proprio mondo: il codice di accesso del suo server riservato è salvato in DataStore (`WorldCodes[userId]`); se non c'è, si crea con `TeleportService:ReserveServer` e si salva anche `WorldOwners[privateServerId] = userId`.
4. `TeleportService:TeleportAsync` con `ReservedServerAccessCode`; in caso di errore riprova 3 volte, poi in ultima istanza fa giocare il giocatore direttamente lì.

**Modalità mondo** (server riservato):
- Legge il proprietario da `WorldOwners[game.PrivateServerId]` (dato sicuro, non arriva dal client).
- Chi entra: il proprietario → gestore; amici del proprietario o invitati → aiutanti; chiunque altro → rimandato al proprio mondo.
- Registra il mondo come attivo in MemoryStore ogni 60 s (per gli inviti).
- Se esce il proprietario: salvataggio, messaggio agli aiutanti e teletrasporto al loro mondo.

**In Studio**: niente teletrasporti; il server è subito "mondo" e il primo giocatore è il proprietario.

Permessi (salvati nei dati del proprietario): `helper` (cucina, serve, pulisce, rifornisce) e `comanager` (anche costruire e comprare con gli yen del proprietario).

---

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
  settings = { lang = "auto", grid = 1, rot = 90, music = 0.5, sfx = 0.8, lowGfx = false },
  receipts = { …ultimi 50 PurchaseId },
}
```

### Regole
- DataStore `Profiles_v1`, chiave `u_<userId>`; scrittura sempre con `UpdateAsync`.
- **Blocco di sessione**: il salvataggio contiene `{ jobId, time }`; un altro server non lo usa finché il blocco è recente (< 10 min), poi lo considera abbandonato. Evita duplicazioni.
- Autosalvataggio ogni 120 s, all'uscita e in `game:BindToClose`; tentativi con attesa crescente; controllo del budget delle richieste.
- `migrate(data)` porta i salvataggi vecchi alla versione corrente; i campi mancanti si riempiono dai valori predefiniti. Versione 2: locale ingrandito; versione 3: bancone da 12 sgabelli, mensole grandi e prima persona; versione 4: cucina componibile e mensole a scacchiera; versione 5: il sushi di base passa alla licenza `lic_sushi0` (chi aveva già giocato la riceve); versione 6: mensole vicino alla porta del magazzino, barattolo delle mance, licenza `lic_sashimi`, pentolone e cuociriso pieni nella cucina ricostruita (gli oggetti comprati tornano nell'inventario, le scorte delle mensole tornano nelle scatole).
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
- Le zone di cucina hanno un `PathfindingModifier` con etichetta `StaffOnly` (i clienti non ci passano).
- Dopo un'espansione: animazione di cantiere, ricostruzione, gli oggetti che non sono più validi vanno nell'inventario (mai persi).

---

## 9. Modelli procedurali e grafica

- `Kit` offre primitive con valori predefiniti curati (bordi `SmoothPlastic`, `CastShadow` solo dove serve, `Anchored`, `CanCollide` coerente) e saldature.
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
- Il client invia `Interact(uid)`; il server controlla distanza (≤ 9 stud), permessi, cosa ha in mano il giocatore e lo stato dell'oggetto; risponde con l'azione eseguita o con un messaggio ("Hai le mani piene").
- Ciò che si porta in mano è uno stack sul server (`{ tipo, id, quantità }`); il modello viene saldato alla mano e si vede anche dagli amici.

### Preparazione a clic
1. Il giocatore porta gli ingredienti alla postazione: vengono posati sul tagliere solo quelli che possono formare una ricetta sbloccata.
2. Quando gli ingredienti sul tagliere corrispondono esattamente a una ricetta (riso e brodo si prendono da soli dal rice cooker e dal pentolone), ogni clic sulla postazione esegue il passaggio successivo con un'animazione sul server (coltello, stuoia, bollitore, mestolo).
3. Durante un'animazione i clic vengono ignorati; la durata dipende da attrezzi, maestria e livello del personale.
4. Dopo l'ultimo passaggio il piatto è un oggetto fisico sulla postazione, pronto da prendere e servire. Un clic a mani vuote su un tagliere con ingredienti non validi li rimette in mano.

### Clienti (macchina a stati)
`Arriva → (Aspetta in coda) → Va al posto → Legge il menu → Ordina → Aspetta → Mangia → Paga → Recensisce → Esce`
- Prenotazione del posto al momento della scelta; percorso con `PathfindingService` (costo infinito sulle zone `StaffOnly`), ricalcolo se bloccato.
- Stati superflui degli Humanoid disattivati (arrampicata, nuoto, caduta) per risparmiare CPU; proprietà fisica al server.
- Massimo 40 NPC in totale; i clienti vengono riutilizzati (pool) invece di essere ricreati.

### Personale (bacheca dei compiti)
- Il `TaskBoard` genera compiti dallo stato del mondo: *prendi ordine*, *servi piatto*, *raccogli stoviglie*, *lava*, *rifornisci mensola X con ingrediente Y*, *cucina biglietto Z*, *prepara brodo*.
- Ogni NPC del personale prende il compito libero più vicino adatto al suo ruolo, lo prenota, lo esegue con gli stessi gestori usati dal giocatore (stesse regole, stesse animazioni) e lo rilascia se fallisce.
- I compiti presi da un giocatore vengono tolti dalla bacheca, così personale e giocatori non si ostacolano.

### Giornata ed economia
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

- `New.luau`: piccola funzione che crea istanze con proprietà e figli (stile dichiarativo), più `Theme` con colori, caratteri (titoli FredokaOne, testi BuilderSans), angoli, bordi, ombre.
- Componenti riutilizzabili; ogni schermata è un modulo con `open()`, `close()`, `refresh()`.
- Scala automatica per telefono/tablet/PC (`UIScale` in base alla risoluzione), pulsanti grandi, nessuna funzione solo da tastiera.
- Icone: emoji nei testi (🍣 🍜 🔨 📦 🏮) + spazi per ID immagine opzionali.
- **Lingue**: `Locale/en.luau` e `Locale/it.luau` con le stesse chiavi; lingua automatica da `player.LocaleId` (italiano se inizia con `it`, altrimenti inglese), modificabile; `AutoLocalize = false` su tutta la UI per evitare traduzioni automatiche di Roblox. Un test verifica che le due lingue abbiano le stesse chiavi e gli stessi parametri.

---

## 13. Rete e sicurezza

- Tutti i remoti sono definiti in `Net/` con il tipo di ogni argomento; gli argomenti sbagliati vengono scartati prima di arrivare ai servizi.
- Limite di frequenza per giocatore e per remoto.
- Il client non manda mai prezzi, quantità guadagnate o risultati finali: manda intenzioni ("clicco questo", "piazza questo oggetto qui", "compra questa licenza").
- Acquisti Robux: `ProcessReceipt` concede il premio solo dopo averlo salvato, e registra il `PurchaseId` per non concederlo due volte.

Remoti principali: `Interact`, `OrderSupplies`, `PlaceItem`, `MoveItem`, `RemoveItem`, `PaintSurface`, `BuyLicense`, `BuyUpgrade`, `BuyExpansion`, `BuyAd`, `HireStaff`, `TrainStaff`, `FireStaff`, `SetMenu`, `SetDayState`, `ClaimQuest`, `ClaimDaily`, `ClaimOffline`, `SetSetting`, `SetPermission`, `Franchise`, `GetSnapshot` (funzione); dal server: `DataChanged`, `Notify`, `PlaySfx`, `Tickets`.

---

## 14. Prestazioni

| Voce | Limite |
|---|---|
| NPC contemporanei | 40 (clienti + personale) |
| Parti per oggetto decorativo | ≤ 60 (≤ 150 per alberi, laghetto, armatura) |
| Parti della strada | ≤ 6.000 (tutte ancorate, costruite una volta) |
| Luci attive | ≤ 40 vicine alla telecamera; modalità ridotta: ≤ 10 |
| Ricalcolo percorsi | al massimo 10 al secondo (coda) |
| `StreamingEnabled` | disattivato (mondo piccolo e privato) |

Animazioni decorative, treno e particelle girano solo sul client.

---

## 15. Test e controlli

- **Test della logica** (`tests/logic_spec.lua`, eseguiti con lupa): formule (XP, prezzi, mance, recensioni), griglia 1/5/10, sovrapposizioni, muri e porte, validità del layout iniziale, piazzamento a terra/parete/soffitto/su bancone, blocco dei passaggi, locale completo su tre piani, ambiente, integrità della configurazione.
- **Controllo statico** (`tools/check_luau.py`, `tools/check_api.py`): blocchi, variabili non dichiarate, require, parità delle lingue, chiamate tra servizi.
- **Costruzione**: `tools/build_place.py` produce il `.rbxlx`.
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
| **B7 Sessioni & Robux** | mondo personale, inviti, permessi, monetizzazione, impostazioni, tutorial | flusso completo dall'ingresso al tutorial |
| **B8 Rifinitura** | suoni, particelle, bilanciamento, test finali, `.rbxl` compilato, `graphify update .` | consegna |

---

## 17. Rischi tecnici

| Rischio | Soluzione |
|---|---|
| Non posso aprire Studio dal cloud: errori visibili solo in gioco | logica pura testata con lupa, controlli statici propri, avvio robusto che isola gli errori dei singoli servizi, log chiari; tu fai la prova finale in Studio |
| Modelli da sole parti meno dettagliati di quelli fatti in Blender | proporzioni e colori curati, luci e particelle; cartella `AssetOverrides` per sostituirli senza toccare il codice |
| Suoni e musica richiedono ID dalla libreria Roblox | spazi già pronti in `Config/Audio`; suoni di base inclusi in Roblox dove disponibili |
| ID delle animazioni standard | uso delle animazioni R15 di Roblox; se un ID non carica, l'NPC si muove comunque (solo senza quella animazione) |
| Teletrasporti funzionano solo nel gioco pubblicato | in Studio modalità mondo diretta; in pubblicazione tentativi ripetuti e ripiego |
| Percorsi degli NPC bloccati da oggetti piazzati | controllo dei passaggi al piazzamento + ricalcolo e teletrasporto di emergenza dell'NPC se resta bloccato più di 8 s |
| Molti NPC pesanti per il server | limite di 40, pool, stati Humanoid ridotti, coda dei percorsi |
