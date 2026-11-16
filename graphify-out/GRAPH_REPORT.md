# Graph Report - Roblox-Ramen-game  (2026-11-16)

## Corpus Check
- 128 files · ~132,950 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1182 nodes · 2900 edges · 69 communities (38 shown, 31 thin omitted)
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 700 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cf54edb9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Services/Staff.luau
- Services/Customers.luau
- Services/Placement.luau
- shared_locale
- Session.luau
- Kit.new
- re
- mock.lua
- World.luau
- Controllers/Build.luau
- Services/Staff.luau
- Kit.box
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
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- 7. Salvataggi
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- Events.luau
- Scene.luau
- Services/Data.luau
- Leaderboard.luau
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- preview.py
- check_luau.py
- build_place.py
- sys
- check_scopes
- build_tree

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 76 edges
2. `Kit.cyl()` - 40 edges
3. `Scene.shell()` - 34 edges
4. `Color.hex()` - 33 edges
5. `Kit.finish()` - 32 edges
6. `Kit.new()` - 25 edges
7. `Scene.street()` - 24 edges
8. `Kit.text()` - 22 edges
9. `Kit.cylH()` - 21 edges
10. `dish()` - 21 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `Build.Init()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Build.luau → src/shared/Util/Color.luau
- `Placement.place()` --calls--> `Economy.spendSakura()`  [INFERRED]
  src/server/Services/Placement.luau → src/server/Services/Economy.luau
- `Progression.rating()` --calls--> `Formulas.rating()`  [INFERRED]
  src/server/Services/Progression.luau → src/shared/Logic/Formulas.luau
- `washHeld()` --calls--> `Appliance.addDirtyToSink()`  [INFERRED]
  src/server/Services/Staff.luau → src/server/Services/Appliance.luau

## Import Cycles
- None detected.

## Communities (69 total, 31 thin omitted)

### Community 1 - "Services/Staff.luau"
Cohesion: 0.07
Nodes (66): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile(), Appliance.takeBroth() (+58 more)

### Community 2 - "Services/Customers.luau"
Cohesion: 0.05
Nodes (60): chooseOrder(), data(), dirtyNear(), dishKind(), eat(), entrance(), floorPos(), leaveDirty() (+52 more)

### Community 3 - "Services/Placement.luau"
Cohesion: 0.06
Nodes (54): open(), Service.check(), Net.fireAll(), Net.fx(), Net.fxTo(), Net.notify(), Net.notifyAll(), Net.num() (+46 more)

### Community 4 - "shared_locale"
Cohesion: 0.06
Nodes (32): Audio.play(), Audio.Start(), volume(), burst(), confetti(), Effects.Init(), popup(), act() (+24 more)

### Community 6 - "Session.luau"
Cohesion: 0.34
Nodes (15): allowedGuest(), becomeOwner(), broadcastInfo(), onLobbyPlayer(), onWorldPlayer(), safe(), Session.canWork(), Session.info() (+7 more)

### Community 7 - "Kit.new"
Cohesion: 0.05
Nodes (80): Data.applyLanguage(), Data.canBuild(), Data.Init(), Data.m(), Data.role(), Data.Start(), Data.w(), Data.wallet() (+72 more)

### Community 8 - "re"
Cohesion: 0.25
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "World.luau"
Cohesion: 0.05
Nodes (27): Ambient.Start(), offset(), track(), allowed(), Dev.Init(), run(), SelfTest.run(), waitFor() (+19 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.10
Nodes (39): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.Init(), Build.place(), Build.removeSelected() (+31 more)

### Community 12 - "Services/Staff.luau"
Cohesion: 0.14
Nodes (40): carryBoxTo(), customerEntity(), data(), deliverDish(), despawnActor(), doCollect(), doCook(), doOrder() (+32 more)

### Community 13 - "Kit.box"
Cohesion: 0.06
Nodes (132): runTrain(), Interaction.highlightRecipe(), Interaction.Init(), B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail() (+124 more)

### Community 14 - "Supply.luau"
Cohesion: 0.06
Nodes (55): Placement.addVeto(), busy(), closestPoint(), free(), gap(), Seating.benchSpot(), Seating.find(), Seating.freeBench() (+47 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (18): 11. Costruzione e griglia, 12. Interfaccia e lingue, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro (+10 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "Day.luau"
Cohesion: 0.40
Nodes (11): data(), Day.broadcast(), Day.closeEarly(), Day.Init(), Day.next(), Day.open(), Day.Start(), finish() (+3 more)

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
Cohesion: 0.33
Nodes (6): 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino, 5.3 Decorazioni, 5.4 Pavimenti e pareti (per zona), 5.5 Livelli di ambiente, 5. Catalogo oggetti piazzabili

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

### Community 48 - "Scene.luau"
Cohesion: 0.06
Nodes (13): World.surfaceOf(), Footprint.subtractRect(), fitOverride(), override(), Registry.build(), facadeColor(), floorY(), holesFor() (+5 more)

### Community 65 - "Services/Data.luau"
Cohesion: 0.05
Nodes (52): Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save(), Data.saveNow() (+44 more)

### Community 66 - "Leaderboard.luau"
Cohesion: 0.53
Nodes (5): fetch(), Leaderboard.Init(), Leaderboard.Start(), nameOf(), submit()

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.29
Nodes (7): Anteprima dei modelli (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Struttura

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

- **Why does `refresh()` connect `Services/Staff.luau` to `Kit.box`, `Piano tecnico — architettura e implementazione`?**
  _High betweenness centrality (0.156) - this node is a cross-community bridge._
- **Are the 71 inferred relationships involving `Kit.box()` (e.g. with `B.doorFrame()` and `B.eave()`) actually correct?**
  _`Kit.box()` has 71 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Staff.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07003129890453834 - nodes in this community are weakly interconnected._
- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `7. Salvataggi`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`?**
  _High betweenness centrality (0.155) - this node is a cross-community bridge._
- **Are the 38 inferred relationships involving `Kit.cyl()` (e.g. with `B.entranceDetail()` and `B.openSign()`) actually correct?**
  _`Kit.cyl()` has 38 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Customers.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05289193302891933 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Piano tecnico — architettura e implementazione` to `Services/Staff.luau`?**
  _High betweenness centrality (0.152) - this node is a cross-community bridge._