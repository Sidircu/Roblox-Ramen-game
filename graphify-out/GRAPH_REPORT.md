# Graph Report - Roblox-Ramen-game  (2026-11-17)

## Corpus Check
- 137 files · ~167,728 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1376 nodes · 3655 edges · 84 communities (51 shown, 33 thin omitted)
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 849 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7c5401b5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Cooking.luau
- Cooking.luau
- Services/Customers.luau
- Services/Placement.luau
- Color.hex
- Scene.shell
- Day.luau
- Kit.new
- re
- mock.lua
- Controllers/Build.luau
- shared_config_gameconfig
- Kit.box
- Services/Data.luau
- Piano tecnico — architettura e implementazione
- Bilanciamento — numeri, prezzi e sblocchi
- World.luau
- 8. Progressione
- Sakura Ramen & Sushi Tycoon — Game Design Document
- Camera.luau
- 5. Cucina
- Signal.luau
- 9. Costruzione e decorazione
- 10. Sistemi di gioco
- 5. Catalogo oggetti piazzabili
- Controllers/Interaction.luau
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- 7. Salvataggi
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- shared_util_color
- Events.luau
- Supply.luau
- HUD.refresh
- Controllers/Audio.luau
- People.luau
- Gifts.luau
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- Screens/Build.luau
- preview.py
- Locale.t
- check_luau.py
- build_place.py
- Guide.luau
- sys
- UI.luau
- Tutorial.luau
- HUD.luau
- check_scopes
- build_tree
- WorldUI.luau
- 10. Interfaccia

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 97 edges
2. `Kit.cyl()` - 58 edges
3. `nc()` - 53 edges
4. `Kit.blob()` - 36 edges
5. `Kit.part()` - 35 edges
6. `Color.hex()` - 35 edges
7. `Scene.shell()` - 34 edges
8. `Kit.finish()` - 32 edges
9. `Kit.new()` - 31 edges
10. `add()` - 29 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `overflowSlots()` --calls--> `World.fixedRects()`  [INFERRED]
  src/server/Services/Supply.luau → src/server/Services/World.luau
- `speed()` --calls--> `Formulas.staffSpeed()`  [INFERRED]
  src/server/Services/Staff.luau → src/shared/Logic/Formulas.luau
- `review()` --calls--> `Economy.addSakura()`  [INFERRED]
  src/server/Services/Customers.luau → src/server/Services/Economy.luau
- `Placement.validate()` --calls--> `Walls.along()`  [INFERRED]
  src/shared/Logic/Placement.luau → src/shared/Logic/Walls.luau

## Import Cycles
- None detected.

## Communities (84 total, 33 thin omitted)

### Community 0 - "Cooking.luau"
Cohesion: 0.18
Nodes (27): animateStep(), attachment(), boardKey(), broadcast(), clearBoardModels(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init() (+19 more)

### Community 1 - "Cooking.luau"
Cohesion: 0.05
Nodes (100): 12. Interfaccia e lingue, Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile() (+92 more)

### Community 2 - "Services/Customers.luau"
Cohesion: 0.05
Nodes (60): bumpCombo(), chooseOrder(), data(), dirtyNear(), dishKind(), eat(), entrance(), floorPos() (+52 more)

### Community 3 - "Services/Placement.luau"
Cohesion: 0.05
Nodes (71): Data.changed(), Data.get(), Economy.add(), Economy.addSakura(), Economy.boostActive(), Economy.charge(), Economy.Init(), Economy.resetLedger() (+63 more)

### Community 4 - "Color.hex"
Cohesion: 0.27
Nodes (7): burst(), comboBanner(), confetti(), Effects.Init(), popup(), ingColor(), Color.hex()

### Community 5 - "Scene.shell"
Cohesion: 0.08
Nodes (29): World.surfaceOf(), Footprint.subtractRect(), B.doorFrame(), B.eave(), B.facadeDetail(), B.floorSkin(), B.openSign(), B.parapet() (+21 more)

### Community 6 - "Day.luau"
Cohesion: 0.40
Nodes (11): data(), Day.broadcast(), Day.closeEarly(), Day.Init(), Day.next(), Day.open(), Day.Start(), finish() (+3 more)

### Community 7 - "Kit.new"
Cohesion: 0.24
Nodes (31): FirstPerson.Init(), UI.Init(), UI.toast(), Kit.bar(), Kit.button(), Kit.card(), Kit.corner(), Kit.goldLine() (+23 more)

### Community 8 - "re"
Cohesion: 0.25
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.11
Nodes (39): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.Init(), Build.place(), Build.removeSelected() (+31 more)

### Community 12 - "shared_config_gameconfig"
Cohesion: 0.11
Nodes (5): allowed(), Dev.Init(), run(), SelfTest.run(), waitFor()

### Community 13 - "Kit.box"
Cohesion: 0.06
Nodes (156): B.entranceDetail(), B.entranceNoren(), bonsai(), chochin(), foliage(), frame(), lanternString(), maneki() (+148 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.06
Nodes (43): Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save(), Data.saveNow(), Data.snapshot(), Data.Start() (+35 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.12
Nodes (17): 11. Costruzione e griglia, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro, 2. Struttura del progetto (+9 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "World.luau"
Cohesion: 0.06
Nodes (27): Ambient.Start(), offset(), track(), buildShell(), buildStreet(), folder(), geo(), World.ctx() (+19 more)

### Community 18 - "8. Progressione"
Cohesion: 0.17
Nodes (12): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 Espansioni, 8.6 Personale (automazione), 8.7 Guadagni offline (+4 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 21 - "Camera.luau"
Cohesion: 0.25
Nodes (17): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.setBuildView(), Camera.setTop() (+9 more)

### Community 22 - "5. Cucina"
Cohesion: 0.29
Nodes (7): 5.1 Ordini, 5.2 Preparare il sushi (postazione sushi / tagliere), 5.3 Preparare il ramen (postazione ramen), 5.4 Altre postazioni (sbloccate con licenze), 5.5 Velocità e freschezza, 5.6 Servire, pagare, pulire, 5. Cucina

### Community 24 - "Signal.luau"
Cohesion: 0.38
Nodes (3): Signal:Connect(), Signal:Once(), Signal:Wait()

### Community 25 - "9. Costruzione e decorazione"
Cohesion: 0.33
Nodes (6): 9.1 Modalità costruzione, 9.2 Tipi di piazzamento, 9.3 Regole di validità, 9.4 Pavimenti e pareti, 9.5 Ambiente, 9. Costruzione e decorazione

### Community 26 - "10. Sistemi di gioco"
Cohesion: 0.33
Nodes (6): 10. Sistemi di gioco, Clienti (macchina a stati), Giornata ed economia, Interazione, Personale (bacheca dei compiti), Preparazione a clic

### Community 27 - "5. Catalogo oggetti piazzabili"
Cohesion: 0.29
Nodes (7): 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino, 5.3 Decorazioni, 5.4 Pavimenti e pareti (per zona), 5.5 Livelli di ambiente, 5. Catalogo oggetti piazzabili, Pacchetto Ramen-ya (ispirato ai banconi dei ramen-ya veri)

### Community 28 - "Controllers/Interaction.luau"
Cohesion: 0.22
Nodes (13): act(), actionText(), aimingCenter(), castAt(), findTarget(), handsKind(), hrp(), inRange() (+5 more)

### Community 29 - "4. Rifornimento: tablet, consegne, magazzino, mensole"
Cohesion: 0.40
Nodes (5): 4.1 Tablet ordini (Fornitore), 4.2 Consegna, 4.3 Dal magazzino alle mensole, 4.4 Preparazioni di base, 4. Rifornimento: tablet, consegne, magazzino, mensole

### Community 30 - "2. Il mondo"
Cohesion: 0.50
Nodes (4): 2.1 Struttura delle sessioni (mondo personale), 2.2 La strada (yokochō), 2.3 Il ristorante iniziale, 2. Il mondo

### Community 31 - "3. Ciclo di gioco"
Cohesion: 0.50
Nodes (4): 3.1 Il ciclo principale (loop), 3.2 La giornata, 3.3 Interazione "basta cliccare", 3. Ciclo di gioco

### Community 32 - "6. Clienti"
Cohesion: 0.50
Nodes (4): 6.1 Comportamento, 6.2 Tipi di cliente, 6.3 Valutazione del ristorante, 6. Clienti

### Community 33 - "7. Salvataggi"
Cohesion: 0.50
Nodes (4): 7. Salvataggi, Regole, Replica al client, Schema (versione 1)

### Community 34 - "Net/init.luau"
Cohesion: 0.83
Nodes (3): getFolder(), Net.event(), Net.func()

### Community 36 - "shared_util_color"
Cohesion: 0.21
Nodes (7): blend(), LightingC.Init(), LightingC.Start(), look(), track(), launch(), Phone.open()

### Community 48 - "Supply.luau"
Cohesion: 0.08
Nodes (36): zoneHere(), Placement.addVeto(), busy(), closestPoint(), free(), gap(), Seating.benchSpot(), Seating.find() (+28 more)

### Community 64 - "HUD.refresh"
Cohesion: 0.17
Nodes (19): Data.applyLanguage(), Data.canBuild(), Data.Init(), Data.m(), Data.role(), Data.Start(), Data.w(), Data.wallet() (+11 more)

### Community 65 - "Controllers/Audio.luau"
Cohesion: 0.18
Nodes (17): runTrain(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start(), Audio.step(), Audio.trainVolume(), customersInside() (+9 more)

### Community 66 - "People.luau"
Cohesion: 0.22
Nodes (36): add(), apron(), backpack(), ball(), belt(), blob(), body(), c() (+28 more)

### Community 67 - "Gifts.luau"
Cohesion: 0.70
Nodes (4): claimedSet(), elapsed(), nextGift(), screen.tick()

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.29
Nodes (7): Anteprima dei modelli (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Struttura

### Community 70 - "Screens/Build.luau"
Cohesion: 0.18
Nodes (13): Icons.forItem(), Kit.clear(), itemCard(), itemLocked(), renderItems(), renderTabs(), Screen.open(), Screen.refresh() (+5 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Locale.t"
Cohesion: 0.24
Nodes (6): Kit.T(), Locale.has(), Locale.name(), Locale.resolve(), Locale.set(), Locale.t()

### Community 73 - "check_luau.py"
Cohesion: 0.24
Nodes (8): check_blocks(), check_locale(), check_requires(), load_locale(), long_bracket(), main(), Tok, tokenize()

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Guide.luau"
Cohesion: 0.24
Nodes (15): clearMarks(), distance(), Guide.close(), Guide.create(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show() (+7 more)

### Community 77 - "UI.luau"
Cohesion: 0.07
Nodes (47): active(), clearViews(), FirstPerson.cursorFree(), FirstPerson.Start(), setHeldLabels(), shortcut(), syncViews(), updateCrosshair() (+39 more)

### Community 78 - "Tutorial.luau"
Cohesion: 0.47
Nodes (8): advance(), findTarget(), save(), show(), Tutorial.Init(), Tutorial.onAction(), Tutorial.restart(), Tutorial.Start()

### Community 79 - "HUD.luau"
Cohesion: 0.28
Nodes (5): HUD.refreshGift(), HUD.refreshHands(), HUD.setBuilding(), keyHint(), Format.duration()

### Community 81 - "build_tree"
Cohesion: 0.50
Nodes (4): build_tree(), add_path(), walk(), rojo_name()

### Community 82 - "WorldUI.luau"
Cohesion: 0.46
Nodes (7): icons(), make(), setBar(), updateEntity(), updateShelf(), updateStaff(), WorldUI.Start()

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

## Knowledge Gaps
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `refresh()` connect `Cooking.luau` to `Color.hex`?**
  _High betweenness centrality (0.132) - this node is a cross-community bridge._
- **Are the 92 inferred relationships involving `Kit.box()` (e.g. with `B.doorFrame()` and `B.eave()`) actually correct?**
  _`Kit.box()` has 92 INFERRED edges - model-reasoned connections that need verification._
- **Should `Cooking.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.051209341117598 - nodes in this community are weakly interconnected._
- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `Cooking.luau`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`, `7. Salvataggi`?**
  _High betweenness centrality (0.126) - this node is a cross-community bridge._
- **Are the 56 inferred relationships involving `Kit.cyl()` (e.g. with `B.entranceDetail()` and `B.openSign()`) actually correct?**
  _`Kit.cyl()` has 56 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Customers.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05289193302891933 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Cooking.luau` to `Piano tecnico — architettura e implementazione`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._