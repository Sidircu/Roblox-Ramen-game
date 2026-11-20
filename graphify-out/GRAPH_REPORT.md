# Graph Report - Roblox-Ramen-game  (2026-11-20)

## Corpus Check
- 176 files · ~253,431 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 2118 nodes · 5228 edges · 153 communities (106 shown, 47 thin omitted)
- Extraction: 80% EXTRACTED · 20% INFERRED · 0% AMBIGUOUS · INFERRED: 1058 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `29eb3b42`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Sink.luau
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
- World.luau
- 8. Progressione
- Sakura Ramen & Sushi Tycoon — Game Design Document
- Formulas.luau
- 5. Cucina
- Signal.luau
- 9. Costruzione e decorazione
- 10. Sistemi di gioco
- 5. Catalogo oggetti piazzabili
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
- script_parent_parent_core
- Services/Plots.luau
- Scene.luau
- env.lua
- People.luau
- gui.lua
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
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
- Progression.luau
- ui_preview.py
- Controllers/Interaction.luau
- Placement.validate
- boot.lua
- newInstance
- Controllers/Data.luau
- Walls.luau
- HUD.luau
- Services/Analytics.luau
- Asset da procurare — modelli, icone e suoni
- RamenYa.luau
- Furniture.luau
- Locale.get
- Appliance.luau
- Cooking.luau
- Economy.luau
- 10. Interfaccia
- Day.luau
- Controllers/Tutorial.luau
- Leaderboard.luau
- methods.Destroy
- task.delay
- Hands.luau
- asset_list.py
- Ambience.compute
- pdata
- FirstPerson.luau
- ShelfTags.luau
- Guide.luau
- Color.hex
- shared_models_registry
- Controllers/Audio.luau
- Logic/Shop.luau
- Effects.luau
- Hints.luau
- runLocal
- camBasis
- Sim.click
- fromClient
- Interaction.lockOf
- className
- 7. Salvataggi
- pdata
- shared_logic_formulas
- Timing.luau
- Sim.press
- script_parent_parent_core
- Supplier.luau
- Lighting.luau
- Format.luau
- Service.trySpawn
- floors.lua
- review
- ShelfGrid.luau
- methods.RemoveTag

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 105 edges
2. `Kit.cyl()` - 62 edges
3. `nc()` - 53 edges
4. `Color.hex()` - 41 edges
5. `Kit.new()` - 41 edges
6. `Kit.blob()` - 36 edges
7. `Kit.part()` - 35 edges
8. `Scene.shell()` - 34 edges
9. `Kit.finish()` - 32 edges
10. `add()` - 31 edges

## Surprising Connections (you probably didn't know these)
- `8. Costruzione del mondo` --references--> `deliver()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Supply.luau
- `14. Prestazioni` --references--> `quiet()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/World.luau
- `Giornata ed economia` --references--> `finish()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Day.luau
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `12. Interfaccia e lingue` --references--> `close()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/client/Controllers/Hints.luau

## Import Cycles
- None detected.

## Communities (153 total, 47 thin omitted)

### Community 0 - "Sink.luau"
Cohesion: 0.21
Nodes (10): handsKind(), washHold(), noQuery(), plateCf(), progressOf(), Sink.beginHold(), Sink.endHold(), Sink.toggle() (+2 more)

### Community 1 - "Services/Staff.luau"
Cohesion: 0.13
Nodes (41): carryBoxTo(), customerEntity(), deliverDish(), despawnActor(), despawnPlot(), doCollect(), doCook(), doOrder() (+33 more)

### Community 3 - "services.lua"
Cohesion: 0.02
Nodes (19): methods.GetTags(), methods.HasTag(), cm.AnalyticsService.LogCustomEvent(), cm.AnalyticsService.LogFunnelStepEvent(), cm.AnalyticsService.LogOnboardingFunnelStepEvent(), cm.AnalyticsService.LogProgressionEvent(), cm.CollectionService.GetTags(), cm.CollectionService.HasTag() (+11 more)

### Community 4 - "Supply.luau"
Cohesion: 0.19
Nodes (23): animateTruck(), boxModel(), cellFloor(), chooseSlot(), handPos(), productFit(), refreshSlot(), shelfState() (+15 more)

### Community 5 - "Kit.box"
Cohesion: 0.23
Nodes (24): B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.ledSign(), B.openSign() (+16 more)

### Community 6 - "Services/Placement.luau"
Cohesion: 0.19
Nodes (25): Net.fire(), Net.fxTo(), Net.notify(), buildPlot(), canAfford(), changed(), checkVetoes(), children() (+17 more)

### Community 7 - "Kit.new"
Cohesion: 0.06
Nodes (97): FirstPerson.Init(), Hints.Init(), actionText(), stepText(), Tutorial.Init(), measure(), placeHolder(), UI.blockTouch() (+89 more)

### Community 8 - "re"
Cohesion: 0.16
Nodes (8): defined(), main(), load(), main(), members(), table_keys(), main(), read_module()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "Kit.cyl"
Cohesion: 0.14
Nodes (36): makeScene(), bonsai(), chochin(), foliage(), frame(), lanternString(), maneki(), neon() (+28 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.08
Nodes (42): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.Init(), Build.place(), Build.removeSelected() (+34 more)

### Community 12 - "Street.luau"
Cohesion: 0.22
Nodes (24): acUnit(), aframe(), balcony(), lp(), NC(), rng(), S.bicycle(), S.bins() (+16 more)

### Community 13 - "Food.luau"
Cohesion: 0.14
Nodes (63): baran(), blobAt(), box(), boxContents(), boxLabel(), c(), cabbage(), chashuSlice() (+55 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.12
Nodes (30): acquire(), Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save() (+22 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (18): 11. Costruzione e griglia, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro, 2. Struttura del progetto (+10 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "World.luau"
Cohesion: 0.15
Nodes (23): overflowSlots(), buildEmptyLot(), buildStreet(), folder(), quiet(), World.clear(), World.ctx(), World.fixedRects() (+15 more)

### Community 18 - "8. Progressione"
Cohesion: 0.15
Nodes (13): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 bis Cartelli "in vendita", 8.5 Espansioni, 8.6 Personale (automazione) (+5 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 21 - "Formulas.luau"
Cohesion: 0.22
Nodes (14): Progression.addXp(), Formulas.addXp(), Formulas.dishPrice(), Formulas.levelReward(), Formulas.masteryLevel(), Formulas.offlineEarnings(), Formulas.questTarget(), Formulas.review() (+6 more)

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

### Community 28 - "Camera.luau"
Cohesion: 0.22
Nodes (20): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.scaleTurn(), Camera.setBuildView() (+12 more)

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
Cohesion: 0.12
Nodes (8): screen.ready(), state(), today(), claimedSet(), elapsed(), nextGift(), screen.tick(), need()

### Community 39 - "HUD.luau"
Cohesion: 0.25
Nodes (4): HUD.bumpWallet(), HUD.refreshHands(), HUD.setBuilding(), patienceOf()

### Community 48 - "Seating.luau"
Cohesion: 0.19
Nodes (11): busy(), closestPoint(), free(), gap(), Seating.find(), Seating.freeCount(), Seating.Init(), Seating.list() (+3 more)

### Community 49 - "script_parent_parent_core"
Cohesion: 0.12
Nodes (12): open(), Service.check(), Net.fireAll(), Net.fx(), Net.invoke(), Net.notifyAll(), Net.num(), Net.on() (+4 more)

### Community 50 - "Services/Plots.luau"
Cohesion: 0.19
Nodes (23): claim(), dedupe(), friends(), Plots.at(), Plots.canBuild(), Plots.canWork(), Plots.data(), Plots.fire() (+15 more)

### Community 64 - "Scene.luau"
Cohesion: 0.09
Nodes (10): World.surfaceOf(), Footprint.subtractRect(), facadeColor(), floorY(), holesFor(), indoorAt(), Scene.surfaceOf(), style() (+2 more)

### Community 65 - "env.lua"
Cohesion: 0.05
Nodes (35): ancestors(), attrSignal(), cloneTree(), eventOf(), fireIf(), inGame(), kids(), methods.AddTag() (+27 more)

### Community 66 - "People.luau"
Cohesion: 0.12
Nodes (47): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.spawn(), Npc.stand() (+39 more)

### Community 67 - "gui.lua"
Cohesion: 0.17
Nodes (39): alignOffset(), automatic(), baseSize(), charWidth(), cls(), colorStops(), constrain(), contentExtent() (+31 more)

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.20
Nodes (10): Anteprima dei modelli (senza Studio), Anteprima dell'interfaccia (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Pubblicare il gioco su Roblox, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio) (+2 more)

### Community 70 - "props"
Cohesion: 0.09
Nodes (24): cm.BindableFunction.Invoke(), cm.Humanoid.AddAccessory(), cm.Humanoid.ChangeState(), cm.Humanoid.GetAccessories(), cm.Humanoid.GetState(), cm.Humanoid.GetStateEnabled(), cm.Humanoid.LoadAnimation(), cm.Humanoid.RemoveAccessories() (+16 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Services/Customers.luau"
Cohesion: 0.15
Nodes (16): dishKind(), eat(), entrance(), floorPos(), leaveRestaurant(), patienceTick(), release(), run() (+8 more)

### Community 73 - "check_luau.py"
Cohesion: 0.13
Nodes (13): build_tree(), add_path(), walk(), check_blocks(), check_locale(), check_requires(), check_scopes(), load_locale() (+5 more)

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Kitchen.luau"
Cohesion: 0.30
Nodes (18): backsplash(), bowlStack(), brothPot(), cabinet(), fittedBase(), hood(), knobs(), nc() (+10 more)

### Community 76 - "sim.py"
Cohesion: 0.15
Nodes (12): luau_to_lua(), main(), make_runtime(), read(), project_entries(), run(), run_scenario(), main() (+4 more)

### Community 77 - "task.wait"
Cohesion: 0.11
Nodes (31): Sim.waitFor(), Sim.trigger(), task.wait(), use(), goTo(), buy(), claim(), clearDirty() (+23 more)

### Community 78 - "Logic/Placement.luau"
Cohesion: 0.27
Nodes (10): Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY(), Placement.footprint(), Placement.pathOk(), Placement.pathTargets() (+2 more)

### Community 79 - "Meta.luau"
Cohesion: 0.26
Nodes (13): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), computeOffline(), dayIndex(), daySeconds(), ensureQuests() (+5 more)

### Community 80 - "Progression.luau"
Cohesion: 0.14
Nodes (17): Placement.revalidate(), buyAd(), buyExpansion(), buyLicense(), buyUpgrade(), payer(), Progression.addMastery(), Progression.applyWalkSpeed() (+9 more)

### Community 81 - "ui_preview.py"
Cohesion: 0.12
Nodes (21): backdrop(), Canvas, cmap(), draw_element(), draw_text(), emoji_image(), fill_image(), font() (+13 more)

### Community 82 - "Controllers/Interaction.luau"
Cohesion: 0.20
Nodes (13): aimingCenter(), castAt(), findTarget(), hrp(), inRange(), Interaction.highlightRecipe(), Interaction.Init(), Interaction.Start() (+5 more)

### Community 83 - "Placement.validate"
Cohesion: 0.30
Nodes (11): Placement.near(), Footprint.axes(), Footprint.bounds(), Footprint.corners(), Footprint.insideRects(), Footprint.new(), Footprint.overlaps(), Footprint.pointIn() (+3 more)

### Community 84 - "boot.lua"
Cohesion: 0.20
Nodes (16): child(), joinArgs(), nodeAt(), print(), props(), relPath(), require(), runScript() (+8 more)

### Community 85 - "newInstance"
Cohesion: 0.17
Nodes (11): defaultsFor(), newInstance(), goTo(), heard(), join(), cm.DataModel.GetService(), cm.Player.LoadCharacter(), cm.Players.CreateHumanoidModelFromDescription() (+3 more)

### Community 86 - "Controllers/Data.luau"
Cohesion: 0.17
Nodes (15): Data.canBuild(), Data.isMine(), Data.m(), Data.plotAttr(), Data.plotFolder(), Data.plotId(), Data.restaurant(), Data.w() (+7 more)

### Community 87 - "Walls.luau"
Cohesion: 0.39
Nodes (8): Placement.wallSpot(), cut(), floorCells(), key(), merge(), Walls.along(), Walls.compute(), Walls.distance()

### Community 88 - "HUD.luau"
Cohesion: 0.11
Nodes (6): allowed(), Dev.Init(), Dev.Start(), run(), SelfTest.run(), waitFor()

### Community 89 - "Services/Analytics.luau"
Cohesion: 0.38
Nodes (9): Analytics.levelUp(), Analytics.sakura(), Analytics.sink(), Analytics.source(), Analytics.Start(), Analytics.step(), flush(), isPlayer() (+1 more)

### Community 90 - "Asset da procurare — modelli, icone e suoni"
Cohesion: 0.25
Nodes (7): Asset da procurare — modelli, icone e suoni, Come si sostituisce un modello, Icone dell'interfaccia, Piatti, Priorità, Stile, Suoni e musica

### Community 92 - "RamenYa.luau"
Cohesion: 0.26
Nodes (9): banner(), bowlArt(), high(), label(), nc(), pendant(), point(), posterRow() (+1 more)

### Community 93 - "Furniture.luau"
Cohesion: 0.38
Nodes (13): chair(), condiments(), counter(), cushion(), ledgeProps(), nc(), placeSetting(), point() (+5 more)

### Community 94 - "Locale.get"
Cohesion: 0.17
Nodes (12): Data.applyLanguage(), Data.Init(), Data.Start(), deviceKey(), Kit.T(), Locale.has(), Locale.name(), Locale.resolve() (+4 more)

### Community 95 - "Appliance.luau"
Cohesion: 0.15
Nodes (28): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.hold(), Appliance.Init(), Appliance.needsRefill(), Appliance.sinkPile(), Appliance.Start() (+20 more)

### Community 96 - "Cooking.luau"
Cohesion: 0.18
Nodes (19): broadcast(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init(), Cooking.isRecipeInProgress(), Cooking.maxTickets(), Cooking.readyDishes(), Cooking.removeTicket() (+11 more)

### Community 97 - "Economy.luau"
Cohesion: 0.19
Nodes (15): drawJars(), Economy.add(), Economy.boostActive(), Economy.charge(), Economy.collectTips(), Economy.ledgerOf(), Economy.multiplier(), Economy.redrawJars() (+7 more)

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

### Community 99 - "Day.luau"
Cohesion: 0.27
Nodes (5): Day.broadcast(), Day.isNight(), Day.Start(), finish(), payload()

### Community 100 - "Controllers/Tutorial.luau"
Cohesion: 0.16
Nodes (14): advance(), finish(), hide(), orderStation(), paintDots(), purchases(), save(), show() (+6 more)

### Community 101 - "Leaderboard.luau"
Cohesion: 0.53
Nodes (5): fetch(), Leaderboard.Init(), Leaderboard.Start(), nameOf(), submit()

### Community 102 - "methods.Destroy"
Cohesion: 0.50
Nodes (4): typeof(), checkStorable(), cm.AnalyticsService.LogEconomyEvent(), encode()

### Community 103 - "task.delay"
Cohesion: 0.13
Nodes (19): Sim.runScenario(), toClient(), hpop(), hpush(), less(), pack(), resume(), schedule() (+11 more)

### Community 104 - "Hands.luau"
Cohesion: 0.20
Nodes (22): Appliance.load(), Appliance.useDishwasher(), Service.collectDirty(), Service.use(), buildVisual(), character(), Hands.add(), Hands.capacity() (+14 more)

### Community 105 - "asset_list.py"
Cohesion: 0.38
Nodes (3): load_names(), lua_list(), main()

### Community 107 - "pdata"
Cohesion: 0.15
Nodes (22): Appliance.willHave(), Service.availableMenu(), autoRestockPlot(), deliver(), deliveryLoop(), deliveryTime(), dropSpots(), freeDropSpot() (+14 more)

### Community 109 - "FirstPerson.luau"
Cohesion: 0.17
Nodes (19): active(), clearViews(), FirstPerson.cursorFree(), FirstPerson.Start(), setHeldLabels(), shortcut(), supplierKey(), syncViews() (+11 more)

### Community 110 - "ShelfTags.luau"
Cohesion: 0.52
Nodes (6): makeTag(), place(), setText(), ShelfTags.Init(), ShelfTags.Start(), update()

### Community 115 - "Guide.luau"
Cohesion: 0.24
Nodes (14): clearMarks(), distance(), Guide.close(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show(), hands() (+6 more)

### Community 116 - "Color.hex"
Cohesion: 0.21
Nodes (13): icons(), make(), makeCustomer(), outline(), paintRankings(), rankingGui(), rankLabel(), rankRow() (+5 more)

### Community 117 - "shared_models_registry"
Cohesion: 0.60
Nodes (3): Ambient.Start(), offset(), track()

### Community 118 - "Controllers/Audio.luau"
Cohesion: 0.18
Nodes (17): runTrain(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start(), Audio.step(), Audio.trainVolume(), customersInside() (+9 more)

### Community 119 - "Logic/Shop.luau"
Cohesion: 0.47
Nodes (9): finish(), level(), Shop.ad(), Shop.buyable(), Shop.expansion(), Shop.hire(), Shop.license(), Shop.staffSlots() (+1 more)

### Community 120 - "Effects.luau"
Cohesion: 0.40
Nodes (10): arc(), burst(), coinsToWallet(), comboBanner(), confetti(), Effects.Init(), popup(), product() (+2 more)

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

### Community 132 - "className"
Cohesion: 0.20
Nodes (18): bounds(), className(), isA(), methods.FindFirstAncestorOfClass(), methods.FindFirstAncestorWhichIsA(), methods.FindFirstChildWhichIsA(), methods.GetBoundingBox(), methods.GetDescendants() (+10 more)

### Community 133 - "7. Salvataggi"
Cohesion: 0.50
Nodes (4): 7. Salvataggi, Regole, Replica al client, Schema (versione 1)

### Community 134 - "pdata"
Cohesion: 0.24
Nodes (10): bumpCombo(), leaveDirty(), pay(), pdata(), serveQueue(), Service.serve(), spawnLoop(), tick() (+2 more)

### Community 138 - "shared_logic_formulas"
Cohesion: 0.31
Nodes (5): grantPass(), Monetization.has(), Monetization.Init(), Monetization.yenMultiplier(), passCfg()

### Community 139 - "Timing.luau"
Cohesion: 0.32
Nodes (5): hide(), Timing.active(), Timing.hit(), Timing.result(), Timing.start()

### Community 140 - "Sim.press"
Cohesion: 0.67
Nodes (3): casDispatch(), inputObject(), Sim.press()

### Community 143 - "script_parent_parent_core"
Cohesion: 0.47
Nodes (3): Interaction.Init(), sizeMargin(), targetPosition()

### Community 144 - "Supplier.luau"
Cohesion: 0.53
Nodes (4): cartForMenu(), lowForMenu(), stock(), unlocked()

### Community 145 - "Lighting.luau"
Cohesion: 0.53
Nodes (5): blend(), LightingC.Init(), LightingC.Start(), look(), track()

### Community 146 - "Format.luau"
Cohesion: 0.47
Nodes (5): HUD.day(), Format.clock(), Format.number(), Format.sakura(), group()

### Community 147 - "Service.trySpawn"
Cohesion: 0.33
Nodes (6): chooseOrder(), countOf(), pickType(), Service.trySpawn(), Formulas.demandFactor(), TableUtil.weightedPick()

### Community 148 - "floors.lua"
Cohesion: 0.60
Nodes (3): railAt(), steps(), tagged()

### Community 149 - "review"
Cohesion: 0.50
Nodes (4): dirtyNear(), review(), Economy.addSakura(), Progression.addReview()

### Community 150 - "ShelfGrid.luau"
Cohesion: 0.67
Nodes (3): ShelfGrid.cell(), ShelfGrid.dims(), ShelfGrid.forIngredient()

## Knowledge Gaps
- **47 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `Hints.luau`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`, `7. Salvataggi`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Are the 100 inferred relationships involving `Kit.box()` (e.g. with `makeScene()` and `B.doorFrame()`) actually correct?**
  _`Kit.box()` has 100 INFERRED edges - model-reasoned connections that need verification._
- **Should `Services/Staff.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.1321353065539112 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Hints.luau` to `Piano tecnico — architettura e implementazione`, `Appliance.luau`?**
  _High betweenness centrality (0.053) - this node is a cross-community bridge._
- **Are the 60 inferred relationships involving `Kit.cyl()` (e.g. with `makeScene()` and `B.entranceDetail()`) actually correct?**
  _`Kit.cyl()` has 60 INFERRED edges - model-reasoned connections that need verification._
- **Should `sim/client.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Why does `Color.hex()` connect `Kit.new` to `Scene.luau`, `People.luau`, `Kit.box`, `Kit.cyl`, `Controllers/Build.luau`, `Street.luau`, `Food.luau`, `Controllers/Interaction.luau`, `Guide.luau`, `Color.hex`, `Effects.luau`, `RamenYa.luau`, `Appliance.luau`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._