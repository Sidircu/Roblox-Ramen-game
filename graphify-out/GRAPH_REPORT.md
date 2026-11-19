# Graph Report - Roblox-Ramen-game  (2026-11-19)

## Corpus Check
- 154 files · ~206,024 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 1789 nodes · 4436 edges · 115 communities (75 shown, 40 thin omitted)
- Extraction: 79% EXTRACTED · 21% INFERRED · 0% AMBIGUOUS · INFERRED: 917 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `61cedaf0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Controllers/Audio.luau
- Appliance.luau
- Cooking.luau
- services.lua
- Supply.luau
- Kit.box
- Services/Placement.luau
- Color.hex
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
- Services/Plots.luau
- Scene.luau
- env.lua
- People.luau
- Camera.luau
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
- Npc.luau
- Controllers/Data.luau
- Walls.luau
- Services/Analytics.luau
- Progression.luau
- RamenYa.luau
- Furniture.luau
- Net.luau
- run
- Net.on
- typeof
- 10. Interfaccia
- Day.luau
- script_parent_parent_core
- Leaderboard.luau
- HUD.luau
- Gifts.luau
- chooseOrder
- shared_config_ingredients
- props
- Ambience.compute
- methods.RemoveTag
- methods.HasTag

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 102 edges
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
- `Build.Init()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Build.luau → src/shared/Util/Color.luau
- `Interaction.highlightRecipe()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Interaction.luau → src/shared/Util/Color.luau
- `Interaction.Init()` --calls--> `Color.hex()`  [INFERRED]
  src/client/Controllers/Interaction.luau → src/shared/Util/Color.luau

## Import Cycles
- None detected.

## Communities (115 total, 40 thin omitted)

### Community 0 - "Controllers/Audio.luau"
Cohesion: 0.07
Nodes (34): Ambient.Start(), offset(), runTrain(), track(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start() (+26 more)

### Community 1 - "Appliance.luau"
Cohesion: 0.05
Nodes (93): 12. Interfaccia e lingue, Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.hold(), Appliance.Init(), Appliance.load(), Appliance.needsRefill() (+85 more)

### Community 2 - "Cooking.luau"
Cohesion: 0.19
Nodes (18): broadcast(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.isRecipeInProgress(), Cooking.maxTickets(), Cooking.readyDishes(), Cooking.removeTicket(), Cooking.Start() (+10 more)

### Community 3 - "services.lua"
Cohesion: 0.02
Nodes (17): methods.GetTags(), cm.AnalyticsService.LogCustomEvent(), cm.AnalyticsService.LogFunnelStepEvent(), cm.AnalyticsService.LogOnboardingFunnelStepEvent(), cm.AnalyticsService.LogProgressionEvent(), cm.CollectionService.GetTags(), cm.DataStoreService.GetDataStore(), cm.DataStoreService.GetGlobalDataStore() (+9 more)

### Community 4 - "Supply.luau"
Cohesion: 0.10
Nodes (45): Service.availableMenu(), autoRestockPlot(), boxModel(), cellFloor(), chooseSlot(), deliver(), deliveryLoop(), deliveryTime() (+37 more)

### Community 5 - "Kit.box"
Cohesion: 0.24
Nodes (23): B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.openSign(), B.parapet() (+15 more)

### Community 6 - "Services/Placement.luau"
Cohesion: 0.20
Nodes (22): buildPlot(), canAfford(), changed(), checkVetoes(), children(), despawn(), findEntry(), itemUnlocked() (+14 more)

### Community 7 - "Color.hex"
Cohesion: 0.05
Nodes (80): FirstPerson.Init(), blend(), LightingC.Init(), LightingC.Start(), look(), track(), Tutorial.Init(), UI.Init() (+72 more)

### Community 8 - "re"
Cohesion: 0.25
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "Kit.cyl"
Cohesion: 0.16
Nodes (30): makeScene(), bonsai(), chochin(), foliage(), frame(), lanternString(), maneki(), neon() (+22 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.11
Nodes (41): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.Init(), Build.place(), Build.removeSelected() (+33 more)

### Community 12 - "Street.luau"
Cohesion: 0.21
Nodes (25): acUnit(), aframe(), balcony(), lp(), NC(), rng(), S.bicycle(), S.bins() (+17 more)

### Community 13 - "Food.luau"
Cohesion: 0.14
Nodes (63): baran(), blobAt(), box(), boxContents(), boxLabel(), c(), cabbage(), chashuSlice() (+55 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.06
Nodes (50): acquire(), Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save() (+42 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (18): 11. Costruzione e griglia, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro, 2. Struttura del progetto (+10 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "World.luau"
Cohesion: 0.14
Nodes (22): overflowSlots(), buildEmptyLot(), buildStreet(), folder(), World.clear(), World.ctx(), World.fixedRects(), World.floorY() (+14 more)

### Community 18 - "8. Progressione"
Cohesion: 0.17
Nodes (12): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 Espansioni, 8.6 Personale (automazione), 8.7 Guadagni offline (+4 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 21 - "Formulas.luau"
Cohesion: 0.16
Nodes (18): Progression.addMastery(), Progression.addXp(), Progression.priceOf(), Formulas.addXp(), Formulas.dishPrice(), Formulas.levelReward(), Formulas.masteryLevel(), Formulas.offlineEarnings() (+10 more)

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
Cohesion: 0.09
Nodes (29): active(), clearViews(), FirstPerson.cursorFree(), FirstPerson.Start(), setHeldLabels(), shortcut(), syncViews(), updateCrosshair() (+21 more)

### Community 29 - "4. Rifornimento: tablet, consegne, magazzino, mensole"
Cohesion: 0.40
Nodes (5): 4.1 Tablet ordini (Fornitore), 4.2 Consegna, 4.3 Dal magazzino alle mensole, 4.4 Preparazioni di base, 4. Rifornimento: tablet, consegne, magazzino, mensole

### Community 30 - "2. Il mondo"
Cohesion: 0.50
Nodes (4): 2.1 Struttura delle sessioni (una strada, quattro ristoranti), 2.2 La strada (yokochō), 2.3 Il ristorante iniziale, 2. Il mondo

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
Cohesion: 0.17
Nodes (3): cartForMenu(), stock(), unlocked()

### Community 48 - "Seating.luau"
Cohesion: 0.18
Nodes (10): busy(), closestPoint(), free(), gap(), Seating.find(), Seating.freeCount(), Seating.Init(), Seating.list() (+2 more)

### Community 50 - "Services/Plots.luau"
Cohesion: 0.19
Nodes (22): claim(), dedupe(), friends(), Plots.at(), Plots.canBuild(), Plots.canWork(), Plots.data(), Plots.fire() (+14 more)

### Community 64 - "Scene.luau"
Cohesion: 0.10
Nodes (10): World.surfaceOf(), Footprint.subtractRect(), facadeColor(), floorY(), holesFor(), indoorAt(), Scene.surfaceOf(), style() (+2 more)

### Community 65 - "env.lua"
Cohesion: 0.05
Nodes (34): attrSignal(), bounds(), className(), eventOf(), hpop(), hpush(), isA(), kids() (+26 more)

### Community 66 - "People.luau"
Cohesion: 0.22
Nodes (36): add(), apron(), backpack(), ball(), belt(), blob(), body(), c() (+28 more)

### Community 67 - "Camera.luau"
Cohesion: 0.26
Nodes (17): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.setBuildView(), Camera.setTop() (+9 more)

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.25
Nodes (8): Anteprima dei modelli (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Simulatore del server (senza Studio), Struttura

### Community 70 - "props"
Cohesion: 0.10
Nodes (24): cm.BindableFunction.Invoke(), cm.Humanoid.AddAccessory(), cm.Humanoid.ChangeState(), cm.Humanoid.GetAccessories(), cm.Humanoid.GetState(), cm.Humanoid.GetStateEnabled(), cm.Humanoid.LoadAnimation(), cm.Humanoid.RemoveAccessories() (+16 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Services/Customers.luau"
Cohesion: 0.13
Nodes (18): bumpCombo(), countOf(), dirtyNear(), leaveDirty(), pay(), pdata(), release(), review() (+10 more)

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
Cohesion: 0.10
Nodes (23): Sim.waitFor(), pack(), schedule(), SignalMT:Fire(), task.defer(), task.delay(), task.spawn(), task.wait() (+15 more)

### Community 78 - "Placement.validate"
Cohesion: 0.22
Nodes (13): Placement.near(), Footprint.bounds(), Footprint.new(), Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY() (+5 more)

### Community 79 - "Meta.luau"
Cohesion: 0.19
Nodes (12): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), computeOffline(), dayIndex(), ensureQuests(), Meta.dayEnded() (+4 more)

### Community 81 - "build_tree"
Cohesion: 0.50
Nodes (4): build_tree(), add_path(), walk(), rojo_name()

### Community 82 - "Controllers/Interaction.luau"
Cohesion: 0.10
Nodes (28): actionText(), aimingCenter(), castAt(), findTarget(), handsKind(), hrp(), inRange(), Interaction.highlightRecipe() (+20 more)

### Community 83 - "Footprint.luau"
Cohesion: 0.42
Nodes (8): Footprint.axes(), Footprint.corners(), Footprint.insideRects(), Footprint.overlaps(), Footprint.pointIn(), Footprint.pointInRect(), Footprint.wallFp(), project()

### Community 84 - "boot.lua"
Cohesion: 0.21
Nodes (16): child(), joinArgs(), nodeAt(), print(), props(), relPath(), require(), runScript() (+8 more)

### Community 85 - "Npc.luau"
Cohesion: 0.15
Nodes (13): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.emote(), Npc.release(), Npc.sit() (+5 more)

### Community 86 - "Controllers/Data.luau"
Cohesion: 0.06
Nodes (45): Data.applyLanguage(), Data.canBuild(), Data.Init(), Data.isMine(), Data.m(), Data.plotAttr(), Data.plotFolder(), Data.plotId() (+37 more)

### Community 87 - "Walls.luau"
Cohesion: 0.43
Nodes (6): cut(), floorCells(), key(), merge(), Walls.along(), Walls.compute()

### Community 89 - "Services/Analytics.luau"
Cohesion: 0.38
Nodes (9): Analytics.levelUp(), Analytics.sakura(), Analytics.sink(), Analytics.source(), Analytics.Start(), Analytics.step(), flush(), isPlayer() (+1 more)

### Community 90 - "Progression.luau"
Cohesion: 0.24
Nodes (14): Net.notify(), buyAd(), buyExpansion(), buyLicense(), buyUpgrade(), payer(), Progression.addReview(), Progression.applyWalkSpeed() (+6 more)

### Community 92 - "RamenYa.luau"
Cohesion: 0.24
Nodes (10): banner(), bowlArt(), high(), label(), nc(), pendant(), pitcher(), point() (+2 more)

### Community 93 - "Furniture.luau"
Cohesion: 0.38
Nodes (13): chair(), condiments(), counter(), cushion(), ledgeProps(), nc(), placeSetting(), point() (+5 more)

### Community 94 - "Net.luau"
Cohesion: 0.17
Nodes (10): open(), Service.check(), Net.fire(), Net.fireAll(), Net.fx(), Net.fxTo(), Net.notifyAll(), Net.num() (+2 more)

### Community 95 - "run"
Cohesion: 0.25
Nodes (11): dishKind(), eat(), entrance(), floorPos(), leaveRestaurant(), patienceTick(), run(), setOrder() (+3 more)

### Community 96 - "Net.on"
Cohesion: 0.25
Nodes (5): Net.invoke(), Net.on(), Progression.Init(), Rewards.Init(), RateLimit.new()

### Community 97 - "typeof"
Cohesion: 0.20
Nodes (12): fireIf(), methods.ClearAllChildren(), methods.Destroy(), methods.GetChildren(), methods.Remove(), methods.SetAttribute(), setParent(), typeof() (+4 more)

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

### Community 99 - "Day.luau"
Cohesion: 0.24
Nodes (6): Day.broadcast(), Day.isNight(), Day.isPeak(), Day.Start(), finish(), payload()

### Community 100 - "script_parent_parent_core"
Cohesion: 0.47
Nodes (3): Interaction.Init(), sizeMargin(), targetPosition()

### Community 101 - "Leaderboard.luau"
Cohesion: 0.53
Nodes (5): fetch(), Leaderboard.Init(), Leaderboard.Start(), nameOf(), submit()

### Community 102 - "HUD.luau"
Cohesion: 0.18
Nodes (8): HUD.bumpWallet(), HUD.refreshGift(), HUD.refreshHands(), HUD.refreshLike(), HUD.setBuilding(), keyHint(), patienceOf(), Format.duration()

### Community 103 - "Gifts.luau"
Cohesion: 0.70
Nodes (4): claimedSet(), elapsed(), nextGift(), screen.tick()

### Community 104 - "chooseOrder"
Cohesion: 0.50
Nodes (4): chooseOrder(), pickType(), Formulas.demandFactor(), TableUtil.weightedPick()

### Community 106 - "shared_config_ingredients"
Cohesion: 0.22
Nodes (6): allowed(), Dev.Init(), Dev.Start(), run(), SelfTest.run(), waitFor()

### Community 107 - "props"
Cohesion: 0.13
Nodes (19): ancestors(), cloneTree(), defaultsFor(), inGame(), methods.AddTag(), methods.Clone(), methods.FindFirstAncestor(), methods.FindFirstChild() (+11 more)

## Knowledge Gaps
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `refresh()` connect `Appliance.luau` to `Color.hex`?**
  _High betweenness centrality (0.075) - this node is a cross-community bridge._
- **Are the 97 inferred relationships involving `Kit.box()` (e.g. with `makeScene()` and `B.doorFrame()`) actually correct?**
  _`Kit.box()` has 97 INFERRED edges - model-reasoned connections that need verification._
- **Should `Controllers/Audio.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07358156028368794 - nodes in this community are weakly interconnected._
- **Why does `Color.hex()` connect `Color.hex` to `Controllers/Audio.luau`, `Appliance.luau`, `People.luau`, `Scene.luau`, `Kit.box`, `Kit.cyl`, `Controllers/Build.luau`, `Street.luau`, `Food.luau`, `Controllers/Interaction.luau`, `Npc.luau`, `RamenYa.luau`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Are the 59 inferred relationships involving `Kit.cyl()` (e.g. with `makeScene()` and `B.entranceDetail()`) actually correct?**
  _`Kit.cyl()` has 59 INFERRED edges - model-reasoned connections that need verification._
- **Should `Appliance.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05366336633663366 - nodes in this community are weakly interconnected._
- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `Appliance.luau`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`, `7. Salvataggi`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._