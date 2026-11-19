# Graph Report - Roblox-Ramen-game  (2026-11-19)

## Corpus Check
- 152 files · ~200,240 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1751 nodes · 4344 edges · 116 communities (78 shown, 38 thin omitted)
- Extraction: 79% EXTRACTED · 21% INFERRED · 0% AMBIGUOUS · INFERRED: 903 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6cc96ffb`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Controllers/Audio.luau
- Appliance.luau
- Cooking.luau
- services.lua
- Supply.luau
- Kit.box
- script_parent_parent_core
- Kit.new
- re
- mock.lua
- Kit.cyl
- Controllers/Build.luau
- Street.luau
- Food.luau
- Services/Data.luau
- Piano tecnico — architettura e implementazione
- Bilanciamento — numeri, prezzi e sblocchi
- World.luau
- 8. Progressione
- Sakura Ramen & Sushi Tycoon — Game Design Document
- Formulas.luau
- 5. Cucina
- Signal.luau
- 9. Costruzione e decorazione
- 10. Sistemi di gioco
- 5. Catalogo oggetti piazzabili
- script_parent_parent_core
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- 7. Salvataggi
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- shared_locale
- Events.luau
- Seating.luau
- Scene.luau
- env.lua
- People.luau
- Screens/Build.luau
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- props
- preview.py
- Services/Customers.luau
- check_luau.py
- build_place.py
- Kitchen.luau
- sim.py
- methods.FindFirstChild
- Placement.validate
- Meta.luau
- check_scopes
- build_tree
- Controllers/Interaction.luau
- Footprint.luau
- boot.lua
- Guide.luau
- HUD.refresh
- Walls.luau
- Services/Analytics.luau
- Effects.luau
- RamenYa.luau
- Furniture.luau
- shared_util_color
- Tutorial.luau
- Color.hex
- typeof
- 10. Interfaccia
- Day.luau
- shared_models_registry
- Economy.luau
- HUD.luau
- Sink.luau
- Locale/init.luau
- ShelfTags.luau
- shared_config_ingredients
- props
- Services/Monetization.luau
- methods.GetTags
- methods.HasTag
- Interaction.lockOf
- TableUtil.deepCopy

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 101 edges
2. `Kit.cyl()` - 61 edges
3. `nc()` - 53 edges
4. `Kit.blob()` - 36 edges
5. `Kit.part()` - 35 edges
6. `Color.hex()` - 35 edges
7. `Scene.shell()` - 34 edges
8. `Kit.finish()` - 32 edges
9. `Kit.new()` - 32 edges
10. `add()` - 30 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `Giornata ed economia` --references--> `finish()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Day.luau
- `HUD.bumpWallet()` --calls--> `Kit.new()`  [INFERRED]
  src/client/UI/Screens/HUD.luau → src/client/UI/Kit.luau
- `chooseOrder()` --calls--> `Formulas.demandFactor()`  [INFERRED]
  src/server/Services/Customers.luau → src/shared/Logic/Formulas.luau
- `Service.collectDirty()` --calls--> `Hands.add()`  [INFERRED]
  src/server/Services/Customers.luau → src/server/Services/Hands.luau

## Import Cycles
- None detected.

## Communities (116 total, 38 thin omitted)

### Community 0 - "Controllers/Audio.luau"
Cohesion: 0.17
Nodes (18): runTrain(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start(), Audio.step(), Audio.trainVolume(), customersInside() (+10 more)

### Community 1 - "Appliance.luau"
Cohesion: 0.06
Nodes (83): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.hold(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile() (+75 more)

### Community 2 - "Cooking.luau"
Cohesion: 0.17
Nodes (16): broadcast(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init(), Cooking.isRecipeInProgress(), Cooking.maxTickets(), Cooking.readyDishes(), Cooking.removeTicket() (+8 more)

### Community 3 - "services.lua"
Cohesion: 0.02
Nodes (15): cm.AnalyticsService.LogCustomEvent(), cm.AnalyticsService.LogFunnelStepEvent(), cm.AnalyticsService.LogOnboardingFunnelStepEvent(), cm.AnalyticsService.LogProgressionEvent(), cm.DataStoreService.GetDataStore(), cm.DataStoreService.GetGlobalDataStore(), cm.DataStoreService.GetOrderedDataStore(), cm.MemoryStoreService.GetQueue() (+7 more)

### Community 4 - "Supply.luau"
Cohesion: 0.11
Nodes (42): autoRestock(), boxModel(), cellFloor(), chooseSlot(), data(), deliveryLoop(), deliveryTime(), dropSpots() (+34 more)

### Community 5 - "Kit.box"
Cohesion: 0.24
Nodes (23): B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.openSign(), B.parapet() (+15 more)

### Community 6 - "script_parent_parent_core"
Cohesion: 0.05
Nodes (76): Economy.spend(), open(), Service.check(), Net.fire(), Net.fireAll(), Net.fx(), Net.fxTo(), Net.invoke() (+68 more)

### Community 7 - "Kit.new"
Cohesion: 0.25
Nodes (30): FirstPerson.Init(), UI.toast(), Kit.bar(), Kit.button(), Kit.card(), Kit.corner(), Kit.goldLine(), Kit.grid() (+22 more)

### Community 8 - "re"
Cohesion: 0.25
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "Kit.cyl"
Cohesion: 0.21
Nodes (23): bonsai(), chochin(), foliage(), frame(), lanternString(), maneki(), neon(), noren() (+15 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.08
Nodes (43): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.place(), Build.removeSelected(), Build.rotate() (+35 more)

### Community 12 - "Street.luau"
Cohesion: 0.19
Nodes (27): acUnit(), aframe(), balcony(), lp(), NC(), rng(), S.bicycle(), S.bins() (+19 more)

### Community 13 - "Food.luau"
Cohesion: 0.13
Nodes (66): shisa(), baran(), blobAt(), box(), boxContents(), boxLabel(), c(), cabbage() (+58 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.17
Nodes (23): acquire(), Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save() (+15 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (19): 11. Costruzione e griglia, 12. Interfaccia e lingue, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro (+11 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "World.luau"
Cohesion: 0.15
Nodes (10): buildShell(), buildStreet(), folder(), geo(), World.floorY(), World.Init(), World.rebuild(), World.recompute() (+2 more)

### Community 18 - "8. Progressione"
Cohesion: 0.17
Nodes (12): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 Espansioni, 8.6 Personale (automazione), 8.7 Guadagni offline (+4 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 21 - "Formulas.luau"
Cohesion: 0.12
Nodes (22): dirtyNear(), review(), Economy.addSakura(), applyProduct(), Progression.addXp(), Progression.priceOf(), Formulas.addXp(), Formulas.demandFactor() (+14 more)

### Community 22 - "5. Cucina"
Cohesion: 0.22
Nodes (9): 5.1 bis La postazione fa da sola, 5.1 Ordini, 5.1 ter Noodles perfetti (facoltativo), 5.2 Preparare il sushi (postazione sushi / tagliere), 5.3 Preparare il ramen (postazione ramen), 5.4 Altre postazioni (sbloccate con licenze), 5.5 Velocità e freschezza, 5.6 Servire, pagare, pulire (+1 more)

### Community 24 - "Signal.luau"
Cohesion: 0.38
Nodes (3): Signal:Connect(), Signal:Once(), Signal:Wait()

### Community 25 - "9. Costruzione e decorazione"
Cohesion: 0.33
Nodes (6): 9.1 Modalità costruzione, 9.2 Tipi di piazzamento, 9.3 Regole di validità, 9.4 Pavimenti e pareti, 9.5 Ambiente, 9. Costruzione e decorazione

### Community 26 - "10. Sistemi di gioco"
Cohesion: 0.33
Nodes (6): 10. Sistemi di gioco, Clienti (macchina a stati), Giornata ed economia, Interazione, Personale (bacheca dei compiti), Preparazione a pressioni

### Community 27 - "5. Catalogo oggetti piazzabili"
Cohesion: 0.29
Nodes (7): 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino, 5.3 Decorazioni, 5.4 Pavimenti e pareti (per zona), 5.5 Livelli di ambiente, 5. Catalogo oggetti piazzabili, Pacchetto Ramen-ya (ispirato ai banconi dei ramen-ya veri)

### Community 28 - "script_parent_parent_core"
Cohesion: 0.06
Nodes (54): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.setBuildView(), Camera.setTop() (+46 more)

### Community 29 - "4. Rifornimento: tablet, consegne, magazzino, mensole"
Cohesion: 0.40
Nodes (5): 4.1 Tablet ordini (Fornitore), 4.2 Consegna, 4.3 Dal magazzino alle mensole, 4.4 Preparazioni di base, 4. Rifornimento: tablet, consegne, magazzino, mensole

### Community 30 - "2. Il mondo"
Cohesion: 0.50
Nodes (4): 2.1 Struttura delle sessioni (mondo personale), 2.2 La strada (yokochō), 2.3 Il ristorante iniziale, 2. Il mondo

### Community 31 - "3. Ciclo di gioco"
Cohesion: 0.50
Nodes (4): 3.1 Il ciclo principale (loop), 3.2 La giornata, 3.3 Interazione: un'azione = un pulsante, 3. Ciclo di gioco

### Community 32 - "6. Clienti"
Cohesion: 0.50
Nodes (4): 6.1 Comportamento, 6.2 Tipi di cliente, 6.3 Valutazione del ristorante, 6. Clienti

### Community 33 - "7. Salvataggi"
Cohesion: 0.50
Nodes (4): 7. Salvataggi, Regole, Replica al client, Schema (versione 1)

### Community 34 - "Net/init.luau"
Cohesion: 0.83
Nodes (3): getFolder(), Net.event(), Net.func()

### Community 36 - "shared_locale"
Cohesion: 0.13
Nodes (5): launch(), Phone.open(), cartForMenu(), stock(), unlocked()

### Community 48 - "Seating.luau"
Cohesion: 0.22
Nodes (9): busy(), closestPoint(), free(), gap(), Seating.find(), Seating.freeCount(), Seating.Init(), Seating.refresh() (+1 more)

### Community 64 - "Scene.luau"
Cohesion: 0.09
Nodes (10): World.surfaceOf(), Footprint.subtractRect(), facadeColor(), floorY(), holesFor(), indoorAt(), Scene.surfaceOf(), style() (+2 more)

### Community 65 - "env.lua"
Cohesion: 0.05
Nodes (36): attrSignal(), bounds(), className(), eventOf(), hpop(), hpush(), isA(), kids() (+28 more)

### Community 66 - "People.luau"
Cohesion: 0.12
Nodes (47): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.spawn(), Npc.stand() (+39 more)

### Community 67 - "Screens/Build.luau"
Cohesion: 0.18
Nodes (11): Icons.forItem(), Kit.clear(), itemCard(), itemLocked(), renderItems(), renderTabs(), Screen.open(), Screen.refresh() (+3 more)

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.25
Nodes (8): Anteprima dei modelli (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Simulatore del server (senza Studio), Struttura

### Community 70 - "props"
Cohesion: 0.08
Nodes (28): methods.FindFirstChild(), methods.FindFirstDescendant(), cm.BindableFunction.Invoke(), cm.Humanoid.AddAccessory(), cm.Humanoid.ChangeState(), cm.Humanoid.GetAccessories(), cm.Humanoid.GetState(), cm.Humanoid.GetStateEnabled() (+20 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Services/Customers.luau"
Cohesion: 0.11
Nodes (27): bumpCombo(), chooseOrder(), data(), dishKind(), eat(), entrance(), floorPos(), leaveDirty() (+19 more)

### Community 73 - "check_luau.py"
Cohesion: 0.24
Nodes (8): check_blocks(), check_locale(), check_requires(), load_locale(), long_bracket(), main(), Tok, tokenize()

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Kitchen.luau"
Cohesion: 0.30
Nodes (18): backsplash(), bowlStack(), brothPot(), cabinet(), fittedBase(), hood(), knobs(), nc() (+10 more)

### Community 76 - "sim.py"
Cohesion: 0.19
Nodes (7): main(), read_module(), luau_to_lua(), main(), project_entries(), run(), read()

### Community 77 - "methods.FindFirstChild"
Cohesion: 0.11
Nodes (21): Sim.waitFor(), methods.WaitForChild(), pack(), schedule(), SignalMT:Fire(), task.defer(), task.delay(), task.spawn() (+13 more)

### Community 78 - "Placement.validate"
Cohesion: 0.27
Nodes (10): Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY(), Placement.footprint(), Placement.pathOk(), Placement.pathTargets() (+2 more)

### Community 79 - "Meta.luau"
Cohesion: 0.19
Nodes (12): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), computeOffline(), dayIndex(), ensureQuests(), Meta.dayEnded() (+4 more)

### Community 81 - "build_tree"
Cohesion: 0.50
Nodes (4): build_tree(), add_path(), walk(), rojo_name()

### Community 82 - "Controllers/Interaction.luau"
Cohesion: 0.27
Nodes (13): actionText(), aimingCenter(), castAt(), findTarget(), handsKind(), hrp(), inRange(), Interaction.Start() (+5 more)

### Community 83 - "Footprint.luau"
Cohesion: 0.23
Nodes (15): Placement.near(), overflowSlots(), World.fixedRects(), Footprint.axes(), Footprint.bounds(), Footprint.corners(), Footprint.inflate(), Footprint.insideRects() (+7 more)

### Community 84 - "boot.lua"
Cohesion: 0.21
Nodes (16): child(), joinArgs(), nodeAt(), print(), props(), relPath(), require(), runScript() (+8 more)

### Community 85 - "Guide.luau"
Cohesion: 0.24
Nodes (14): clearMarks(), distance(), Guide.close(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show(), hands() (+6 more)

### Community 86 - "HUD.refresh"
Cohesion: 0.17
Nodes (19): Data.canBuild(), Data.m(), Data.role(), Data.w(), Data.wallet(), rewardText(), HUD.day(), HUD.refresh() (+11 more)

### Community 87 - "Walls.luau"
Cohesion: 0.23
Nodes (10): World.ctx(), Geometry.compute(), Geometry.ctx(), Geometry.stairs(), cut(), floorCells(), key(), merge() (+2 more)

### Community 89 - "Services/Analytics.luau"
Cohesion: 0.38
Nodes (9): Analytics.levelUp(), Analytics.sakura(), Analytics.sink(), Analytics.source(), Analytics.Start(), Analytics.step(), flush(), isPlayer() (+1 more)

### Community 90 - "Effects.luau"
Cohesion: 0.40
Nodes (10): arc(), burst(), coinsToWallet(), comboBanner(), confetti(), Effects.Init(), popup(), product() (+2 more)

### Community 92 - "RamenYa.luau"
Cohesion: 0.24
Nodes (10): banner(), bowlArt(), high(), label(), nc(), pendant(), pitcher(), point() (+2 more)

### Community 93 - "Furniture.luau"
Cohesion: 0.38
Nodes (13): chair(), condiments(), counter(), cushion(), ledgeProps(), nc(), placeSetting(), point() (+5 more)

### Community 94 - "shared_util_color"
Cohesion: 0.43
Nodes (5): blend(), LightingC.Init(), LightingC.Start(), look(), track()

### Community 95 - "Tutorial.luau"
Cohesion: 0.29
Nodes (10): advance(), findTarget(), orderStation(), save(), show(), stationStep(), Tutorial.Init(), Tutorial.onAction() (+2 more)

### Community 96 - "Color.hex"
Cohesion: 0.20
Nodes (12): Build.Init(), Interaction.highlightRecipe(), Interaction.Init(), icons(), make(), makeCustomer(), setBar(), updateEntity() (+4 more)

### Community 97 - "typeof"
Cohesion: 0.20
Nodes (12): fireIf(), methods.ClearAllChildren(), methods.Destroy(), methods.GetChildren(), methods.Remove(), methods.SetAttribute(), setParent(), typeof() (+4 more)

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

### Community 99 - "Day.luau"
Cohesion: 0.20
Nodes (10): serveQueue(), spawnLoop(), data(), Day.broadcast(), Day.isNight(), Day.isPeak(), Day.Start(), finish() (+2 more)

### Community 100 - "shared_models_registry"
Cohesion: 0.47
Nodes (4): Ambient.Start(), offset(), track(), Registry.load()

### Community 101 - "Economy.luau"
Cohesion: 0.20
Nodes (14): pay(), drawJars(), Economy.add(), Economy.boostActive(), Economy.charge(), Economy.collectTips(), Economy.Init(), Economy.multiplier() (+6 more)

### Community 102 - "HUD.luau"
Cohesion: 0.16
Nodes (11): HUD.bumpWallet(), HUD.currentGoal(), HUD.refreshGift(), HUD.refreshGoal(), HUD.refreshHands(), HUD.refreshLike(), HUD.refreshTickets(), HUD.setBuilding() (+3 more)

### Community 103 - "Sink.luau"
Cohesion: 0.23
Nodes (10): washHold(), makeScene(), noQuery(), plateCf(), progressOf(), Sink.beginHold(), Sink.endHold(), Sink.toggle() (+2 more)

### Community 104 - "Locale/init.luau"
Cohesion: 0.19
Nodes (11): Data.applyLanguage(), Data.Init(), Data.Start(), Kit.T(), Locale.has(), Locale.name(), Locale.resolve(), Locale.set() (+3 more)

### Community 105 - "ShelfTags.luau"
Cohesion: 0.52
Nodes (6): makeTag(), place(), setText(), ShelfTags.Init(), ShelfTags.Start(), update()

### Community 106 - "shared_config_ingredients"
Cohesion: 0.18
Nodes (10): claimedSet(), elapsed(), nextGift(), screen.tick(), allowed(), Dev.Init(), Dev.Start(), run() (+2 more)

### Community 107 - "props"
Cohesion: 0.17
Nodes (15): ancestors(), cloneTree(), defaultsFor(), inGame(), methods.AddTag(), methods.Clone(), methods.FindFirstAncestor(), methods.GetFullName() (+7 more)

### Community 108 - "Services/Monetization.luau"
Cohesion: 0.29
Nodes (6): grantPass(), Monetization.has(), Monetization.Init(), Monetization.ownerHas(), Monetization.ownerYenMultiplier(), passCfg()

### Community 114 - "Interaction.lockOf"
Cohesion: 0.70
Nodes (4): Interaction.lockOf(), firstLicense(), Locks.rice(), Locks.station()

### Community 115 - "TableUtil.deepCopy"
Cohesion: 0.50
Nodes (4): TableUtil.count(), TableUtil.deepCopy(), TableUtil.reconcile(), TableUtil.shuffle()

## Knowledge Gaps
- **38 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `7. Salvataggi`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`?**
  _High betweenness centrality (0.105) - this node is a cross-community bridge._
- **Are the 96 inferred relationships involving `Kit.box()` (e.g. with `makeScene()` and `B.doorFrame()`) actually correct?**
  _`Kit.box()` has 96 INFERRED edges - model-reasoned connections that need verification._
- **Should `Appliance.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05967540574282147 - nodes in this community are weakly interconnected._
- **Why does `refresh()` connect `Appliance.luau` to `Color.hex`, `Piano tecnico — architettura e implementazione`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Are the 59 inferred relationships involving `Kit.cyl()` (e.g. with `makeScene()` and `B.entranceDetail()`) actually correct?**
  _`Kit.cyl()` has 59 INFERRED edges - model-reasoned connections that need verification._
- **Should `services.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.024366937410415672 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Piano tecnico — architettura e implementazione` to `Appliance.luau`?**
  _High betweenness centrality (0.101) - this node is a cross-community bridge._