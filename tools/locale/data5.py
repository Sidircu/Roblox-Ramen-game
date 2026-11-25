# Texts added by the big update (core loop, plots, UI, tutorial, progression, retention).
# (key, English, Italian)
REVAMP = [
("msg.loading_wait","Your restaurant is still being saved on another server: it opens in a few seconds…","Il tuo ristorante si sta ancora salvando su un altro server: si apre tra pochi secondi…"),
("msg.load_failed","Your restaurant could not be loaded (Roblox data service). Your progress is safe: please join again in a minute.","Non riesco a caricare il tuo ristorante (servizio dati di Roblox). I tuoi progressi sono al sicuro: rientra tra un minuto."),
]
REVAMP += [
("ui.ok","OK","OK"),
("tut.take_dish","Ready! Pick up the bowl.","Pronto! Prendi la ciotola."),
("act.boil","🍜 Cook the noodles · {dish} ({i}/{n})","🍜 Cuoci i noodles · {dish} ({i}/{n})"),
("act.pour","🥣 Pour the broth · {dish} ({i}/{n})","🥣 Versa il brodo · {dish} ({i}/{n})"),
("act.top","🌱 Add the toppings · {dish} ({i}/{n})","🌱 Aggiungi i condimenti · {dish} ({i}/{n})"),
("act.cut","🔪 Cut · {dish} ({i}/{n})","🔪 Taglia · {dish} ({i}/{n})"),
("act.combine","🍙 Put together · {dish} ({i}/{n})","🍙 Unisci · {dish} ({i}/{n})"),
("act.roll","🎋 Roll · {dish} ({i}/{n})","🎋 Arrotola · {dish} ({i}/{n})"),
("act.mold","🤲 Shape · {dish} ({i}/{n})","🤲 Modella · {dish} ({i}/{n})"),
("act.batter","🥣 Batter · {dish} ({i}/{n})","🥣 Impana · {dish} ({i}/{n})"),
("act.fry","🍤 Fry · {dish} ({i}/{n})","🍤 Friggi · {dish} ({i}/{n})"),
("act.flip","🍳 Flip · {dish} ({i}/{n})","🍳 Gira · {dish} ({i}/{n})"),
("hint.missing_for","{dish}: missing {list} · restock the shelves","{dish}: mancano {list} · rifornisci gli scaffali"),
("hint.no_orders","No orders for this station","Nessun ordine per questa postazione"),
("hint.cooking_now","Cooking {dish}…","Sto cucinando {dish}…"),
("msg.no_orders","No orders yet: customers order by themselves when they sit down.","Ancora nessun ordine: i clienti ordinano da soli quando si siedono."),
("msg.no_orders_here","The orders waiting are for another station.","Gli ordini in attesa sono per un'altra postazione."),
("msg.restock_needed","{name} is finished: put a box of it on the shelves (📦 Supplier).","È finito {name}: metti una scatola sugli scaffali (📦 Fornitore)."),
("msg.day_summary","🌅 Day {day} is over: ¥{yen} earned, {served} dishes served. Tap the clock for the summary.","🌅 Il giorno {day} è finito: ¥{yen} guadagnati, {served} piatti serviti. Tocca l'orologio per il resoconto."),
]
REVAMP += [
("guide.on_shelves","Ingredients on the shelves","Ingredienti sugli scaffali"),
("guide.press_steps","Press {station}: {n} steps","Premi {station}: {n} passaggi"),
]
REVAMP += [
("msg.shelf_auto","The stations take the ingredients by themselves: just press the station.","Le postazioni prendono gli ingredienti da sole: premi la postazione."),
]
REVAMP += [
("msg.other_restaurant","That belongs to another restaurant: bring it back where you took it.","Questo è di un altro ristorante: riportalo dove l'hai preso."),
("msg.not_your_restaurant","This is someone else's restaurant: you can help only if the owner is your friend or invites you.","Questo è il ristorante di un altro: puoi aiutare solo se il proprietario è tuo amico o ti invita."),
("msg.no_plot","All four restaurants on this street are taken: you can visit and help your friends.","I quattro ristoranti di questa strada sono occupati: puoi visitare e aiutare i tuoi amici."),
]
REVAMP += [
("ui.go_home","Back to my restaurant","Torna al mio ristorante"),
("ui.coop_who","Who may help in my restaurant","Chi può aiutare nel mio ristorante"),
("ui.coop_friends","Friends","Amici"),
("ui.coop_everyone","Everyone","Tutti"),
("ui.street_players","Players on this street","Giocatori su questa strada"),
("perm.default","Helps if they are your friend","Aiuta se è tuo amico"),
("perm.helper","Helper in your restaurant","Aiutante nel tuo ristorante"),
("perm.comanager","Co-manager: can build and buy","Co-gestore: può costruire e comprare"),
]

# Phase 4: one shop with tabs, a smaller HUD
REVAMP += [
("ui.more","More","Altro"),
("ui.home","Home","A casa"),
("ui.premium","Premium","Premium"),
("ui.tab_recipes","Recipes","Ricette"),
("ui.tab_rooms","Rooms","Spazi"),
("ui.tab_renos","Renovations","Ristrutturazioni"),
("ui.need_slots","Team full: open a room","Squadra piena: apri uno spazio"),
("ui.need_manager","You have one","Ne hai già uno"),
("ui.missing","{yen} more needed","Mancano {yen}"),
("ui.only_owner","Only the owner and co-managers can buy here","Qui possono comprare solo il proprietario e i co-gestori"),
]

# Phase 5: the two-minute tutorial and the one-time tips
REVAMP += [
("tut.cook","Press the ramen station: 🍜 → 🥣 → 🌱","Premi la postazione del ramen: 🍜 → 🥣 → 🌱"),
("tut.reward","A gift of {yen}! Open the shop 🛒","Un regalo di {yen}! Apri il negozio 🛒"),
("tut.skipped","Tutorial skipped: you find it again in More → How to play.","Tutorial saltato: lo ritrovi in Altro → Come si gioca."),
("msg.tutorial_gift","🎁 +¥{yen}: spend it in the shop!","🎁 +¥{yen}: spendili nel negozio!"),
("msg.tutorial_done","🎉 Tutorial done! +🌸 {n}","🎉 Tutorial completato! +🌸 {n}"),
("hint.first_restock","The shelves are running out: order boxes from the 📦 supplier and put them on the shelves.","Gli scaffali si svuotano: ordina scatole dal 📦 fornitore e mettile sugli scaffali."),
("hint.first_dishes","Dirty dishes are piling up: wash them at the sink 🧽, or customers will have no bowls.","I piatti sporchi si accumulano: lavali al lavello 🧽, o i clienti resteranno senza ciotole."),
("hint.first_shop","You can buy something new in the 🛒 shop!","Puoi comprare qualcosa di nuovo nel 🛒 negozio!"),
("hint.first_staff","You can hire your first helper: 🛒 shop → 👥 Staff.","Puoi assumere il tuo primo aiutante: 🛒 negozio → 👥 Personale."),
]

# Phase 6: franchise requirements grow with each city
REVAMP += [
("ui.franchise_next","To open in {city}:","Per aprire a {city}:"),
("hint.buy_room","🏗️ Build {name} · {yen}","🏗️ Costruisci {name} · {yen}"),
("msg.shelf_full_other","This shelf is full: another shelf has room for it.","Questa mensola è piena: su un'altra c'è posto."),
("msg.shelf_full_buy","Every shelf is full: buy a new one (🔨 Build → Kitchen).","Tutte le mensole sono piene: comprane un'altra (🔨 Costruisci → Cucina)."),
]

# Phase 8: daily gift calendar, ranking boards in the street, extra staff pass, co-op bonus
REVAMP += [
("ui.daily_gift","Daily gift","Regalo del giorno"),
("ui.daily_hint","Come back every day: the gifts grow for 7 days in a row!","Torna ogni giorno: i regali crescono per 7 giorni di fila!"),
("ui.lb_you","⭐ You","⭐ Tu"),
("gp.gp_extra_staff","Extra staff","Personale extra"),
("gpdesc.gp_extra_staff","+2 staff slots in your restaurant","+2 posti per il personale nel tuo ristorante"),
("msg.coop_bonus","🤝 Teamwork: +{pct}% earnings while you work together!","🤝 Lavoro di squadra: +{pct}% di guadagni finché lavorate insieme!"),
]

# Tutorial cards for the device you play with (Controllers/Tutorial deviceKey: _pc, _touch, _pad)
REVAMP += [
("tut.welcome_pc","Welcome to your ramen shop! 🏮 WASD to walk, the mouse to look. Q frees the mouse for the buttons.","Benvenuto nel tuo ramen-ya! 🏮 WASD per camminare, il mouse per guardare. Q libera il mouse per i pulsanti."),
("tut.welcome_touch","Welcome to your ramen shop! 🏮 Walk with the stick on the left, tap the buttons to use things.","Benvenuto nel tuo ramen-ya! 🏮 Cammina con la levetta a sinistra, tocca i pulsanti per usare le cose."),
("tut.welcome_pad","Welcome to your ramen shop! 🏮 Left stick to walk, right stick to look, X to use things.","Benvenuto nel tuo ramen-ya! 🏮 Levetta sinistra per camminare, destra per guardare, X per usare."),
("tut.cook_pc","Look at the ramen station and press E (or click): 🍜 → 🥣 → 🌱","Guarda la postazione del ramen e premi E (o clicca): 🍜 → 🥣 → 🌱"),
("tut.cook_touch","Tap the button over the ramen station: 🍜 → 🥣 → 🌱","Tocca il pulsante sopra la postazione del ramen: 🍜 → 🥣 → 🌱"),
("tut.cook_pad","Look at the ramen station and press X: 🍜 → 🥣 → 🌱","Guarda la postazione del ramen e premi X: 🍜 → 🥣 → 🌱"),
("tut.take_dish_pc","Ready! Press E on the station to pick up the bowl.","Pronto! Premi E sulla postazione per prendere la ciotola."),
("tut.take_dish_touch","Ready! Tap the station's button to pick up the bowl.","Pronto! Tocca il pulsante della postazione per prendere la ciotola."),
("tut.take_dish_pad","Ready! Press X on the station to pick up the bowl.","Pronto! Premi X sulla postazione per prendere la ciotola."),
("tut.serve_pc","Bring it to the customer and press E 💴","Portala al cliente e premi E 💴"),
("tut.serve_touch","Bring it to the customer and tap their button 💴","Portala al cliente e tocca il suo pulsante 💴"),
("tut.serve_pad","Bring it to the customer and press X 💴","Portala al cliente e premi X 💴"),
("tut.reward_pc","A gift of {yen}! Press U to open the shop 🛒 (or Q and click 🛒)","Un regalo di {yen}! Premi U per aprire il negozio 🛒 (o Q e clicca 🛒)"),
("tut.reward_touch","A gift of {yen}! Tap 🛒 Shop at the bottom","Un regalo di {yen}! Tocca 🛒 Negozio in basso"),
("tut.buy_pc","Buy an upgrade: click a green price.","Compra un miglioramento: clicca un prezzo verde."),
("tut.buy_pad","Buy an upgrade: move to a green price and press A.","Compra un miglioramento: vai su un prezzo verde e premi A."),
("tut.collect_pc","Pick up the dirty bowl: look at it and press E.","Raccogli la ciotola sporca: guardala e premi E."),
("tut.collect_touch","Pick up the dirty bowl: tap its button.","Raccogli la ciotola sporca: tocca il suo pulsante."),
("tut.collect_pad","Pick up the dirty bowl: look at it and press X.","Raccogli la ciotola sporca: guardala e premi X."),
("tut.wash_pc","At the sink: hold E to wash it 🧽","Al lavello: tieni premuto E per lavarla 🧽"),
("tut.wash_touch","At the sink: tap the button, the water runs until the bowls are clean 🧽","Al lavello: tocca il pulsante, l'acqua scorre finché le ciotole sono pulite 🧽"),
("tut.wash_pad","At the sink: hold X to wash it 🧽","Al lavello: tieni premuto X per lavarla 🧽"),
]

# Settings → Sensitivity
REVAMP += [
("ui.sens_high","High","Alta"),
("ui.sens_medium","Medium","Media"),
("ui.sens_low","Low","Bassa"),
]

# Delivery pop-ups (Controllers/Effects "delivery")
REVAMP += [
("ui.delivery_here","The delivery van is here!","È arrivato il furgone!"),
("ui.delivery_unloading","Unloading {n} boxes…","Sta scaricando {n} scatole…"),
("ui.delivery_unloading_one","Unloading 1 box…","Sta scaricando 1 scatola…"),
("ui.delivery_done","Delivery: {n} boxes","Consegna: {n} scatole"),
("ui.delivery_done_one","Delivery: 1 box","Consegna: 1 scatola"),
("ui.delivery_where","On the ground outside the storage door","A terra fuori dalla porta del magazzino"),
]

# The OPEN / CLOSED sign by the door (Plots.setOpen)
REVAMP += [
("hint.open_shop","Open the restaurant","Apri il ristorante"),
("hint.close_shop","Close the restaurant","Chiudi il ristorante"),
("msg.shop_opened","🟢 The restaurant is open: customers are coming!","🟢 Il ristorante è aperto: arrivano i clienti!"),
("msg.shop_closed","🔴 Closed: no new customers until you open again (the ones inside are served).","🔴 Chiuso: nessun nuovo cliente finché non riapri (chi è dentro viene servito)."),
("ui.closed","Closed","Chiuso"),
("hint.first_opensign","🏮 The OPEN sign by the door opens and closes your restaurant (use it like a station).","🏮 Il cartello OPEN accanto alla porta apre e chiude il ristorante (si usa come una postazione)."),
]
# round 4: clearer cards, the setting for the other restaurants
REVAMP += [
("ui.offline_rule","{h} h at {pct}%","{h} h al {pct}%"),
("ui.level_short","Lv. {level}/{max}","Liv. {level}/{max}"),
("ui.stock_line","Shelves {shelf} · Boxes {boxes}","Mensole {shelf} · Scatole {boxes}"),
("ui.others_detail","Other restaurants","Altri locali"),
("ui.others_show","Show all","Mostra tutto"),
("ui.others_hide","Only the outside","Solo fuori"),
]
