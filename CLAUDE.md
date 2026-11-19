# Sakura Ramen & Sushi Tycoon — istruzioni per Claude

Gioco Roblox (Luau + Rojo). Prima di scrivere codice leggi i documenti in `docs/`:
`01-GAME-DESIGN.md` (cosa), `02-PIANO-TECNICO.md` (come, struttura e ordine dei blocchi B0–B8), `03-BILANCIAMENTO.md` (numeri).

Regole del progetto:
- Lingua della conversazione con l'utente: italiano. Codice, identificatori e commenti nel codice: inglese.
- Ogni file Luau inizia con `--!nonstrict` e **non usa annotazioni di tipo** (così i controlli statici di `tools/check_luau.py` restano affidabili).
- Moduli in `src/shared/Logic/` e `src/shared/Config/`: solo sintassi Lua standard (niente `+=`, `continue`, stringhe con backtick), così girano nei test con lupa.
- Niente librerie esterne: le utilità stanno in `src/shared/Util`.
- Tutti i numeri di gioco vanno in `src/shared/Config/` (mai prezzi o tempi scritti nel codice dei sistemi).
- Tutti i testi visibili passano da `Locale.t(key)`; ogni chiave esiste sia in `en.luau` sia in `it.luau`.
  I testi si modificano in `tools/locale/data*.py` (inglese e italiano affiancati) e si rigenerano con `python3 tools/locale/gen.py src/shared/Locale`: non modificare a mano `en.luau`/`it.luau`.
- Il server è autoritativo: il client manda solo intenzioni, il server valida tutto.
- I servizi si chiamano tra loro solo tramite `Core.S.<Servizio>` (server) e `Core.C.<Controller>` (client), mai con require circolari.
- Se cambiano i documenti di design, aggiorna anche `03-BILANCIAMENTO.md` e i moduli `Config` corrispondenti.

Prima di ogni commit esegui (tutti devono dare 0 problemi):
```
python3 tools/check_luau.py        # sintassi a blocchi, variabili non dichiarate, require, lingue
python3 tools/check_api.py         # chiamate Core.S.X.f / Core.C.X.f esistenti
python3 tools/run_logic_tests.py   # test della logica (pip install lupa)
python3 tools/check_roblox_api.py  # enum, classi, servizi, metodi e proprietà Roblox (serve build/API-Dump.json, vedi il file)
python3 tools/sim.py               # simula il server e gioca gli scenari di tools/sim/scenarios
python3 tools/build_place.py       # rigenera build/SakuraRamenTycoon.rbxlx
graphify update .                  # aggiorna il grafo
```

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
