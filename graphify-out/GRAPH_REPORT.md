# Graph Report - Roblox-Ramen-game  (2026-11-16)

## Corpus Check
- 131 files · ~158,878 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1314 nodes · 3500 edges · 100 communities (65 shown, 35 thin omitted)
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 828 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ded9dff6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Cooking.luau
- Services/Staff.luau
- Services/Customers.luau
- Services/Placement.luau
- Color.hex
- Scene.shell
- Day.luau
- Kit.new
- re
- mock.lua
- Controllers/Build.luau
- Walls.luau
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
- Formulas.luau
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- 7. Salvataggi
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- HUD.refresh
- Events.luau
- Scene.luau
- Registry.luau
- Meta.luau
- People.luau
- shared_models_registry
- Grid.luau
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- Npc.luau
- preview.py
- Screens/Build.luau
- check_luau.py
- build_place.py
- Guide.luau
- sys
- UI.luau
- Locale.t
- Progression.luau
- check_scopes
- build_tree
- Services/Monetization.luau
- step
- Controllers/Interaction.luau
- Net.notify
- Net.luau
- data
- script_parent_parent_core
- Tutorial.luau
- Economy.luau
- Geometry.compute
- shared_config_expansions
- HUD.luau
- Phone.luau
- Leaderboard.luau
- Net.on
- 10. Interfaccia
- Ambience.compute

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 97 edges
2. `Kit.cyl()` - 58 edges
3. `nc()` - 53 edges
4. `Kit.blob()` - 36 edges
5. `Kit.part()` - 35 edges
6. `Scene.shell()` - 34 edges
7. `Color.hex()` - 34 edges
8. `Kit.finish()` - 32 edges
9. `Kit.new()` - 30 edges
10. `add()` - 29 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `HUD.refreshTickets()` --calls--> `Format.duration()`  [INFERRED]
  src/client/UI/Screens/HUD.luau → src/shared/Util/Format.luau
- `chooseOrder()` --calls--> `Formulas.demandFactor()`  [INFERRED]
  src/server/Services/Customers.luau → src/shared/Logic/Formulas.luau
- `run()` --calls--> `Npc.sit()`  [INFERRED]
  src/server/Services/Customers.luau → src/server/Services/Npc.luau
- `Service.collectDirty()` --calls--> `Hands.add()`  [INFERRED]
  src/server/Services/Customers.luau → src/server/Services/Hands.luau

## Import Cycles
- None detected.

## Communities (100 total, 35 thin omitted)

### Community 0 - "Cooking.luau"
Cohesion: 0.18
Nodes (28): animateStep(), attachment(), boardKey(), broadcast(), clearBoardModels(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init() (+20 more)

### Community 1 - "Services/Staff.luau"
Cohesion: 0.06
Nodes (78): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile(), Appliance.takeBroth() (+70 more)

### Community 2 - "Services/Customers.luau"
Cohesion: 0.14
Nodes (20): dishKind(), eat(), entrance(), floorPos(), leaveDirty(), leaveRestaurant(), patienceTick(), release() (+12 more)

### Community 3 - "Services/Placement.luau"
Cohesion: 0.25
Nodes (21): canAfford(), changed(), checkVetoes(), children(), despawn(), findEntry(), itemUnlocked(), ownerData() (+13 more)

### Community 4 - "Color.hex"
Cohesion: 0.09
Nodes (24): Audio.play(), Audio.Start(), volume(), Build.Init(), burst(), confetti(), Effects.Init(), popup() (+16 more)

### Community 5 - "Scene.shell"
Cohesion: 0.07
Nodes (29): World.surfaceOf(), Footprint.subtractRect(), B.doorFrame(), B.eave(), B.facadeDetail(), B.floorSkin(), B.openSign(), B.parapet() (+21 more)

### Community 6 - "Day.luau"
Cohesion: 0.40
Nodes (11): data(), Day.broadcast(), Day.closeEarly(), Day.Init(), Day.next(), Day.open(), Day.Start(), finish() (+3 more)

### Community 7 - "Kit.new"
Cohesion: 0.28
Nodes (27): Kit.bar(), Kit.button(), Kit.card(), Kit.corner(), Kit.goldLine(), Kit.grid(), Kit.label(), Kit.list() (+19 more)

### Community 8 - "re"
Cohesion: 0.25
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.26
Nodes (16): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.place(), Build.removeSelected(), Build.rotate(), Build.select() (+8 more)

### Community 12 - "Walls.luau"
Cohesion: 0.43
Nodes (6): cut(), floorCells(), key(), merge(), Walls.along(), Walls.compute()

### Community 13 - "Kit.box"
Cohesion: 0.06
Nodes (155): B.entranceDetail(), B.entranceNoren(), bonsai(), chochin(), foliage(), frame(), lanternString(), maneki() (+147 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.13
Nodes (35): Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save(), Data.saveNow() (+27 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (18): 11. Costruzione e griglia, 12. Interfaccia e lingue, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro (+10 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "World.luau"
Cohesion: 0.15
Nodes (12): buildShell(), buildStreet(), folder(), geo(), World.fixedRects(), World.floorY(), World.Init(), World.rebuild() (+4 more)

### Community 18 - "8. Progressione"
Cohesion: 0.17
Nodes (12): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 Espansioni, 8.6 Personale (automazione), 8.7 Guadagni offline (+4 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 21 - "Camera.luau"
Cohesion: 0.33
Nodes (12): Camera.applyRoofs(), Camera.currentFloor(), Camera.setBuildView(), Camera.setTop(), Camera.Start(), Camera.toggleTop(), clearDistance(), orbitLoop() (+4 more)

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
Cohesion: 0.11
Nodes (22): pay(), serveQueue(), spawnLoop(), Day.isPeak(), computeOffline(), applyProduct(), Progression.addXp(), Progression.priceOf() (+14 more)

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

### Community 36 - "HUD.refresh"
Cohesion: 0.18
Nodes (18): Data.applyLanguage(), Data.canBuild(), Data.Init(), Data.m(), Data.role(), Data.Start(), Data.w(), Data.wallet() (+10 more)

### Community 48 - "Scene.luau"
Cohesion: 0.07
Nodes (56): Placement.addVeto(), busy(), closestPoint(), free(), gap(), Seating.find(), Seating.freeCount(), Seating.Init() (+48 more)

### Community 64 - "Registry.luau"
Cohesion: 0.18
Nodes (6): SelfTest.run(), waitFor(), fitOverride(), override(), Registry.build(), Registry.place()

### Community 65 - "Meta.luau"
Cohesion: 0.15
Nodes (14): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), dayIndex(), ensureQuests(), Meta.dayEnded(), Meta.event() (+6 more)

### Community 66 - "People.luau"
Cohesion: 0.22
Nodes (36): add(), apron(), backpack(), ball(), belt(), blob(), body(), c() (+28 more)

### Community 67 - "shared_models_registry"
Cohesion: 0.47
Nodes (4): Ambient.Start(), offset(), runTrain(), track()

### Community 68 - "Grid.luau"
Cohesion: 0.33
Nodes (8): drawGrid(), gridLine(), Grid.aabb(), Grid.nextRotation(), Grid.normRot(), Grid.snapFloor(), Grid.snapValue(), Grid.snapWall()

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.29
Nodes (7): Anteprima dei modelli (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Struttura

### Community 70 - "Npc.luau"
Cohesion: 0.16
Nodes (12): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.sit(), Npc.spawn() (+4 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Screens/Build.luau"
Cohesion: 0.18
Nodes (11): Icons.forItem(), Kit.clear(), itemCard(), itemLocked(), renderItems(), renderTabs(), Screen.open(), Screen.refresh() (+3 more)

### Community 73 - "check_luau.py"
Cohesion: 0.24
Nodes (8): check_blocks(), check_locale(), check_requires(), load_locale(), long_bracket(), main(), Tok, tokenize()

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Guide.luau"
Cohesion: 0.24
Nodes (14): clearMarks(), distance(), Guide.close(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show(), hands() (+6 more)

### Community 77 - "UI.luau"
Cohesion: 0.24
Nodes (10): UI.close(), UI.Init(), UI.open(), UI.refreshAll(), UI.register(), UI.Start(), UI.toast(), UI.toggle() (+2 more)

### Community 78 - "Locale.t"
Cohesion: 0.19
Nodes (9): Kit.T(), effectText(), Locale.get(), Locale.has(), Locale.name(), Locale.resolve(), Locale.set(), Locale.t() (+1 more)

### Community 79 - "Progression.luau"
Cohesion: 0.32
Nodes (11): data(), owner(), Progression.addMastery(), Progression.addReview(), Progression.applyWalkSpeed(), Progression.isRecipeUnlocked(), Progression.menuRecipes(), Progression.popularity() (+3 more)

### Community 81 - "build_tree"
Cohesion: 0.50
Nodes (4): build_tree(), add_path(), walk(), rojo_name()

### Community 83 - "Services/Monetization.luau"
Cohesion: 0.23
Nodes (8): Economy.multiplier(), grantPass(), Monetization.has(), Monetization.Init(), Monetization.ownerHas(), Monetization.ownerYenMultiplier(), passCfg(), Formulas.incomeMultiplier()

### Community 84 - "step"
Cohesion: 0.27
Nodes (12): buildRequest(), cast(), cursor(), cursorRay(), floorY(), itemsFolder(), onFloor(), ownerModel() (+4 more)

### Community 85 - "Controllers/Interaction.luau"
Cohesion: 0.32
Nodes (10): act(), actionText(), castAt(), findTarget(), handsKind(), hrp(), inRange(), Interaction.Start() (+2 more)

### Community 86 - "Net.notify"
Cohesion: 0.36
Nodes (11): open(), Net.fireAll(), Net.fx(), Net.notify(), Net.notifyAll(), Placement.revalidate(), buyAd(), buyExpansion() (+3 more)

### Community 87 - "Net.luau"
Cohesion: 0.24
Nodes (5): Net.fire(), Net.fxTo(), Net.num(), Net.str(), parseReq()

### Community 88 - "data"
Cohesion: 0.27
Nodes (10): chooseOrder(), data(), dirtyNear(), pickType(), review(), Service.availableMenu(), Service.trySpawn(), Economy.addSakura() (+2 more)

### Community 89 - "script_parent_parent_core"
Cohesion: 0.28
Nodes (4): Service.check(), Interaction.Init(), sizeMargin(), targetPosition()

### Community 90 - "Tutorial.luau"
Cohesion: 0.47
Nodes (8): advance(), findTarget(), save(), show(), Tutorial.Init(), Tutorial.onAction(), Tutorial.restart(), Tutorial.Start()

### Community 91 - "Economy.luau"
Cohesion: 0.31
Nodes (7): Economy.add(), Economy.boostActive(), Economy.charge(), Economy.Init(), Economy.resetLedger(), Economy.spend(), Economy.spendSakura()

### Community 92 - "Geometry.compute"
Cohesion: 0.32
Nodes (7): Build.geometry(), ctx(), geometry(), World.ctx(), Geometry.compute(), Geometry.ctx(), Geometry.stairs()

### Community 93 - "shared_config_expansions"
Cohesion: 0.47
Nodes (3): allowed(), Dev.Init(), run()

### Community 95 - "Phone.luau"
Cohesion: 0.47
Nodes (3): launch(), Phone.open(), Phone.refresh()

### Community 96 - "Leaderboard.luau"
Cohesion: 0.53
Nodes (5): fetch(), Leaderboard.Init(), Leaderboard.Start(), nameOf(), submit()

### Community 97 - "Net.on"
Cohesion: 0.33
Nodes (3): Net.on(), Progression.Init(), RateLimit.new()

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera, Tutorial

## Knowledge Gaps
- **35 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `refresh()` connect `Services/Staff.luau` to `Color.hex`, `Piano tecnico — architettura e implementazione`?**
  _High betweenness centrality (0.160) - this node is a cross-community bridge._
- **Are the 92 inferred relationships involving `Kit.box()` (e.g. with `B.doorFrame()` and `B.eave()`) actually correct?**
  _`Kit.box()` has 92 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Staff.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.06414565826330532 - nodes in this community are weakly interconnected._
- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `7. Salvataggi`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`?**
  _High betweenness centrality (0.151) - this node is a cross-community bridge._
- **Are the 56 inferred relationships involving `Kit.cyl()` (e.g. with `B.entranceDetail()` and `B.openSign()`) actually correct?**
  _`Kit.cyl()` has 56 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Customers.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.14153846153846153 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Piano tecnico — architettura e implementazione` to `Services/Staff.luau`?**
  _High betweenness centrality (0.147) - this node is a cross-community bridge._