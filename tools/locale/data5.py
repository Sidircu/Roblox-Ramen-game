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
