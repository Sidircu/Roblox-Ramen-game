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
| Mondo | **Una strada con 4 ristoranti per server**: ogni giocatore ha il suo locale, uno accanto all'altro, e vede gli altri lavorare |
| Co-op | **Ibrido**: gli amici (o tutti, se lo decidi tu) possono **aiutare nel tuo locale** (cucinano, servono, riforniscono) e guadagnano una quota |
| Lingua | **Inglese + Italiano**, scelta automatica in base alla lingua del giocatore, modificabile nelle impostazioni |
| Interazione | **Movimento libero** con joystick/WASD come in ogni gioco Roblox. Quando sei vicino a un oggetto, **lo clicchi (o lo tocchi)** e l'azione avviene |
| Cucina | **Fisica + clic, senza tempismo**: gli ingredienti si prendono davvero dalle mensole e si portano in mano; alla postazione ogni clic esegue un passaggio (il coltello taglia, gli ingredienti si uniscono, il maki si arrotola). Nessun minigioco a tempo, nessun gesto da fare |
| Costruzione | Decorazioni e mobili acquistabili e piazzabili su una **griglia a terra regolabile: 1, 5 o 10 stud** |
| Robux | **Predisposta**: gamepass e prodotti già nel codice, attivi solo dopo aver inserito gli ID. Il gioco resta completabile gratis |
| Grafica | Stile 3D curato e pulito, luci calde, lanterne, neon notturni; modelli generati dal codice e sostituibili con modelli migliori |

> Nota sulle unità: in Roblox l'unità di misura è lo **stud** (≈ 28 cm), non il pixel. Un personaggio è alto circa 5 stud, uno sgabello è largo circa 2 stud.

---

## 1. Visione

Apri un piccolo ramen-ya in un vicolo giapponese illuminato da lanterne. All'inizio hai un lungo bancone con 12 sgabelli, due mensole e una pentola. Cucini tu ogni piatto, porti tu le scatole dal magazzino, lavi tu le ciotole. Ora dopo ora guadagni yen, sblocchi licenze per nuovi piatti, assumi personale che automatizza il lavoro, ingrandisci il locale stanza dopo stanza fino al secondo piano e alla terrazza sul tetto, e lo arredi come vuoi tu. Alla fine apri nuovi locali in altre città del Giappone (Franchise) e ricominci più forte.

### Pilastri

1. **Il lavoro manuale è soddisfacente**: prendere, portare, cucinare, servire. Ogni azione ha un'animazione e un suono che la rendono piacevole.
2. **Ogni acquisto si vede**: tutto ciò che compri appare fisicamente nel ristorante.
3. **Il tuo locale è unico**: griglia, rotazione, pavimenti, pareti e oltre 50 decorazioni.
4. **Progressione lunga e costante**: c'è sempre un obiettivo vicino (prossimo piatto, prossima decorazione) e uno lontano (secondo piano, franchise).
5. **Atmosfera giapponese autentica**: noren all'ingresso, vetrina del pesce sul bancone, vapore dalle ciotole, il treno che passa la sera.

### Durata prevista

| Fase | Livelli | Tempo indicativo | Cosa succede |
|---|---|---|---|
| Inizio | 1–5 | 0–20 min | Tutorial, primo piatto, primi miglioramenti; il **primo aiutante** (lavapiatti) arriva verso i 10 minuti |
| Crescita | 5–11 | 20 min – 3 h | Cameriere, magazziniere, sushi, Sala Est e Sala Ovest, primi cuochi; al livello 11 si può aprire il **primo franchise** |
| Maturità | 11–30 | 3–25 h (stima) | Terrazza, giardino, sala tatami, cucina professionale, secondo piano, menu completo, maestrie |
| Fine gioco | 30–50 | 25–55 h (stima) | Piatti da maestro, tetto, collezioni complete |
| Franchise | ×5 città | + molte ore | Ricominci in una nuova città con bonus permanenti e piatti regionali; ogni città chiede un po' di più (livello 11 → 16 → 20 → 25 → 30) |

**Ritmo** (misurato con un giocatore automatico che gioca con il server vero, `python3 tools/sim.py progression --hours=4`): nella prima ora il negozio non resta mai più di due minuti senza niente di comprabile; il primo aiutante a 9 minuti, il livello 5 verso i 18 minuti, la Sala Ovest verso l'ora e mezza, il livello 10 verso le 2 ore, il livello 11 con le tre stanze del primo franchise in 2 ore e mezza – 2 ore e 50 minuti. Un giocatore che arreda, assume cuochi, compra mensole per i prodotti nuovi e gioca con gli amici (bonus squadra) va più veloce. Dopo il livello 11 ogni acquisto costa da 1 a 3 livelli di guadagni, e fino al livello 45 ogni livello sblocca qualcosa.

---

## 2. Il mondo

### 2.1 Struttura delle sessioni (una strada, quattro ristoranti)

- Ogni server è **una strada con 4 lotti** affiancati (`Config/Plots`: 4 lotti a 240 stud l'uno dall'altro). Il server accetta al massimo 4 giocatori (in Studio: Game Settings → Max Players = 4).
- Quando entri vedi per pochi secondi una schermata di caricamento ("Preparing your restaurant…" / "Stiamo preparando il tuo ristorante…"), ricevi il **primo lotto libero** e il tuo ristorante viene costruito lì dal tuo salvataggio. Il personaggio compare davanti alla tua porta.
- I lotti liberi mostrano un recinto e il cartello "空き地 · 近日オープン" (terreno libero, apertura a breve). Quando un giocatore esce, il suo lotto torna libero: clienti, personale e oggetti spariscono e i suoi aiutanti tornano a lavorare nel proprio locale.
- Puoi passeggiare nella strada ed entrare negli altri ristoranti. **Lavori nel locale in cui ti trovi** se il proprietario te lo permette, altrimenti nel tuo.
- **Ruoli nel ristorante di un altro** (decide il proprietario dall'app Amici):
  - **Aiutante**: cucina, serve, pulisce, rifornisce. Lo sono automaticamente gli **amici Roblox** del proprietario, oppure **tutti** se il proprietario apre la cucina a tutti; il proprietario può anche nominare aiutante un singolo giocatore.
  - **Co-gestore**: come l'aiutante, in più può comprare, vendere e spostare oggetti.
  - **Visitatore**: chiunque altro. Può guardare, ma le postazioni rispondono "Questo non è il tuo ristorante".
  - Gli aiutanti guadagnano XP e una **quota** in yen per il **proprio** salvataggio (pagata dal gioco, non tolta al proprietario).
- **Lavoro di squadra**: ogni giocatore che lavora nel ristorante di un altro (aiutante o co-gestore che cucina, serve, pulisce) aumenta del **10%** gli incassi di quel ristorante (vendite e mance), fino a **+30%** con tre aiutanti. In alto compare 🤝 +10% e tutti quelli che lavorano lì ricevono un messaggio quando il bonus sale. Gli aiutanti ricevono comunque la loro quota.
- **Invita amici**: pulsante nell'app Amici → invito Roblox. L'amico che accetta entra nello stesso server, riceve un lotto suo e può aiutarti. Il pulsante **Torna al tuo ristorante** riporta alla tua porta.

### 2.2 La strada (yokochō)

I quattro ristoranti stanno lungo la stessa via giapponese, sempre visibile e decorativa. **Tutto è in proporzione al locale** (come in Supermarket Together): il quartiere è grande e i negozi ci stanno dentro in modo credibile. Tra un lotto e l'altro ci sono edifici vicini più bassi, un distributore automatico e alberi.
- Davanti all'ingresso un marciapiede largo 20 stud, poi un **viale a 4 corsie** largo 36 stud (strisce gialle centrali, attraversamento pedonale, tombini, fermata dell'autobus) e un secondo marciapiede.
- Di fronte, una fila di **palazzi di 3–6 piani** (alti 32–70 stud, il doppio o più del locale) con negozi al piano terra, insegne verticali, balconi, condizionatori, cartelloni e cisterne sui tetti. Ogni lotto ha la sua recinzione di bambù sul retro.
- Edifici vicini non accessibili (negozietti, una lavanderia, una casa con le luci accese), pali della luce con i fili, lampioni su entrambi i marciapiedi, distributori automatici luminosi, biciclette parcheggiate, vasi di piante.
- Ciliegi lungo la strada, petali che cadono.
- Un treno che passa su un cavalcavia sullo sfondo, soprattutto la sera.
- Da entrambe le estremità del vicolo arrivano e se ne vanno i clienti.
- Sul lato di ogni ristorante c'è la **porta di carico del magazzino**, dove arriva il furgoncino delle consegne (kei truck).
- Il quartiere (palette e cielo) è quello di Tokyo per tutta la strada; la città del Franchise cambia solo il tuo locale.

### 2.3 Il ristorante iniziale

Pianta indicativa (vista dall'alto):

```
               STRADA (clienti)
  ┌──────────────[ ingresso con noren ]─────────────┬───────────┐
  │                                                  │           │
  │   SALA        [lavagna menu]   [lanterna]        │ MAGAZZINO │
  │                                                  │  scaffale │
  │  ()()()()()()()()()()()()   <- 12 sgabelli       │  scatole  │
  │  ═══════════ BANCONE ═══════════ [vetrina pesce] │           │
  │   postazione sushi   postazione ramen  lavello   │  [porta]  │──► furgone
  │   [mensola] [mensola]  [rice cooker] [pentola]   │   carico  │
  │   [tablet ordini]                                │           │
  └──────────────────────────────────────────────────┴───────────┘
```

- Il bancone separa la **sala clienti** dalla **zona di lavoro**. I clienti non entrano dietro il bancone.
- Dietro, oltre il corridoio, due mensole e una **cucina componibile**: moduli con la stessa altezza, ante in legno, piano in acciaio e piastrelle bianche fino alla stessa linea, messi uno accanto all'altro come un unico mobile: cuociriso, **fornello a gas** (forno, manopole, due fuochi, il pentolone del brodo e un pentolino di rame, cappa), piano di lavoro con ceppo dei coltelli e ciotole, **lavello** a due vasche incassate con scolapiatti, altro piano di lavoro. Il piano di lavoro si compra anche a parte per allungare la cucina e ci si possono appoggiare oggetti.
- Gli oggetti iniziali sono normali oggetti piazzabili: puoi spostarli tutti in modalità costruzione.
- **In scala con gli avatar**: il locale base misura 72 × 46 stud (sala 72 × 32, cucina 72 × 14, magazzino 24 × 32 che sporge sul retro). La cucina è poco profonda apposta: postazioni dietro il bancone, un corridoio di 9 stud e **tutto il resto attaccato al muro di fondo** (gli scaffali proprio dietro le postazioni, poi la cucina componibile verso la porta del magazzino); niente spazi vuoti inutili, e lungo il muro resta posto per le postazioni e gli scaffali che compri. Il bancone è basso (3 stud) e profondo (3,8), lungo 40 stud: 12 moduli da 3 stud, uno per cliente, così i clienti seduti non si sovrappongono mai; ogni posto ha bacchette sul poggia-bacchette, tovagliolo e volantino del menu, e sul gradino del cuoco porta-menu (お品書き), bicchiere di bacchette, soia e peperoncino. Il piatto viene servito sul piano, non sul bordo; in cucina le postazioni subito dietro e, oltre un corridoio largo 6 stud, scaffali, cuociriso, pentolone e lavello.
- **Si parte da un locale semplice ma caldo**: pavimento di legno, pareti color crema, un soffitto di listelli di legno chiaro con **lanterne di carta** che pendono basse e fanno una luce calda (in cucina e in magazzino luci da lavoro), una striscia di luce calda sotto il bancone, tre lanterne sopra il bancone e bambù in vaso nei quattro angoli della sala. Il resto (decorazioni e dettagli tradizionali) si compra col tempo: decorazioni piazzabili (§9) e **ristrutturazioni** (§8.5), che rendono il locale ancora più curato.

---

## 3. Ciclo di gioco

### 3.1 Il ciclo principale (loop)

Chiaro nei primi 30 secondi: entri, il locale è già aperto e rifornito, e dopo pochi secondi entra il primo cliente.

```
Il cliente entra e ordina da solo (nuvoletta con l'icona del piatto)
        │
        ▼
Alla postazione: 3 pressioni (🍜 noodles → 🥣 brodo → 🌱 condimenti); gli ingredienti volano dagli scaffali
        │
        ▼
Prendi la ciotola e servi ─► paga SUBITO prezzo + mancia (monete che volano al portafoglio)
        │
        ▼
Spendi gli yen (miglioramenti, licenze, personale, ampliamenti) ─► più clienti e piatti migliori
```

Il rifornimento (fornitore, furgone, scatole, scaffali a scacchiera) e il lavaggio delle stoviglie restano, ma entrano in gioco dopo: all'inizio gli scaffali sono pieni, il pentolone e il cuociriso pronti e i piatti puliti abbondanti.

### 3.2 La giornata

Il ristorante è **aperto appena arrivi** e nessuna schermata ferma il gioco. Fuori, subito a destra della porta, c'è un **cartello LED su un palo** con scritto **OPEN** (verde) o **CLOSED** (rosso): si usa come una postazione (E, clic o tocco) e apre o chiude il ristorante. Da chiuso non entrano nuovi clienti (chi è già dentro viene servito); accanto all'orologio compare «🔴 Chiuso». Possono usarlo il proprietario e i co-gestori; ogni volta che rientri il ristorante è di nuovo aperto.
- L'orologio gira da solo: un'ora di gioco dura 45 secondi (15 di notte, dalle 23 alle 6, così la notte passa in fretta); un giorno intero dura circa 14 minuti.
- Picco del pranzo (12:00–14:00) e della cena (19:00–21:00) con più clienti; di notte ne arrivano meno.
- La luce cambia: giorno → tramonto arancione → sera con lanterne e neon accesi → notte breve.
- Alle 6:00 si chiude la giornata: stipendi, statistiche, missioni del giorno, mance del barattolo nel portafoglio e un messaggio «Il giorno 3 è finito: ¥1.240 guadagnati». Il **resoconto** completo (incassi, mance, costi, recensioni) si apre toccando l'orologio in alto.

### 3.3 Interazione: un'azione = un pulsante

- Il personaggio si muove **liberamente** con WASD (PC) o joystick (telefono/tablet).
- L'oggetto che puoi usare (quello al centro dello schermo in prima persona; in terza persona quello sotto il mouse o, senza mouse, il più vicino davanti a te) si illumina e sopra compare un **pulsante** in legno scuro con cosa succede: «🍜 Cuoci i noodles · Shoyu Ramen (1/3)», «Servi», «Lava i piatti». Su computer porta il tasto da premere (**E**, o **X** con il gamepad); su telefono è grande e si tocca.
- **E** (tastiera), **X** (gamepad) o un **tocco sul pulsante** (telefono) eseguono l'azione; vanno bene anche il clic o il tocco sull'oggetto. Se sei troppo lontano compare "Avvicinati".
- Il personaggio porta gli oggetti **visibilmente in mano** (scatole, piatti, stoviglie sporche); i piatti e le stoviglie dipendono dal **Vassoio** (1 all'inizio, fino a 6). Gli ingredienti non si portano più a mano: le postazioni li prendono da sole dagli scaffali.

---

## 4. Rifornimento: tablet, consegne, magazzino, mensole

### 4.1 Tablet ordini (Fornitore)
- Un tablet appeso al muro della cucina (o il pulsante "Fornitore" nell'interfaccia).
- Catalogo ingredienti divisi per categoria (Pesce, Riso & alghe, Verdure, Brodi, Noodles, Carni, Bevande, Dolci). Ogni ingrediente si compra **a scatole** (es. "Salmone — scatola da 12 porzioni — ¥120").
- Ingredienti visibili solo se hai la licenza del piatto che li usa.
- Carrello → "Ordina". Con l'upgrade **Fornitore premium** compaiono le scatole grandi scontate.

### 4.2 Consegna
- La consegna è **immediata**: il furgoncino arriva in circa 6 secondi, entra in retromarcia e **si ferma poco prima del piazzale**; il corriere **lascia le scatole a terra**, una alla volta, **appena fuori dalla porta del magazzino**, a sinistra della porta (fino a due scatole impilate per posto), così il passaggio resta libero. Le porti tu sugli scaffali.
- Due **pop-up con suono** avvisano chi lavora nel ristorante: «🚚 È arrivato il furgone! Sta scaricando 3 scatole…» (motore del furgone) e poi «📦 Consegna: 3 scatole · A terra fuori dalla porta del magazzino» (campanello).
- Il miglioramento **Carrello per scatole** permette di portare 2 e poi 3 scatole insieme (+1 con il pass Carrello grande); usi quella giusta per lo scaffale o il pentolone che clicchi.
- Ogni scatola ha un'etichetta con icona e nome dell'ingrediente e il numero di porzioni rimaste.
- **Kit di soccorso**: se resti senza soldi e senza ingredienti per qualsiasi piatto, il fornitore ti regala quelli del piatto più economico (al massimo ogni 10 minuti), così non resti mai bloccato.
- Nel fornitore il pulsante **«🍜 Tutto per il menu»** mette nel carrello una scatola di ogni ingrediente che serve ai piatti del menu e che sta finendo.

### 4.3 Dal magazzino alle mensole
- Clicchi una scatola → la prendi in mano: la scatola **si apre** (alette piegate in fuori) e dentro si vedono alcuni prodotti, come in Pet Store Tycoon e Supermarket Together; sulla faccia verso di te c'è l'icona e quanti pezzi restano (es. 7/20).
- Clicchi un **ripiano** di una mensola → i prodotti **volano fuori dalla scatola uno alla volta** (un piccolo arco e un "toc" quando si posano) **solo in quel ripiano**. Quelli che non ci stanno restano nella scatola: scegli tu il prossimo ripiano. Mirando un ripiano il suggerimento dice cosa succede ("Aggiungi noodles: 4 posti liberi", "Ripiano pieno", "Qui c'è cipollotto"). Prendendo un prodotto dalla mensola, quello vola nelle tue mani.
- Le mensole sono **grandi** (la piccola è alta 7,4 stud e larga 5,6).
- Sul bordo di ogni ripiano c'è un **cartellino** (come nei giochi di negozi) con icona e nome del prodotto, scritto nella lingua di ogni giocatore; i ripiani vuoti hanno il cartellino bianco.
- Ogni mensola ha dei **ripiani** (slot); ogni ripiano contiene un solo tipo di ingrediente, disposto **a scacchiera** (2×3, 2×4, 2×5, 3×5…): ogni casella è un prodotto e le **caselle libere sono segnate** da un quadratino chiaro, così si vede a colpo d'occhio quanti ne entrano e quanti mancano (niente numeri "10/10"). Un ripiano contiene **mezza scatola**: **una scatola riempie al massimo 2 ripiani**. Il miglioramento *Mensole rinforzate* aggiunge file di prodotti verso il fondo; la mensola grande ha più ripiani.
- Se avanzano porzioni la scatola resta in mano con quelle che mancano; una scatola vuota si butta automaticamente. Il personale magazziniere riempie un ripiano dopo l'altro finché la scatola è vuota.
- Si comprano scaffali più grandi e più belli (Costruisci → Cucina): **scaffale alto in legno** (8 ripiani, con un piccolo noren), **scaffale da mercato in bambù** (9 ripiani, lanterne rosse) e **dispensa laccata deluxe** (12 ripiani, nera e oro, luci sotto ogni ripiano).
- Le **postazioni** per cucinare si comprano in Costruisci → Cucina (altre postazioni sushi e ramen per cucinare di più, e con le licenze bevande, piastra, friggitrice, takoyaki e dolci). Quando una licenza porta piatti per una postazione che non hai, un messaggio ti dice quale comprare.
- La **vetrina refrigerata del pesce** (sul bancone, come nei veri sushi bar) funziona come una mensola per il pesce e dà un bonus di freschezza (qualità).

### 4.4 Preparazioni di base
- **Riso**: il riso crudo va nel **rice cooker** (clic) → cottura 30 s → diventa "riso per sushi" (lotto da 10 porzioni, 25 con il modello pro).
- **Brodo**: la base del brodo va nel **pentolone** (clic) → 60 s → lotto da 8 porzioni. Ogni tipo di brodo (shoyu, shio, miso, tonkotsu) occupa un pentolone; servono più pentoloni per più brodi contemporaneamente.
- Indicatori sopra gli apparecchi: barra di cottura, porzioni rimaste, icona "pronto".

---

## 5. Cucina

### 5.1 Ordini
- Il cliente si siede, guarda il menu un attimo e **ordina da solo**: la nuvoletta sopra la testa mostra l'icona del piatto e la barra della pazienza, e l'ordine diventa un **biglietto** a sinistra (fino a 12 biglietti; 16, 20 e 24 con il miglioramento Barra ordini, che serve quando in cucina lavorano i cuochi).
- Toccando un biglietto si apre la **guida dell'ordine** e si illumina la postazione da usare.

### 5.1 bis La postazione fa da sola
- Ogni postazione sa qual è il **prossimo ordine** per lei (il più vecchio che nessuno sta già preparando) e lo mostra nel suo prompt: «🍜 Cuoci i noodles · Shoyu Ramen (1/3)».
- La **prima pressione** porta gli ingredienti: volano dagli scaffali al tagliere, ognuno dal suo ripiano, e parte subito il primo passaggio. Ogni pressione successiva fa il passaggio dopo.
- Se manca qualcosa il prompt lo dice prima: «Shoyu Ramen: mancano 🍥 · rifornisci gli scaffali» (o il brodo, il riso, i piatti puliti).
- Sul tagliere vuoto le **sagome trasparenti** mostrano il piatto che verrà preparato.

### 5.1 ter Noodles perfetti (facoltativo)
- Mentre i noodles bollono compare una barra con una parte verde e un ago che scorre: clicca (o E, o ✋) quando l'ago è nel verde e la ciotola è **perfetta** (+20% di mancia). Se sbagli o non clicchi, la ciotola è buona lo stesso.

### 5.2 Preparare il sushi (postazione sushi / tagliere)
Esempio *Sake Nigiri*: due pressioni.
1. Il salmone vola dallo scaffale al tagliere e **il coltello taglia** il filetto (il riso viene preso da solo dal cuociriso).
2. **Gli ingredienti si uniscono**: la fetta si posa sul riso e diventa un nigiri, impiattato e pronto da servire.

I maki hanno i passaggi **Unisci → Arrotola → Taglia**: tre pressioni, tre animazioni (stuoia di bambù che arrotola, coltello che fa sei pezzi). Il sashimi di salmone è una pressione sola.

### 5.3 Preparare il ramen (postazione ramen)
Esempio *Shoyu Ramen*: tre pressioni.
1. 🍜 Noodles, cipollotto e naruto volano dagli scaffali e **i noodles cuociono** nel bollitore (vapore, e la barra del tempismo facoltativa).
2. 🥣 **Il brodo viene versato** dal pentolone nella ciotola.
3. 🌱 **I condimenti si dispongono** sopra: ciotola fumante pronta.

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
- Una pressione sul piatto pronto → lo prendi (anche più piatti, in base al Vassoio). Una pressione sul cliente → lo servi.
- Il cliente **paga subito**, appena il piatto arriva: «+¥62» sopra di lui, monete che volano fino al portafoglio in alto (che sobbalza mentre il numero sale), scintille, "cha-ching" e una faccina felice 😋. Il pagamento è **prezzo del menu + mancia**; poi mangia con calma e se ne va.
- Al posto restano **stoviglie sporche**: il posto non è utilizzabile finché non le raccogli. Clic → le prendi → clic sul **lavello** → i piatti si **accumulano di lato**, impilati nella vasca con l'acqua saponata.
- **Minigioco del lavaggio**: quando ci sono piatti sporchi compare "Tieni premuto: lava i piatti". Tieni premuto il clic (o E, o il pulsante ✋ su telefono): il rubinetto si apre, un piatto sporco va sotto l'acqua e una **spugna gira** sopra mentre lo sporco sparisce; una **barra sottile** sotto il centro dello schermo mostra il completamento. Quando il piatto è pulito **scorre verso sinistra**, verso lo scolapiatti, diventando trasparente fino a sparire, e si passa da solo al piatto successivo finché tieni premuto. Se lasci, il piatto in corso si ferma (con un tocco sul lavello, sul telefono, si avvia e si ferma). Il personale lava da solo con la stessa animazione.
- Le **stoviglie pulite** sono una risorsa: se finiscono non puoi impiattare. Puoi comprare altri set di ciotole e piatti; la **lavastoviglie** lava da sola.

---

## 6. Clienti

### 6.1 Comportamento
1. Arrivano dalla strada. Se non c'è un posto libero adatto, aspettano sulla **panchina d'attesa** (se c'è) o se ne vanno (recensione persa). Quando in cucina aspettano già molti ordini (3, più 3 per ogni cuoco del personale) entra meno gente (2,5 volte più di rado): il locale non si riempie di clienti che nessuno riesce a servire, e assumere cuochi porta davvero più clienti.
2. Scelgono un posto: i clienti singoli preferiscono il **bancone**, coppie e gruppi hanno bisogno di **tavoli**.
3. Si siedono, guardano il menu (2–4 s), mostrano l'ordine.
4. Nei **primi 2 giorni** i picchi di pranzo e cena sono leggeri.
4. **Barra della pazienza** sopra la testa (verde → gialla → rossa). Se finisce, se ne vanno arrabbiati senza pagare (recensione 1 ★). **Difficoltà bassa**: i clienti aspettano molto (1,8 volte la pazienza del loro tipo) e, quando prendi l'ordine, il tempo **riparte da pieno**, così hai tutto il tempo per cucinare.
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
Vassoio (capienza), scarpe da cucina (velocità), coltello, stuoia e scolapasta (passaggi più veloci), mensole rinforzate (più prodotti per scaffale), carrello per scatole, fornitore premium (scatole grandi scontate), insegna luminosa (più clienti), barra ordini (più biglietti, utile con i cuochi), jukebox (ambiente), cassaforte (guadagni offline), riordino automatico (con il magazziniere). Pentoloni, cuociriso e frigoriferi sono oggetti da piazzare. Ogni miglioramento costa da 1 a 2 livelli di guadagni, così arriva poco dopo lo sblocco; dal livello 31 al 44 ogni livello porta un passo nuovo, fino alla fine. Dettagli in [`03-BILANCIAMENTO.md`](03-BILANCIAMENTO.md#6-miglioramenti).

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
| 8 | Secondo piano | una sala intera in più, con una scala ad angolo larga 8 stud in stile *hako-kaidan* (13 gradini bassi per rampa, pianerottolo su una cassettiera, fianchi pieni con cassetti, ringhiere con pilastri su tutti i lati aperti) |
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
| Manager | riordino automatico, bonus a tutto il personale |

Il personale diventa più veloce con l'addestramento. Il primo aiutante arriva presto: il **lavapiatti al livello 4** (¥2.000), il **cameriere al 5**, il magazziniere al 7, i cuochi dal livello 9.

### 8.5 bis Cartelli "in vendita"
Come nei tycoon, dove si può costruire la prossima stanza al piano terra c'è un **cartello di legno** con lanterna: nome della stanza e prezzo (✅ se hai i soldi), oppure 🔒 e il livello che serve. Si usa come una postazione (E o tocco): un'azione e la stanza si costruisce (il server controlla livello, stanze precedenti e prezzo). Comprata la stanza, il cartello sparisce e compaiono quelli delle stanze che ora si possono costruire.

### 8.7 Guadagni offline
**Tutti** guadagnano qualcosa anche quando non giocano: la prima ora al **5%** della media oraria (calcolata sugli ultimi giorni di servizio). La **Cassaforte** allunga il tempo e alza la percentuale: 2 ore al 10%, 4 al 15%, 8 al 20%, 12 al 25%, 24 ore al 30%. Al rientro una schermata mostra quanto hai guadagnato, con un solo pulsante per ritirarlo.

### 8.8 Obiettivi, missioni e collezioni
- **Missioni giornaliere** (3 al giorno): "Servi 20 ramen", "Servi 10 piatti a clienti ancora sereni", "Guadagna ¥5.000 di mance".
- **Obiettivi permanenti** (traguardi): con ricompense in gettoni e titoli.
- **Ricettario**: collezione di tutti i piatti con il livello di maestria.
- **Set di decorazioni**: piazzare tutti i pezzi di un set (es. "Matsuri", "Giardino zen", "Samurai", "Ramen-ya") dà un bonus permanente.
- **Pacchetto Ramen-ya** (dalle foto di riferimento di un vero bancone da ramen): sgabelli rossi su palo nero, lampade a sospensione industriali, tettoia in legno sopra il bancone con striscione rosso e lampade, poster del menù colorati, mensola menù da bancone, brocche d'acqua e portacondimenti, poster retrò, insegna verticale, tavola del brodo, tavolo con panche. La categoria **Sul tavolo** raccoglie gli oggetti da appoggiare su banconi e tavoli.
- **Premio di accesso giornaliero**: un calendario di 7 giorni (yen, 🌸, al 7° giorno 🌸15 e una decorazione esclusiva) che **si apre da solo quando entri** se il premio di oggi non è ancora ritirato, dopo la schermata dei guadagni offline e mai durante il tutorial (a un giocatore nuovo compare 20 secondi dopo la fine del tutorial). I giorni passati hanno la spunta, quello di oggi è dorato con un grande pulsante **Riscuoti**. Se salti un giorno si riparte dal giorno 1; dopo il 7° si ricomincia, e gli yen crescono con il livello. Lo stesso calendario è in Obiettivi → Giornaliero.
- **Regali a tempo** (come nei giochi Roblox più famosi): mentre giochi si sblocca un regalo gratis ogni pochi minuti (yen, 🌸, scatole di ingredienti). Il pulsante 🎁 sotto i soldi mostra il conto alla rovescia e diventa dorato quando un regalo è pronto (tasto R). Ripartono a ogni nuova sessione.
- **Codici**: nell'app 🎟️ Codici del telefono si scrive un codice (annunciato sui social o nel gruppo) per ricevere un premio; ogni codice vale una volta per giocatore.
- **Combo di servizio**: servire piatti a meno di 30 secondi l'uno dall'altro fa salire la combo (scritta grande "🔥 COMBO x3!" e suono che sale): ogni passo dà +5% di mancia a quel cliente, fino a +50%.
- **Classifica nella lista giocatori** (leaderstats): ¥ e livello ⭐ di ognuno.
- **Bacheche delle classifiche** (番付) sul marciapiede di fronte a ogni ristorante, rivolte verso la porta: tre pannelli con i primi 10 di tutti i server per **piatti serviti**, **yen guadagnati** e **Mi piace**; la tua riga è dorata se ci sei e in fondo c'è sempre il tuo numero. I testi sono nella lingua di chi guarda; i numeri si aggiornano ogni 2 minuti. Le stesse classifiche sono in Obiettivi → Classifiche. Gli yen comprati con i Robux **non contano** nella classifica.
- **Obiettivo del giorno** sempre visibile sotto la barra del giorno (la prima missione non ancora ritirata, es. «🎯 Servi 8 ramen · 3/8»); quando è completo diventa dorato e un clic lo ritira.
- **Barattolo delle mance** sul bancone: le mance si accumulano dentro (le monete salgono); un clic le ritira con una pioggia di monete, a fine giornata si ritirano da sole.
- **❤️ Mi piace**: chi visita il ristorante di un amico può mettergli Mi piace (una volta al giorno); il numero si vede in alto a destra e c'è la classifica dei ristoranti più amati.

### 8.9 Franchise (rinascita / prestigio)
La prima volta è disponibile dopo poche ore di gioco: **livello 11, valutazione ≥ 4,0, Sala Est, Magazzino ampliato e Sala Ovest**. Ogni città successiva chiede di più (livello 16 con ★4,1 e anche terrazza e giardino; 20 con ★4,2 e sala tatami e cucina professionale; 25 e 30 con il secondo piano). Gli obiettivi (scheda Franchise) mostrano cosa manca, voce per voce.
- Apri un nuovo locale in un'altra città: **Kyoto → Osaka → Sapporo → Fukuoka → Okinawa**. Ogni città ha una strada diversa (templi a Kyoto, insegne giganti a Osaka, neve a Sapporo…) e **2–3 piatti regionali** esclusivi.
- Si azzerano: livello, yen, licenze, espansioni, miglioramenti, personale (e la media degli incassi usata per i guadagni offline, che riparte dalle giornate nella nuova città).
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
| Parete | quadri, noren, neon, rotoli | si aggancia al muro sotto il puntatore, appoggiato alla parete, con griglia lungo il muro; dalla vista dall'alto (si punta la cima del muro) va sul lato in cui ti trovi, all'altezza solita (6 stud dal pavimento); fuori dall'edificio non si appende |
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

Stile: carta washi color crema, bordi in legno scuro, accenti rosso lacca e oro, angoli arrotondati, icone semplici e grandi. **Regola: un'azione = un pulsante**, e sullo schermo resta solo quello che serve ogni minuto.

| Elemento | Contenuto |
|---|---|
| In alto a sinistra | **Portafoglio**: yen (grande), gettoni Sakura, livello in un cerchio dorato e barra XP; sotto, il timer del regalo |
| In alto al centro | **Orologio e giorno** (🌙 di notte); toccandolo si apre il resoconto dell'ultimo giorno. Sotto, l'**obiettivo di oggi** (toccandolo si riscuote o si aprono gli obiettivi); durante il tutorial al suo posto c'è la scheda del tutorial |
| In alto a destra | **Il ristorante in cui sei**: il tuo (★ valutazione · ❤️ Mi piace) o quello di un altro (🏮 nome del proprietario, ★, pulsanti **❤️ Mi piace** e **🏠 A casa**). Sotto, solo quando c'è da lavare, la pillola dei piatti (🍽️ puliti/totale · 🧽 da lavare), dorata quando ne restano pochi |
| A destra | **Gli ordini**, dal più vecchio (bordo dorato: è quello da cucinare ora): icona e nome del piatto, icone di cosa serve e barra della pazienza. Al massimo 3 sul telefono, 4 sul tablet, 5 sul computer (+N per gli altri). Toccandone uno si apre la **guida dell'ordine** a sinistra |
| In basso | **Quattro pulsanti grandi**: 🛒 **Negozio** (con il numero di cose che puoi comprare adesso), 🔨 Costruisci, 📦 Fornitore, 📱 **Altro**. Sopra, cosa tieni in mano con **⬇ Posa** |
| Altro (telefono) | Le funzioni che non servono ogni minuto, come app: Menu, Obiettivi, Regali, Invita, Premium, Codici, Come si gioca, Impostazioni |
| Sopra gli oggetti | **Solo scritte**, senza riquadro: bianche e crema con un contorno scuro spesso, così si leggono su qualsiasi sfondo (nome e livello degli aiutanti, «Raccogli le stoviglie», brodo e riso con le porzioni rimaste, passo della postazione, barattolo delle mance). Sopra i clienti, anche qui **senza riquadro** e larga quanto un posto (non si sovrappone a quella del vicino), sempre visibile: icona grande (❗, il piatto, 😋), nome del piatto in bianco con il contorno scuro e una barra della pazienza sottile con il bordo scuro (verde → gialla → rossa); la scritta lampeggia oro e bianco quando aspetta di ordinare |
| Fine giornata | Resoconto con grafico degli incassi della giornata |

**Colori dei pulsanti**, sempre gli stessi: verde per comprare e confermare, rosso per chiudere, annullare o togliere, oro per premi e offerte (Riscuoti, Robux), beige per il resto; la scheda o l'opzione scelta è in legno scuro. I numeri (yen, prezzi, orologio, livello) e i titoli delle schede usano un carattere tondo (Fredoka). Nel catalogo della costruzione e sulle schede delle ricette c'è l'**immagine 3D vera** dell'oggetto o del piatto (con la grafica leggera torna l'emoji).

**Negozio** (un'unica finestra, cinque schede con il numero di acquisti possibili): ⬆️ Miglioramenti (con la sezione 📣 Pubblicità), 🍜 Ricette, 👥 Personale (la tua squadra da addestrare e chi assumere), 🏗️ Spazi, 🪚 Ristrutturazioni. Ogni scheda è una carta con l'icona grande, il nome, il livello («Liv. 2/5»), cosa fa scritto come un cambiamento con l'unità (adesso → al prossimo livello: «+0% → +8%» di velocità o di clienti, «0% → -10%» di tempo, «1 → 2» piatti, «2 h al 10%» di guadagni offline) e un solo pulsante:
- **verde con il prezzo**: tocca e compri;
- **prezzo in rosso** e "Mancano ¥…": non hai ancora abbastanza yen;
- **beige con il lucchetto** e cosa serve prima (livello, ricetta, spazio, personale, stelle, posti liberi); toccandolo, un messaggio lo ripete;
- **✅ Acquistato / MAX**.
Prima le cose che puoi comprare (dalla più economica), poi quelle troppo care, poi quelle bloccate, in fondo quelle già tue. Il saldo è nella barra del titolo. Quando l'acquisto arriva la carta fa un piccolo salto. Gli aiutanti vedono il negozio ma comprano solo proprietario e co-gestori.

**Telefono e tablet**: l'interfaccia si ingrandisce (le scritte non scendono sotto una misura leggibile) e tiene libero l'angolo in basso a sinistra (joystick) e quello in basso a destra (salto, con 🏃 Corri accanto): i quattro pulsanti stanno in basso poco a destra del centro. Le finestre occupano quasi tutto lo schermo e, finché sono aperte (o è aperto il catalogo di costruzione), joystick e salto si nascondono, così un tocco arriva sempre al pulsante giusto. I **pop-up sono più piccoli sul telefono**, perché il gioco resti in vista: messaggi larghi 340 (testo 15), pop-up delle consegne alti 54 (titolo 16, riga 14), consigli larghi 330 (testo 15), scheda del tutorial 360×68 con icona e pulsanti più piccoli (lo spazio per le parole resta lo stesso), scritta della combo 300×50.

**Risposta dei pulsanti**: ogni pulsante si schiaccia quando lo premi e si ingrandisce un poco sotto il mouse; le finestre e i messaggi si aprono con un piccolo rimbalzo; il pulsante del negozio salta quando c'è qualcosa di nuovo da comprare.

Altre schermate: inventario decorazioni, ricettario, obiettivi, premio giornaliero, guadagni offline, impostazioni (lingua, griglia, rotazione, volume musica/effetti, qualità grafica ridotta per dispositivi deboli).

### Tutorial
Si parte con **solo il ramen shoyu**, gli **scaffali già pieni** (noodles, cipollotto, naruto), il pentolone pieno di brodo, il cuociriso pieno e una scatola di riserva in magazzino. Al livello 2 la licenza **Sashimi** (¥300) aggiunge un secondo piatto facilissimo (due fette di salmone, un taglio); il sushi con il riso arriva al livello 3. Postazione sushi e cuociriso mostrano un 🔒 con la licenza e il livello che servono. Il **tutorial dura circa due minuti** (in prova automatica meno di uno) e insegna tutto il ciclo, un passo alla volta. In alto al centro c'è una scheda con un'icona grande, una frase corta, i pallini dei passi e **Salta**. Una freccia luminosa gialla va da te all'oggetto da usare, con un ⬇ che rimbalza sopra di esso; sui pulsanti dell'interfaccia compaiono una mano 👇 e un anello che pulsa. Le frasi cambiano con il dispositivo che usi (e cambiano subito se passi da uno all'altro): con tastiera e mouse dicono **WASD**, **E** o clic e **Q per liberare il mouse sui pulsanti**; su telefono e tablet la levetta e i pulsanti da toccare; con il controller le levette e **X**. La prima scheda aspetta che la schermata di caricamento sia sparita e il ristorante costruito, e **ogni scheda resta almeno 3 secondi**, anche quando la cosa è già successa (il primo cliente può aver già ordinato). I passi:
1. benvenuto, con i comandi del tuo dispositivo (7 s, o ▶);
2. arriva un cliente e ordina da solo;
3. premi la postazione del ramen: 🍜 → 🥣 → 🌱 (con il contatore 1/3, 2/3, 3/3);
4. prendi la ciotola;
5. portala al cliente (incassi subito);
6. **regalo di ¥1.000** e la mano sul pulsante 🛒: apri il negozio;
7. compra un miglioramento (la mano va sul primo prezzo verde);
8. raccogli la ciotola sporca;
9. lavala al lavello;
10. **regalo di 🌸10** e coriandoli.

I passi che chiedono un'azione vanno avanti da soli quando la fai. I regali li dà il server, una volta sola e solo dopo aver servito (e poi lavato) davvero un piatto. Il tutorial non torna più: si può rivedere da Altro → ❓ Come si gioca, ma senza regali. Chi lo finisce è contato nelle statistiche (`tutorial_done`).

**Consigli della prima volta** (`Controllers/Hints`): dopo il tutorial, la prima volta che succede una cosa compare una scheda con 💡 sopra i pulsanti in basso, con la freccia azzurra sul pulsante o sull'oggetto giusto. Resta qualche secondo o finché non lo fai, e non torna più:
- gli scaffali di un ingrediente del menu si svuotano → 📦 Fornitore;
- i piatti sporchi si accumulano → lavello;
- nel negozio c'è qualcosa da comprare → 🛒;
- si può assumere il primo aiutante → 🛒 → 👥;
- dopo i primi 3 piatti serviti → il cartello OPEN accanto alla porta (apre e chiude il ristorante).

Un consiglio alla volta, mai durante il tutorial o con una finestra aperta.

### Guida dell'ordine
Toccando un ordine (a destra) si apre a sinistra una scheda con pochi passaggi brevi, ognuno con la spunta ✅ quando è fatto e il dito 👉 su quello da fare ora: riso o brodo pronti → ingredienti sugli scaffali (✓ o ✗ per ognuno; se manca qualcosa, la freccia va alla sua scatola) → premi la postazione una volta per passaggio (es. Unisci → Arrotola → Taglia, con il contatore) → prendi il piatto → servilo al cliente. Gli spazi degli scaffali con gli ingredienti giusti e la postazione da usare si illuminano, e una freccia verde va da te alla prossima cosa da cliccare (anche al cliente giusto quando hai il piatto in mano).

### Oggetti in mano
Un clic con una scatola su uno scaffale riempie **tutti** gli spazi liberi adatti, e un messaggio dice quante porzioni restano nella scatola. **Posa** (tasto G o ⬇) appoggia la scatola a terra davanti a te, visibile e da riprendere, oppure sulla scaffalatura se sei in magazzino. Gli ingredienti in mano tornano sullo scaffale più vicino, i piatti vanno al lavello. Un messaggio dice sempre dove è finito l'oggetto.

### Telecamera e comandi
**Telecamera automatica** (predefinita): **terza persona** su telefono e tablet, **prima persona** con la tastiera; si cambia in Impostazioni → Telecamera. **Prima persona** (come in Supermarket Together): ci si guarda intorno con il mouse o trascinando un dito; un **pallino al centro** dello schermo indica cosa si sta puntando e sotto compare cosa succede cliccando (dorato quando sei abbastanza vicino). Clic o **E** per usare, **tasto destro** per posare la scatola (solo le scatole, così un piatto non si perde per sbaglio), **G** per posare qualsiasi cosa, **Shift** per correre, **Q** per liberare il mouse e usare i pulsanti (di nuovo Q per tornare a guardarti intorno; funziona anche Alt tenuto premuto (il mouse si libera da solo quando si apre un menu o in costruzione, dove la vista passa dall'alto). Scorciatoie: **U** negozio, **B** costruisci, **O** fornitore (funziona anche se Roblox usa O per lo zoom), **P** altro (telefono), **R** regali, **Invio** per il consiglio successivo del tutorial. Quello che hai in mano si vede davanti alla telecamera. Su telefono e tablet si tocca il pulsante che compare sopra l'oggetto, e accanto al salto c'è **🏃 Corri**.

Nelle impostazioni si può scegliere anche la **terza persona** (telecamera morbida e lenta: tasto destro o un dito per girare, ← →, rotellina o due dita per lo zoom; non finisce dietro i muri e, se sei dentro e sale sopra il soffitto, il tetto sparisce) o la telecamera classica di Roblox. **Impostazioni → 🖱️ Sensibilità: Alta · Media · Bassa** (seconda riga, subito sotto la lingua) vale in tutte le modalità: in prima persona moltiplica la sensibilità del menu di Roblox (Esc → Impostazioni) per 2,4 / 1,6 / 1; la terza persona su telefono resta calma con «Media». **Impostazioni → 🏘️ Altri locali: Mostra tutto · Solo fuori**: con «Solo fuori» degli altri ristoranti della strada vedi solo l'edificio (muri, tetto, facciata, lanterne del soffitto), mentre oggetti, lampade e persone dentro spariscono dal tuo schermo; il locale in cui entri, e quello accanto quando ti avvicini, sono sempre completi. Serve a far andare più fluido il gioco sui telefoni; per gli altri giocatori non cambia niente.

---

## 11. Grafica e atmosfera

- **Illuminazione**: tecnologia *Future* di Roblox, atmosfera leggera, bloom, correzione colore calda. Luce del giorno morbida e calda, un'**ora d'oro lunga** (dalle 15:30 alle 20:30, le lanterne si accendono quando comincia) e un'alba rosata, cielo blu di sera ma interni caldi e accoglienti (lanterne di carta, lampade a sospensione e neon che illuminano davvero l'ambiente).
- **Palette** (dalla moodboard): arancione, legno scuro, crema, rosso lacca e blu indaco; il noren d'ingresso blu ha la ciotola di ramen bianca.
- **Materiali**: legno a doghe, legno chiaro, tessuto (noren, cuscini), ardesia, metallo spazzolato (pentole), vetro (vetrina), neon (insegne).
- **Cibo realistico** (proporzioni e colori veri, niente colori "da gioco"): ciotole curve con fascia decorata *raimon* e smalto interno; brodo lucido con gocce di grasso e colore giusto per tipo (shoyu ambrato, shio dorato, miso nocciola, tonkotsu lattiginoso); noodles mossi; chashu con bordo rosolato, anello di grasso e carne rosata; uovo marinato tagliato col tuorlo cremoso; naruto a spirale col bordo ondulato; menma, cipollotto a rondelle, nori, cucchiaio renge e bacchette sul poggiabacchette. Sushi su geta di legno: riso modellato con chicchi sparsi, fette di pesce morbide con le venature di grasso (salmone, otoro), la striscia scura della ricciola, gamberi a strisce con la coda, uova di salmone traslucide; uramaki con tobiko e sesamo, dragon roll con avocado a ventaglio e salsa d'anguilla a zigzag; wasabi, zenzero rosa e foglia *baran*. Fritti con pastella grumosa, takoyaki con salsa, maionese, alga e katsuobushi, okonomiyaki con la griglia di maionese, gyoza con la crosticina dorata, bento kaiseki a scomparti, zaru soba su stuoia di bambù, bottiglia di ramune con la biglia. Anche gli ingredienti crudi sono realistici (blocchi di pesce su carta, cetrioli, avocado tagliato, mazzo di cipollotti, confezioni di carne con pellicola, barattoli e bottiglie con etichetta).
- **Effetti**: vapore dalle ciotole, dalle zuppe, dai fritti, dai takoyaki e dai pentoloni, bolle nel brodo, scintille dorate quando un piatto è pronto, petali che cadono dai ciliegi della strada, monete che volano alla cassa, coriandoli al livello.
- **Animazioni**: zampa del maneki-neko, pesci nel laghetto koi e nell'acquario, shishi-odoshi che si inclina, noren che ondeggia, treno serale.
- **Scritte giapponesi** sulle insegne: ラーメン (ramen), 寿司 (sushi), 営業中 (aperto), 準備中 (in preparazione).
- **Audio realistico** (tutto dalla libreria pubblica di Roblox: Pro Sound Effects, APM Music e suoni UI di Roblox, ID in `Config/Audio.luau`): il coltello che taglia sul tagliere a ritmo con l'animazione (16 colpi diversi), il brodo versato nella ciotola, i noodles che bollono e poi si scolano, lo sfrigolio della piastra e della friggitrice, la spatola, il riso versato nel cuociriso e il bip quando è pronto, i piatti di ceramica, le scatole di cartone, il lavello, la cassa e le monete della mancia, il campanello del piatto pronto, il fūrin (campanella a vento) quando entra un cliente, i clienti che risucchiano i noodles. Ambiente: traffico giapponese in strada (più piano dentro), brusio del ristorante che cresce con i clienti, pentole che bollono vicino a te, il treno sul cavalcavia. Musica: playlist calma di giorno (koto, lounge) e di sera.

I modelli sono costruiti dal codice con parti Roblox, curati nelle proporzioni e nei colori. Il livello di dettaglio cresce con le ristrutturazioni (§8.5): lo stesso oggetto ha una versione base e una versione rifinita. Ogni modello è **sostituibile**: se più avanti metti un modello 3D più dettagliato (da Blender o dal Creator Store) con lo stesso nome nella cartella apposita, il gioco usa quello al posto della versione generata.

---

## 12. Monetizzazione (predisposta)

Tutto è opzionale e nessun contenuto essenziale si ottiene solo con i Robux.

**Regole oneste**:
- Tutto ciò che serve per giocare si ottiene giocando: ricette, stanze, personale, franchise. I pass fanno andare **più veloce** o sono **estetici**, non aprono contenuti chiusi.
- Nessuna ricompensa a sorpresa a pagamento (niente casse o ruote con i Robux).
- Gli acquisti si trovano solo nell'app 💎 Premium del telefono: nessuna finestra che si apre da sola per vendere qualcosa, nessun conto alla rovescia finto.
- Ogni pass dice esattamente cosa dà prima dell'acquisto (finestra di Roblox con il prezzo).
- Gli yen comprati non contano nelle classifiche; i piatti serviti e i Mi piace non si possono comprare.
- I pass valgono per il **tuo** ristorante: non tolgono niente a chi lavora con te.

| Gamepass | Effetto |
|---|---|
| VIP | +25% yen, etichetta VIP in chat, **set d'oro** nell'inventario: maneki-neko d'oro, 2 lanterne d'oro e un noren d'oro (chi non ha il pass li può comprare con gli yen ai livelli alti) |
| 2× Yen | raddoppia gli yen guadagnati |
| Vassoio extra | +2 capienza del vassoio |
| Carrello grande | porti una scatola in più alla volta |
| Personale extra | +2 posti per il personale (anche oltre il massimo di 12) |
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
| **Importante** | strada con 4 ristoranti e aiutanti, inviti agli amici, monetizzazione predisposta, impostazioni |
| **Completamento** | secondo piano e tetto, maestrie, set di decorazioni, franchise con città, eventi stagionali, classifiche |

---

## 14. Da decidere più avanti (non blocca lo sviluppo)

- Nome definitivo, icona e immagini del gioco.
- Brani musicali ed effetti sonori dalla libreria audio di Roblox (il codice ha già gli spazi per gli ID).
- Prezzi in Robux di gamepass e prodotti.
- Eventuali modelli 3D personalizzati per sostituire quelli generati dal codice.
