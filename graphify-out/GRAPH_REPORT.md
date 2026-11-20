# Graph Report - Roblox-Ramen-game  (2026-11-20)

## Corpus Check
- 176 files · ~255,156 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 2120 nodes · 5232 edges · 141 communities (92 shown, 49 thin omitted)
- Extraction: 80% EXTRACTED · 20% INFERRED · 0% AMBIGUOUS · INFERRED: 1059 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c125daba`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Screens/Build.luau
- Services/Staff.luau
- sim/client.lua
- services.lua
- Supply.luau
- Kit.box
- Services/Placement.luau
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
- UI.luau
- 8. Progressione
- Sakura Ramen & Sushi Tycoon — Game Design Document
- Screens/Shop.luau
- Formulas.luau
- 5. Cucina
- Signal.luau
- 9. Costruzione e decorazione
- 10. Sistemi di gioco
- Camera.luau
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- shared_util_color
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- shared_locale
- Events.luau
- HUD.luau
- Seating.luau
- Registry.luau
- Services/Plots.luau
- Scene.luau
- env.lua
- People.luau
- gui.lua
- shared_config_ingredients
- props
- preview.py
- Services/Customers.luau
- check_luau.py
- build_place.py
- Kitchen.luau
- sim.py
- task.wait
- Logic/Placement.luau
- Meta.luau
- script_parent_parent_core
- ui_preview.py
- Controllers/Interaction.luau
- Placement.validate
- boot.lua
- newInstance
- Controllers/Data.luau
- Walls.luau
- shared_config_expansions
- Services/Analytics.luau
- RamenYa.luau
- Furniture.luau
- Locale.get
- Appliance.luau
- Cooking.luau
- Economy.luau
- 10. Interfaccia
- Day.luau
- Controllers/Tutorial.luau
- methods.FindFirstChild
- methods.Destroy
- task.delay
- methods.HasTag
- asset_list.py
- Ambience.compute
- Services/Rewards.luau
- Guide.luau
- Color.hex
- Controllers/Audio.luau
- Logic/Shop.luau
- Hints.luau
- runLocal
- camBasis
- Sim.click
- fromClient
- Interaction.lockOf
- 7. Salvataggi
- shared_logic_formulas
- Sim.press
- script_parent_parent_core
- Lighting.luau
- floors.lua
- methods.RemoveTag

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 105 edges
2. `Kit.cyl()` - 62 edges
3. `nc()` - 53 edges
4. `Kit.new()` - 41 edges
5. `Color.hex()` - 41 edges
6. `Kit.blob()` - 36 edges
7. `Kit.part()` - 35 edges
8. `Scene.shell()` - 34 edges
9. `Kit.finish()` - 32 edges
10. `add()` - 31 edges

## Surprising Connections (you probably didn't know these)
- `8. Costruzione del mondo` --references--> `deliver()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Supply.luau
- `Giornata ed economia` --references--> `finish()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Day.luau
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `14. Prestazioni` --references--> `quiet()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/World.luau
- `12. Interfaccia e lingue` --references--> `close()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/client/Controllers/Hints.luau

## Import Cycles
- None detected.

## Communities (141 total, 49 thin omitted)

### Community 0 - "Screens/Build.luau"
Cohesion: 0.14
Nodes (19): actionText(), stepText(), paintSigns(), Icons.forItem(), Kit.clear(), itemCard(), itemLocked(), renderItems() (+11 more)

### Community 1 - "Services/Staff.luau"
Cohesion: 0.13
Nodes (41): carryBoxTo(), customerEntity(), deliverDish(), despawnActor(), despawnPlot(), doCollect(), doCook(), doOrder() (+33 more)

### Community 3 - "services.lua"
Cohesion: 0.02
Nodes (17): methods.GetTags(), cm.AnalyticsService.LogCustomEvent(), cm.AnalyticsService.LogFunnelStepEvent(), cm.AnalyticsService.LogOnboardingFunnelStepEvent(), cm.AnalyticsService.LogProgressionEvent(), cm.CollectionService.GetTags(), cm.DataStoreService.GetDataStore(), cm.DataStoreService.GetGlobalDataStore() (+9 more)

### Community 4 - "Supply.luau"
Cohesion: 0.07
Nodes (68): Appliance.useDishwasher(), Service.availableMenu(), Service.use(), buildVisual(), character(), Hands.add(), Hands.capacity(), Hands.clear() (+60 more)

### Community 5 - "Kit.box"
Cohesion: 0.21
Nodes (26): makeScene(), B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.ledSign() (+18 more)

### Community 6 - "Services/Placement.luau"
Cohesion: 0.20
Nodes (23): Net.fxTo(), buildPlot(), canAfford(), changed(), checkVetoes(), children(), despawn(), findEntry() (+15 more)

### Community 7 - "Kit.new"
Cohesion: 0.23
Nodes (35): FirstPerson.Init(), Hints.Init(), Tutorial.Init(), fitWindow(), Kit.badge(), Kit.bar(), Kit.button(), Kit.card() (+27 more)

### Community 8 - "re"
Cohesion: 0.16
Nodes (8): defined(), main(), load(), main(), members(), table_keys(), main(), read_module()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "Kit.cyl"
Cohesion: 0.20
Nodes (24): bonsai(), chochin(), foliage(), frame(), lanternString(), maneki(), neon(), noren() (+16 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.06
Nodes (62): 14. Prestazioni, Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.place(), Build.removeSelected() (+54 more)

### Community 12 - "Street.luau"
Cohesion: 0.18
Nodes (29): acUnit(), aframe(), balcony(), lp(), NC(), rng(), S.bicycle(), S.bins() (+21 more)

### Community 13 - "Food.luau"
Cohesion: 0.14
Nodes (63): baran(), blobAt(), box(), boxContents(), boxLabel(), c(), cabbage(), chashuSlice() (+55 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.14
Nodes (29): acquire(), Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save() (+21 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.12
Nodes (17): 11. Costruzione e griglia, 13. Rete e sicurezza, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro, 2. Struttura del progetto, 3. Configurazione (dati) (+9 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.05
Nodes (40): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino (+32 more)

### Community 17 - "UI.luau"
Cohesion: 0.20
Nodes (16): measure(), placeHolder(), UI.blockTouch(), UI.close(), UI.Init(), UI.isTouch(), UI.open(), UI.popup() (+8 more)

### Community 18 - "8. Progressione"
Cohesion: 0.15
Nodes (13): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 bis Cartelli "in vendita", 8.5 Espansioni, 8.6 Personale (automazione) (+5 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 20 - "Screens/Shop.luau"
Cohesion: 0.33
Nodes (14): BUILD.recipes(), BUILD.reno(), BUILD.rooms(), BUILD.staff(), BUILD.upgrades(), card(), cardSize(), effectText() (+6 more)

### Community 21 - "Formulas.luau"
Cohesion: 0.13
Nodes (21): dirtyNear(), review(), Economy.addSakura(), Progression.addMastery(), Progression.addXp(), Progression.priceOf(), Formulas.addXp(), Formulas.dishPrice() (+13 more)

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

### Community 28 - "Camera.luau"
Cohesion: 0.13
Nodes (32): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.scaleTurn(), Camera.setBuildView() (+24 more)

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

### Community 33 - "shared_util_color"
Cohesion: 0.17
Nodes (4): Pointer:step(), shown(), launch(), Phone.open()

### Community 34 - "Net/init.luau"
Cohesion: 0.83
Nodes (3): getFolder(), Net.event(), Net.func()

### Community 36 - "shared_locale"
Cohesion: 0.13
Nodes (8): screen.ready(), state(), today(), need(), cartForMenu(), lowForMenu(), stock(), unlocked()

### Community 39 - "HUD.luau"
Cohesion: 0.14
Nodes (14): Kit.bump(), tween(), HUD.bumpWallet(), HUD.currentGoal(), HUD.layout(), HUD.refreshGift(), HUD.refreshGoal(), HUD.refreshHands() (+6 more)

### Community 48 - "Seating.luau"
Cohesion: 0.18
Nodes (12): Placement.addVeto(), busy(), closestPoint(), free(), gap(), Seating.find(), Seating.freeCount(), Seating.Init() (+4 more)

### Community 49 - "Registry.luau"
Cohesion: 0.32
Nodes (3): fitOverride(), override(), Registry.build()

### Community 50 - "Services/Plots.luau"
Cohesion: 0.19
Nodes (23): claim(), dedupe(), friends(), Plots.at(), Plots.canBuild(), Plots.canWork(), Plots.data(), Plots.fire() (+15 more)

### Community 64 - "Scene.luau"
Cohesion: 0.11
Nodes (10): World.surfaceOf(), Footprint.subtractRect(), facadeColor(), floorY(), holesFor(), indoorAt(), Scene.surfaceOf(), style() (+2 more)

### Community 65 - "env.lua"
Cohesion: 0.05
Nodes (43): ancestors(), attrSignal(), bounds(), className(), cloneTree(), eventOf(), inGame(), isA() (+35 more)

### Community 66 - "People.luau"
Cohesion: 0.12
Nodes (47): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.spawn(), Npc.stand() (+39 more)

### Community 67 - "gui.lua"
Cohesion: 0.17
Nodes (39): alignOffset(), automatic(), baseSize(), charWidth(), cls(), colorStops(), constrain(), contentExtent() (+31 more)

### Community 69 - "shared_config_ingredients"
Cohesion: 0.43
Nodes (5): claimedSet(), elapsed(), nextGift(), screen.tick(), Format.duration()

### Community 70 - "props"
Cohesion: 0.09
Nodes (24): cm.BindableFunction.Invoke(), cm.Humanoid.AddAccessory(), cm.Humanoid.ChangeState(), cm.Humanoid.GetAccessories(), cm.Humanoid.GetState(), cm.Humanoid.GetStateEnabled(), cm.Humanoid.LoadAnimation(), cm.Humanoid.RemoveAccessories() (+16 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Services/Customers.luau"
Cohesion: 0.09
Nodes (32): bumpCombo(), chooseOrder(), countOf(), dishKind(), eat(), entrance(), floorPos(), leaveDirty() (+24 more)

### Community 73 - "check_luau.py"
Cohesion: 0.13
Nodes (13): build_tree(), add_path(), walk(), check_blocks(), check_locale(), check_requires(), check_scopes(), load_locale() (+5 more)

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Kitchen.luau"
Cohesion: 0.29
Nodes (19): backsplash(), bowlStack(), brothPot(), cabinet(), fittedBase(), hood(), knobs(), nc() (+11 more)

### Community 76 - "sim.py"
Cohesion: 0.15
Nodes (12): luau_to_lua(), main(), make_runtime(), read(), project_entries(), run(), run_scenario(), main() (+4 more)

### Community 77 - "task.wait"
Cohesion: 0.09
Nodes (36): Sim.waitFor(), Sim.trigger(), task.wait(), use(), goTo(), buy(), claim(), clearDirty() (+28 more)

### Community 78 - "Logic/Placement.luau"
Cohesion: 0.27
Nodes (10): Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY(), Placement.footprint(), Placement.pathOk(), Placement.pathTargets() (+2 more)

### Community 79 - "Meta.luau"
Cohesion: 0.16
Nodes (16): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), computeOffline(), dayIndex(), daySeconds(), ensureQuests() (+8 more)

### Community 80 - "script_parent_parent_core"
Cohesion: 0.12
Nodes (22): open(), Service.check(), Net.fireAll(), Net.fx(), Net.notify(), Net.notifyAll(), Net.num(), Net.str() (+14 more)

### Community 81 - "ui_preview.py"
Cohesion: 0.12
Nodes (21): backdrop(), Canvas, cmap(), draw_element(), draw_text(), emoji_image(), fill_image(), font() (+13 more)

### Community 82 - "Controllers/Interaction.luau"
Cohesion: 0.30
Nodes (11): aimingCenter(), castAt(), findTarget(), hrp(), inRange(), Interaction.Start(), promptFor(), proximityTarget() (+3 more)

### Community 83 - "Placement.validate"
Cohesion: 0.27
Nodes (12): Placement.near(), Footprint.axes(), Footprint.bounds(), Footprint.corners(), Footprint.insideRects(), Footprint.new(), Footprint.overlaps(), Footprint.pointIn() (+4 more)

### Community 84 - "boot.lua"
Cohesion: 0.17
Nodes (19): child(), joinArgs(), nodeAt(), print(), props(), relPath(), require(), runScript() (+11 more)

### Community 85 - "newInstance"
Cohesion: 0.33
Nodes (6): defaultsFor(), newInstance(), cm.DataModel.GetService(), cm.Player.LoadCharacter(), cm.Players.CreateHumanoidModelFromDescription(), Sim.rig()

### Community 86 - "Controllers/Data.luau"
Cohesion: 0.14
Nodes (19): Data.canBuild(), Data.isMine(), Data.m(), Data.plotAttr(), Data.plotFolder(), Data.plotId(), Data.restaurant(), Data.w() (+11 more)

### Community 87 - "Walls.luau"
Cohesion: 0.39
Nodes (8): Placement.wallSpot(), cut(), floorCells(), key(), merge(), Walls.along(), Walls.compute(), Walls.distance()

### Community 88 - "shared_config_expansions"
Cohesion: 0.17
Nodes (9): Ambient.Start(), offset(), track(), allowed(), Dev.Init(), Dev.Start(), run(), SelfTest.run() (+1 more)

### Community 89 - "Services/Analytics.luau"
Cohesion: 0.38
Nodes (9): Analytics.levelUp(), Analytics.sakura(), Analytics.sink(), Analytics.source(), Analytics.Start(), Analytics.step(), flush(), isPlayer() (+1 more)

### Community 92 - "RamenYa.luau"
Cohesion: 0.21
Nodes (13): shisa(), banner(), bowlArt(), high(), label(), nc(), pendant(), pitcher() (+5 more)

### Community 93 - "Furniture.luau"
Cohesion: 0.34
Nodes (12): chair(), condiments(), counter(), cushion(), ledgeProps(), nc(), placeSetting(), point() (+4 more)

### Community 94 - "Locale.get"
Cohesion: 0.12
Nodes (19): Data.applyLanguage(), Data.Init(), Data.Start(), makeTag(), place(), setText(), ShelfTags.Init(), ShelfTags.Start() (+11 more)

### Community 95 - "Appliance.luau"
Cohesion: 0.15
Nodes (29): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.hold(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile() (+21 more)

### Community 96 - "Cooking.luau"
Cohesion: 0.12
Nodes (24): broadcast(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init(), Cooking.isRecipeInProgress(), Cooking.maxTickets(), Cooking.readyDishes(), Cooking.removeTicket() (+16 more)

### Community 97 - "Economy.luau"
Cohesion: 0.19
Nodes (15): pay(), drawJars(), Economy.add(), Economy.boostActive(), Economy.charge(), Economy.collectTips(), Economy.ledgerOf(), Economy.multiplier() (+7 more)

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

### Community 99 - "Day.luau"
Cohesion: 0.27
Nodes (5): Day.broadcast(), Day.isNight(), Day.Start(), finish(), payload()

### Community 100 - "Controllers/Tutorial.luau"
Cohesion: 0.16
Nodes (14): advance(), finish(), hide(), orderStation(), paintDots(), purchases(), save(), show() (+6 more)

### Community 101 - "methods.FindFirstChild"
Cohesion: 0.50
Nodes (4): methods.FindFirstChild(), methods.FindFirstDescendant(), methods.WaitForChild(), cm.Player.DistanceFromCharacter()

### Community 102 - "methods.Destroy"
Cohesion: 0.22
Nodes (10): fireIf(), methods.ClearAllChildren(), methods.Destroy(), methods.GetChildren(), methods.SetAttribute(), typeof(), checkStorable(), cm.AnalyticsService.LogEconomyEvent() (+2 more)

### Community 103 - "task.delay"
Cohesion: 0.15
Nodes (16): toClient(), hpop(), hpush(), less(), pack(), schedule(), SignalMT:Fire(), task.defer() (+8 more)

### Community 105 - "asset_list.py"
Cohesion: 0.38
Nodes (3): load_names(), lua_list(), main()

### Community 109 - "Services/Rewards.luau"
Cohesion: 0.15
Nodes (12): Net.invoke(), Net.on(), Progression.Init(), claimGift(), grant(), leaderstats(), onPlayer(), publishClaimed() (+4 more)

### Community 115 - "Guide.luau"
Cohesion: 0.24
Nodes (14): clearMarks(), distance(), Guide.close(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show(), hands() (+6 more)

### Community 116 - "Color.hex"
Cohesion: 0.14
Nodes (18): Build.Init(), Interaction.highlightRecipe(), Interaction.Init(), icons(), make(), makeCustomer(), outline(), paintRankings() (+10 more)

### Community 118 - "Controllers/Audio.luau"
Cohesion: 0.07
Nodes (42): runTrain(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start(), Audio.step(), Audio.trainVolume(), customersInside() (+34 more)

### Community 119 - "Logic/Shop.luau"
Cohesion: 0.47
Nodes (9): finish(), level(), Shop.ad(), Shop.buyable(), Shop.expansion(), Shop.hire(), Shop.license(), Shop.staffSlots() (+1 more)

### Community 121 - "Hints.luau"
Cohesion: 0.18
Nodes (10): 12. Interfaccia e lingue, Data.role(), aim(), close(), dockButton(), Hints.Start(), open(), seen() (+2 more)

### Community 123 - "runLocal"
Cohesion: 0.53
Nodes (6): clientRequire(), envFor(), props(), relPath(), runLocal(), Sim.startClient()

### Community 124 - "camBasis"
Cohesion: 0.40
Nodes (5): camBasis(), cm.Camera.ScreenPointToRay(), cm.Camera.ViewportPointToRay(), cm.Camera.WorldToScreenPoint(), cm.Camera.WorldToViewportPoint()

### Community 125 - "Sim.click"
Cohesion: 0.50
Nodes (4): buttonOf(), guiOf(), Sim.click(), Sim.findText()

### Community 126 - "fromClient"
Cohesion: 0.67
Nodes (3): cm.RunService.IsClient(), cm.RunService.IsServer(), fromClient()

### Community 127 - "Interaction.lockOf"
Cohesion: 0.70
Nodes (4): Interaction.lockOf(), firstLicense(), Locks.rice(), Locks.station()

### Community 133 - "7. Salvataggi"
Cohesion: 0.50
Nodes (4): 7. Salvataggi, Regole, Replica al client, Schema (versione 1)

### Community 138 - "shared_logic_formulas"
Cohesion: 0.27
Nodes (5): grantPass(), Monetization.has(), Monetization.Init(), Monetization.yenMultiplier(), passCfg()

### Community 140 - "Sim.press"
Cohesion: 0.67
Nodes (3): casDispatch(), inputObject(), Sim.press()

### Community 143 - "script_parent_parent_core"
Cohesion: 0.60
Nodes (3): Interaction.Init(), sizeMargin(), targetPosition()

### Community 145 - "Lighting.luau"
Cohesion: 0.53
Nodes (5): blend(), LightingC.Init(), LightingC.Start(), look(), track()

### Community 148 - "floors.lua"
Cohesion: 0.60
Nodes (3): railAt(), steps(), tagged()

## Knowledge Gaps
- **49 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `7. Salvataggi`, `Controllers/Build.luau`, `Bilanciamento — numeri, prezzi e sblocchi`, `Hints.luau`, `10. Sistemi di gioco`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Are the 100 inferred relationships involving `Kit.box()` (e.g. with `makeScene()` and `B.doorFrame()`) actually correct?**
  _`Kit.box()` has 100 INFERRED edges - model-reasoned connections that need verification._
- **Should `Screens/Build.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.13846153846153847 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Hints.luau` to `Piano tecnico — architettura e implementazione`, `Appliance.luau`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `Kit.cyl()` (e.g. with `makeScene()` and `B.entranceDetail()`) actually correct?**
  _`Kit.cyl()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Staff.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.1321353065539112 - nodes in this community are weakly interconnected._
- **Why does `Kit.box()` connect `Kit.box` to `Kit.cyl`, `Kitchen.luau`, `Street.luau`, `Food.luau`, `Registry.luau`, `RamenYa.luau`, `Furniture.luau`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._