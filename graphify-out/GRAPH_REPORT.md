# Graph Report - Roblox-Ramen-game  (2026-11-15)

## Corpus Check
- 119 files · ~110,940 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1059 nodes · 2583 edges · 72 communities (42 shown, 30 thin omitted)
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 607 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8953fdb6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Kit.box
- Services/Staff.luau
- Services/Customers.luau
- Services/Placement.luau
- shared_locale
- Services/Data.luau
- Session.luau
- Kit.new
- check_luau.py
- Seating.luau
- World.luau
- Controllers/Build.luau
- Cooking.luau
- script_parent_parent_core
- Supply.luau
- Piano tecnico — architettura e implementazione
- Bilanciamento — numeri, prezzi e sblocchi
- Day.luau
- 8. Progressione
- Sakura Ramen & Sushi Tycoon — Game Design Document
- Camera.luau
- 5. Cucina
- Signal.luau
- 9. Costruzione e decorazione
- 10. Sistemi di gioco
- 5. Catalogo oggetti piazzabili
- Formulas.luau
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- 7. Salvataggi
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- 1. Visione
- Events.luau
- Npc.luau
- Logic/Placement.luau
- Placement.validate
- Walls.luau
- People.luau
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- shared_models_registry
- spawnLoop

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 58 edges
2. `Kit.finish()` - 32 edges
3. `Color.hex()` - 32 edges
4. `buildShell()` - 29 edges
5. `Kit.cyl()` - 29 edges
6. `Kit.new()` - 23 edges
7. `dish()` - 21 edges
8. `Hands.get()` - 19 edges
9. `Placement.validate()` - 18 edges
10. `Piano tecnico — architettura e implementazione` - 18 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `Interaction.highlightRecipe()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Interaction.luau → src/shared/Util/Color.luau
- `Interaction.Init()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Interaction.luau → src/shared/Util/Color.luau
- `runTrain()` --calls--> `S.train()`  [INFERRED]
  src/client/Controllers/Ambient.luau → src/shared/Models/Builders/Street.luau
- `Build.Init()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Build.luau → src/shared/Util/Color.luau

## Import Cycles
- None detected.

## Communities (72 total, 30 thin omitted)

### Community 0 - "Kit.box"
Cohesion: 0.07
Nodes (95): buildShell(), buildStreet(), B.doorFrame(), B.eave(), B.entranceNoren(), B.floorSkin(), B.openSign(), B.parapet() (+87 more)

### Community 1 - "Services/Staff.luau"
Cohesion: 0.07
Nodes (75): 12. Interfaccia e lingue, Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile() (+67 more)

### Community 2 - "Services/Customers.luau"
Cohesion: 0.12
Nodes (28): chooseOrder(), data(), dirtyNear(), dishKind(), eat(), entrance(), floorPos(), leaveDirty() (+20 more)

### Community 3 - "Services/Placement.luau"
Cohesion: 0.05
Nodes (70): Economy.add(), Economy.addSakura(), Economy.boostActive(), Economy.charge(), Economy.Init(), Economy.multiplier(), Economy.resetLedger(), Economy.spend() (+62 more)

### Community 4 - "shared_locale"
Cohesion: 0.09
Nodes (3): allowed(), Dev.Init(), run()

### Community 5 - "Services/Data.luau"
Cohesion: 0.07
Nodes (41): Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save(), Data.saveNow() (+33 more)

### Community 6 - "Session.luau"
Cohesion: 0.34
Nodes (15): allowedGuest(), becomeOwner(), broadcastInfo(), onLobbyPlayer(), onWorldPlayer(), safe(), Session.canWork(), Session.info() (+7 more)

### Community 7 - "Kit.new"
Cohesion: 0.05
Nodes (77): Data.applyLanguage(), Data.canBuild(), Data.Init(), Data.m(), Data.role(), Data.Start(), Data.w(), Data.wallet() (+69 more)

### Community 8 - "check_luau.py"
Cohesion: 0.07
Nodes (25): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class() (+17 more)

### Community 9 - "Seating.luau"
Cohesion: 0.15
Nodes (12): busy(), closestPoint(), free(), gap(), Seating.benchSpot(), Seating.find(), Seating.freeBench(), Seating.freeCount() (+4 more)

### Community 10 - "World.luau"
Cohesion: 0.13
Nodes (15): folder(), holesFor(), indoorAt(), style(), subtractAll(), World.fixedRects(), World.floorY(), World.Init() (+7 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.11
Nodes (37): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.Init(), Build.place(), Build.removeSelected() (+29 more)

### Community 12 - "Cooking.luau"
Cohesion: 0.12
Nodes (28): animateStep(), attachment(), boardKey(), broadcast(), clearBoardModels(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init() (+20 more)

### Community 13 - "script_parent_parent_core"
Cohesion: 0.06
Nodes (39): Audio.play(), Audio.Start(), volume(), burst(), confetti(), Effects.Init(), popup(), act() (+31 more)

### Community 14 - "Supply.luau"
Cohesion: 0.20
Nodes (22): autoRestock(), boxModel(), chooseSlot(), data(), deliveryLoop(), deliveryTime(), ingUnlocked(), overflowSlots() (+14 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.12
Nodes (17): 11. Costruzione e griglia, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro, 2. Struttura del progetto (+9 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.13
Nodes (15): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+7 more)

### Community 17 - "Day.luau"
Cohesion: 0.40
Nodes (11): data(), Day.broadcast(), Day.closeEarly(), Day.Init(), Day.next(), Day.open(), Day.Start(), finish() (+3 more)

### Community 18 - "8. Progressione"
Cohesion: 0.18
Nodes (11): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 Espansioni, 8.6 Personale (automazione), 8.7 Guadagni offline (+3 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.22
Nodes (9): 0. Decisioni già prese, 10. Interfaccia, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 7. Menu e prezzi, Sakura Ramen & Sushi Tycoon — Game Design Document (+1 more)

### Community 21 - "Camera.luau"
Cohesion: 0.46
Nodes (6): Camera.currentFloor(), Camera.setBuildView(), Camera.setTop(), Camera.Start(), Camera.toggleTop(), setRoofs()

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
Cohesion: 0.33
Nodes (6): 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino, 5.3 Decorazioni, 5.4 Pavimenti e pareti (per zona), 5.5 Livelli di ambiente, 5. Catalogo oggetti piazzabili

### Community 28 - "Formulas.luau"
Cohesion: 0.17
Nodes (17): Progression.addXp(), Progression.priceOf(), Formulas.addXp(), Formulas.dishPrice(), Formulas.levelReward(), Formulas.masteryLevel(), Formulas.offlineEarnings(), Formulas.popularity() (+9 more)

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

### Community 36 - "1. Visione"
Cohesion: 0.67
Nodes (3): 1. Visione, Durata prevista, Pilastri

### Community 64 - "Npc.luau"
Cohesion: 0.19
Nodes (11): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.spawn(), Npc.stand() (+3 more)

### Community 65 - "Logic/Placement.luau"
Cohesion: 0.22
Nodes (9): Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY(), Placement.footprint(), Placement.pathOk(), Placement.pathTargets() (+1 more)

### Community 66 - "Placement.validate"
Cohesion: 0.36
Nodes (12): Footprint.axes(), Footprint.bounds(), Footprint.corners(), Footprint.insideRects(), Footprint.new(), Footprint.overlaps(), Footprint.pointIn(), Footprint.pointInRect() (+4 more)

### Community 67 - "Walls.luau"
Cohesion: 0.24
Nodes (9): World.ctx(), Geometry.compute(), Geometry.ctx(), cut(), floorCells(), key(), merge(), Walls.along() (+1 more)

### Community 68 - "People.luau"
Cohesion: 0.61
Nodes (8): at(), People.apron(), People.bag(), People.dress(), People.glasses(), People.hair(), People.hat(), weld()

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.33
Nodes (6): Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Struttura

### Community 70 - "shared_models_registry"
Cohesion: 0.47
Nodes (4): Ambient.Start(), offset(), runTrain(), track()

### Community 71 - "spawnLoop"
Cohesion: 0.50
Nodes (4): serveQueue(), spawnLoop(), Day.isPeak(), Formulas.customerInterval()

## Knowledge Gaps
- **30 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `refresh()` connect `Services/Staff.luau` to `Kit.box`?**
  _High betweenness centrality (0.156) - this node is a cross-community bridge._
- **Are the 53 inferred relationships involving `Kit.box()` (e.g. with `buildShell()` and `buildStreet()`) actually correct?**
  _`Kit.box()` has 53 INFERRED edges - model-reasoned connections that need verification._
- **Should `Kit.box` be split into smaller, more focused modules?**
  _Cohesion score 0.06660231660231661 - nodes in this community are weakly interconnected._
- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `Services/Staff.luau`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`, `7. Salvataggi`?**
  _High betweenness centrality (0.145) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `Kit.finish()` (e.g. with `bonsai()` and `chochin()`) actually correct?**
  _`Kit.finish()` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Staff.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.0653417645287564 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Services/Staff.luau` to `Piano tecnico — architettura e implementazione`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._