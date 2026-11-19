#!/usr/bin/env python3
"""Writes docs/04-ASSET.md: the assets to get to replace the procedural placeholders.

Every placeable object of Config/Items is built with its procedural builder (tools/preview.py's
Roblox mock) and its parts are counted, so the list shows which models cost the most and are seen
the most (priority A: the starting restaurant and the kitchen; B: early decorations; C: the rest).
The page also lists the dishes, the interface icons and the rules for a model dropped into
ReplicatedStorage/AssetOverrides.

  python3 tools/asset_list.py            # rewrites docs/04-ASSET.md
Requires: pip install lupa
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import preview  # noqa: E402
from lupa import lua54  # noqa: E402

ROOT = preview.ROOT
OUT = os.path.join(ROOT, "docs", "04-ASSET.md")

COUNT = r"""
local Items = require(Shared.Config.Items)
local Recipes = require(Shared.Config.Recipes)
local StarterLayout = require(Shared.Config.StarterLayout)
local Registry = require(Shared.Models.Registry)
function count_items()
  local starter = {}
  for _, s in ipairs(StarterLayout.items) do
    starter[s.i] = (starter[s.i] or 0) + 1
  end
  local out = {}
  for _, it in ipairs(Items.list) do
    local ok, m = pcall(Registry.build, it.id, nil)
    local parts = 0
    if ok and m then
      for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then
          parts = parts + 1
        end
      end
    end
    table.insert(out, { id = it.id, cat = it.cat, lv = it.lv or 1, price = it.price or 0, sakura = it.sakura or 0,
      w = it.size[1], h = it.size[2], d = it.size[3], parts = parts, starter = starter[it.id] or 0,
      kind = it.fn and it.fn.type or "", event = it.event or "", franchise = it.franchise or "" })
  end
  local dishes = {}
  for _, r in ipairs(Recipes.list) do
    table.insert(dishes, { id = r.id, dish = r.dish, station = r.station, icon = r.icon })
  end
  return out, dishes
end
"""


def lua_list(t):
    return [dict(t[i + 1]) for i in range(len(t))]


def main():
    lua = lua54.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.__read = preview.read_module
    g.__list = lambda p: lua.table_from(preview.list_dir(p))
    lua.execute(open(os.path.join(ROOT, "tools", "preview", "mock.lua"), encoding="utf-8").read())
    lua.execute(preview.PRELUDE)
    lua.execute(preview.SCENES)
    lua.execute(COUNT)
    items, dishes = lua.eval("count_items")()
    items = lua_list(items)
    dishes = lua_list(dishes)
    names = load_names()

    def prio(it):
        if it["starter"] or it["kind"] in ("station", "shelf", "sink", "rice", "pot", "counter", "seat", "table"):
            return "A"
        if it["lv"] <= 8 and not it["event"] and not it["franchise"]:
            return "B"
        return "C"

    rows = sorted(items, key=lambda it: (prio(it), -it["parts"], it["id"]))
    total_parts = sum(it["parts"] * max(it["starter"], 0) for it in items)
    out = []
    out.append("# Asset da procurare — modelli, icone e suoni\n")
    out.append("> Generato da `python3 tools/asset_list.py` (rigeneralo quando cambiano gli oggetti). Tutto il gioco funziona già con modelli generati dal codice: questa lista dice cosa sostituire per primo e come.\n")
    out.append("## Come si sostituisce un modello\n")
    out.append("""1. Crea o importa il modello (Model) in Studio e chiamalo **esattamente come l'ID** della tabella (es. `ramen_station`).
2. Mettilo in `ReplicatedStorage/AssetOverrides`. Il gioco lo usa al posto di quello procedurale (`Models/Registry`): lo **scala per stare nella misura** della tabella (larghezza × altezza × profondità in stud) e lo **appoggia a terra al centro**.
3. Il **davanti** del modello guarda verso −Z (come la telecamera di Roblox all'inizio): sedie e sgabelli guardano il bancone, le postazioni guardano il cuoco.
4. Parti piccole: `CastShadow = false`, `CanCollide` solo dove si cammina contro, `Anchored = true`. Niente script dentro il modello.
5. Per le **postazioni**, gli **scaffali**, il **lavello** e i **pentoloni** le parti di gioco (tagliere, caselle dello scaffale, vasca) sono aggiunte dal codice sopra il modello: tieni la superficie di lavoro piatta all'altezza indicata dal modello procedurale (`python3 tools/preview.py item <id> out.png` per vederlo).
6. Nessun testo scritto nelle texture (il gioco è in due lingue): le scritte giapponesi decorative vanno bene.
""")
    out.append("## Stile\n")
    out.append("""- **Palette calda giapponese** (`Models/Palette`): legno chiaro `#C89F6E`, legno scuro `#5B3A24`, lacca rossa `#B3262E`, carta washi `#F4EBDD`, inchiostro `#2B2320`, oro `#D4A23C`, matcha `#7A9A4A`, indaco `#2E3A5C`, pietra `#8C8C88`.
- **Materiali**: legno (`Wood`, `WoodPlanks`), carta (`Fabric` chiaro), lacca (`SmoothPlastic` lucido), pietra (`Slate`, `Cobblestone`), metallo spazzolato per la cucina (`Metal`, `DiamondPlate` solo nel magazzino).
- **Forme morbide e leggibili da lontano** (come nei tycoon più giocati): pochi dettagli piccoli, silhouette chiara, colori pieni; si deve capire cosa è un oggetto anche dal telefono.
- **Budget**: oggetti piccoli ≤ 1.500 triangoli, mobili ≤ 4.000, postazioni ≤ 6.000, alberi e laghetti ≤ 8.000; una texture 512×512 al massimo per oggetto (meglio colori dei materiali).
""")
    out.append("## Priorità\n")
    out.append("- **A** — si vede da subito: il locale iniziale e la cucina (postazioni, bancone, sedute, scaffali, lavello, pentoloni). Ogni ristorante della strada ne ha una copia: oggi questi oggetti valgono circa %d parti per locale." % total_parts)
    out.append("- **B** — decorazioni e mobili dei primi livelli (fino al livello 8).")
    out.append("- **C** — il resto del catalogo, gli oggetti degli eventi e delle città del franchise.\n")
    out.append("Più **parti** ha la versione procedurale, più si guadagna sostituendola con un modello (meno parti da disegnare e da trasmettere).\n")
    out.append("| Pr. | ID | Nome | Categoria | Misura (L×A×P stud) | Liv. | Prezzo | Parti oggi | Nel locale iniziale |")
    out.append("|---|---|---|---|---|---|---|---|---|")
    for it in rows:
        price = ("🌸%d" % it["sakura"]) if it["sakura"] else ("¥%s" % format(int(it["price"]), ",").replace(",", "."))
        size = "%g×%g×%g" % (it["w"], it["h"], it["d"])
        out.append("| %s | `%s` | %s | %s | %s | %d | %s | %d | %s |" % (
            prio(it), it["id"], names.get("item." + it["id"], it["id"]), it["cat"], size, it["lv"], price, it["parts"],
            ("×%d" % it["starter"]) if it["starter"] else ""))
    out.append("\n## Piatti\n")
    out.append("I piatti sono modelli piccoli costruiti da `Models/Builders/Food` per tipo (`dish`). Un modello per tipo copre tutte le ricette di quel tipo; i colori degli ingredienti li mette il codice. Priorità A: `bowl` (ramen) e `nigiri`/`maki` (sushi).\n")
    out.append("| Tipo di piatto | Ricette |")
    out.append("|---|---|")
    by_dish = {}
    for dsh in dishes:
        by_dish.setdefault(dsh["dish"], []).append("%s `%s`" % (dsh["icon"], dsh["id"]))
    for dish in sorted(by_dish):
        out.append("| `%s` | %s |" % (dish, ", ".join(by_dish[dish])))
    out.append("\n## Icone dell'interfaccia\n")
    out.append("""Oggi l'interfaccia usa emoji (si vedono uguali su ogni dispositivo Roblox). Icone disegnate a mano danno subito un aspetto più curato: PNG 256×256 con sfondo trasparente, contorno scuro morbido, stile della palette. In ordine di importanza:

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
""")
    out.append("## Suoni e musica\n")
    out.append("Sono già scelti dalla libreria pubblica di Roblox (`Config/Audio.luau`: musica giorno/notte, ambiente della strada e del locale, coltello, brodo, frittura, piatti, interfaccia). Da aggiungere se si trovano: un suono di **acquisto** più festoso (ora la cassa), una **fanfara breve** per il livello e per il franchise, la **campanella della porta** diversa per i clienti VIP.\n")
    open(OUT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("wrote", OUT, len(rows), "objects")
    return 0


def load_names():
    """Italian names from the locale data (tools/locale)."""
    sys.path.insert(0, os.path.join(ROOT, "tools", "locale"))
    from data1 import NAMES  # noqa: E402
    from data2 import ITEMS  # noqa: E402
    out = {}
    for k, _, it in NAMES:
        out[k] = it
    for i, _, it in ITEMS:
        out["item." + i] = it
    return out


if __name__ == "__main__":
    sys.exit(main())
