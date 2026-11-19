# Asset da procurare — modelli, icone e suoni

> Generato da `python3 tools/asset_list.py` (rigeneralo quando cambiano gli oggetti). Tutto il gioco funziona già con modelli generati dal codice: questa lista dice cosa sostituire per primo e come.

## Come si sostituisce un modello

1. Crea o importa il modello (Model) in Studio e chiamalo **esattamente come l'ID** della tabella (es. `ramen_station`).
2. Mettilo in `ReplicatedStorage/AssetOverrides`. Il gioco lo usa al posto di quello procedurale (`Models/Registry`): lo **scala per stare nella misura** della tabella (larghezza × altezza × profondità in stud) e lo **appoggia a terra al centro**.
3. Il **davanti** del modello guarda verso −Z (come la telecamera di Roblox all'inizio): sedie e sgabelli guardano il bancone, le postazioni guardano il cuoco.
4. Parti piccole: `CastShadow = false`, `CanCollide` solo dove si cammina contro, `Anchored = true`. Niente script dentro il modello.
5. Per le **postazioni**, gli **scaffali**, il **lavello** e i **pentoloni** le parti di gioco (tagliere, caselle dello scaffale, vasca) sono aggiunte dal codice sopra il modello: tieni la superficie di lavoro piatta all'altezza indicata dal modello procedurale (`python3 tools/preview.py item <id> out.png` per vederlo).
6. Nessun testo scritto nelle texture (il gioco è in due lingue): le scritte giapponesi decorative vanno bene.

## Stile

- **Palette calda giapponese** (`Models/Palette`): legno chiaro `#C89F6E`, legno scuro `#5B3A24`, lacca rossa `#B3262E`, carta washi `#F4EBDD`, inchiostro `#2B2320`, oro `#D4A23C`, matcha `#7A9A4A`, indaco `#2E3A5C`, pietra `#8C8C88`.
- **Materiali**: legno (`Wood`, `WoodPlanks`), carta (`Fabric` chiaro), lacca (`SmoothPlastic` lucido), pietra (`Slate`, `Cobblestone`), metallo spazzolato per la cucina (`Metal`, `DiamondPlate` solo nel magazzino).
- **Forme morbide e leggibili da lontano** (come nei tycoon più giocati): pochi dettagli piccoli, silhouette chiara, colori pieni; si deve capire cosa è un oggetto anche dal telefono.
- **Budget**: oggetti piccoli ≤ 1.500 triangoli, mobili ≤ 4.000, postazioni ≤ 6.000, alberi e laghetti ≤ 8.000; una texture 512×512 al massimo per oggetto (meglio colori dei materiali).

## Priorità

- **A** — si vede da subito: il locale iniziale e la cucina (postazioni, bancone, sedute, scaffali, lavello, pentoloni). Ogni ristorante della strada ne ha una copia: oggi questi oggetti valgono circa 1275 parti per locale.
- **B** — decorazioni e mobili dei primi livelli (fino al livello 8).
- **C** — il resto del catalogo, gli oggetti degli eventi e delle città del franchise.

Più **parti** ha la versione procedurale, più si guadagna sostituendola con un modello (meno parti da disegnare e da trasmettere).

| Pr. | ID | Nome | Categoria | Misura (L×A×P stud) | Liv. | Prezzo | Parti oggi | Nel locale iniziale |
|---|---|---|---|---|---|---|---|---|
| A | `ramen_station` | Postazione ramen | kitchen | 5×3.5×2.5 | 1 | ¥1.500 | 79 | ×1 |
| A | `sink` | Lavello | kitchen | 4×3.5×2.5 | 1 | ¥500 | 77 | ×1 |
| A | `sushi_station` | Postazione sushi | kitchen | 5×3.5×2.5 | 1 | ¥800 | 65 | ×1 |
| A | `counter_straight` | Bancone dritto (2 posti) | seating | 3×3×3.8 | 1 | ¥750 | 51 | ×12 |
| A | `counter_corner` | Bancone ad angolo | seating | 3.8×3×3.8 | 1 | ¥1.200 | 48 |  |
| A | `broth_pot` | Fornello con pentolone | kitchen | 4×4.6×2.5 | 1 | ¥900 | 44 | ×1 |
| A | `broth_pot_large` | Fornello con pentolone grande | kitchen | 4.6×4.8×2.5 | 13 | ¥7.500 | 44 |  |
| A | `shelf_deluxe` | Dispensa laccata deluxe | kitchen | 11×10×2.4 | 22 | ¥25.000 | 43 |  |
| A | `takoyaki_stove` | Fornello takoyaki | kitchen | 3×3.5×2.5 | 24 | ¥9.000 | 42 |  |
| A | `griddle` | Piastra teppan | kitchen | 4×3.5×2.5 | 12 | ¥6.000 | 39 |  |
| A | `shelf_market` | Scaffale da mercato in bambù | kitchen | 9.6×8.8×2.2 | 15 | ¥9.000 | 38 |  |
| A | `shelf_tall` | Scaffale alto in legno | kitchen | 7.8×10×2 | 10 | ¥4.000 | 38 |  |
| A | `kitchen_counter` | Piano di lavoro | kitchen | 2.6×3.5×2.5 | 1 | ¥250 | 36 | ×2 |
| A | `drink_station` | Postazione bevande | kitchen | 4×3.5×2.5 | 5 | ¥2.000 | 35 |  |
| A | `rice_cooker` | Rice cooker | kitchen | 2.6×4.9×2.5 | 1 | ¥600 | 33 | ×1 |
| A | `fryer` | Friggitrice | kitchen | 3×3.5×2.5 | 18 | ¥8.000 | 31 |  |
| A | `shelf_large` | Mensola grande | kitchen | 7.8×8.4×2 | 7 | ¥1.500 | 30 |  |
| A | `shelf_small` | Mensola piccola | kitchen | 5.6×7.4×2 | 1 | ¥400 | 29 | ×2 |
| A | `dessert_station` | Postazione dolci | kitchen | 4×3.5×2.5 | 28 | ¥10.000 | 28 |  |
| A | `counter_end` | Bancone terminale | seating | 2×3×3.8 | 1 | ¥800 | 27 | ×2 |
| A | `table_2` | Tavolo da 2 | seating | 3×2.6×3 | 3 | ¥600 | 23 |  |
| A | `table_4` | Tavolo da 4 | seating | 5×2.6×3 | 6 | ¥1.400 | 23 |  |
| A | `chabudai` | Tavolino basso chabudai | seating | 4×1.2×4 | 10 | ¥1.800 | 16 |  |
| A | `stool_cushion` | Sgabello imbottito | seating | 1.6×2.4×1.6 | 4 | ¥300 | 14 |  |
| A | `neta_case` | Vetrina refrigerata del pesce | kitchen | 5×3.2×2.2 | 5 | ¥3.000 | 13 |  |
| A | `stool_wood` | Sgabello in legno | seating | 1.6×2.4×1.6 | 1 | ¥80 | 13 | ×12 |
| A | `chair_lacquer` | Sedia laccata rossa | seating | 1.6×3.5×1.6 | 14 | ¥700 | 11 |  |
| A | `chair_wood` | Sedia in legno | seating | 1.6×3.5×1.6 | 3 | ¥150 | 11 |  |
| A | `chochin_white` | Lanterna chochin bianca | lighting | 1.4×2.4×1.4 | 1 | ¥150 | 11 | ×1 |
| A | `stool_red` | Sgabello rosso da ramen-ya | seating | 1.6×2.4×1.6 | 2 | ¥220 | 8 |  |
| A | `storage_rack` | Scaffale magazzino | storage | 6×4.4×2 | 1 | ¥700 | 8 | ×1 |
| A | `zabuton` | Cuscino zabuton | seating | 1.8×0.4×1.8 | 10 | ¥200 | 7 |  |
| A | `stool_swivel` | Sgabello girevole laccato | seating | 1.8×2.4×1.8 | 12 | ¥900 | 6 |  |
| A | `tip_jar` | Barattolo delle mance | tabletop | 0.9×1.3×0.9 | 1 | ¥150 | 6 | ×1 |
| B | `counter_posters` | Mensola menù da bancone | tabletop | 3.8×1.4×0.5 | 4 | ¥650 | 121 |  |
| B | `menu_posters` | Poster del menù | art | 6×2.2×0.2 | 3 | ¥450 | 101 |  |
| B | `bamboo_pot` | Bambù in vaso | plants | 1.6×5×1.6 | 1 | ¥300 | 34 |  |
| B | `bench_table` | Tavolo con panche | seating | 5×2.7×5 | 7 | ¥2.400 | 33 |  |
| B | `ramen_poster` | Poster retrò del ramen | art | 2.4×3.2×0.2 | 5 | ¥600 | 30 |  |
| B | `noren_banner` | Striscione rosso | art | 8×1.8×0.3 | 4 | ¥700 | 24 |  |
| B | `condiment_caddy` | Portacondimenti | tabletop | 1.6×1.1×0.7 | 1 | ¥180 | 19 |  |
| B | `wagasa` | Ombrello wagasa | art | 3.5×4.5×3.5 | 6 | ¥650 | 14 |  |
| B | `chochin_orange` | Lanterna arancione | lighting | 1.4×2.4×1.4 | 2 | ¥200 | 12 |  |
| B | `soup_sign` | Tavola del brodo segreto | art | 6×2.6×0.9 | 8 | ¥1.600 | 12 |  |
| B | `toro_stone` | Lanterna di pietra tōrō | lighting | 1.8×4.5×1.8 | 6 | ¥1.200 | 12 |  |
| B | `chochin_red` | Lanterna chochin rossa | lighting | 1.4×2.4×1.4 | 1 | ¥150 | 11 |  |
| B | `fan_wall` | Ventaglio sensu | art | 3×1.8×0.3 | 2 | ¥350 | 11 |  |
| B | `maneki_neko` | Maneki-neko | statues | 0.9×1.3×0.8 | 2 | ¥500 | 11 |  |
| B | `water_pitcher` | Brocca d'acqua | tabletop | 1×1.3×1.1 | 1 | ¥120 | 11 |  |
| B | `andon_lamp` | Lampada andon | lighting | 1.4×3×1.4 | 3 | ¥600 | 10 |  |
| B | `tanuki` | Statua tanuki | statues | 1.8×3×1.6 | 8 | ¥1.100 | 10 |  |
| B | `waiting_bench` | Panchina d'attesa | seating | 5×2×1.5 | 2 | ¥500 | 10 |  |
| B | `bonsai_pine` | Bonsai di pino | plants | 1.8×1.6×1.2 | 4 | ¥900 | 8 |  |
| B | `menu_plaques` | Tavolette menu in legno | art | 4×2.5×0.3 | 1 | ¥300 | 8 |  |
| B | `ramen_sign_vertical` | Insegna verticale ラーメン | art | 1.6×5×0.9 | 6 | ¥900 | 8 |  |
| B | `ikebana` | Ikebana | plants | 1.2×1.8×1.2 | 7 | ¥700 | 7 |  |
| B | `pendant_lamp` | Lampada a sospensione | lighting | 1.2×3.2×1.2 | 2 | ¥350 | 7 |  |
| B | `soy_barrel` | Botte di salsa di soia | statues | 2.2×2.6×2.2 | 4 | ¥450 | 7 |  |
| B | `daruma` | Daruma | statues | 1×1.1×1 | 3 | ¥350 | 6 |  |
| B | `noren_indigo` | Noren indaco | art | 4×3×0.3 | 5 | ¥400 | 6 |  |
| B | `noren_red` | Noren rosso | art | 4×3×0.3 | 1 | ¥250 | 6 |  |
| B | `paper_pendant` | Lampada a sospensione in carta | lighting | 1.8×2.6×1.8 | 5 | ¥900 | 6 |  |
| B | `kakejiku` | Rotolo kakejiku | art | 1.8×4.5×0.3 | 3 | ¥700 | 5 |  |
| B | `kokedama` | Kokedama sospeso | plants | 1.2×2.6×1.2 | 2 | ¥250 | 5 |  |
| B | `neon_ramen` | Insegna neon ラーメン | lighting | 6×2×0.4 | 8 | ¥3.500 | 5 |  |
| B | `nobori` | Stendardo nobori | festival | 1.4×7×0.6 | 4 | ¥450 | 5 |  |
| B | `stone_path` | Pietra da sentiero | garden | 2×0.2×2 | 5 | ¥120 | 3 |  |
| C | `ramenya_canopy` | Tettoia del ramen-ya | lighting | 8×4.2×2.6 | 9 | ¥4.500 | 59 |  |
| C | `booth` | Separé imbottito (4 posti) | seating | 6×4×5 | 15 | ¥5.000 | 58 |  |
| C | `zashiki_table` | Tavolo VIP zashiki | seating | 6×1.3×6 | 18 | ¥30.000 | 41 |  |
| C | `red_bridge` | Ponticello rosso | garden | 3×2.4×8 | 24 | ¥18.000 | 39 |  |
| C | `rice_cooker_pro` | Rice cooker professionale | kitchen | 3×5.1×2.5 | 11 | ¥5.000 | 33 |  |
| C | `dragon_statue` | Statua del drago | statues | 5×6×4 | 40 | ¥150.000 | 31 |  |
| C | `byobu` | Paravento byōbu | art | 6×4.5×0.6 | 10 | ¥1.800 | 25 |  |
| C | `hanami_dango` | Banchetto dango di hanami | festival | 3×5×2.5 | 1 | 🌸40 | 25 |  |
| C | `koi_pond` | Laghetto koi | garden | 8×1×6 | 20 | ¥15.000 | 24 |  |
| C | `tanabata_bamboo` | Bambù di Tanabata | festival | 2×8×2 | 1 | 🌸40 | 23 |  |
| C | `samurai_armor` | Armatura samurai | statues | 2.4×6×2 | 28 | ¥25.000 | 21 |  |
| C | `shisa_pair` | Coppia di shisa | statues | 5×2.6×1.6 | 1 | ¥80.000 | 19 |  |
| C | `vending_machine` | Distributore automatico | festival | 3×6.5×2.2 | 9 | ¥2.200 | 19 |  |
| C | `wave_painting` | Quadro dell'onda | art | 5×3×0.3 | 9 | ¥1.500 | 17 |  |
| C | `aquarium` | Acquario | statues | 5×5×2 | 16 | ¥9.000 | 16 |  |
| C | `zen_garden` | Giardino zen | garden | 6×0.8×6 | 17 | ¥8.000 | 16 |  |
| C | `gashapon` | Macchina gashapon | festival | 1.8×4.5×1.6 | 11 | ¥2.800 | 15 |  |
| C | `osaka_octopus_sign` | Insegna takoyaki di Osaka | art | 6×4×0.8 | 1 | ¥40.000 | 14 |  |
| C | `yatai` | Carretto yatai | festival | 6×7×4 | 19 | ¥10.000 | 14 |  |
| C | `sakura_garland` | Ghirlanda di ciliegio | festival | 6×1.2×0.4 | 1 | 🌸25 | 13 |  |
| C | `kimono_display` | Kimono in esposizione | art | 4×6×1 | 18 | ¥4.000 | 12 |  |
| C | `kyoto_lantern` | Lanterna del tempio di Kyoto | lighting | 2.4×6×2.4 | 1 | ¥30.000 | 12 |  |
| C | `lantern_string` | Fila di lanterne festival | lighting | 8×1.8×0.6 | 12 | ¥2.000 | 12 |  |
| C | `sakura_tree` | Ciliegio in fiore | plants | 7×12×7 | 20 | ¥12.000 | 12 |  |
| C | `snow_lantern` | Lanterna della neve | lighting | 2.4×4×2.4 | 1 | ¥50.000 | 12 |  |
| C | `susuki_vase` | Vaso di erba susuki | festival | 1×2.2×1 | 1 | 🌸20 | 12 |  |
| C | `yatai_lanterns` | Lanterne yatai di Fukuoka | lighting | 8×2.4×0.8 | 1 | ¥60.000 | 12 |  |
| C | `fireworks_lantern` | Lanterna dei fuochi d'artificio | festival | 1.4×2.4×1.4 | 1 | 🌸25 | 11 |  |
| C | `maneki_gold` | Maneki-neko d'oro | statues | 1.2×1.7×1 | 30 | ¥250.000 | 11 |  |
| C | `maple_tree` | Acero giapponese | plants | 6×11×6 | 15 | ¥6.000 | 11 |  |
| C | `taiko` | Tamburo taiko | festival | 3×3.5×2.4 | 13 | ¥3.000 | 11 |  |
| C | `torii_gold` | Torii dorato | garden | 8×9×1.5 | 45 | ¥500.000 | 11 |  |
| C | `torii_small` | Piccolo torii | garden | 6×7×1.2 | 25 | ¥20.000 | 11 |  |
| C | `kadomatsu` | Kadomatsu | festival | 2×5×2 | 1 | 🌸40 | 10 |  |
| C | `moon_rabbit` | Coniglio della luna | festival | 1.6×2×1.4 | 1 | 🌸35 | 10 |  |
| C | `storage_rack_large` | Scaffale magazzino grande | storage | 6×8.2×2 | 9 | ¥3.000 | 10 |  |
| C | `bonsai_ancient` | Bonsai secolare | plants | 3×4×3 | 32 | ¥45.000 | 9 |  |
| C | `koinobori` | Koinobori | festival | 2×10×2 | 12 | ¥1.600 | 9 |  |
| C | `shishi_odoshi` | Fontana shishi-odoshi | garden | 3.5×2.6×2 | 14 | ¥4.000 | 9 |  |
| C | `waterfall` | Cascata di roccia | garden | 6×8×4 | 36 | ¥60.000 | 9 |  |
| C | `dishwasher` | Lavastoviglie | kitchen | 3×3.5×2.5 | 13 | ¥12.000 | 7 |  |
| C | `fridge` | Frigorifero professionale | kitchen | 3×7×2.5 | 16 | ¥15.000 | 7 |  |
| C | `moss_garden` | Aiuola di muschio | garden | 4×0.8×4 | 11 | ¥2.500 | 7 |  |
| C | `kagami_mochi` | Kagami mochi | festival | 1×1.4×1 | 1 | 🌸20 | 5 |  |
| C | `neon_sushi` | Insegna neon 寿司 | lighting | 4×2.2×0.4 | 10 | ¥3.500 | 5 |  |

## Piatti

I piatti sono modelli piccoli costruiti da `Models/Builders/Food` per tipo (`dish`). Un modello per tipo copre tutte le ricette di quel tipo; i colori degli ingredienti li mette il codice. Priorità A: `bowl` (ramen) e `nigiri`/`maki` (sushi).

| Tipo di piatto | Ricette |
|---|---|
| `bottle` | 🥤 `ramune` |
| `bowl` | 🍜 `shoyu_ramen`, 🍜 `shio_ramen`, 🍜 `miso_ramen`, 🍜 `tonkotsu_ramen`, 🌶️ `tantanmen`, 🍜 `mayu_ramen`, 🍵 `matcha_soba`, 🌽 `butter_corn_ramen`, 🍜 `hakata_ramen`, 🍜 `okinawa_soba` |
| `cup` | 🍵 `green_tea`, 🍵 `matcha_latte` |
| `edamame` | 🫛 `edamame` |
| `fried` | 🍤 `ebi_tempura`, 🍗 `karaage`, 🍢 `kushikatsu` |
| `gunkan` | 🍣 `ikura_gunkan` |
| `gyoza` | 🥟 `gyoza`, 🥟 `yatai_gyoza` |
| `maki` | 🍣 `kappa_maki`, 🍣 `tekka_maki` |
| `mochi` | 🍡 `mochi` |
| `nigiri` | 🍣 `sake_nigiri`, 🍣 `maguro_nigiri`, 🍤 `ebi_nigiri`, 🍣 `otoro_nigiri` |
| `okonomiyaki` | 🥞 `okonomiyaki`, 🥩 `jingisukan`, 🥗 `goya_champuru` |
| `platter` | 🍱 `omakase`, 🎌 `kaiseki` |
| `roll` | 🍣 `california_roll`, 🐉 `dragon_roll` |
| `sashimi` | 🍣 `sake_sashimi`, 🍱 `sashimi_moriawase` |
| `soup` | 🥣 `miso_soup`, 🍲 `yudofu` |
| `takoyaki` | 🐙 `takoyaki` |
| `temaki` | 🍣 `temaki_salmon` |
| `tsukemen` | 🍜 `tsukemen` |

## Icone dell'interfaccia

Oggi l'interfaccia usa emoji (si vedono uguali su ogni dispositivo Roblox). Icone disegnate a mano danno subito un aspetto più curato: PNG 256×256 con sfondo trasparente, contorno scuro morbido, stile della palette. In ordine di importanza:

| Dove | Icone |
|---|---|
| Barra in basso | negozio 🛒, costruisci 🔨, fornitore 📦, altro 📱 |
| Portafoglio | moneta ¥, fiore di sakura 🌸, medaglia del livello |
| Negozio (schede) | miglioramenti ⬆️, ricette 🍜, personale 👥, spazi 🏗️, ristrutturazioni 🪚 |
| Miglioramenti | vassoio, scarpe, coltello, stuoia, scolapasta, mensole, carrello, fornitore, insegna, barra ordini, jukebox, cassaforte, riordino |
| Ricette | una per ogni piatto (vedi tabella dei piatti) |
| Personale | cameriere, lavapiatti, magazziniere, cuoco sushi, cuoco ramen, cuoco di linea, manager |
| Altro (telefono) | menu, obiettivi, regali, invita, premium, codici, aiuto, impostazioni |

Le icone si caricano come immagini (Creator Dashboard → Development Items → Decals) e i loro ID vanno messi al posto delle emoji dove servono.

## Suoni e musica

Sono già scelti dalla libreria pubblica di Roblox (`Config/Audio.luau`: musica giorno/notte, ambiente della strada e del locale, coltello, brodo, frittura, piatti, interfaccia). Da aggiungere se si trovano: un suono di **acquisto** più festoso (ora la cassa), una **fanfara breve** per il livello e per il franchise, la **campanella della porta** diversa per i clienti VIP.

