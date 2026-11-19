# Graph Report - Roblox-Ramen-game  (2026-11-19)

## Corpus Check
- 165 files · ~226,730 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 2025 nodes · 4988 edges · 136 communities (92 shown, 44 thin omitted)
- Extraction: 80% EXTRACTED · 20% INFERRED · 0% AMBIGUOUS · INFERRED: 999 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3d4d8e55`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Controllers/Audio.luau
- Appliance.luau
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
- gui.lua
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
- ui_preview.py
- Controllers/Interaction.luau
- Footprint.luau
- boot.lua
- Npc.luau
- Controllers/Data.luau
- Walls.luau
- Services/Analytics.luau
- Progression.luau
- gen.py
- RamenYa.luau
- Furniture.luau
- Net.luau
- Screens/Build.luau
- Economy.luau
- typeof
- 10. Interfaccia
- Day.luau
- Controllers/Tutorial.luau
- Leaderboard.luau
- HUD.luau
- task.delay
- Cooking.luau
- script_parent_parent_core
- Screens/Shop.luau
- Ambience.compute
- Locale/init.luau
- pdata
- Guide.luau
- Color.hex
- UI.luau
- shared_util_color
- Logic/Shop.luau
- shared_logic_formulas
- Registry.luau
- ShelfTags.luau
- runLocal
- camBasis
- Sim.click
- fromClient
- Effects.luau
- Services/Rewards.luau
- Format.luau
- review

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 102 edges
2. `Kit.cyl()` - 61 edges
3. `nc()` - 53 edges
4. `Kit.new()` - 40 edges
5. `Color.hex()` - 37 edges
6. `Kit.blob()` - 36 edges
7. `Kit.part()` - 35 edges
8. `Scene.shell()` - 34 edges
9. `Kit.finish()` - 32 edges
10. `add()` - 31 edges

## Surprising Connections (you probably didn't know these)
- `12. Interfaccia e lingue` --references--> `close()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/client/Controllers/Hints.luau
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau
- `Giornata ed economia` --references--> `finish()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Day.luau
- `Sim.snapshot()` --calls--> `Sim.dumpGui()`  [INFERRED]
  tools/sim/client.lua → tools/sim/gui.lua
- `Timing.result()` --calls--> `Audio.play()`  [INFERRED]
  src/client/Controllers/Timing.luau → src/client/Controllers/Audio.luau

## Import Cycles
- None detected.

## Communities (136 total, 44 thin omitted)

### Community 0 - "Controllers/Audio.luau"
Cohesion: 0.18
Nodes (17): runTrain(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start(), Audio.step(), Audio.trainVolume(), customersInside() (+9 more)

### Community 1 - "Appliance.luau"
Cohesion: 0.06
Nodes (90): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.hold(), Appliance.Init(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile() (+82 more)

### Community 2 - "sim/client.lua"
Cohesion: 0.04
Nodes (3): inputObject(), Sim.press(), Sim.snapshot()

### Community 3 - "services.lua"
Cohesion: 0.02
Nodes (15): cm.AnalyticsService.LogCustomEvent(), cm.AnalyticsService.LogFunnelStepEvent(), cm.AnalyticsService.LogOnboardingFunnelStepEvent(), cm.AnalyticsService.LogProgressionEvent(), cm.DataStoreService.GetDataStore(), cm.DataStoreService.GetGlobalDataStore(), cm.DataStoreService.GetOrderedDataStore(), cm.MemoryStoreService.GetQueue() (+7 more)

### Community 4 - "Supply.luau"
Cohesion: 0.11
Nodes (44): Service.availableMenu(), autoRestockPlot(), boxModel(), cellFloor(), chooseSlot(), deliver(), deliveryLoop(), deliveryTime() (+36 more)

### Community 5 - "Kit.box"
Cohesion: 0.24
Nodes (23): B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.openSign(), B.parapet() (+15 more)

### Community 6 - "Services/Placement.luau"
Cohesion: 0.18
Nodes (26): Net.fire(), Net.fxTo(), Net.notify(), buildPlot(), canAfford(), changed(), checkVetoes(), children() (+18 more)

### Community 7 - "Kit.new"
Cohesion: 0.20
Nodes (39): FirstPerson.Init(), Hints.Init(), Tutorial.Init(), UI.toast(), fitWindow(), Kit.badge(), Kit.bar(), Kit.bump() (+31 more)

### Community 8 - "re"
Cohesion: 0.22
Nodes (6): defined(), main(), load(), main(), members(), table_keys()

### Community 9 - "mock.lua"
Cohesion: 0.07
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChild(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA() (+11 more)

### Community 10 - "Kit.cyl"
Cohesion: 0.17
Nodes (29): makeScene(), bonsai(), chochin(), foliage(), frame(), lanternString(), maneki(), neon() (+21 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.11
Nodes (40): Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry(), Build.Init(), Build.place(), Build.removeSelected() (+32 more)

### Community 12 - "Street.luau"
Cohesion: 0.21
Nodes (25): acUnit(), aframe(), balcony(), lp(), NC(), rng(), S.bicycle(), S.bins() (+17 more)

### Community 13 - "Food.luau"
Cohesion: 0.13
Nodes (67): shisa(), baran(), blobAt(), box(), boxContents(), boxLabel(), c(), cabbage() (+59 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.14
Nodes (28): acquire(), Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save() (+20 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (19): 11. Costruzione e griglia, 12. Interfaccia e lingue, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro (+11 more)

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
Cohesion: 0.15
Nodes (19): Progression.addMastery(), Progression.addXp(), Progression.priceOf(), Formulas.addXp(), Formulas.dishPrice(), Formulas.incomeMultiplier(), Formulas.levelReward(), Formulas.masteryLevel() (+11 more)

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
Cohesion: 0.15
Nodes (27): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.setBuildView(), Camera.setTop() (+19 more)

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
Cohesion: 0.15
Nodes (8): claimedSet(), elapsed(), nextGift(), screen.tick(), cartForMenu(), lowForMenu(), stock(), unlocked()

### Community 48 - "Seating.luau"
Cohesion: 0.21
Nodes (6): busy(), free(), Seating.find(), Seating.freeCount(), Seating.Init(), Seating.list()

### Community 50 - "Services/Plots.luau"
Cohesion: 0.19
Nodes (22): claim(), dedupe(), friends(), Plots.at(), Plots.canBuild(), Plots.canWork(), Plots.data(), Plots.fire() (+14 more)

### Community 64 - "Scene.luau"
Cohesion: 0.10
Nodes (10): World.surfaceOf(), Footprint.subtractRect(), facadeColor(), floorY(), holesFor(), indoorAt(), Scene.surfaceOf(), style() (+2 more)

### Community 65 - "env.lua"
Cohesion: 0.04
Nodes (55): ancestors(), attrSignal(), bounds(), className(), cloneTree(), eventOf(), inGame(), kids() (+47 more)

### Community 66 - "People.luau"
Cohesion: 0.22
Nodes (36): add(), apron(), backpack(), ball(), belt(), blob(), body(), c() (+28 more)

### Community 67 - "gui.lua"
Cohesion: 0.15
Nodes (41): cm.TextService.GetTextSize(), isA(), alignOffset(), automatic(), baseSize(), charWidth(), cls(), colorStops() (+33 more)

### Community 69 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.22
Nodes (9): Anteprima dei modelli (senza Studio), Anteprima dell'interfaccia (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio), Simulatore del server (senza Studio) (+1 more)

### Community 70 - "props"
Cohesion: 0.10
Nodes (24): cm.BindableFunction.Invoke(), cm.Humanoid.AddAccessory(), cm.Humanoid.ChangeState(), cm.Humanoid.GetAccessories(), cm.Humanoid.GetState(), cm.Humanoid.GetStateEnabled(), cm.Humanoid.LoadAnimation(), cm.Humanoid.RemoveAccessories() (+16 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Services/Customers.luau"
Cohesion: 0.15
Nodes (18): bumpCombo(), dishKind(), eat(), entrance(), floorPos(), leaveRestaurant(), patienceTick(), release() (+10 more)

### Community 73 - "check_luau.py"
Cohesion: 0.18
Nodes (12): build_tree(), add_path(), walk(), check_blocks(), check_locale(), check_requires(), load_locale(), long_bracket() (+4 more)

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Kitchen.luau"
Cohesion: 0.30
Nodes (18): backsplash(), bowlStack(), brothPot(), cabinet(), fittedBase(), hood(), knobs(), nc() (+10 more)

### Community 76 - "sim.py"
Cohesion: 0.18
Nodes (12): luau_to_lua(), main(), make_runtime(), read(), project_entries(), run(), run_scenario(), main() (+4 more)

### Community 77 - "methods.FindFirstChild"
Cohesion: 0.10
Nodes (20): Sim.waitFor(), Sim.trigger(), defaultsFor(), newInstance(), task.wait(), use(), goTo(), goTo() (+12 more)

### Community 78 - "Placement.validate"
Cohesion: 0.27
Nodes (10): Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY(), Placement.footprint(), Placement.pathOk(), Placement.pathTargets() (+2 more)

### Community 79 - "Meta.luau"
Cohesion: 0.15
Nodes (14): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), computeOffline(), dayIndex(), ensureQuests(), Meta.dayEnded() (+6 more)

### Community 81 - "ui_preview.py"
Cohesion: 0.12
Nodes (21): backdrop(), Canvas, cmap(), draw_element(), draw_text(), emoji_image(), fill_image(), font() (+13 more)

### Community 82 - "Controllers/Interaction.luau"
Cohesion: 0.20
Nodes (17): actionText(), aimingCenter(), castAt(), findTarget(), handsKind(), hrp(), inRange(), Interaction.lockOf() (+9 more)

### Community 83 - "Footprint.luau"
Cohesion: 0.22
Nodes (16): Placement.near(), closestPoint(), gap(), Seating.refresh(), topY(), Footprint.axes(), Footprint.bounds(), Footprint.corners() (+8 more)

### Community 84 - "boot.lua"
Cohesion: 0.20
Nodes (16): child(), joinArgs(), nodeAt(), print(), props(), relPath(), require(), runScript() (+8 more)

### Community 85 - "Npc.luau"
Cohesion: 0.16
Nodes (12): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.sit(), Npc.spawn() (+4 more)

### Community 86 - "Controllers/Data.luau"
Cohesion: 0.20
Nodes (14): Data.canBuild(), Data.isMine(), Data.m(), Data.plotAttr(), Data.plotFolder(), Data.plotId(), Data.restaurant(), Data.w() (+6 more)

### Community 87 - "Walls.luau"
Cohesion: 0.43
Nodes (6): cut(), floorCells(), key(), merge(), Walls.along(), Walls.compute()

### Community 89 - "Services/Analytics.luau"
Cohesion: 0.38
Nodes (9): Analytics.levelUp(), Analytics.sakura(), Analytics.sink(), Analytics.source(), Analytics.Start(), Analytics.step(), flush(), isPlayer() (+1 more)

### Community 90 - "Progression.luau"
Cohesion: 0.25
Nodes (12): buyAd(), buyLicense(), buyUpgrade(), payer(), Progression.addReview(), Progression.applyWalkSpeed(), Progression.isRecipeUnlocked(), Progression.menuRecipes() (+4 more)

### Community 92 - "RamenYa.luau"
Cohesion: 0.24
Nodes (10): banner(), bowlArt(), high(), label(), nc(), pendant(), pitcher(), point() (+2 more)

### Community 93 - "Furniture.luau"
Cohesion: 0.38
Nodes (13): chair(), condiments(), counter(), cushion(), ledgeProps(), nc(), placeSetting(), point() (+5 more)

### Community 94 - "Net.luau"
Cohesion: 0.12
Nodes (13): open(), Service.check(), Net.fireAll(), Net.fx(), Net.invoke(), Net.notifyAll(), Net.num(), Net.on() (+5 more)

### Community 95 - "Screens/Build.luau"
Cohesion: 0.17
Nodes (17): stepText(), Icons.forItem(), Kit.clear(), itemCard(), itemLocked(), renderItems(), renderTabs(), Screen.open() (+9 more)

### Community 96 - "Economy.luau"
Cohesion: 0.19
Nodes (15): pay(), drawJars(), Economy.add(), Economy.boostActive(), Economy.charge(), Economy.collectTips(), Economy.ledgerOf(), Economy.multiplier() (+7 more)

### Community 97 - "typeof"
Cohesion: 0.29
Nodes (7): fireIf(), methods.SetAttribute(), typeof(), checkStorable(), cm.AnalyticsService.LogEconomyEvent(), cm.Player.SetAttribute(), encode()

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

### Community 99 - "Day.luau"
Cohesion: 0.31
Nodes (5): Day.broadcast(), Day.isNight(), Day.Start(), finish(), payload()

### Community 100 - "Controllers/Tutorial.luau"
Cohesion: 0.05
Nodes (35): Data.role(), aim(), close(), dockButton(), Hints.Start(), open(), seen(), shopBadge() (+27 more)

### Community 101 - "Leaderboard.luau"
Cohesion: 0.53
Nodes (5): fetch(), Leaderboard.Init(), Leaderboard.Start(), nameOf(), submit()

### Community 102 - "HUD.luau"
Cohesion: 0.15
Nodes (11): HUD.bumpWallet(), HUD.currentGoal(), HUD.layout(), HUD.refreshGift(), HUD.refreshGoal(), HUD.refreshHands(), HUD.setBuilding(), keyboard() (+3 more)

### Community 103 - "task.delay"
Cohesion: 0.13
Nodes (19): Sim.runScenario(), toClient(), hpop(), hpush(), less(), pack(), resume(), schedule() (+11 more)

### Community 104 - "Cooking.luau"
Cohesion: 0.17
Nodes (20): broadcast(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init(), Cooking.isRecipeInProgress(), Cooking.maxTickets(), Cooking.readyDishes(), Cooking.removeTicket() (+12 more)

### Community 106 - "script_parent_parent_core"
Cohesion: 0.12
Nodes (12): Ambient.Start(), offset(), track(), allowed(), Dev.Init(), Dev.Start(), run(), Interaction.Init() (+4 more)

### Community 107 - "Screens/Shop.luau"
Cohesion: 0.33
Nodes (14): BUILD.recipes(), BUILD.reno(), BUILD.rooms(), BUILD.staff(), BUILD.upgrades(), card(), cardSize(), effectText() (+6 more)

### Community 109 - "Locale/init.luau"
Cohesion: 0.17
Nodes (12): Data.applyLanguage(), Data.Init(), Data.Start(), Kit.T(), Locale.has(), Locale.name(), Locale.resolve(), Locale.set() (+4 more)

### Community 110 - "pdata"
Cohesion: 0.18
Nodes (13): chooseOrder(), countOf(), leaveDirty(), pdata(), pickType(), serveQueue(), Service.trySpawn(), spawnLoop() (+5 more)

### Community 115 - "Guide.luau"
Cohesion: 0.24
Nodes (15): clearMarks(), distance(), Guide.close(), Guide.create(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show() (+7 more)

### Community 116 - "Color.hex"
Cohesion: 0.22
Nodes (11): Interaction.highlightRecipe(), Interaction.Init(), icons(), make(), makeCustomer(), setBar(), updateEntity(), updateStaff() (+3 more)

### Community 117 - "UI.luau"
Cohesion: 0.25
Nodes (12): measure(), UI.blockTouch(), UI.close(), UI.Init(), UI.isTouch(), UI.open(), UI.refreshAll(), UI.register() (+4 more)

### Community 118 - "shared_util_color"
Cohesion: 0.14
Nodes (10): blend(), LightingC.Init(), LightingC.Start(), look(), track(), Pointer:step(), shown(), launch() (+2 more)

### Community 119 - "Logic/Shop.luau"
Cohesion: 0.45
Nodes (9): finish(), level(), Shop.ad(), Shop.buyable(), Shop.expansion(), Shop.hire(), Shop.license(), Shop.staffSlots() (+1 more)

### Community 120 - "shared_logic_formulas"
Cohesion: 0.31
Nodes (5): grantPass(), Monetization.has(), Monetization.Init(), Monetization.yenMultiplier(), passCfg()

### Community 122 - "ShelfTags.luau"
Cohesion: 0.52
Nodes (6): makeTag(), place(), setText(), ShelfTags.Init(), ShelfTags.Start(), update()

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

### Community 127 - "Effects.luau"
Cohesion: 0.40
Nodes (10): arc(), burst(), coinsToWallet(), comboBanner(), confetti(), Effects.Init(), popup(), product() (+2 more)

### Community 132 - "Services/Rewards.luau"
Cohesion: 0.33
Nodes (7): claimGift(), grant(), leaderstats(), onPlayer(), publishClaimed(), redeemCode(), Rewards.Start()

### Community 133 - "Format.luau"
Cohesion: 0.47
Nodes (5): HUD.day(), Format.clock(), Format.number(), Format.sakura(), group()

### Community 134 - "review"
Cohesion: 0.67
Nodes (3): dirtyNear(), review(), Economy.addSakura()

## Knowledge Gaps
- **44 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Piano tecnico — architettura e implementazione` connect `Piano tecnico — architettura e implementazione` to `7. Salvataggi`, `10. Sistemi di gioco`, `01-GAME-DESIGN.md`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Are the 97 inferred relationships involving `Kit.box()` (e.g. with `makeScene()` and `B.doorFrame()`) actually correct?**
  _`Kit.box()` has 97 INFERRED edges - model-reasoned connections that need verification._
- **Should `Appliance.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.056175047338523035 - nodes in this community are weakly interconnected._
- **Why does `12. Interfaccia e lingue` connect `Piano tecnico — architettura e implementazione` to `Appliance.luau`, `Controllers/Tutorial.luau`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **Are the 59 inferred relationships involving `Kit.cyl()` (e.g. with `makeScene()` and `B.entranceDetail()`) actually correct?**
  _`Kit.cyl()` has 59 INFERRED edges - model-reasoned connections that need verification._
- **Should `sim/client.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Why does `Color.hex()` connect `Color.hex` to `Scene.luau`, `Appliance.luau`, `People.luau`, `Kit.box`, `Kit.new`, `Kit.cyl`, `Controllers/Build.luau`, `Screens/Shop.luau`, `Food.luau`, `Street.luau`, `Controllers/Interaction.luau`, `Guide.luau`, `Npc.luau`, `shared_util_color`, `RamenYa.luau`, `Effects.luau`?**
  _High betweenness centrality (0.053) - this node is a cross-community bridge._