# Bilanciamento — numeri, prezzi e sblocchi

> Questi valori diventano i moduli di configurazione in `src/shared/Config/`. Sono un punto di partenza: si ritoccano dopo i primi test di gioco.
> Gli ID (es. `sake_nigiri`) sono quelli usati nel codice. I nomi sono in italiano / inglese.

---

## 1. Formule principali

| Formula | Valore |
|---|---|
| XP per passare dal livello L al successivo | `round(100 × L^1.65)` |
| Livello massimo | 50 (per ogni franchise) |
| Yen iniziali | ¥500 + 2 scatole di ogni ingrediente base in magazzino |
| Prezzo effettivo di un piatto | `prezzoBase × (1 + 0,05 × livelloMaestria) × moltiplicatorePrezzoMenu × bonusFranchise` |
| Mancia | `prezzo × (0,05 + bonusFreschezza + bonusAmbiente + bonusComfort + bonusPazienza) × moltiplicatoreTipoCliente` (bonusFreschezza = 0,10 se il pesce viene dalla vetrina o se c'è un frigorifero professionale vicino alla postazione) |
| Bonus pazienza sulla mancia | `0,10 × pazienzaResidua` (0–1) |
| Intervallo tra clienti | `max(2,5 s; 18 s / (1 + popolarità))` |
| Popolarità | `0,15 × (livello/10) + 0,35 × (valutazione−3) + bonusAmbiente + bonusInsegna + pubblicità` (minimo 0) |
| Picchi pranzo/cena | intervallo × 0,6 |
| Domanda in base al prezzo del menu | `probabilità ordine × (1 − 1,2 × (moltiplicatore − 1))` |
| Rimborso vendita oggetti | 75% (100% entro 30 s dal piazzamento) |
| Guadagno offline | `incassoMedioOrario × percentualeCassaforte × ore (max ore cassaforte)` |

### Andamento previsto dei livelli

| Livello | XP per il livello | XP totali | Ore indicative |
|---|---|---|---|
| 5 | ~1.420 | ~3.400 | 2 |
| 10 | ~4.470 | ~19.000 | 6 |
| 20 | ~14.000 | ~113.000 | 17 |
| 30 | ~27.400 | ~324.000 | 26 |
| 40 | ~44.000 | ~690.000 | 35 |
| 50 | ~64.000 | ~1.230.000 | 45 |

---

## 2. Ingredienti (scatole del fornitore)

| ID | Nome IT / EN | Porzioni per scatola | Prezzo scatola | Dove si conserva | Sblocco |
|---|---|---|---|---|---|
| `rice` | Riso / Rice | 20 | ¥60 | mensola → rice cooker | base |
| `nori` | Alga nori / Nori | 30 | ¥45 | mensola | base |
| `cucumber` | Cetriolo / Cucumber | 16 | ¥32 | mensola | base |
| `salmon` | Salmone / Salmon | 12 | ¥120 | mensola o vetrina | base |
| `noodles` | Noodles / Noodles | 20 | ¥80 | mensola | base |
| `broth_shoyu` | Base shoyu / Shoyu base | 16 | ¥96 | mensola → pentolone | base |
| `scallion` | Cipollotto / Scallion | 30 | ¥45 | mensola | base |
| `naruto` | Naruto / Naruto | 20 | ¥60 | mensola | base |
| `tuna` | Tonno / Tuna | 12 | ¥168 | mensola o vetrina | Sushi I |
| `egg` | Uovo ajitama / Ajitama egg | 12 | ¥72 | mensola | Ramen I |
| `broth_shio` | Base shio / Shio base | 16 | ¥96 | mensola → pentolone | Ramen I |
| `edamame` | Edamame | 20 | ¥60 | mensola | Contorni & tè |
| `green_tea` | Tè verde / Green tea | 30 | ¥60 | mensola | Contorni & tè |
| `miso_paste` | Pasta di miso / Miso paste | 16 | ¥96 | mensola | Contorni & tè |
| `tofu` | Tofu | 20 | ¥50 | mensola | Contorni & tè |
| `avocado` | Avocado | 12 | ¥72 | mensola | Sushi II |
| `surimi` | Surimi | 16 | ¥80 | mensola | Sushi II |
| `sesame` | Sesamo / Sesame | 40 | ¥40 | mensola | Sushi II |
| `shrimp` | Gambero / Shrimp | 12 | ¥144 | mensola o vetrina | Sushi II |
| `broth_miso` | Base miso ramen / Miso ramen base | 16 | ¥128 | mensola → pentolone | Ramen II |
| `corn` | Mais / Corn | 20 | ¥40 | mensola | Ramen II |
| `butter` | Burro / Butter | 20 | ¥60 | mensola | Ramen II |
| `gyoza_raw` | Gyoza crudi / Raw gyoza | 24 | ¥120 | mensola | Piastra |
| `eel` | Anguilla / Eel | 10 | ¥220 | vetrina | Sushi III |
| `eel_sauce` | Salsa unagi / Eel sauce | 30 | ¥60 | mensola | Sushi III |
| `broth_tonkotsu` | Ossa tonkotsu / Tonkotsu bones | 16 | ¥192 | mensola → pentolone | Ramen III |
| `chashu` | Chashu | 12 | ¥144 | mensola | Ramen III |
| `kikurage` | Funghi kikurage / Wood ear | 20 | ¥80 | mensola | Ramen III |
| `minced_pork` | Carne macinata / Minced pork | 12 | ¥120 | mensola | Ramen III |
| `chili_oil` | Olio piccante / Chili oil | 16 | ¥96 | mensola | Ramen III |
| `batter` | Pastella / Batter | 20 | ¥40 | mensola | Friggitrice |
| `chicken` | Pollo / Chicken | 12 | ¥120 | mensola | Friggitrice |
| `yellowtail` | Ricciola / Yellowtail | 10 | ¥200 | vetrina | Sushi IV |
| `ikura` | Ikura | 10 | ¥260 | vetrina | Sushi IV |
| `daikon` | Daikon | 20 | ¥40 | mensola | Sushi IV |
| `octopus` | Polpo / Octopus | 12 | ¥180 | mensola | Street food |
| `tsukemen_noodles` | Noodles spessi / Thick noodles | 20 | ¥110 | mensola | Ramen IV |
| `mochi` | Mochi | 12 | ¥96 | mensola | Dolci & Matcha |
| `matcha` | Matcha | 20 | ¥100 | mensola | Dolci & Matcha |
| `ramune` | Ramune | 12 | ¥72 | mensola | Dolci & Matcha |
| `otoro` | Otoro | 8 | ¥480 | vetrina | Maestro Sushi |
| `black_garlic` | Olio d'aglio nero / Black garlic oil | 16 | ¥160 | mensola | Maestro Ramen |

Scatole grandi (Fornitore premium): ×3 porzioni, −10% (livello 1) o −20% (livello 2) sul prezzo.

**Scatole e ripiani** (`GameConfig.BoxShelfSlots = 2`, `Logic/ShelfGrid.luau`): un ripiano contiene **mezza scatola** disposta a scacchiera, al massimo 5 colonne, nella forma più quadrata: 6 → 3×2, 8 → 4×2, 10 → 5×2, 12 → 4×3, 15 → 5×3, 20 → 5×4, 5 → 5×1. Tutte le scatole hanno un numero pari di porzioni (cetriolo e surimi passano da 15 a 16), così una scatola riempie **esattamente 2 ripiani**. *Mensole rinforzate* moltiplica le file (righe verso il fondo) per 1,25 / 1,5 / 1,75 arrotondando alla fila (es. 5×2 → 5×3 → 5×3 → 5×4). Una scatola grande riempie 2 ripiani per volta e tiene il resto.

---

## 3. Ricette

Passaggi (un clic ciascuno, nessun tempismo): **U** = unisci, **A** = arrotola, **T** = taglia, **N** = cuoci noodles, **B** = versa brodo, **C** = condimenti, **G** = gira/cuoci sulla piastra, **F** = friggi, **I** = impana, **V** = versa, **M** = modella.

| ID | Piatto | Postazione | Ingredienti | Passaggi | Prezzo base | XP | Licenza |
|---|---|---|---|---|---|---|---|
| `kappa_maki` | Kappa Maki | sushi | riso, nori, cetriolo | U, A, T | ¥25 | 8 | base |
| `sake_nigiri` | Sake Nigiri | sushi | riso, salmone | T, U | ¥40 | 10 | base |
| `shoyu_ramen` | Shoyu Ramen | ramen | noodles, brodo shoyu, cipollotto, naruto | N, B, C | ¥55 | 14 | base |
| `tekka_maki` | Tekka Maki | sushi | riso, nori, tonno | U, A, T | ¥45 | 12 | Sushi I |
| `maguro_nigiri` | Maguro Nigiri | sushi | riso, tonno | T, U | ¥50 | 13 | Sushi I |
| `shio_ramen` | Shio Ramen | ramen | noodles, brodo shio, cipollotto, uovo | N, B, C | ¥62 | 16 | Ramen I |
| `edamame` | Edamame | bevande/contorni | edamame | V | ¥20 | 5 | Contorni & tè |
| `green_tea` | Tè verde | bevande | tè verde | V | ¥12 | 3 | Contorni & tè |
| `miso_soup` | Zuppa di miso | ramen | pasta di miso, tofu, cipollotto | U, V | ¥18 | 5 | Contorni & tè |
| `california_roll` | California Roll | sushi | riso, nori, surimi, avocado, cetriolo, sesamo | U, A, T | ¥85 | 22 | Sushi II |
| `ebi_nigiri` | Ebi Nigiri | sushi | riso, gambero | T, U | ¥60 | 16 | Sushi II |
| `miso_ramen` | Miso Ramen | ramen | noodles, brodo miso, mais, burro, cipollotto | N, B, C | ¥90 | 24 | Ramen II |
| `gyoza` | Gyoza | piastra | gyoza crudi | G, G | ¥45 | 12 | Piastra |
| `temaki_salmon` | Temaki al salmone | sushi | nori, riso, salmone, avocado | U, A | ¥95 | 26 | Sushi III |
| `dragon_roll` | Dragon Roll | sushi | riso, nori, anguilla, avocado, salsa unagi | U, A, T, C | ¥150 | 38 | Sushi III |
| `tonkotsu_ramen` | Tonkotsu Ramen | ramen | noodles, brodo tonkotsu, chashu, uovo, kikurage | N, B, C | ¥140 | 36 | Ramen III |
| `tantanmen` | Tantanmen | ramen | noodles, brodo tonkotsu, carne macinata, olio piccante, cipollotto | N, B, C | ¥150 | 38 | Ramen III |
| `ebi_tempura` | Ebi Tempura | friggitrice | gambero, pastella | I, F | ¥90 | 24 | Friggitrice |
| `karaage` | Karaage | friggitrice | pollo, pastella | I, F | ¥80 | 22 | Friggitrice |
| `sashimi_moriawase` | Sashimi misto | sushi | salmone, tonno, ricciola, daikon | T, T, U | ¥260 | 60 | Sushi IV |
| `ikura_gunkan` | Ikura Gunkan | sushi | riso, nori, ikura | U, A | ¥180 | 44 | Sushi IV |
| `takoyaki` | Takoyaki | fornello takoyaki | polpo, pastella, cipollotto | V, G | ¥110 | 28 | Street food |
| `tsukemen` | Tsukemen | ramen | noodles spessi, brodo tonkotsu, chashu, uovo | N, B, C | ¥200 | 50 | Ramen IV |
| `mochi` | Mochi | dolci | mochi, matcha | U, M | ¥70 | 18 | Dolci & Matcha |
| `matcha_latte` | Matcha latte | bevande | matcha | V | ¥60 | 14 | Dolci & Matcha |
| `ramune` | Ramune | bevande | ramune | V | ¥35 | 6 | Dolci & Matcha |
| `otoro_nigiri` | Otoro Nigiri | sushi | riso, otoro | T, U | ¥300 | 75 | Maestro Sushi |
| `omakase` | Omakase | sushi | otoro, ricciola, ikura, gambero, riso, nori | T, T, U, A | ¥900 | 200 | Maestro Sushi |
| `mayu_ramen` | Mayu Tonkotsu | ramen | noodles, brodo tonkotsu, aglio nero, chashu, uovo, kikurage | N, B, C | ¥320 | 80 | Maestro Ramen |
| `kaiseki` | Menu degustazione | sushi + ramen | otoro, ikura, brodo tonkotsu, noodles, matcha, mochi | T, U, N, B, C | ¥2.000 | 450 | Gran Maestro |

Riso cotto: il rice cooker trasforma 1 porzione di riso crudo in 1 porzione di riso per sushi. Brodo: 1 porzione di base = 1 porzione di brodo nel pentolone.

### Maestria (per ricetta)
| Livello | Piatti serviti | Prezzo | Velocità passaggi |
|---|---|---|---|
| 1 | 25 | +5% | +5% |
| 2 | 100 | +10% | +10% |
| 3 | 500 | +15% | +15% |
| 4 | 2.000 | +20% | +20% |
| 5 (oro) | 10.000 | +25% | +25%, impiattamento dorato |

---

## 4. Licenze

| ID | Licenza | Livello | Costo | Requisiti extra | Sblocca |
|---|---|---|---|---|---|
| `lic_base` | Base (ramen) | 1 | gratis | — | Shoyu Ramen |
| `lic_sushi0` | Sushi di base | 2 | ¥800 | — | Kappa Maki, Sake Nigiri (riso, nori, cetriolo, salmone) |
| `lic_sushi1` | Sushi I | 3 | ¥2.500 | — | Tekka Maki, Maguro Nigiri |
| `lic_ramen1` | Ramen I | 4 | ¥3.000 | — | Shio Ramen |
| `lic_sides` | Contorni & tè | 5 | ¥4.000 | — | Edamame, Tè verde, Zuppa di miso, postazione bevande |
| `lic_sushi2` | Sushi II | 8 | ¥12.000 | Sushi I | California Roll, Ebi Nigiri |
| `lic_ramen2` | Ramen II | 9 | ¥15.000 | Ramen I | Miso Ramen |
| `lic_griddle` | Piastra | 12 | ¥30.000 | Contorni | Gyoza, piastra |
| `lic_sushi3` | Sushi III | 14 | ¥45.000 | Sushi II, ★3,5 | Temaki, Dragon Roll |
| `lic_ramen3` | Ramen III | 16 | ¥60.000 | Ramen II, ★3,5 | Tonkotsu, Tantanmen |
| `lic_fryer` | Friggitrice | 18 | ¥80.000 | Piastra | Ebi Tempura, Karaage, friggitrice |
| `lic_sushi4` | Sushi IV | 22 | ¥150.000 | Sushi III, ★4,0 | Sashimi, Ikura Gunkan |
| `lic_street` | Street food | 24 | ¥180.000 | Friggitrice | Takoyaki, fornello takoyaki |
| `lic_ramen4` | Ramen IV | 25 | ¥220.000 | Ramen III, ★4,0 | Tsukemen |
| `lic_dessert` | Dolci & Matcha | 28 | ¥300.000 | Contorni | Mochi, Matcha latte, Ramune, postazione dolci |
| `lic_sushi_master` | Maestro del Sushi | 35 | ¥900.000 | Sushi IV, ★4,5 | Otoro, Omakase |
| `lic_ramen_master` | Maestro del Ramen | 38 | ¥1.200.000 | Ramen IV, ★4,5 | Mayu Tonkotsu |
| `lic_grandmaster` | Gran Maestro | 45 | ¥3.000.000 | entrambi i Maestri, ★4,7 | Menu degustazione |

---

## 5. Catalogo oggetti piazzabili

Colonne: prezzo, punti ambiente (Amb.), livello di sblocco, tipo di piazzamento, dimensioni indicative in stud (L × P × A).

### 5.1 Sedute, tavoli e bancone
| ID | Nome | Prezzo | Comfort | Liv. | Piazzamento | Dim. |
|---|---|---|---|---|---|---|
| `counter_straight` | Bancone dritto (2 posti) | ¥1.000 | — | 1 | pavimento | 4×3×3,5 |
| `counter_corner` | Bancone ad angolo | ¥1.200 | — | 1 | pavimento | 3×3×3,5 |
| `counter_end` | Bancone terminale | ¥800 | — | 1 | pavimento | 2×3×3,5 |
| `stool_wood` | Sgabello in legno | ¥80 | 1 | 1 | pavimento | 1,6×1,6×2,8 |
| `stool_cushion` | Sgabello imbottito | ¥300 | 2 | 4 | pavimento | 1,6×1,6×2,8 |
| `stool_swivel` | Sgabello girevole laccato | ¥900 | 3 | 12 | pavimento | 1,8×1,8×2,8 |
| `stool_red` | Sgabello rosso da ramen-ya | ¥220 | 2 | 2 | pavimento | 1,6×1,6×2,8 |
| `table_2` | Tavolo da 2 | ¥600 | — | 3 | pavimento | 3×3×2,6 |
| `table_4` | Tavolo da 4 | ¥1.400 | — | 6 | pavimento | 5×3×2,6 |
| `chair_wood` | Sedia in legno | ¥150 | 1 | 3 | pavimento | 1,6×1,6×3,5 |
| `chair_lacquer` | Sedia laccata rossa | ¥700 | 3 | 14 | pavimento | 1,6×1,6×3,5 |
| `chabudai` | Tavolino basso chabudai | ¥1.800 | — | 10 | pavimento | 4×4×1,2 |
| `zabuton` | Cuscino zabuton | ¥200 | 2 | 10 | pavimento | 1,8×1,8×0,4 |
| `bench_table` | Tavolo con panche (4 posti) | ¥2.400 | 2 | 7 | pavimento | 5×5×2,7 |
| `booth` | Separé imbottito (4 posti) | ¥5.000 | 4 | 15 | pavimento | 6×5×4 |
| `zashiki_table` | Tavolo VIP zashiki | ¥30.000 | 5 | 18 | pavimento (sala tatami) | 6×4×1,3 |
| `waiting_bench` | Panchina d'attesa (+3 in coda) | ¥500 | — | 2 | esterno | 5×1,5×2 |

### 5.2 Cucina e magazzino
| ID | Nome | Prezzo | Liv. | Funzione |
|---|---|---|---|---|
| `shelf_small` | Mensola piccola | ¥400 | 1 | 4 ripiani a scacchiera da ½ scatola |
| `shelf_large` | Mensola grande | ¥1.500 | 7 | 6 ripiani a scacchiera da ½ scatola |
| `neta_case` | Vetrina refrigerata del pesce | ¥3.000 | 5 | 4 ripiani a scacchiera da ½ scatola di pesce, +10% qualità ai piatti di pesce |
| `rice_cooker` | Rice cooker | ¥600 | 1 | lotto 10, 30 s |
| `rice_cooker_pro` | Rice cooker professionale | ¥5.000 | 11 | lotto 25, 20 s |
| `broth_pot` | Pentolone | ¥900 | 1 | lotto 8, 60 s |
| `broth_pot_large` | Pentolone grande | ¥7.500 | 13 | lotto 20, 45 s |
| `sushi_station` | Postazione sushi | ¥800 | 1 | tagliere |
| `ramen_station` | Postazione ramen | ¥1.500 | 1 | bollitore noodles |
| `drink_station` | Postazione bevande | ¥2.000 | 5 | tè, bevande |
| `griddle` | Piastra teppan | ¥6.000 | 12 | gyoza |
| `fryer` | Friggitrice | ¥8.000 | 18 | fritti |
| `takoyaki_stove` | Fornello takoyaki | ¥9.000 | 24 | takoyaki |
| `dessert_station` | Postazione dolci | ¥10.000 | 28 | dolci |
| `kitchen_counter` | Piano di lavoro (modulo della cucina componibile) | ¥250 | 1 | decorativo, ci si appoggiano oggetti |
| `sink` | Lavello | ¥500 | 1 | lavaggio a mano tenendo premuto: 1,6 s a piatto (`GameConfig.Washing`), si vedono fino a 12 piatti sporchi nella vasca; il personale ne lava fino a 8 a giro |
| `dishwasher` | Lavastoviglie | ¥12.000 | 13 | lava 6 stoviglie ogni 20 s da sola |
| `dish_set` | Set stoviglie (+6) | ¥300 | 1 | aumenta le stoviglie totali |
| `storage_rack` | Scaffale magazzino | ¥700 | 1 | 6 scatole |
| `storage_rack_large` | Scaffale magazzino grande | ¥3.000 | 9 | 12 scatole |
| `fridge` | Frigorifero professionale | ¥15.000 | 16 | +10% qualità a tutti i piatti nel suo raggio |

Stoviglie iniziali: 12. Il set di stoviglie si compra dal Fornitore (non si piazza).

### 5.3 Decorazioni
| ID | Nome | Categoria | Prezzo | Amb. | Liv. | Piazzamento |
|---|---|---|---|---|---|---|
| `chochin_red` | Lanterna chochin rossa | Illuminazione | ¥150 | 2 | 1 | soffitto/parete |
| `chochin_white` | Lanterna chochin bianca | Illuminazione | ¥150 | 2 | 1 | soffitto/parete |
| `noren_red` | Noren rosso | Arte & pareti | ¥250 | 3 | 1 | parete/porta |
| `menu_plaques` | Tavolette menu in legno | Arte & pareti | ¥300 | 3 | 1 | parete |
| `bamboo_pot` | Bambù in vaso | Piante | ¥300 | 3 | 1 | pavimento |
| `fan_wall` | Ventaglio sensu | Arte & pareti | ¥350 | 3 | 2 | parete |
| `kokedama` | Kokedama sospeso | Piante | ¥250 | 2 | 2 | soffitto |
| `maneki_neko` | Maneki-neko | Statue | ¥500 | 6 | 2 | appoggio (+1% mance, max 3) |
| `andon_lamp` | Lampada andon | Illuminazione | ¥600 | 5 | 3 | pavimento |
| `kakejiku` | Rotolo kakejiku | Arte & pareti | ¥700 | 5 | 3 | parete |
| `daruma` | Daruma | Statue | ¥350 | 3 | 3 | appoggio/pavimento |
| `bonsai_pine` | Bonsai di pino | Piante | ¥900 | 7 | 4 | appoggio/pavimento |

#### Pacchetto Ramen-ya (ispirato ai banconi dei ramen-ya veri)
| ID | Nome | Categoria | Prezzo | Amb. | Liv. | Piazzamento |
|---|---|---|---|---|---|---|
| `water_pitcher` | Brocca d'acqua (con bicchieri) | Sul tavolo | ¥120 | 1 | 1 | appoggio |
| `condiment_caddy` | Portacondimenti (bacchette, aglio, peperoncino, pepe, fazzoletti) | Sul tavolo | ¥180 | 2 | 1 | appoggio |
| `pendant_lamp` | Lampada a sospensione | Illuminazione | ¥350 | 3 | 2 | soffitto |
| `chochin_orange` | Lanterna arancione ラーメン | Illuminazione | ¥200 | 2 | 2 | soffitto |
| `menu_posters` | Poster del menù (5 piatti con prezzo) | Arte & pareti | ¥450 | 4 | 3 | parete |
| `counter_posters` | Mensola menù da bancone | Sul tavolo | ¥650 | 5 | 4 | appoggio (bancone) |
| `noren_banner` | Striscione rosso ラーメン・餃子・炒飯 | Arte & pareti | ¥700 | 5 | 4 | soffitto |
| `ramen_poster` | Poster retrò del ramen | Arte & pareti | ¥600 | 5 | 5 | parete |
| `ramen_sign_vertical` | Insegna verticale ラーメン con faretto | Arte & pareti | ¥900 | 6 | 6 | parete |
| `soup_sign` | Tavola del brodo segreto 秘伝スープ | Arte & pareti | ¥1.600 | 9 | 8 | parete |
| `ramenya_canopy` | Tettoia del ramen-ya (striscione + 3 lampade) | Illuminazione | ¥4.500 | 18 | 9 | soffitto |

Le parti alte della tettoia si nascondono in modalità costruzione, come il tetto.
| `nobori` | Stendardo nobori | Festival | ¥450 | 4 | 4 | pavimento/esterno |
| `soy_barrel` | Botte di salsa di soia | Statue | ¥450 | 4 | 4 | pavimento |
| `noren_indigo` | Noren indaco con onde | Arte & pareti | ¥400 | 4 | 5 | parete/porta |
| `paper_pendant` | Lampada a sospensione in carta | Illuminazione | ¥900 | 6 | 5 | soffitto |
| `stone_path` | Pietra da sentiero | Giardino & acqua | ¥120 | 1 | 5 | pavimento/esterno |
| `toro_stone` | Lanterna di pietra tōrō | Illuminazione | ¥1.200 | 8 | 6 | pavimento/esterno |
| `wagasa` | Ombrello wagasa | Arte & pareti | ¥650 | 5 | 6 | pavimento |
| `ikebana` | Ikebana | Piante | ¥700 | 5 | 7 | appoggio |
| `neon_ramen` | Insegna neon ラーメン | Illuminazione | ¥3.500 | 15 | 8 | parete |
| `tanuki` | Statua tanuki | Statue | ¥1.100 | 7 | 8 | pavimento |
| `wave_painting` | Quadro "Onda" | Arte & pareti | ¥1.500 | 9 | 9 | parete |
| `vending_machine` | Distributore automatico | Festival | ¥2.200 | 8 | 9 | pavimento/esterno |
| `neon_sushi` | Insegna neon 寿司 | Illuminazione | ¥3.500 | 15 | 10 | parete |
| `byobu` | Paravento byōbu | Arte & pareti | ¥1.800 | 10 | 10 | pavimento |
| `moss_garden` | Aiuola di muschio | Giardino & acqua | ¥2.500 | 12 | 11 | pavimento/esterno |
| `gashapon` | Macchina gashapon | Festival | ¥2.800 | 10 | 11 | pavimento |
| `lantern_string` | Fila di lanterne festival | Illuminazione | ¥2.000 | 10 | 12 | soffitto/esterno |
| `koinobori` | Koinobori | Festival | ¥1.600 | 8 | 12 | esterno |
| `taiko` | Tamburo taiko | Festival | ¥3.000 | 15 | 13 | pavimento |
| `shishi_odoshi` | Shishi-odoshi | Giardino & acqua | ¥4.000 | 20 | 14 | pavimento/esterno |
| `maple_tree` | Acero giapponese | Piante | ¥6.000 | 25 | 15 | esterno/grande |
| `aquarium` | Acquario | Statue | ¥9.000 | 30 | 16 | pavimento |
| `zen_garden` | Giardino zen | Giardino & acqua | ¥8.000 | 30 | 17 | pavimento/esterno |
| `kimono_display` | Kimono in esposizione | Arte & pareti | ¥4.000 | 18 | 18 | parete/pavimento |
| `yatai` | Carretto yatai | Festival | ¥10.000 | 35 | 19 | esterno |
| `sakura_tree` | Ciliegio in fiore | Piante | ¥12.000 | 40 | 20 | esterno/grande |
| `koi_pond` | Laghetto koi | Giardino & acqua | ¥15.000 | 45 | 20 | esterno |
| `red_bridge` | Ponticello rosso | Giardino & acqua | ¥18.000 | 40 | 24 | esterno |
| `torii_small` | Piccolo torii | Giardino & acqua | ¥20.000 | 50 | 25 | esterno |
| `samurai_armor` | Armatura samurai | Statue | ¥25.000 | 50 | 28 | pavimento |
| `maneki_gold` | Maneki-neko d'oro | Statue | ¥250.000 (o VIP) | 30 | 30 | appoggio (+3% mance) |
| `bonsai_ancient` | Bonsai secolare | Piante | ¥45.000 | 60 | 32 | pavimento |
| `waterfall` | Cascata di roccia | Giardino & acqua | ¥60.000 | 80 | 36 | esterno |
| `dragon_statue` | Statua del drago | Statue | ¥150.000 | 120 | 40 | pavimento/esterno |
| `torii_gold` | Torii dorato | Giardino & acqua | ¥500.000 | 200 | 45 | esterno |

**Ambiente con rendimenti decrescenti**: la n-esima copia dello stesso oggetto vale `amb × 0,8^(n−1)`.

### 5.4 Pavimenti e pareti (per zona)
| ID | Pavimento | Prezzo | Liv. | | ID | Parete | Prezzo | Liv. |
|---|---|---|---|---|---|---|---|---|
| `floor_wood_light` | Legno chiaro | gratis | 1 | | `wall_plaster` | Intonaco crema | gratis | 1 |
| `floor_wood_dark` | Legno scuro | ¥2.000 | 3 | | `wall_wood` | Pannelli in legno | ¥2.500 | 3 |
| `floor_tatami` | Tatami | ¥5.000 | 6 | | `wall_shoji` | Shoji | ¥6.000 | 7 |
| `floor_slate` | Ardesia | ¥8.000 | 10 | | `wall_brick` | Mattone scuro | ¥9.000 | 12 |
| `floor_pebble` | Ciottoli di fiume | ¥12.000 | 14 | | `wall_bamboo` | Bambù | ¥15.000 | 16 |
| `floor_marble` | Marmo nero | ¥40.000 | 26 | | `wall_yakisugi` | Legno bruciato yakisugi | ¥30.000 | 22 |
| `floor_hinoki` | Legno di hinoki | ¥80.000 | 34 | | `wall_gold` | Oro e lacca | ¥120.000 | 38 |

Ogni stile di pavimento/parete dà punti ambiente pari a `prezzo / 1.000` (massimo 40) per zona.

### 5.5 Livelli di ambiente
| Livello | Punti | Pazienza | Mancia | Popolarità |
|---|---|---|---|---|
| Spoglio | 0–29 | 0% | 0% | 0 |
| Accogliente | 30–99 | +10% | +5% | +0,10 |
| Elegante | 100–249 | +20% | +10% | +0,25 |
| Raffinato | 250–599 | +30% | +18% | +0,45 |
| Leggendario | 600+ | +40% | +25% | +0,70 |

---

## 6. Miglioramenti

| ID | Miglioramento | Livelli | Costi | Effetto |
|---|---|---|---|---|
| `up_tray` | Vassoio | 1→5 | ¥1.500 (L2) · ¥8.000 (L8) · ¥40.000 (L18) · ¥150.000 (L30) | capienza 1→2→3→4→5 |
| `up_shoes` | Scarpe da cucina | 0→5 | ¥1.000 × 3^n | +8% velocità per livello |
| `up_knife` | Coltello (Santoku → Yanagiba → Damasco → Hon-yaki) | 0→4 | ¥2.000 · ¥15.000 · ¥90.000 · ¥400.000 | −10% durata dei passaggi T e U |
| `up_mat` | Stuoia makisu | 0→3 | ¥3.000 · ¥25.000 · ¥150.000 | −12% durata del passaggio A |
| `up_strainer` | Scolapasta tebo | 0→3 | ¥3.000 · ¥25.000 · ¥150.000 | −12% durata dei passaggi N, B, C, F |
| `up_shelf` | Mensole rinforzate | 0→3 | ¥5.000 · ¥30.000 · ¥200.000 | file di prodotti × 1,25 / 1,5 / 1,75 (arrotondate) |
| `up_delivery` | Consegna | 0→3 | ¥4.000 · ¥40.000 · ¥250.000 | 45 s → 30 s → 15 s → 5 s |
| `up_supplier` | Fornitore premium | 0→2 | ¥20.000 (L10) · ¥200.000 (L25) | scatole grandi −10% / −20% |
| `up_sign` | Insegna luminosa | 0→5 | ¥2.000 × 4^n | +0,08 popolarità per livello |
| `up_ticket` | Barra ordini | 0→2 | ¥6.000 · ¥60.000 | 6 → 8 → 10 biglietti |
| `up_jukebox` | Jukebox | 0→3 | ¥5.000 · ¥50.000 · ¥300.000 | +15 / +40 / +90 ambiente |
| `up_safe` | Cassaforte (guadagni offline) | 0→5 | ¥10.000 × 4^n | 2/4/8/12/24 h al 10/15/20/25/30% |
| `up_autorestock` | Riordino automatico | 0→1 | ¥120.000 (L20, serve un Magazziniere) | ordina da solo sotto soglia |

### Pubblicità (consumabili, durano 1 giornata)
| ID | Nome | Costo | Effetto |
|---|---|---|---|
| `ad_flyers` | Volantini | ¥500 | +0,20 popolarità |
| `ad_radio` | Spot radio | ¥5.000 (L10) | +0,35 popolarità |
| `ad_tv` | Spot TV | ¥50.000 (L25) | +0,60 popolarità, più turisti |

---

## 7. Personale

| ID | Ruolo | Liv. | Assunzione | Stipendio / giorno | Velocità base |
|---|---|---|---|---|---|
| `staff_waiter` | Cameriere | 6 | ¥5.000 | ¥300 | 1,0 |
| `staff_dishwasher` | Lavapiatti | 7 | ¥4.000 | ¥250 | 1,0 |
| `staff_stocker` | Magazziniere | 10 | ¥8.000 | ¥400 | 1,0 |
| `staff_sushi_chef` | Cuoco sushi | 14 | ¥20.000 | ¥900 | 0,8 (piatti/min ≈ 3) |
| `staff_ramen_chef` | Cuoco ramen | 16 | ¥25.000 | ¥1.000 | 0,8 |
| `staff_line_cook` | Cuoco di linea | 18 | ¥30.000 | ¥1.100 | 0,8 |
| `staff_manager` | Manager | 26 | ¥150.000 | ¥3.000 | — (+10% velocità a tutti) |

- **Addestramento** (livelli 1→5): costo `assunzione × 0,8 × 2,2^(livello−1)`; +15% velocità per livello.
- **Posti personale**: 2 con il locale base, +1 per Sala Est, Sala Ovest, Terrazza; +3 con la Cucina professionale; +3 con il Secondo piano. Massimo 12.

---

## 8. Espansioni (zone)

| ID | Espansione | Liv. | Costo | Dimensioni (stud) | Note |
|---|---|---|---|---|---|
| `zone_base` | Locale base | 1 | — | sala 72×32 + cucina 72×24, magazzino 24×32 | bancone 6 posti |
| `zone_east` | Sala Est | 3 | ¥5.000 | +32×32 | sblocca i tavoli |
| `zone_storage2` | Magazzino ampliato | 5 | ¥8.000 | +24×32 | |
| `zone_west` | Sala Ovest | 8 | ¥25.000 | +32×56 | |
| `zone_terrace` | Terrazza esterna | 12 | ¥60.000 | 72×10 sulla strada | esterno |
| `zone_garden` | Giardino zen | 15 | ¥100.000 | 48×36 sul retro | esterno |
| `zone_tatami` | Sala tatami privata | 18 | ¥180.000 | 32×32 | clienti VIP |
| `zone_kitchen_pro` | Cucina professionale | 20 | ¥250.000 | +32×24 di cucina | +3 posti personale |
| `zone_floor2` | Secondo piano | 25 | ¥600.000 | 72×56 + scala ad angolo larga 6 | +3 posti personale |
| `sign_rooftop` | Insegna gigante | 28 | ¥500.000 | — | +0,3 popolarità |
| `facade_deluxe` | Facciata deluxe | 30 | ¥1.000.000 | — | +60 ambiente |
| `zone_rooftop` | Terrazza sul tetto | 35 | ¥2.000.000 | 72×56 esterno + scala ad angolo | vista, fuochi d'artificio |

### 8.1 Ristrutturazioni (estetiche, `reno` in `Config/Expansions.luau`)
Il locale iniziale è spoglio. Ogni ristrutturazione si compra una volta; l'atmosfera si somma come quella delle decorazioni. Le voci con *stile* aggiungono il gruppo `Detail_<stile>` ai modelli piazzati.

| ID | Ristrutturazione | Gruppo | Liv. | Costo | Atmosfera | Altro |
|---|---|---|---|---|---|---|
| `reno_storage` | Magazzino in ordine | interno | 2 | ¥1.500 | +2 | |
| `reno_wainscot` | Boiserie koshi-ita | interno | 3 | ¥3.500 | +5 | |
| `reno_kitchen_tiles` | Piastrelle in cucina | interno | 4 | ¥4.000 | +3 | |
| `reno_facade` | Facciata machiya | esterno | 4 | ¥6.000 | +6 | +0,03 popolarità |
| `reno_entrance` | Ingresso tradizionale | esterno | 5 | ¥8.000 | +8 | +0,04 popolarità |
| `reno_counter` | Bancone in hinoki | arredi | 6 | ¥10.000 | +10 | stile `counter` |
| `reno_eaves` | Tettoia di tegole | esterno | 7 | ¥14.000 | +10 | +0,04 popolarità |
| `reno_kitchen_gear` | Attrezzatura da chef | arredi | 8 | ¥16.000 | +6 | stile `kitchen` |
| `reno_windows` | Finestre a grata | esterno | 9 | ¥18.000 | +10 | |
| `reno_beams` | Travi e pilastri | interno | 10 | ¥22.000 | +14 | richiede la boiserie |
| `reno_tableware` | Servizio da tavola | arredi | 11 | ¥28.000 | +16 | stile `tableware` |
| `reno_bamboo` | Recinzione inu-yarai | esterno | 13 | ¥40.000 | +18 | richiede la facciata machiya |
| `reno_furnish` | Rifiniture degli arredi | arredi | 15 | ¥60.000 | +24 | stile `furnish` |

Totale ¥231.000 e +122 atmosfera (circa un livello di ambiente in più a metà partita). Anche `sign_rooftop` e `facade_deluxe` stanno nella scheda Ristrutturazioni. Traguardo *Completa {n} ristrutturazioni*: 3 / 8 / 15 → 🌸5 / 15 / 40.

**Si parte con il magazzino vuoto** (¥500 per il primo ordine: gli ingredienti del ramen costano ¥281). Oggetti iniziali: bancone (6 moduli + 2 terminali, 28 stud), 12 sgabelli, postazioni sushi e ramen, 2 mensole, cucina componibile (cuociriso, fornello con pentolone, 2 piani di lavoro, lavello), scaffale del magazzino e **una sola lanterna**: tutte le altre decorazioni si comprano.

---

## 9. Clienti

| ID | Tipo | Liv. | Peso | Gruppo | Pazienza (s) | Molt. mancia | Preferenze (×2 probabilità) |
|---|---|---|---|---|---|---|---|
| `cust_student` | Studente | 1 | 30 | 1 | 70 | 0,7 | piatti ≤ ¥60, ramen |
| `cust_salaryman` | Salaryman | 1 | 30 | 1 | 50 (35 a pranzo) | 1,0 | ramen |
| `cust_tourist` | Turista | 3 | 15 | 1–2 | 100 | 1,4 | sushi |
| `cust_couple` | Coppia | 3 | 12 | 2 | 80 | 1,1 | sushi, dolci |
| `cust_elder` | Anziano | 5 | 8 | 1 | 130 | 1,0 | tè, miso, nigiri |
| `cust_family` | Famiglia | 6 | 10 | 3–4 | 90 | 1,0 | vari |
| `cust_influencer` | Influencer | 10 | 2 | 1 | 45 | 1,5 | piatti costosi |
| `cust_critic` | Critico | 12 | 1,5 | 1 | 80 | 1,6 | piatti di maestria alta |
| `cust_vip` | Ospite VIP | 18 | 3 | 2–4 | 150 | 2,5 | solo sala tatami, 3 piatti a testa |
| `cust_celebrity` | Celebrità | 30 | 0,3 | 1 | 90 | 5,0 | evento |

- **Difficoltà bassa** (`GameConfig.Customers.PatienceMult = 1,8`): la pazienza reale è quella della tabella × 1,8 (× il bonus dell'ambiente); quando prendi l'ordine il timer riparte da pieno per la cottura.
- Piatti per cliente: 1 principale; 40% di probabilità di contorno o bevanda se sbloccati; 15% di un secondo ordine.
- Tempo per mangiare: 12 s (sushi), 18 s (ramen), 6 s (bevande).
- Numero massimo di clienti contemporanei: posti disponibili + coda (massimo 40 NPC in totale, personale incluso, per non pesare sul server).

### Recensione
`stelle = 4,2 − penaltàAttesa − penaltàSporco + bonusFreschezza(0,3) + bonusAmbiente(0–0,5) + bonusComfort(0–0,3)`, limitata tra 1 e 5.
- penaltàAttesa: 0 se il cliente ha usato meno del 50% della pazienza, poi fino a −2.
- penaltàSporco: −0,5 se ci sono stoviglie sporche entro 6 stud.
- Cliente andato via senza mangiare: 1 ★.

---

## 10. Ricompense e meta

| Sistema | Valori |
|---|---|
| Ricompensa di livello | `¥(50 × L²)` + 🌸5 ogni 5 livelli |
| Missioni giornaliere | 3 al giorno; ricompensa `¥(200 × livello)` + 🌸2 ciascuna; 🌸5 bonus se completi tutte e 3 |
| Accesso giornaliero | giorni 1–7: ¥500, ¥1.000, 🌸3, ¥2.500, 🌸5, ¥5.000, 🌸15 + decorazione esclusiva; scala con il livello |
| Critico 5 ★ | 🌸3 |
| Obiettivi | traguardi a livelli (piatti, clienti, yen, decorazioni, personale, maestrie, licenze, zone, ristrutturazioni…) con 🌸3–100 |
| Set di decorazioni | Matsuri, Giardino zen, Samurai, Neon di Tokyo, Ciliegi: +5% mance o +0,1 popolarità ciascuno; Ramen-ya (tettoia, striscione, poster del menù, sgabello rosso, brocca): +4% mance e +0,06 popolarità |
| Franchise | ogni stella: +25% yen, +10% XP; ¥2.000 iniziali nella nuova città |
| Regali a tempo (`Config/Rewards.luau`) | minuti di gioco nella sessione: 2 → ¥250 · 5 → 🌸2 · 9 → salmone + noodles · 14 → ¥900 · 20 → 🌸5 · 28 → ¥2.200 · 38 → 2 brodo shoyu + riso · 50 → 🌸10 · 65 → ¥6.000; gli yen × (1 + livello × 0,12); agli aiutanti ¥400 al posto delle scatole |
| Codici | RAMEN ¥500 · SAKURA 🌸5 · ITADAKIMASU ¥1.500 · OISHII 🌸10 · NEWSHOP ¥3.000 (yen × (1 + livello × 0,12)); una volta per giocatore |
| Combo di servizio | piatti serviti entro 30 s l'uno dall'altro: +5% di mancia per passo, massimo +50% |
| Corsa | Shift o 🏃: velocità × 1,45 |

---

## 11. Monetizzazione (valori predefiniti, prezzi in Robux da decidere)

| ID | Tipo | Effetto |
|---|---|---|
| `gp_vip` | Gamepass | ×1,25 yen, etichetta chat, `maneki_gold` gratuito |
| `gp_double_yen` | Gamepass | ×2 yen (si somma al VIP: ×2,5) |
| `gp_big_tray` | Gamepass | +2 vassoio |
| `gp_express` | Gamepass | consegna 1 s |
| `gp_starter` | Gamepass | ¥10.000, `stool_cushion` ×6, `neon_ramen`, `maneki_neko`, `sakura_tree` |
| `dp_yen_s/m/l/xl` | Prodotto | `¥(1.000 / 5.000 / 15.000 / 50.000) × (1 + livello/5)` |
| `dp_sakura_s/m/l` | Prodotto | 🌸20 / 🌸120 / 🌸300 |
| `dp_rush_hour` | Prodotto | 2× clienti per 30 minuti |
| `dp_golden_sign` | Prodotto | +50% mance per 30 minuti |
