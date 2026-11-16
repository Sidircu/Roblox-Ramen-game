# Sakura Ramen & Sushi Tycoon — Game Design Document

> Titolo provvisorio. Documento di riferimento per l'implementazione completa del gioco.
> Numeri, prezzi e tabelle di bilanciamento stanno in [`03-BILANCIAMENTO.md`](03-BILANCIAMENTO.md).
> Architettura e codice stanno in [`02-PIANO-TECNICO.md`](02-PIANO-TECNICO.md).

---

## 0. Decisioni già prese

| Tema | Decisione |
|---|---|
| Genere | Tycoon/gestionale a lungo termine, ispirato a *Pet Store Tycoon* e *Supermarket Together* |
| Tema | Ristorante giapponese di **ramen e sushi**, tutto a tema (arredi, decorazioni, strada, luci) |
| Mondo | **Mondo personale**: ogni giocatore è da solo nel suo mondo con il suo ristorante. Nessun estraneo |
| Co-op | **Ibrido**: puoi **invitare amici** nel tuo mondo come aiutanti (cucinano, servono, riforniscono) |
| Lingua | **Inglese + Italiano**, scelta automatica in base alla lingua del giocatore, modificabile nelle impostazioni |
| Interazione | **Movimento libero** con joystick/WASD come in ogni gioco Roblox. Quando sei vicino a un oggetto, **lo clicchi (o lo tocchi)** e l'azione avviene |
| Cucina | **Fisica + clic, senza tempismo**: gli ingredienti si prendono davvero dalle mensole e si portano in mano; alla postazione ogni clic esegue un passaggio (il coltello taglia, gli ingredienti si uniscono, il maki si arrotola). Nessun minigioco a tempo, nessun gesto da fare |
| Costruzione | Decorazioni e mobili acquistabili e piazzabili su una **griglia a terra regolabile: 1, 5 o 10 stud** |
| Robux | **Predisposta**: gamepass e prodotti già nel codice, attivi solo dopo aver inserito gli ID. Il gioco resta completabile gratis |
| Grafica | Stile 3D curato e pulito, luci calde, lanterne, neon notturni; modelli generati dal codice e sostituibili con modelli migliori |

> Nota sulle unità: in Roblox l'unità di misura è lo **stud** (≈ 28 cm), non il pixel. Un personaggio è alto circa 5 stud, uno sgabello è largo circa 2 stud.

---

## 1. Visione

Apri un piccolo ramen-ya in un vicolo giapponese illuminato da lanterne. All'inizio hai un bancone con 6 sgabelli, due mensole e una pentola. Cucini tu ogni piatto, porti tu le scatole dal magazzino, lavi tu le ciotole. Ora dopo ora guadagni yen, sblocchi licenze per nuovi piatti, assumi personale che automatizza il lavoro, ingrandisci il locale stanza dopo stanza fino al secondo piano e alla terrazza sul tetto, e lo arredi come vuoi tu. Alla fine apri nuovi locali in altre città del Giappone (Franchise) e ricominci più forte.

### Pilastri

1. **Il lavoro manuale è soddisfacente**: prendere, portare, cucinare, servire. Ogni azione ha un'animazione e un suono che la rendono piacevole.
2. **Ogni acquisto si vede**: tutto ciò che compri appare fisicamente nel ristorante.
3. **Il tuo locale è unico**: griglia, rotazione, pavimenti, pareti e oltre 50 decorazioni.
4. **Progressione lunga e costante**: c'è sempre un obiettivo vicino (prossimo piatto, prossima decorazione) e uno lontano (secondo piano, franchise).
5. **Atmosfera giapponese autentica**: noren all'ingresso, vetrina del pesce sul bancone, vapore dalle ciotole, il treno che passa la sera.

### Durata prevista

| Fase | Livelli | Ore indicative | Cosa succede |
|---|---|---|---|
| Inizio | 1–10 | 0–6 h | Tutto a mano. Prime licenze, primi tavoli, prima espansione |
| Crescita | 10–25 | 6–20 h | Arrivano camerieri e cuochi, ramen avanzati, terrazza, giardino, sala tatami |
| Maturità | 25–40 | 20–35 h | Secondo piano, menu completo, maestrie, decorazioni di lusso |
| Fine gioco | 40–50 | 35–45 h | Piatti da maestro, tetto, collezioni complete |
| Franchise | ×5 città | +60–150 h | Ricominci in una nuova città con bonus permanenti e piatti regionali |

---

## 2. Il mondo

### 2.1 Struttura delle sessioni (mondo personale)

- Quando entri nel gioco vedi per pochi secondi una schermata di caricamento ("Preparing your restaurant…" / "Stiamo preparando il tuo ristorante…") e vieni portato nel **tuo mondo privato**, creato solo per te.
- Nel tuo mondo ci sei solo tu e chi inviti.
- **Invita amici**: pulsante nell'interfaccia → invito Roblox. L'amico che accetta entra nel tuo mondo.
  - Gli amici sono **Aiutanti**: possono cucinare, servire, pulire, rifornire.
  - Non possono comprare, vendere o spostare oggetti, a meno che tu non dia loro il permesso **Co-gestore**.
  - Gli aiutanti guadagnano XP e un piccolo compenso in yen per il **proprio** salvataggio (pagato dal gioco, non tolto a te).
- Se il proprietario esce, il mondo si chiude: gli aiutanti vengono riportati nel proprio mondo con un messaggio.

### 2.2 La strada (yokochō)

Il ristorante si trova a metà di un vicolo giapponese, sempre visibile e decorativo:
- Edifici vicini non accessibili (negozietti, una lavanderia, una casa con le luci accese), insegne verticali, pali della luce con i fili, distributori automatici luminosi, biciclette parcheggiate, vasi di piante.
- Ciliegi lungo la strada, petali che cadono.
- Un treno che passa su un cavalcavia sullo sfondo, soprattutto la sera.
- Da entrambe le estremità del vicolo arrivano e se ne vanno i clienti.
- Sul lato del ristorante c'è la **porta di carico del magazzino**, dove arriva il furgoncino delle consegne (kei truck).

### 2.3 Il ristorante iniziale

Pianta indicativa (vista dall'alto):

```
               STRADA (clienti)
  ┌──────────────[ ingresso con noren ]─────────────┬───────────┐
  │                                                  │           │
  │   SALA        [lavagna menu]   [lanterna]        │ MAGAZZINO │
  │                                                  │  scaffale │
  │   ( ) ( ) ( ) ( ) ( ) ( )     <- 6 sgabelli      │  scatole  │
  │  ═══════════ BANCONE ═══════════ [vetrina pesce] │           │
  │   postazione sushi   postazione ramen  lavello   │  [porta]  │──► furgone
  │   [mensola] [mensola]  [rice cooker] [pentola]   │   carico  │
  │   [tablet ordini]                                │           │
  └──────────────────────────────────────────────────┴───────────┘
```

- Il bancone separa la **sala clienti** dalla **zona di lavoro**. I clienti non entrano dietro il bancone.
- Gli oggetti iniziali sono normali oggetti piazzabili: puoi spostarli tutti in modalità costruzione.
- **In scala con gli avatar**: il locale base misura 72 × 56 stud (sala 72 × 32, cucina 72 × 24, magazzino 24 × 32). In cucina il bancone, le postazioni subito dietro e, oltre un corridoio largo 6 stud, scaffali, cuociriso, pentolone e lavello.
- **Si parte da un locale base**: pareti lisce, tettoia in lamiera, finestre semplici, bancone e postazioni essenziali, una sola lanterna. Tutto il resto (decorazioni e dettagli tradizionali) si compra col tempo: decorazioni piazzabili (§9) e **ristrutturazioni** (§8.5).

---

## 3. Ciclo di gioco

### 3.1 Il ciclo principale (loop)

```
Ordina scatole dal tablet ─► Il furgone consegna in magazzino ─► Porti le scatole alle mensole
        ▲                                                                   │
        │                                                                   ▼
   Spendi gli yen  ◄── Il cliente paga + mancia ◄── Servi il piatto ◄── Cucini al bancone
 (licenze, mobili,                                                          ▲
  personale, ampliamenti)                         Il cliente si siede e ordina ┘
```

### 3.2 La giornata

1. **Preparazione** (durata libera, nessun cliente): rifornisci, cuoci il riso, prepari il brodo, costruisci, compri.
2. **Apertura**: clicchi "Apri" → il noren viene appeso, l'insegna "営業中" si accende.
3. **Servizio** (12 minuti reali = dalle 11:00 alle 23:00, 1 ora di gioco = 1 minuto reale):
   - Picco del pranzo (12:00–14:00) e della cena (19:00–21:00) con più clienti.
   - La luce cambia: giorno → tramonto arancione → sera con lanterne e neon accesi.
4. **Chiusura**: alle 23:00 non entrano più clienti, quelli seduti finiscono di mangiare.
5. **Resoconto della giornata**: incassi, mance, costi (ingredienti, stipendi), recensioni, XP, obiettivi completati.

Più avanti, con il **Manager**, puoi attivare la "giornata automatica" (apertura e chiusura da sole) per giocare in modo più rilassato.

### 3.3 Interazione "basta cliccare"

- Il personaggio si muove **liberamente** con WASD (PC) o joystick (telefono/tablet).
- Quando sei **vicino** a un oggetto interattivo (entro ~10 stud) e ci passi sopra con il mouse, si illumina il contorno e compare un'etichetta ("Prendi salmone", "Servi", "Lava").
- **Clicchi o tocchi** l'oggetto → l'azione avviene subito, con un'animazione. Se sei troppo lontano compare "Avvicinati".
- Il personaggio porta gli oggetti **visibilmente in mano** (scatola, ingredienti, piatti). Gli ingredienti in mano sono fino a 6; i piatti e le stoviglie dipendono dal **Vassoio** (1 all'inizio, fino a 5).

---

## 4. Rifornimento: tablet, consegne, magazzino, mensole

### 4.1 Tablet ordini (Fornitore)
- Un tablet appeso al muro della cucina (o il pulsante "Fornitore" nell'interfaccia).
- Catalogo ingredienti divisi per categoria (Pesce, Riso & alghe, Verdure, Brodi, Noodles, Carni, Bevande, Dolci). Ogni ingrediente si compra **a scatole** (es. "Salmone — scatola da 12 porzioni — ¥120").
- Ingredienti visibili solo se hai la licenza del piatto che li usa.
- Carrello → "Ordina". Con l'upgrade **Fornitore premium** compaiono le scatole grandi scontate.

### 4.2 Consegna
- Il furgoncino arriva alla porta di carico dopo un tempo di consegna (45 s all'inizio, si riduce con gli upgrade).
- Il corriere scarica le scatole sugli **scaffali del magazzino** (o a terra davanti, se gli scaffali sono pieni).
- Ogni scatola ha un'etichetta con icona e nome dell'ingrediente e il numero di porzioni rimaste.

### 4.3 Dal magazzino alle mensole
- Clicchi una scatola → la prendi in mano.
- Clicchi una **mensola** dietro il bancone → il personaggio la svuota nello slot giusto (animazione di sistemazione).
- Ogni mensola ha degli **slot**; ogni slot contiene un solo tipo di ingrediente fino a una capienza massima. Gli oggetti sulle mensole sono visibili (barattoli, pacchetti, filetti di pesce).
- Se lo slot si riempie, la scatola resta in mano con le porzioni avanzate; una scatola vuota si butta automaticamente.
- La **vetrina refrigerata del pesce** (sul bancone, come nei veri sushi bar) funziona come una mensola per il pesce e dà un bonus di freschezza (qualità).

### 4.4 Preparazioni di base
- **Riso**: il riso crudo va nel **rice cooker** (clic) → cottura 30 s → diventa "riso per sushi" (lotto da 10 porzioni, 25 con il modello pro).
- **Brodo**: la base del brodo va nel **pentolone** (clic) → 60 s → lotto da 8 porzioni. Ogni tipo di brodo (shoyu, shio, miso, tonkotsu) occupa un pentolone; servono più pentoloni per più brodi contemporaneamente.
- Indicatori sopra gli apparecchi: barra di cottura, porzioni rimaste, icona "pronto".

---

## 5. Cucina

### 5.1 Ordini
- Il cliente seduto mostra una nuvoletta con l'icona del piatto.
- Clic sul cliente → l'ordine diventa un **biglietto** appeso alla barra degli ordini sopra il bancone (max 6 biglietti; 10 con upgrade).
- Clic su un biglietto (o sulla postazione) → il gioco **evidenzia in oro** gli ingredienti che servono sulle mensole e la postazione corretta.

### 5.2 Preparare il sushi (postazione sushi / tagliere)
Esempio *Sake Nigiri*:
1. Clic sul salmone sulla mensola → lo prendi in mano.
2. Clic sulla postazione sushi → il salmone va sul tagliere; il riso viene preso da solo dal rice cooker.
3. Clic → **il coltello taglia** il filetto (animazione).
4. Clic → **gli ingredienti si uniscono**: la fetta si posa sul riso e diventa un nigiri.
5. Il piatto viene impiattato da solo e resta sulla postazione, pronto da servire.

I maki hanno i passaggi **Unisci → Arrotola → Taglia**: tre clic, tre animazioni (stuoia di bambù che arrotola, coltello che fa sei pezzi).

Sopra la postazione un'etichetta mostra sempre cosa c'è sul tagliere, che piatto ne verrà fuori e il prossimo passaggio ("Clicca per tagliare").

### 5.3 Preparare il ramen (postazione ramen)
Esempio *Shoyu Ramen*:
1. Prendi noodles, cipollotto e naruto dalle mensole (puoi tenere in mano fino a 6 ingredienti).
2. Clic sulla postazione ramen → gli ingredienti vengono posati.
3. Clic → **i noodles cuociono** nel bollitore (animazione con vapore).
4. Clic → **il brodo viene versato** dal pentolone nella ciotola.
5. Clic → **i condimenti si dispongono** sopra.
6. Ciotola fumante pronta.

### 5.4 Altre postazioni (sbloccate con licenze)
| Postazione | Piatti | Passaggi |
|---|---|---|
| Piastra (teppan) | Gyoza | Cuoci → Gira |
| Friggitrice | Tempura, Karaage | Impana → Friggi |
| Postazione bevande | Tè, Matcha, Ramune | Versa |
| Postazione dolci | Mochi | Unisci → Modella |
| Fornello takoyaki | Takoyaki | Versa → Gira |

### 5.5 Velocità e freschezza
Non esistono errori né tempismo: ogni piatto riesce sempre. Il guadagno dipende da:
- **Velocità del servizio**: più pazienza resta al cliente, più alta è la mancia.
- **Freschezza**: il pesce preso dalla vetrina refrigerata e i piatti preparati vicino al frigorifero professionale valgono di più (+10% di mancia e recensioni migliori).
- **Attrezzi migliori** (coltelli, stuoie, scolapasta): rendono le animazioni dei passaggi più veloci.
- **Maestria** della ricetta: aumenta il prezzo e la velocità.

### 5.6 Servire, pagare, pulire
- Clic sul piatto pronto → lo prendi (anche più piatti, in base al Vassoio). Clic sul cliente → lo servi.
- Il cliente mangia (barra), poi paga in automatico: le monete volano verso la cassa con un "cha-ching". Il pagamento è **prezzo del menu + mancia**.
- Al posto restano **stoviglie sporche**: il posto non è utilizzabile finché non le raccogli. Clic → le prendi → clic sul **lavello** → si lavano con un'animazione e tornano pulite.
- Le **stoviglie pulite** sono una risorsa: se finiscono non puoi impiattare. Puoi comprare altri set di ciotole e piatti; la **lavastoviglie** lava da sola.

---

## 6. Clienti

### 6.1 Comportamento
1. Arrivano dalla strada. Se non c'è un posto libero adatto, aspettano sulla **panchina d'attesa** (se c'è) o se ne vanno (recensione persa).
2. Scelgono un posto: i clienti singoli preferiscono il **bancone**, coppie e gruppi hanno bisogno di **tavoli**.
3. Si siedono, guardano il menu (2–4 s), mostrano l'ordine.
4. **Barra della pazienza** sopra la testa (verde → gialla → rossa). Se finisce, se ne vanno arrabbiati senza pagare (recensione 1 ★).
5. Mangiano, pagano, lasciano una **recensione** (stelle + commento breve, es. "Il brodo era perfetto!").
6. A volte ordinano un secondo piatto o una bevanda dopo il primo.

### 6.2 Tipi di cliente

| Tipo | Da livello | Gruppo | Pazienza | Mancia | Preferenze |
|---|---|---|---|---|---|
| Studente | 1 | 1 | media | bassa | piatti economici, ramen |
| Salaryman | 1 | 1 | bassa a pranzo | media | ramen, veloce |
| Turista | 3 | 1–2 | alta | alta | sushi, fa foto (flash) |
| Coppia | 3 | 2 | media | media | sushi + dolci, solo tavoli |
| Famiglia | 6 | 3–4 | media | media | piatti vari, tavoli da 4 |
| Anziano | 5 | 1 | molto alta | media | tè, miso, nigiri classici |
| Influencer | 10 | 1 | bassa | alta | se lasci 5 ★: +25% clienti il giorno dopo |
| Critico gastronomico | 12 | 1 | media | alta | recensione con peso ×5 sulla valutazione |
| Ospite VIP | 18 | 2–4 | alta | molto alta | solo nella sala tatami, ordina menu completi |
| Celebrità | 30 | 1 | media | enorme | evento raro, porta una folla di fan per 2 minuti |

I clienti sono personaggi R15 dettagliati, con corporatura leggermente diversa l'uno dall'altro:
- **Viso** con occhi lucidi, sopracciglia, guance rosate e bocca. L'**espressione segue l'umore**: sereno all'arrivo, preoccupato quando la pazienza scende sotto metà, arrabbiato (sopracciglia aggrottate, bocca all'ingiù) sotto il 30%, sorriso aperto quando viene servito e mentre mangia.
- **Capelli** voluminosi a più ciocche (corti, caschetto, lunghi, coda, chignon, a punta, stempiati) con frangia.
- **Abiti per tipo**: studente con maglietta stampata o felpa col cappuccio, jeans o gonna, sneakers, cappellino o zaino; impiegato in giacca e cravatta con camicia bianca, cintura, scarpe lucide, valigetta e orologio; turista con camicia hawaiana a fiori, pantaloncini, cappello, macchina fotografica a tracolla; anziano con cardigan abbottonato, coppola, occhiali dorati e bastone; influencer con giacca aperta, occhiali da sole, telefono in mano, orecchini e borsa a tracolla; VIP e celebrità con cappotto lungo, sciarpa e orologio d'oro, occhiali da sole e fedora.
- **Famiglie** con bambini più piccoli: maglietta, pantaloncini o gonna, a volte la cartella *randoseru* e il cappellino giallo della scuola.

### 6.3 Valutazione del ristorante
- Ogni recensione da 1 a 5 ★ dipende da: attesa, qualità del piatto, ambiente (decorazioni), comfort della seduta, pulizia (stoviglie sporche vicine).
- La **valutazione del ristorante** è la media delle ultime 50 recensioni (il critico conta 5 volte).
- Più è alta, più clienti arrivano e più alte sono le mance. Alcune licenze richiedono una valutazione minima.

---

## 7. Menu e prezzi

- La **lavagna del menu** (oshinagaki) all'ingresso mostra i piatti attivi.
- Dal pannello Menu puoi **attivare/disattivare** i piatti e regolare il **prezzo** tra −30% e +30% del prezzo consigliato:
  - Prezzo più alto = più guadagno a piatto, ma meno ordini e meno pazienza.
  - Prezzo più basso = più clienti e più recensioni positive.
- Ogni ricetta ha una **Maestria** (piatti serviti: 25 / 100 / 500 / 2.000 / 10.000): ogni livello aumenta il prezzo base del 5% e rende più veloci i passaggi di quel piatto. Al massimo livello il piatto si serve con un **impiattamento dorato**.

L'elenco completo dei piatti con ingredienti, prezzi e sblocchi è in [`03-BILANCIAMENTO.md`](03-BILANCIAMENTO.md#3-ricette).

---

## 8. Progressione

### 8.1 Valute
- **Yen (¥)**: valuta principale; guadagnata servendo i clienti.
- **Gettoni Sakura (🌸)**: valuta rara da obiettivi, giornaliere, eventi, recensioni perfette dei critici. Serve per decorazioni speciali ed eventi. (Acquistabile anche con Robux, ma tutto si ottiene giocando.)

### 8.2 Livello del ristorante (XP)
- Ogni piatto servito dà XP. I livelli (1–50) sbloccano piatti acquistabili, decorazioni, espansioni, personale.
- Ad ogni livello: piccola ricompensa (yen o gettoni) e un'animazione di festa (coriandoli, suono di gong).

### 8.3 Licenze
Le licenze sbloccano nuovi piatti e le postazioni necessarie. Si comprano dal pannello **Licenze** (un albero diviso in rami Sushi, Ramen, Contorni, Dolci & bevande). Ogni licenza richiede: livello minimo + yen (+ a volte valutazione minima).

```
Sushi:  Base ─► Sushi I ─► Sushi II ─► Sushi III ─► Sushi IV ─► Maestro del Sushi
Ramen:  Base ─► Ramen I ─► Ramen II ─► Ramen III ─► Ramen IV ─► Maestro del Ramen
Altro:  Contorni & tè ─► Piastra ─► Friggitrice ─► Street food ─► Dolci & Matcha
Finale: Gran Maestro (richiede entrambi i Maestri)
```

### 8.4 Miglioramenti (upgrade)
Vassoio (capienza), scarpe da cucina (velocità), coltelli, stuoie e scolapasta (passaggi più veloci), pentoloni e rice cooker (lotti più grandi), mensole più capienti, consegna più rapida, fornitore premium, insegna luminosa (più clienti), frigorifero professionale (qualità), jukebox (ambiente), cassaforte (guadagni offline), barra ordini più lunga. Dettagli in [`03-BILANCIAMENTO.md`](03-BILANCIAMENTO.md#6-miglioramenti).

### 8.5 Espansioni
Il locale cresce per **zone**. Ogni espansione aggiunge una zona: muri, pavimento e tetto vengono ricostruiti in automatico attorno alla nuova forma, con un'animazione di cantiere (impalcature e polvere per 3 secondi).

| # | Espansione | Effetto |
|---|---|---|
| 1 | Sala Est | spazio per i primi tavoli |
| 2 | Magazzino ampliato | più scaffali |
| 3 | Sala Ovest | più posti |
| 4 | Terrazza esterna | posti all'aperto con lanterne |
| 5 | Giardino zen sul retro | decorazioni da giardino, bonus ambiente |
| 6 | Sala tatami privata | clienti VIP |
| 7 | Cucina professionale | più postazioni e più personale |
| 8 | Secondo piano | una sala intera in più, con scala |
| 9 | Terrazza sul tetto | vista sulla città, fuochi d'artificio negli eventi |
| 10 | Insegna gigante sul tetto | +clienti |
| 11 | Facciata deluxe | aspetto esterno di lusso |

#### Ristrutturazioni
Nella stessa schermata, scheda **Ristrutturazioni**: lavori estetici che trasformano il locale base in quello tradizionale e dettagliato. Non cambiano la pianta; danno **atmosfera** (e alcuni un po' di popolarità), quindi più clienti e mance. Si comprano una volta sola e cambiano subito l'aspetto di tutto il locale, oggetti già piazzati compresi.

| Gruppo | Ristrutturazione | Cosa aggiunge |
|---|---|---|
| Esterno | Facciata machiya | fasce in legno e grata koshi sulla facciata |
| Esterno | Ingresso tradizionale | porte scorrevoli a grata, coni di sale, pini in vaso, gradino in pietra |
| Esterno | Tettoia di tegole | tegole kawara, colmo, travetti, onigawara (al posto della lamiera) |
| Esterno | Finestre a grata | grata kumiko, davanzali e fioriere |
| Esterno | Recinzione inu-yarai | recinzione curva in bambù lungo la facciata |
| Interno | Magazzino in ordine | zoccolo in cemento, linee gialle, portone di carico segnalato |
| Interno | Boiserie koshi-ita | pannelli di legno scuro e corrimano in sala |
| Interno | Piastrelle in cucina | piastrelle bianche e profilo in acciaio |
| Interno | Travi e pilastri | travi a vista, nageshi e pilastri hashira |
| Arredi | Bancone in hinoki | piano in hinoki, listelli, ganci in ottone, luce calda, nicchia dei piatti |
| Arredi | Attrezzatura da chef | barre portautensili, targhe in kanji, attrezzi e accessori sulle postazioni |
| Arredi | Servizio da tavola | condimenti, set da tè e da sakè, menù su bancone e tavoli |
| Arredi | Rifiniture degli arredi | cuscini, finiture in ottone, grate kumiko sui box, telo rosso sulla panca |

Anche *Insegna gigante* e *Facciata deluxe* compaiono in questa scheda. Prezzi e livelli in `03-BILANCIAMENTO.md` §8.

### 8.6 Personale (automazione)
Il personale sono NPC che lavorano da soli. Si assumono, si pagano a giornata e si addestrano (livelli 1–5: più veloci e più precisi). Ogni ruolo ha la sua divisa: i cuochi la giacca bianca *kappogi* con grembiule lungo e asciugamano (il sushi chef con hachimaki e geta, il cuoco del ramen con il cappello da chef); il cameriere la giacca *happi* indaco col colletto bianco, grembiule corto, bandana e blocchetto degli ordini; il lavapiatti il grembiule di gomma con pettorina, guanti gialli e stivali; il magazziniere la giacca da lavoro con banda riflettente, cappellino e guanti; il direttore il completo scuro con cravatta dorata, spilla col nome e cartellina.

| Ruolo | Cosa fa |
|---|---|
| Cameriere | prende gli ordini, serve i piatti pronti, raccoglie le stoviglie |
| Lavapiatti | lava le stoviglie al lavello |
| Magazziniere | porta le scatole dal magazzino alle mensole; con l'upgrade riordina da solo ciò che sta finendo |
| Cuoco sushi | prepara gli ordini di sushi su una propria postazione |
| Cuoco ramen | prepara gli ordini di ramen e tiene pieni i pentoloni |
| Cuoco di linea | contorni, fritti, piastra |
| Manager | giornata automatica, riordino automatico, bonus a tutto il personale |

Il personale diventa più veloce con l'addestramento.

### 8.7 Guadagni offline
Con la **Cassaforte** il ristorante produce una parte del guadagno anche quando non giochi (dal 10% al 30% della media oraria, fino a 2–24 ore in base al livello). Al rientro una schermata mostra quanto hai guadagnato.

### 8.8 Obiettivi, missioni e collezioni
- **Missioni giornaliere** (3 al giorno): "Servi 20 ramen", "Servi 10 piatti a clienti ancora sereni", "Guadagna ¥5.000 di mance".
- **Obiettivi permanenti** (traguardi): con ricompense in gettoni e titoli.
- **Ricettario**: collezione di tutti i piatti con il livello di maestria.
- **Set di decorazioni**: piazzare tutti i pezzi di un set (es. "Matsuri", "Giardino zen", "Samurai", "Ramen-ya") dà un bonus permanente.
- **Pacchetto Ramen-ya** (dalle foto di riferimento di un vero bancone da ramen): sgabelli rossi su palo nero, lampade a sospensione industriali, tettoia in legno sopra il bancone con striscione rosso e lampade, poster del menù colorati, mensola menù da bancone, brocche d'acqua e portacondimenti, poster retrò, insegna verticale, tavola del brodo, tavolo con panche. La categoria **Sul tavolo** raccoglie gli oggetti da appoggiare su banconi e tavoli.
- **Premio di accesso giornaliero** con serie (7 giorni, poi ricomincia con premi migliori).

### 8.9 Franchise (rinascita / prestigio)
Disponibile al livello 40 con valutazione ≥ 4,5 e tutte le espansioni principali.
- Apri un nuovo locale in un'altra città: **Kyoto → Osaka → Sapporo → Fukuoka → Okinawa**. Ogni città ha una strada diversa (templi a Kyoto, insegne giganti a Osaka, neve a Sapporo…) e **2–3 piatti regionali** esclusivi.
- Si azzerano: livello, yen, licenze, espansioni, personale.
- Si conservano: **tutte le decorazioni** (vanno nell'inventario), gettoni, ricettario, obiettivi.
- Guadagni una **Stella Franchise**: +25% yen e +10% XP permanenti, e decorazioni esclusive della città.

### 8.10 Eventi stagionali
Struttura pronta per eventi a tempo, con decorazioni limitate e clienti speciali:
- **Hanami** (primavera): ciliegi ovunque, dango.
- **Tanabata / Matsuri** (estate): bancarelle, yukata, fuochi d'artificio.
- **Tsukimi** (autunno): luna piena, mochi.
- **Shōgatsu** (Capodanno): kadomatsu, campana.

---

## 9. Costruzione e decorazione

### 9.1 Modalità costruzione
- Pulsante **martello** → si apre il catalogo in basso (categorie: Sedute & tavoli, Bancone, Cucina, Magazzino, Illuminazione, Piante, Arte & pareti, Statue, Giardino & acqua, Festival, Pavimenti, Pareti).
- Scegli un oggetto → appare un'**anteprima trasparente** che segue il mouse: verde = posizionabile, rosso = non posizionabile.
- **Griglia**: 1, 5 o 10 stud, si cambia con un clic sull'interfaccia (o tasto G). La griglia viene disegnata a terra attorno al cursore.
- **Rotazione**: pulsante/tasto R; passo di rotazione 90°, 45° o 15° nelle impostazioni.
- Clic per piazzare. Tenere premuto Shift (o il pulsante "Ripeti" su mobile) per piazzarne un altro uguale.
- Clic su un oggetto già piazzato → **Sposta / Ruota / Metti in inventario / Vendi** (rimborso 75%; 100% se piazzato da meno di 30 secondi).
- La telecamera può passare alla **vista dall'alto** in modalità costruzione.

### 9.2 Tipi di piazzamento
| Tipo | Esempi | Regola |
|---|---|---|
| Pavimento | sgabelli, tavoli, piante, statue | sulla griglia a terra |
| Parete | quadri, noren, neon, rotoli | si aggancia al muro più vicino, con griglia lungo il muro |
| Soffitto | lanterne appese, kokedama | si aggancia al soffitto |
| Piano d'appoggio | maneki-neko, bonsai, ikebana | sopra bancone o tavoli |
| Esterno | torii, koinobori, laghetto | solo nelle zone all'aperto (terrazza, giardino) |

### 9.3 Regole di validità
- Dentro le zone del ristorante (o nelle zone esterne per gli oggetti da esterno).
- Nessuna sovrapposizione con altri oggetti.
- Gli oggetti di cucina vanno solo nella zona di lavoro; sedute e tavoli solo nella sala.
- Deve restare sempre un passaggio tra l'ingresso e ogni posto a sedere, e tra il magazzino e la cucina (controllato al piazzamento).
- **Sgabelli**: funzionano come posti se sono davanti al bancone. **Sedie e cuscini zabuton**: funzionano se sono vicino a un tavolo. Un'icona sull'anteprima mostra se il posto sarà "attivo".

### 9.4 Pavimenti e pareti
Ogni zona può avere un pavimento e uno stile di parete diversi (legno chiaro, legno scuro, tatami, ardesia, ciottoli, marmo nero, hinoki; intonaco, pannelli di legno, shoji, mattoni scuri, bambù, yakisugi, oro e lacca).

### 9.5 Ambiente
- Ogni decorazione ha **punti ambiente**. Più copie dello stesso oggetto valgono sempre meno (incoraggia la varietà).
- Livelli di ambiente (Spoglio → Accogliente → Elegante → Raffinato → Leggendario): aumentano pazienza, mance e arrivo dei clienti.
- Il comfort delle sedute aumenta pazienza e mance di chi ci si siede.

---

## 10. Interfaccia

Stile: carta washi color crema, bordi in legno scuro, accenti rosso lacca e oro, angoli arrotondati, icone semplici e grandi (adatte al telefono).

| Elemento | Contenuto |
|---|---|
| In alto a sinistra | Pillola compatta: yen, gettoni Sakura, livello con barra XP sottile |
| In alto al centro | Barra sottile come in Pet Store Tycoon: orologio, giorno e un interruttore **CHIUSO / APERTO** (rosso/verde) da toccare |
| In alto a destra | Una riga: ★ valutazione · ✨ atmosfera · 🍽️ piatti puliti / 🧽 da lavare |
| A sinistra | Biglietti degli ordini; toccandone uno si apre la **guida dell'ordine** accanto |
| In basso a sinistra | Solo 3 pulsanti: 🔨 Costruisci, 📦 Fornitore, 📱 **Telefono** |
| Telefono | Tutte le altre funzioni come app, in ordine di utilità: Menu, Personale, Miglioramenti, Espansioni e ristrutturazioni, Licenze, Obiettivi, Come si gioca, Negozio, Invita, Impostazioni |
| In basso al centro | Cosa tieni in mano, con **⬇ Posa** (tasto G) |
| Sopra gli oggetti | Barre di cottura, porzioni rimaste, pazienza, nuvolette d'ordine |
| Fine giornata | Resoconto con grafico degli incassi della giornata |

Altre schermate: inventario decorazioni, ricettario, obiettivi, premio giornaliero, guadagni offline, impostazioni (lingua, griglia, rotazione, volume musica/effetti, qualità grafica ridotta per dispositivi deboli).

### Tutorial
La prima giornata è guidata da una scheda grande a destra e da una freccia luminosa gialla con un indicatore ⬇ sull'oggetto da cliccare: prendi la scatola → riempi lo scaffale → cuoci il riso → prepara il brodo → apri → prendi l'ordine → (si apre la guida dell'ordine) → prepara e servi → raccogli e lava le stoviglie → arreda. Si può saltare e rivedere dal telefono (❓ Come si gioca).

### Guida dell'ordine
Toccando un ordine a sinistra si apre una scheda con pochi passaggi brevi, ognuno con la spunta ✅ quando è fatto e il dito 👉 su quello da fare ora: riso o brodo pronti → ingredienti da prendere (con la spunta su quelli che hai in mano) → clicca la postazione per posarli → cliccala ancora per ogni passaggio (es. Unisci → Arrotola → Taglia, con il contatore) → prendi il piatto → servilo al cliente. Gli spazi degli scaffali con gli ingredienti giusti e la postazione da usare si illuminano, e una freccia verde va da te alla prossima cosa da cliccare (anche al cliente giusto quando hai il piatto in mano).

### Oggetti in mano
Un clic con una scatola su uno scaffale riempie **tutti** gli spazi liberi adatti, e un messaggio dice quante porzioni restano nella scatola. **Posa** (tasto G o ⬇) appoggia la scatola a terra davanti a te, visibile e da riprendere, oppure sulla scaffalatura se sei in magazzino. Gli ingredienti in mano tornano sullo scaffale più vicino, i piatti vanno al lavello. Un messaggio dice sempre dove è finito l'oggetto.

### Telecamera
Telecamera del gioco morbida e più lenta di quella standard: tasto destro tenuto premuto (o un dito sullo schermo) per girare, frecce ← → per ruotare, rotellina o due dita per lo zoom. Non finisce mai dietro i muri e, quando sale sopra il soffitto, il tetto sparisce e la cucina si vede dall'alto. Velocità (lenta, media, veloce) e telecamera classica di Roblox nelle impostazioni.

---

## 11. Grafica e atmosfera

- **Illuminazione**: tecnologia *Future* di Roblox, atmosfera leggera, bloom, correzione colore calda. Luce del giorno morbida, tramonto arancione, cielo blu di sera ma interni caldi e accoglienti (lanterne, lampade a sospensione e neon che illuminano davvero l'ambiente).
- **Palette** (dalla moodboard): arancione, legno scuro, crema, rosso lacca e blu indaco; il noren d'ingresso blu ha la ciotola di ramen bianca.
- **Materiali**: legno a doghe, legno chiaro, tessuto (noren, cuscini), ardesia, metallo spazzolato (pentole), vetro (vetrina), neon (insegne).
- **Cibo realistico** (proporzioni e colori veri, niente colori "da gioco"): ciotole curve con fascia decorata *raimon* e smalto interno; brodo lucido con gocce di grasso e colore giusto per tipo (shoyu ambrato, shio dorato, miso nocciola, tonkotsu lattiginoso); noodles mossi; chashu con bordo rosolato, anello di grasso e carne rosata; uovo marinato tagliato col tuorlo cremoso; naruto a spirale col bordo ondulato; menma, cipollotto a rondelle, nori, cucchiaio renge e bacchette sul poggiabacchette. Sushi su geta di legno: riso modellato con chicchi sparsi, fette di pesce morbide con le venature di grasso (salmone, otoro), la striscia scura della ricciola, gamberi a strisce con la coda, uova di salmone traslucide; uramaki con tobiko e sesamo, dragon roll con avocado a ventaglio e salsa d'anguilla a zigzag; wasabi, zenzero rosa e foglia *baran*. Fritti con pastella grumosa, takoyaki con salsa, maionese, alga e katsuobushi, okonomiyaki con la griglia di maionese, gyoza con la crosticina dorata, bento kaiseki a scomparti, zaru soba su stuoia di bambù, bottiglia di ramune con la biglia. Anche gli ingredienti crudi sono realistici (blocchi di pesce su carta, cetrioli, avocado tagliato, mazzo di cipollotti, confezioni di carne con pellicola, barattoli e bottiglie con etichetta).
- **Effetti**: vapore dalle ciotole e dai pentoloni, bolle nel brodo, scintille dorate quando un piatto è pronto, petali di ciliegio, monete che volano alla cassa, coriandoli al livello.
- **Animazioni**: zampa del maneki-neko, pesci nel laghetto koi e nell'acquario, shishi-odoshi che si inclina, noren che ondeggia, treno serale.
- **Scritte giapponesi** sulle insegne: ラーメン (ramen), 寿司 (sushi), 営業中 (aperto), 準備中 (in preparazione).
- **Audio** (da scegliere nella libreria audio di Roblox): musica di sottofondo con shamisen e koto in versione lo-fi, ambiente della strada, sfrigolio, taglio, campanello d'ingresso, gong del livello.

I modelli sono costruiti dal codice con parti Roblox, curati nelle proporzioni e nei colori. Il livello di dettaglio cresce con le ristrutturazioni (§8.5): lo stesso oggetto ha una versione base e una versione rifinita. Ogni modello è **sostituibile**: se più avanti metti un modello 3D più dettagliato (da Blender o dal Creator Store) con lo stesso nome nella cartella apposita, il gioco usa quello al posto della versione generata.

---

## 12. Monetizzazione (predisposta)

Tutto è opzionale e nessun contenuto essenziale si ottiene solo con i Robux.

| Gamepass | Effetto |
|---|---|
| VIP | +25% yen, etichetta VIP in chat, maneki-neko d'oro esclusivo |
| 2× Yen | raddoppia gli yen guadagnati |
| Vassoio extra | +2 capienza del vassoio |
| Consegna express | consegne istantanee |
| Pacchetto iniziale | ¥10.000 + 3 decorazioni esclusive + sgabelli imbottiti |

| Prodotto (consumabile) | Effetto |
|---|---|
| Pacchetti di yen (S/M/L/XL) | quantità che cresce con il tuo livello |
| Pacchetti di gettoni Sakura | gettoni |
| Ora di punta | 2× clienti per 30 minuti |
| Insegna d'oro | +50% mance per 30 minuti |

Gli ID dei prodotti si inseriscono in un solo file di configurazione; finché sono vuoti i pulsanti non vengono mostrati.

---

## 13. Priorità di realizzazione

Tutto verrà implementato in un unico intervento, in quest'ordine (così ogni passo si appoggia su quello prima):

| Priorità | Contenuto |
|---|---|
| **Indispensabile** | mondo e strada, ristorante iniziale, consegne, magazzino, mensole, rice cooker e pentoloni, 3 piatti iniziali con i passaggi a clic, clienti con pazienza e pagamento, stoviglie, giornata e resoconto, salvataggio, interfaccia base, inglese/italiano |
| **Indispensabile** | modalità costruzione con griglia 1/5/10, rotazione, vendita, inventario, catalogo decorazioni, pavimenti e pareti |
| **Indispensabile** | livelli, licenze, tutte le ricette, upgrade, espansioni, valutazione e recensioni, prezzi del menu |
| **Importante** | personale e automazione, tavoli e gruppi, sala tatami e VIP, missioni giornaliere, obiettivi, premio giornaliero, guadagni offline, tutorial |
| **Importante** | mondo personale con inviti agli amici, monetizzazione predisposta, impostazioni |
| **Completamento** | secondo piano e tetto, maestrie, set di decorazioni, franchise con città, eventi stagionali, classifiche |

---

## 14. Da decidere più avanti (non blocca lo sviluppo)

- Nome definitivo, icona e immagini del gioco.
- Brani musicali ed effetti sonori dalla libreria audio di Roblox (il codice ha già gli spazi per gli ID).
- Prezzi in Robux di gamepass e prodotti.
- Eventuali modelli 3D personalizzati per sostituire quelli generati dal codice.
