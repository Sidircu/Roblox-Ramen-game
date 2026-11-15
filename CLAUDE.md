# Sakura Ramen & Sushi Tycoon — istruzioni per Claude

Gioco Roblox (Luau + Rojo). Prima di scrivere codice leggi i documenti in `docs/`:
`01-GAME-DESIGN.md` (cosa), `02-PIANO-TECNICO.md` (come, struttura e ordine dei blocchi B0–B8), `03-BILANCIAMENTO.md` (numeri).

Regole del progetto:
- Lingua della conversazione con l'utente: italiano. Codice, identificatori e commenti nel codice: inglese.
- Ogni file Luau inizia con `--!strict`. Niente librerie esterne: le utilità stanno in `src/shared/Util`.
- Tutti i numeri di gioco vanno in `src/shared/Config/` (mai prezzi o tempi scritti nel codice dei sistemi).
- Tutti i testi visibili passano da `Locale.t(key)`; ogni chiave esiste sia in `en.luau` sia in `it.luau`.
- Il server è autoritativo: il client manda solo intenzioni, il server valida tutto.
- Logica pura (formule, griglia, impronte, percorsi) in `src/shared/Logic/`, senza API Roblox, coperta da test Lune in `tests/`.
- Se cambiano i documenti di design, aggiorna anche `03-BILANCIAMENTO.md` e i moduli `Config` corrispondenti.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
