# Graph Report - Roblox-Ramen-game  (2026-11-16)

## Corpus Check
- 129 files · ~145,723 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1240 nodes · 3233 edges · 77 communities (46 shown, 31 thin omitted)
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 795 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e16e71de`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Cooking.luau
- Services/Staff.luau
- Services/Customers.luau
- Services/Placement.luau
- shared_locale
- Npc.luau
- Session.luau
- Kit.new
- re
- mock.lua
- script_parent_parent_kit
- Controllers/Build.luau
- Seating.luau
- Kit.box
- logic_spec.lua
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
- Formulas.luau
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- 7. Salvataggi
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- run
- Events.luau
- Scene.luau
- Registry.luau
- Services/Data.luau
- People.luau
- shared_models_registry
- Grid.luau
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- spawnLoop
- preview.py
- check_luau.py
- build_place.py
- sys
- check_scopes
- build_tree

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 97 edges
2. `Kit.cyl()` - 58 edges
3. `nc()` - 53 edges
4. `Kit.part()` - 38 edges
5. `Kit.blob()` - 35 edges
6. `Scene.shell()` - 34 edges
7. `Kit.finish()` - 32 edges
8. `Color.hex()` - 31 edges
9. `dish()` - 27 edges
10. `Kit.new()` - 25 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `Service.collectDirty()` --calls--> `Hands.add()`  [INFERRED]
  src/server/Services/Customers.luau → src/server/Services/Hands.luau
- `speed()` --calls--> `Formulas.staffSpeed()`  [INFERRED]
  src/server/Services/Staff.luau → src/shared/Logic/Formulas.luau
- `runTrain()` --calls--> `S.train()`  [INFERRED]
  src/client/Controllers/Ambient.luau → src/shared/Models/Builders/Street.luau
- `overflowSlots()` --calls--> `World.fixedRects()`  [INFERRED]
  src/server/Services/Supply.luau → src/server/Services/World.luau

## Import Cycles
- None detected.

## Communities (77 total, 31 thin omitted)

### Community 0 - "Cooking.luau"
Cohesion: 0.18
Nodes (27): animateStep(), attachment(), boardKey(), broadcast(), clearBoardModels(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init() (+19 more)

### Community 1 - "Services/Staff.luau"
Cohesion: 0.05
Nodes (94): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile(), Appliance.takeBroth() (+86 more)

### Community 2 - "Services/Customers.luau"
Cohesion: 0.15
Nodes (20): chooseOrder(), data(), dirtyNear(), dishKind(), eat(), pay(), pickType(), release() (+12 more)

### Community 3 - "Services/Placement.luau"
Cohesion: 0.05
Nodes (69): Data.changed(), Economy.add(), Economy.boostActive(), Economy.charge(), Economy.Init(), Economy.resetLedger(), Economy.spend(), Economy.spendSakura() (+61 more)

### Community 4 - "shared_locale"
Cohesion: 0.05
Nodes (53): Audio.play(), Audio.Start(), volume(), Build.Init(), burst(), confetti(), Effects.Init(), popup() (+45 more)

### Community 5 - "Npc.luau"
Cohesion: 0.22
Nodes (8): describe(), loadAnims(), Npc.acquireCustomer(), Npc.create(), Npc.sit(), Npc.spawn(), Npc.Start(), setupAnimator()

### Community 6 - "Session.luau"
Cohesion: 0.34
Nodes (15): allowedGuest(), becomeOwner(), broadcastInfo(), onLobbyPlayer(), onWorldPlayer(), safe(), Session.canWork(), Session.info() (+7 more)

### Community 7 - "Kit.new"
Cohesion: 0.07
Nodes (57): Tutorial.Init(), UI.close(), UI.Init(), UI.open(), UI.refreshAll(), UI.register(), UI.Start(), UI.toast() (+49 more)

### Community 8 - "re"
Cohesion: 0.25
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "script_parent_parent_kit"
Cohesion: 0.06
Nodes (37): Data.applyLanguage(), Data.canBuild(), Data.Init(), Data.m(), Data.role(), Data.Start(), Data.w(), Data.wallet() (+29 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.15
Nodes (29): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.place(), Build.removeSelected(), Build.select() (+21 more)

### Community 12 - "Seating.luau"
Cohesion: 0.19
Nodes (6): Placement.addVeto(), busy(), free(), Seating.find(), Seating.freeCount(), Seating.Init()

### Community 13 - "Kit.box"
Cohesion: 0.05
Nodes (174): B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.openSign(), B.parapet() (+166 more)

### Community 14 - "logic_spec.lua"
Cohesion: 0.11
Nodes (5): allowed(), Dev.Init(), run(), SelfTest.run(), waitFor()

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (18): 11. Costruzione e griglia, 12. Interfaccia e lingue, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro (+10 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "World.luau"
Cohesion: 0.14
Nodes (14): buildShell(), buildStreet(), folder(), geo(), World.ctx(), World.fixedRects(), World.floorY(), World.Init() (+6 more)

### Community 18 - "8. Progressione"
Cohesion: 0.17
Nodes (12): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 Espansioni, 8.6 Personale (automazione), 8.7 Guadagni offline (+4 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.17
Nodes (12): 0. Decisioni già prese, 10. Interfaccia, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi (+4 more)

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
Cohesion: 0.29
Nodes (7): 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino, 5.3 Decorazioni, 5.4 Pavimenti e pareti (per zona), 5.5 Livelli di ambiente, 5. Catalogo oggetti piazzabili, Pacchetto Ramen-ya (ispirato ai banconi dei ramen-ya veri)

### Community 28 - "Formulas.luau"
Cohesion: 0.20
Nodes (15): Progression.addXp(), Progression.priceOf(), Formulas.addXp(), Formulas.dishPrice(), Formulas.levelReward(), Formulas.masteryLevel(), Formulas.offlineEarnings(), Formulas.questTarget() (+7 more)

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

### Community 36 - "run"
Cohesion: 0.17
Nodes (15): entrance(), floorPos(), leaveDirty(), leaveRestaurant(), patienceTick(), run(), setOrder(), moveTo() (+7 more)

### Community 48 - "Scene.luau"
Cohesion: 0.05
Nodes (43): Placement.near(), closestPoint(), gap(), Seating.refresh(), topY(), World.surfaceOf(), Footprint.axes(), Footprint.bounds() (+35 more)

### Community 64 - "Registry.luau"
Cohesion: 0.22
Nodes (3): fitOverride(), override(), Registry.build()

### Community 65 - "Services/Data.luau"
Cohesion: 0.11
Nodes (28): Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save(), Data.saveNow(), Data.snapshot() (+20 more)

### Community 66 - "People.luau"
Cohesion: 0.61
Nodes (8): at(), People.apron(), People.bag(), People.dress(), People.glasses(), People.hair(), People.hat(), weld()

### Community 67 - "shared_models_registry"
Cohesion: 0.38
Nodes (5): Ambient.Start(), offset(), runTrain(), track(), Registry.load()

### Community 68 - "Grid.luau"
Cohesion: 0.39
Nodes (7): Build.rotate(), Grid.aabb(), Grid.nextRotation(), Grid.normRot(), Grid.snapFloor(), Grid.snapValue(), Grid.snapWall()

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.29
Nodes (7): Anteprima dei modelli (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Struttura

### Community 70 - "spawnLoop"
Cohesion: 0.50
Nodes (4): serveQueue(), spawnLoop(), Day.isPeak(), Formulas.customerInterval()

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 73 - "check_luau.py"
Cohesion: 0.24
Nodes (8): check_blocks(), check_locale(), check_requires(), load_locale(), long_bracket(), main(), Tok, tokenize()

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 81 - "build_tree"
Cohesion: 0.50
Nodes (4): build_tree(), add_path(), walk(), rojo_name()

## Knowledge Gaps
- **31 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `refresh()` connect `Services/Staff.luau` to `shared_locale`, `Piano tecnico — architettura e implementazione`?**
  _High betweenness centrality (0.136) - this node is a cross-community bridge._
- **Are the 92 inferred relationships involving `Kit.box()` (e.g. with `B.doorFrame()` and `B.eave()`) actually correct?**
  _`Kit.box()` has 92 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Staff.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05347985347985348 - nodes in this community are weakly interconnected._
- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `7. Salvataggi`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Are the 56 inferred relationships involving `Kit.cyl()` (e.g. with `B.entranceDetail()` and `B.openSign()`) actually correct?**
  _`Kit.cyl()` has 56 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Placement.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05225718194254446 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Piano tecnico — architettura e implementazione` to `Services/Staff.luau`?**
  _High betweenness centrality (0.127) - this node is a cross-community bridge._