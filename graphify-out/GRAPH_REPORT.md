# Graph Report - Roblox-Ramen-game  (2026-11-25)

## Corpus Check
- 183 files · ~267,064 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 2175 nodes · 5367 edges · 158 communities (104 shown, 54 thin omitted)
- Extraction: 80% EXTRACTED · 20% INFERRED · 0% AMBIGUOUS · INFERRED: 1098 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `12e0709b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Screens/Build.luau
- Tasks.luau
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
- 5. Cucina
- Signal.luau
- 9. Costruzione e decorazione
- 10. Sistemi di gioco
- Hands.luau
- Camera.luau
- 4. Rifornimento: tablet, consegne, magazzino, mensole
- 2. Il mondo
- 3. Ciclo di gioco
- 6. Clienti
- Phone.luau
- Net/init.luau
- Sakura Ramen & Sushi Tycoon — istruzioni per Claude
- shared_locale
- Events.luau
- HUD.luau
- Seating.luau
- World.luau
- Services/Plots.luau
- Scene.luau
- env.lua
- People.luau
- gui.lua
- className
- props
- preview.py
- Services/Customers.luau
- check_luau.py
- build_place.py
- Kitchen.luau
- sim.py
- progression.lua
- Logic/Placement.luau
- Meta.luau
- script_parent_parent_core
- ui_preview.py
- Controllers/Interaction.luau
- Placement.validate
- boot.lua
- cloneTree
- Controllers/Data.luau
- Walls.luau
- Net.notify
- Services/Analytics.luau
- RamenYa.luau
- Furniture.luau
- Locale.get
- Appliance.luau
- Cooking.luau
- Economy.luau
- 10. Interfaccia
- Services/Staff.luau
- Controllers/Tutorial.luau
- Lighting.luau
- logAnalytics
- task.delay
- props
- asset_list.py
- Sakura Ramen & Sushi Tycoon (titolo provvisorio)
- street.lua
- Neighbours.luau
- Asset da procurare — modelli, icone e suoni
- Guide.luau
- Color.hex
- 5. Catalogo oggetti piazzabili
- Controllers/Audio.luau
- Logic/Shop.luau
- ShelfTags.luau
- Hints.luau
- runLocal
- Format.luau
- Sim.click
- Geometry.compute
- Services/Signs.luau
- 7. Salvataggi
- shared_logic_formulas
- Net.on
- script_parent_parent_core
- methods.Destroy
- copyArgs
- TableUtil.deepCopy
- camBasis
- scenarios/tutorial.lua
- floors.lua
- Ambience.compute
- Sim.press
- fromClient
- loop.lua
- neighbours.lua
- Sim.rig
- methods.GetTags
- methods.HasTag

## God Nodes (most connected - your core abstractions)
1. `Kit.box()` - 108 edges
2. `Kit.cyl()` - 65 edges
3. `nc()` - 54 edges
4. `Color.hex()` - 46 edges
5. `Kit.new()` - 43 edges
6. `Kit.blob()` - 38 edges
7. `Scene.shell()` - 36 edges
8. `Kit.part()` - 35 edges
9. `Kit.finish()` - 32 edges
10. `add()` - 32 edges

## Surprising Connections (you probably didn't know these)
- `14. Prestazioni` --references--> `quiet()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/World.luau
- `9. Modelli procedurali e grafica` --references--> `withShape()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/shared/Models/Kit.luau
- `8. Costruzione del mondo` --references--> `deliver()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Supply.luau
- `Giornata ed economia` --references--> `finish()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Day.luau
- `12. Interfaccia e lingue` --references--> `refresh()`  [INFERRED]
  docs/02-PIANO-TECNICO.md → src/server/Services/Appliance.luau

## Import Cycles
- None detected.

## Communities (158 total, 54 thin omitted)

### Community 0 - "Screens/Build.luau"
Cohesion: 0.14
Nodes (17): stepText(), paintSigns(), Icons.forItem(), Kit.clear(), itemCard(), itemLocked(), renderItems(), renderTabs() (+9 more)

### Community 1 - "Tasks.luau"
Cohesion: 0.19
Nodes (27): carryBoxTo(), customerEntity(), deliverDish(), doCollect(), doCook(), doOrder(), doRefill(), doRestock() (+19 more)

### Community 3 - "services.lua"
Cohesion: 0.02
Nodes (12): cm.DataStoreService.GetDataStore(), cm.DataStoreService.GetGlobalDataStore(), cm.DataStoreService.GetOrderedDataStore(), cm.MemoryStoreService.GetQueue(), cm.MemoryStoreService.GetSortedMap(), cm.Player.Kick(), cm.Players.GetPlayerByUserId(), cm.Players.GetPlayerFromCharacter() (+4 more)

### Community 4 - "Supply.luau"
Cohesion: 0.10
Nodes (46): animateTruck(), autoRestockPlot(), boxModel(), cellFloor(), chooseSlot(), deliver(), deliveryLoop(), deliveryTime() (+38 more)

### Community 5 - "Kit.box"
Cohesion: 0.18
Nodes (29): B.doorFrame(), B.eave(), B.entranceDetail(), B.entranceNoren(), B.facadeDetail(), B.floorSkin(), B.ledSign(), B.openSign() (+21 more)

### Community 6 - "Services/Placement.luau"
Cohesion: 0.21
Nodes (22): Net.fxTo(), buildPlot(), canAfford(), changed(), checkVetoes(), children(), despawn(), findEntry() (+14 more)

### Community 7 - "Kit.new"
Cohesion: 0.18
Nodes (44): FirstPerson.Init(), Hints.Init(), Tutorial.Init(), placeHolder(), UI.Init(), UI.popup(), UI.rescale(), UI.toast() (+36 more)

### Community 8 - "re"
Cohesion: 0.16
Nodes (8): defined(), main(), load(), main(), members(), table_keys(), main(), read_module()

### Community 9 - "mock.lua"
Cohesion: 0.08
Nodes (19): CF.Inverse(), CF.Lerp(), children(), methods.ClearAllChildren(), methods.Destroy(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA(), methods.GetChildren() (+11 more)

### Community 10 - "Kit.cyl"
Cohesion: 0.17
Nodes (29): makeScene(), bonsai(), chochin(), foliage(), frame(), lanternString(), maneki(), neon() (+21 more)

### Community 11 - "Controllers/Build.luau"
Cohesion: 0.06
Nodes (55): Ambient.Start(), offset(), track(), Build.cancel(), Build.cycleGrid(), Build.enter(), Build.exit(), Build.geometry() (+47 more)

### Community 12 - "Street.luau"
Cohesion: 0.19
Nodes (28): acUnit(), aframe(), balcony(), lp(), NC(), rng(), S.bicycle(), S.bins() (+20 more)

### Community 13 - "Food.luau"
Cohesion: 0.14
Nodes (64): baran(), blobAt(), box(), boxContents(), boxLabel(), c(), cabbage(), chashuSlice() (+56 more)

### Community 14 - "Services/Data.luau"
Cohesion: 0.18
Nodes (22): acquire(), Data.changed(), Data.get(), Data.Init(), Data.isLoaded(), Data.newProfile(), Data.reset(), Data.save() (+14 more)

### Community 15 - "Piano tecnico — architettura e implementazione"
Cohesion: 0.11
Nodes (18): 11. Costruzione e griglia, 13. Rete e sicurezza, 14. Prestazioni, 15. Test e controlli, 16. Ordine di implementazione, 17. Rischi tecnici, 1. Strumenti e flusso di lavoro, 2. Struttura del progetto (+10 more)

### Community 16 - "Bilanciamento — numeri, prezzi e sblocchi"
Cohesion: 0.12
Nodes (16): 10. Ricompense e meta, 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere), 1. Formule principali, 2. Ingredienti (scatole del fornitore), 3. Ricette, 4. Licenze, 6. Miglioramenti, 7. Personale (+8 more)

### Community 17 - "UI.luau"
Cohesion: 0.08
Nodes (33): active(), clearViews(), FirstPerson.cursorFree(), FirstPerson.Start(), setHeldLabels(), shortcut(), supplierKey(), syncViews() (+25 more)

### Community 18 - "8. Progressione"
Cohesion: 0.15
Nodes (13): 8.10 Eventi stagionali, 8.1 Valute, 8.2 Livello del ristorante (XP), 8.3 Licenze, 8.4 Miglioramenti (upgrade), 8.5 bis Cartelli "in vendita", 8.5 Espansioni, 8.6 Personale (automazione) (+5 more)

### Community 19 - "Sakura Ramen & Sushi Tycoon — Game Design Document"
Cohesion: 0.20
Nodes (10): 0. Decisioni già prese, 11. Grafica e atmosfera, 12. Monetizzazione (predisposta), 13. Priorità di realizzazione, 14. Da decidere più avanti (non blocca lo sviluppo), 1. Visione, 7. Menu e prezzi, Durata prevista (+2 more)

### Community 20 - "Screens/Shop.luau"
Cohesion: 0.31
Nodes (15): BUILD.recipes(), BUILD.reno(), BUILD.rooms(), BUILD.staff(), BUILD.upgrades(), card(), cardSize(), effectText() (+7 more)

### Community 22 - "5. Cucina"
Cohesion: 0.22
Nodes (9): 5.1 bis La postazione fa da sola, 5.1 Ordini, 5.1 ter Noodles perfetti (facoltativo), 5.2 Preparare il sushi (postazione sushi / tagliere), 5.3 Preparare il ramen (postazione ramen), 5.4 Altre postazioni (sbloccate con licenze), 5.5 Velocità e freschezza, 5.6 Servire, pagare, pulire (+1 more)

### Community 24 - "Signal.luau"
Cohesion: 0.38
Nodes (3): Signal:Connect(), Signal:Once(), Signal:Wait()

### Community 25 - "9. Costruzione e decorazione"
Cohesion: 0.29
Nodes (7): 9.1 Modalità costruzione, 9.2 Tipi di piazzamento, 9.3 Regole di validità, 9.4 Pavimenti e pareti, 9.5 Ambiente, 9.6 L'insegna del ristorante, 9. Costruzione e decorazione

### Community 26 - "10. Sistemi di gioco"
Cohesion: 0.33
Nodes (6): 10. Sistemi di gioco, Clienti (macchina a stati), Giornata ed economia, Interazione, Personale (bacheca dei compiti), Preparazione a pressioni

### Community 27 - "Hands.luau"
Cohesion: 0.21
Nodes (21): Appliance.useDishwasher(), Service.collectDirty(), Service.use(), buildVisual(), character(), Hands.add(), Hands.capacity(), Hands.clear() (+13 more)

### Community 28 - "Camera.luau"
Cohesion: 0.16
Nodes (23): Camera.apply(), Camera.applyRoofs(), Camera.currentFloor(), Camera.isFirstPerson(), Camera.isIndoors(), Camera.mode(), Camera.scaleTurn(), Camera.setBuildView() (+15 more)

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

### Community 33 - "Phone.luau"
Cohesion: 0.47
Nodes (3): launch(), Phone.open(), Phone.refresh()

### Community 34 - "Net/init.luau"
Cohesion: 0.83
Nodes (3): getFolder(), Net.event(), Net.func()

### Community 36 - "shared_locale"
Cohesion: 0.11
Nodes (12): screen.ready(), state(), today(), claimedSet(), elapsed(), nextGift(), screen.tick(), need() (+4 more)

### Community 39 - "HUD.luau"
Cohesion: 0.16
Nodes (11): HUD.bumpWallet(), HUD.currentGoal(), HUD.layout(), HUD.refreshGift(), HUD.refreshGoal(), HUD.refreshHands(), HUD.setBuilding(), keyboard() (+3 more)

### Community 48 - "Seating.luau"
Cohesion: 0.17
Nodes (8): Appliance.Init(), Placement.addVeto(), busy(), free(), Seating.find(), Seating.freeCount(), Seating.Init(), Seating.list()

### Community 49 - "World.luau"
Cohesion: 0.17
Nodes (20): overflowSlots(), buildEmptyLot(), buildStreet(), folder(), quiet(), World.clear(), World.fixedRects(), World.floorY() (+12 more)

### Community 50 - "Services/Plots.luau"
Cohesion: 0.19
Nodes (23): claim(), dedupe(), friends(), Plots.at(), Plots.canBuild(), Plots.canWork(), Plots.data(), Plots.fire() (+15 more)

### Community 64 - "Scene.luau"
Cohesion: 0.07
Nodes (12): Pointer:step(), shown(), World.surfaceOf(), Footprint.subtractRect(), facadeColor(), floorY(), holesFor(), indoorAt() (+4 more)

### Community 65 - "env.lua"
Cohesion: 0.06
Nodes (13): attrSignal(), eventOf(), methods.GetAttributeChangedSignal(), methods.GetPropertyChangedSignal(), methods.IsAncestorOf(), methods.IsDescendantOf(), methods.RemoveTag(), newSignal() (+5 more)

### Community 66 - "People.luau"
Cohesion: 0.12
Nodes (47): describe(), loadAnims(), moveTo(), Npc.acquireCustomer(), Npc.create(), Npc.release(), Npc.spawn(), Npc.stand() (+39 more)

### Community 67 - "gui.lua"
Cohesion: 0.16
Nodes (41): isA(), alignOffset(), automatic(), baseSize(), charWidth(), cls(), colorStops(), constrain() (+33 more)

### Community 69 - "className"
Cohesion: 0.19
Nodes (16): bounds(), className(), methods.FindFirstAncestorOfClass(), methods.FindFirstAncestorWhichIsA(), methods.GetBoundingBox(), methods.GetDescendants(), methods.GetExtentsSize(), methods.GetPivot() (+8 more)

### Community 70 - "props"
Cohesion: 0.08
Nodes (27): methods.FindFirstChild(), methods.WaitForChild(), task.delay(), join(), cm.BindableFunction.Invoke(), cm.Debris.AddItem(), cm.Humanoid.AddAccessory(), cm.Humanoid.ChangeState() (+19 more)

### Community 71 - "preview.py"
Cohesion: 0.17
Nodes (7): list_dir(), luau_to_lua(), main(), part_faces(), read_module(), render(), to_plot()

### Community 72 - "Services/Customers.luau"
Cohesion: 0.05
Nodes (56): bumpCombo(), chooseOrder(), countOf(), dirtyNear(), dishKind(), eat(), entrance(), floorPos() (+48 more)

### Community 73 - "check_luau.py"
Cohesion: 0.13
Nodes (13): build_tree(), add_path(), walk(), check_blocks(), check_locale(), check_requires(), check_scopes(), load_locale() (+5 more)

### Community 74 - "build_place.py"
Cohesion: 0.32
Nodes (8): cdata(), from_fs(), from_node(), item(), main(), prop_xml(), ref(), script_class()

### Community 75 - "Kitchen.luau"
Cohesion: 0.32
Nodes (17): backsplash(), bowlStack(), brothPot(), cabinet(), fittedBase(), hood(), knobs(), nc() (+9 more)

### Community 76 - "sim.py"
Cohesion: 0.15
Nodes (12): luau_to_lua(), main(), make_runtime(), read(), project_entries(), run(), run_scenario(), main() (+4 more)

### Community 77 - "progression.lua"
Cohesion: 0.14
Nodes (28): Sim.waitFor(), Sim.trigger(), task.wait(), use(), buy(), claim(), clearDirty(), cook() (+20 more)

### Community 78 - "Logic/Placement.luau"
Cohesion: 0.27
Nodes (10): Pathgrid.check(), boxesOverlap(), contains(), Placement.box(), Placement.floorY(), Placement.footprint(), Placement.pathOk(), Placement.pathTargets() (+2 more)

### Community 79 - "Meta.luau"
Cohesion: 0.20
Nodes (13): checkAchievements(), claimAchievement(), claimDaily(), claimQuest(), computeOffline(), dayIndex(), daySeconds(), ensureQuests() (+5 more)

### Community 80 - "script_parent_parent_core"
Cohesion: 0.16
Nodes (15): buyAd(), buyLicense(), buyUpgrade(), payer(), Progression.addMastery(), Progression.applyWalkSpeed(), Progression.isRecipeUnlocked(), Progression.menuRecipes() (+7 more)

### Community 81 - "ui_preview.py"
Cohesion: 0.12
Nodes (21): backdrop(), Canvas, cmap(), draw_element(), draw_text(), emoji_image(), fill_image(), font() (+13 more)

### Community 82 - "Controllers/Interaction.luau"
Cohesion: 0.19
Nodes (18): actionText(), aimingCenter(), castAt(), findTarget(), handsKind(), hrp(), inRange(), Interaction.lockOf() (+10 more)

### Community 83 - "Placement.validate"
Cohesion: 0.22
Nodes (16): Placement.near(), closestPoint(), gap(), Seating.refresh(), topY(), Footprint.axes(), Footprint.bounds(), Footprint.corners() (+8 more)

### Community 84 - "boot.lua"
Cohesion: 0.20
Nodes (16): child(), joinArgs(), nodeAt(), print(), props(), relPath(), require(), runScript() (+8 more)

### Community 85 - "cloneTree"
Cohesion: 0.20
Nodes (10): cloneTree(), defaultsFor(), kids(), methods.AddTag(), methods.Clone(), methods.FindFirstChildOfClass(), methods.FindFirstChildWhichIsA(), newInstance() (+2 more)

### Community 86 - "Controllers/Data.luau"
Cohesion: 0.18
Nodes (15): Data.canBuild(), Data.isMine(), Data.m(), Data.plotAttr(), Data.plotFolder(), Data.plotId(), Data.restaurant(), Data.w() (+7 more)

### Community 87 - "Walls.luau"
Cohesion: 0.39
Nodes (8): Placement.wallSpot(), cut(), floorCells(), key(), merge(), Walls.along(), Walls.compute(), Walls.distance()

### Community 88 - "Net.notify"
Cohesion: 0.16
Nodes (12): open(), Service.check(), Net.fire(), Net.fireAll(), Net.fx(), Net.notify(), Net.notifyAll(), Net.num() (+4 more)

### Community 89 - "Services/Analytics.luau"
Cohesion: 0.38
Nodes (9): Analytics.levelUp(), Analytics.sakura(), Analytics.sink(), Analytics.source(), Analytics.Start(), Analytics.step(), flush(), isPlayer() (+1 more)

### Community 92 - "RamenYa.luau"
Cohesion: 0.24
Nodes (10): banner(), bowlArt(), high(), label(), nc(), pendant(), pitcher(), point() (+2 more)

### Community 93 - "Furniture.luau"
Cohesion: 0.38
Nodes (13): chair(), condiments(), counter(), cushion(), ledgeProps(), nc(), placeSetting(), point() (+5 more)

### Community 94 - "Locale.get"
Cohesion: 0.17
Nodes (12): Data.applyLanguage(), Data.Init(), Data.Start(), deviceKey(), Kit.T(), Locale.has(), Locale.name(), Locale.resolve() (+4 more)

### Community 95 - "Appliance.luau"
Cohesion: 0.15
Nodes (28): Appliance.addDirtyToSink(), Appliance.hasBroth(), Appliance.hasRice(), Appliance.hold(), Appliance.load(), Appliance.needsRefill(), Appliance.sinkPile(), Appliance.Start() (+20 more)

### Community 96 - "Cooking.luau"
Cohesion: 0.18
Nodes (19): broadcast(), Cooking.addTicket(), Cooking.clearTickets(), Cooking.Init(), Cooking.isRecipeInProgress(), Cooking.maxTickets(), Cooking.readyDishes(), Cooking.removeTicket() (+11 more)

### Community 97 - "Economy.luau"
Cohesion: 0.19
Nodes (15): drawJars(), Economy.add(), Economy.boostActive(), Economy.charge(), Economy.collectTips(), Economy.ledgerOf(), Economy.multiplier(), Economy.redrawJars() (+7 more)

### Community 98 - "10. Interfaccia"
Cohesion: 0.40
Nodes (5): 10. Interfaccia, Guida dell'ordine, Oggetti in mano, Telecamera e comandi, Tutorial

### Community 99 - "Services/Staff.luau"
Cohesion: 0.29
Nodes (14): despawnActor(), despawnPlot(), fire(), hire(), homeOf(), idleAt(), managed(), managerBonus() (+6 more)

### Community 100 - "Controllers/Tutorial.luau"
Cohesion: 0.15
Nodes (16): 12. Interfaccia e lingue, advance(), finish(), hide(), offerDaily(), orderStation(), paintDots(), purchases() (+8 more)

### Community 101 - "Lighting.luau"
Cohesion: 0.24
Nodes (10): blend(), LightingC.Init(), LightingC.Start(), look(), track(), fetch(), Leaderboard.Init(), Leaderboard.Start() (+2 more)

### Community 102 - "logAnalytics"
Cohesion: 0.22
Nodes (9): typeof(), checkStorable(), cm.AnalyticsService.LogCustomEvent(), cm.AnalyticsService.LogEconomyEvent(), cm.AnalyticsService.LogFunnelStepEvent(), cm.AnalyticsService.LogOnboardingFunnelStepEvent(), cm.AnalyticsService.LogProgressionEvent(), encode() (+1 more)

### Community 103 - "task.delay"
Cohesion: 0.18
Nodes (13): Sim.runScenario(), toClient(), hpop(), hpush(), less(), pack(), resume(), schedule() (+5 more)

### Community 104 - "props"
Cohesion: 0.25
Nodes (11): ancestors(), inGame(), methods.FindFirstAncestor(), methods.FindFirstChild(), methods.FindFirstDescendant(), methods.GetFullName(), methods.GetScale(), methods.Remove() (+3 more)

### Community 105 - "asset_list.py"
Cohesion: 0.38
Nodes (3): load_names(), lua_list(), main()

### Community 106 - "Sakura Ramen & Sushi Tycoon (titolo provvisorio)"
Cohesion: 0.20
Nodes (10): Anteprima dei modelli (senza Studio), Anteprima dell'interfaccia (senza Studio), Aprire il gioco in Roblox Studio, Controlli, Documenti, Pubblicare il gioco su Roblox, Robux, suoni, modelli, Sakura Ramen & Sushi Tycoon (titolo provvisorio) (+2 more)

### Community 107 - "street.lua"
Cohesion: 0.40
Nodes (4): goTo(), heard(), join(), Sim.noticesFor()

### Community 109 - "Neighbours.luau"
Cohesion: 0.33
Nodes (6): apply(), hereX(), Neighbours.step(), setNpc(), setPlot(), setting()

### Community 110 - "Asset da procurare — modelli, icone e suoni"
Cohesion: 0.25
Nodes (7): Asset da procurare — modelli, icone e suoni, Come si sostituisce un modello, Icone dell'interfaccia, Piatti, Priorità, Stile, Suoni e musica

### Community 115 - "Guide.luau"
Cohesion: 0.15
Nodes (19): clearMarks(), distance(), Guide.close(), Guide.create(), Guide.hide(), Guide.open(), Guide.refresh(), Guide.show() (+11 more)

### Community 116 - "Color.hex"
Cohesion: 0.14
Nodes (19): Interaction.highlightRecipe(), Interaction.Init(), icons(), make(), makeCustomer(), outline(), paintRankings(), rankingGui() (+11 more)

### Community 117 - "5. Catalogo oggetti piazzabili"
Cohesion: 0.29
Nodes (7): 5.1 Sedute, tavoli e bancone, 5.2 Cucina e magazzino, 5.3 Decorazioni, 5.4 Pavimenti e pareti (per zona), 5.5 Livelli di ambiente, 5. Catalogo oggetti piazzabili, Pacchetto Ramen-ya (ispirato ai banconi dei ramen-ya veri)

### Community 118 - "Controllers/Audio.luau"
Cohesion: 0.08
Nodes (37): runTrain(), ambienceLoop(), Audio.attachTrain(), Audio.play(), Audio.Start(), Audio.step(), Audio.trainVolume(), customersInside() (+29 more)

### Community 119 - "Logic/Shop.luau"
Cohesion: 0.47
Nodes (9): finish(), level(), Shop.ad(), Shop.buyable(), Shop.expansion(), Shop.hire(), Shop.license(), Shop.staffSlots() (+1 more)

### Community 120 - "ShelfTags.luau"
Cohesion: 0.52
Nodes (6): makeTag(), place(), setText(), ShelfTags.Init(), ShelfTags.Start(), update()

### Community 121 - "Hints.luau"
Cohesion: 0.22
Nodes (8): Data.role(), aim(), close(), dockButton(), Hints.Start(), open(), seen(), shopBadge()

### Community 123 - "runLocal"
Cohesion: 0.53
Nodes (6): clientRequire(), envFor(), props(), relPath(), runLocal(), Sim.startClient()

### Community 124 - "Format.luau"
Cohesion: 0.47
Nodes (5): HUD.day(), Format.clock(), Format.number(), Format.sakura(), group()

### Community 125 - "Sim.click"
Cohesion: 0.50
Nodes (4): buttonOf(), guiOf(), Sim.click(), Sim.findText()

### Community 126 - "Geometry.compute"
Cohesion: 0.50
Nodes (4): World.ctx(), Geometry.compute(), Geometry.ctx(), Geometry.stairs()

### Community 132 - "Services/Signs.luau"
Cohesion: 0.39
Nodes (5): refilter(), Service.clean(), Service.filter(), Service.Init(), Service.set()

### Community 133 - "7. Salvataggi"
Cohesion: 0.50
Nodes (4): 7. Salvataggi, Regole, Replica al client, Schema (versione 1)

### Community 138 - "shared_logic_formulas"
Cohesion: 0.19
Nodes (9): Data.saveNow(), Data.storeAvailable(), applyProduct(), grantPass(), Monetization.has(), Monetization.Init(), Monetization.yenMultiplier(), passCfg() (+1 more)

### Community 139 - "Net.on"
Cohesion: 0.25
Nodes (5): Net.invoke(), Net.on(), Progression.Init(), Rewards.Init(), RateLimit.new()

### Community 140 - "script_parent_parent_core"
Cohesion: 0.47
Nodes (3): Interaction.Init(), sizeMargin(), targetPosition()

### Community 143 - "methods.Destroy"
Cohesion: 0.40
Nodes (6): fireIf(), methods.ClearAllChildren(), methods.Destroy(), methods.GetChildren(), methods.SetAttribute(), typeof()

### Community 144 - "copyArgs"
Cohesion: 0.40
Nodes (6): cm.RemoteEvent.FireAllClients(), cm.RemoteEvent.FireClient(), copyArgs(), record(), remote(), Sim.invoke()

### Community 145 - "TableUtil.deepCopy"
Cohesion: 0.50
Nodes (4): TableUtil.count(), TableUtil.deepCopy(), TableUtil.reconcile(), TableUtil.shuffle()

### Community 146 - "camBasis"
Cohesion: 0.40
Nodes (5): camBasis(), cm.Camera.ScreenPointToRay(), cm.Camera.ViewportPointToRay(), cm.Camera.WorldToScreenPoint(), cm.Camera.WorldToViewportPoint()

### Community 148 - "floors.lua"
Cohesion: 0.60
Nodes (3): railAt(), steps(), tagged()

### Community 150 - "Sim.press"
Cohesion: 0.67
Nodes (3): casDispatch(), inputObject(), Sim.press()

### Community 151 - "fromClient"
Cohesion: 0.67
Nodes (3): cm.RunService.IsClient(), cm.RunService.IsServer(), fromClient()

### Community 155 - "Sim.rig"
Cohesion: 0.67
Nodes (3): cm.Player.LoadCharacter(), cm.Players.CreateHumanoidModelFromDescription(), Sim.rig()

## Knowledge Gaps
- **54 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `join()` connect `Camera.luau` to `progression.lua`, `props`?**
  _High betweenness centrality (0.312) - this node is a cross-community bridge._
- **Are the 103 inferred relationships involving `Kit.box()` (e.g. with `makeScene()` and `B.doorFrame()`) actually correct?**
  _`Kit.box()` has 103 INFERRED edges - model-reasoned connections that need verification._
- **Should `Screens/Build.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.1422924901185771 - nodes in this community are weakly interconnected._
- **Why does `Sim.addPlayer()` connect `props` to `services.lua`, `street.lua`, `Camera.luau`, `cloneTree`?**
  _High betweenness centrality (0.188) - this node is a cross-community bridge._
- **Are the 62 inferred relationships involving `Kit.cyl()` (e.g. with `makeScene()` and `B.entranceDetail()`) actually correct?**
  _`Kit.cyl()` has 62 INFERRED edges - model-reasoned connections that need verification._
- **Should `sim/client.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Why does `Sim.waitFor()` connect `progression.lua` to `props`, `street.lua`, `scenarios/tutorial.lua`, `boot.lua`, `Camera.luau`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._