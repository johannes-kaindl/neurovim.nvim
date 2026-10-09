# AGENTS.md — neurovim.nvim

> **Role:** context for AI agents working in this repo. Humans start in [`README.md`](README.md). The coordination rules of the Neovim plugins — above all "Bibliothek ab Eins" and its justification gate — live one level up, in `../AGENTS.md` (the `nvim-plugins` Dach).
>
> **Language:** code, comments, identifiers and docs are **English**; commit messages **German**, Conventional Commits. Tags SemVer without `v`.

## TL;DR

**neurovim.nvim** is NeuroVim — the Vim-learning spy thriller — as a Neovim plugin. The game logic (scoring, progression, par tiers) is written in Lua and proven against conformance vectors generated from neurovim's TypeScript core; missions and tables come from neurovim's JSON export. No Node, no helper process.

## Architecture

| Path | What |
|---|---|
| `lua/neurovim/rules/` | domain rules ported from the TS core (pure Lua, `-- domain: neurovim`) |
| `lua/neurovim/data.lua` | loads the vendored export `data/neurovim-data.json` through the kit's schema-checked loader; `default_plugin_data()` exact (null and {} kept) |
| `lua/neurovim/state.lua` | the save file (PluginData) under `stdpath('data')/neurovim/`, through `kit.store` |
| `lua/neurovim/missions.lua` | the 40 story missions (no KATA), chapters, status per player |
| `lua/neurovim/ui/` | NEXUS, briefing, mission buffer (panel, winbar, keytrack, check, reveal, restart), result float |
| `lua/neurovim/command.lua`, `plugin/neurovim.lua` | `:NeuroVim`, Tab completion, `<Plug>` mappings, version check |
| `lua/neurovim/kit/` | vendored from `nvim-kit` (`VENDOR.json`) — never edit |
| `data/`, `spec/conformance/` | vendored from `neurovim` (`data/VENDOR.json`): the content export and the conformance vectors — never edit |
| `tests/` | specs for the kit's headless runner; `tests/conformance_spec.lua` runs every vector against its Lua port |

## Commands

```bash
make check           # stylua --check · selene · tests in headless Neovim · vendor-check (../tools/kit/vendor.py)
make release-check   # Bibliothek gate over everything since the last tag (../tools/bibliothek/gate.py)
stylua lua tests     # format (skips lua/neurovim/kit/ via .styluaignore)
make test NVIM=/path/to/nvim   # the suite with another Neovim — the minimum version run:
# D=$(mktemp -d); curl -sfL https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-macos-arm64.tar.gz | tar -xz -C "$D"; xattr -cr "$D"
# make test NVIM="$D/nvim-macos-arm64/bin/nvim"
```

Tools: `brew install stylua selene`. Neovim ≥ 0.10. The Dach (`..`) must be present for `vendor-check` and `release-check`.

## Rules

- **Rules change in the TS core first**, then here: re-vendor neurovim's export and vectors, and the conformance spec shows which Lua ports lag behind. Never adjust a vector to fit the port.
- **Never edit vendored files** (`lua/neurovim/kit/`, `data/`, `spec/conformance/`). Fix upstream, re-vendor with `../tools/kit/vendor.py add`; `make check` fails on any drift.
- **Every module under `lua/neurovim/` except `kit/` carries `-- domain: neurovim` on line 1.** A module without it is gate-pflichtig under "Bibliothek ab Eins" (`../AGENTS.md`).
- Every test has a counter-check that shows it can fail.

## Conformance

The rules in `lua/neurovim/rules/` are ports of neurovim's TS core (`packages/core/src/utils/diff.ts`, `engine/ProgressionEngine.ts`, `engine/ParTier.ts`). `tests/conformance_spec.lua` runs every vector file in `spec/conformance/` against its Lua function (table `IMPLS`, TS name → Lua function); a vector without a port is a red case, and the vector count is pinned (`12`) so a new function shows up.

After a rule change upstream:

1. Re-vendor from the new neurovim commit (from the Dach): `python3 tools/kit/vendor.py add neurovim.nvim --source ../apps/neurovim --ref <commit> --manifest data/VENDOR.json --license AGPL-3.0-only packages/content/export/neurovim-data.json:data/neurovim-data.json packages/core/conformance/:spec/conformance`.
2. `make test` names the red functions and cases; port the change until they pass. Never edit a vector.
3. A new vector function: add its port to `IMPLS` and raise the pinned count.
4. Tell the neurovim session about the new pin — neurovim's `consumers.json`/`CONSUMERS.md` track it.

## Gotchas

- **`vim.NIL` is truthy.** The game data goes through the kit's loader with `luanil`, so `null` inside objects is an absent field there. The save file and `data.default_plugin_data()` are read **without** `luanil` on purpose: `null` stays `vim.NIL` and `{}` stays an object, so the file keeps the shape NeuroVim's other builds read.
- **`nvim_feedkeys` needs the flag `t`** (`'ntx'`) for keys to count as typed (macros, keystroke counting); **without `n`** (`'tx'`) for keys that must hit a mapping (the briefing's and NEXUS's `<CR>`).
- **`tests/run.lua` points `XDG_DATA_HOME` at a temp dir** — never remove it, or tests write the player's real save.
- **Headless `nvim -l` never fires `CursorMoved`**; tests that depend on it raise it with `nvim_exec_autocmds`.
- **`T.eq(x, vim.NIL)` passes for `nil`** (`deep_equal`); check a JSON null with `rawequal(x, vim.NIL)` or compare with `T.json_eq`.
- **StyLua must skip `kit/`** (`.styluaignore`); otherwise it reformats the vendored copies and `vendor-check` turns red.

## Memory

- Cockpit (SSOT for status and tasks): `$VAULT/25_Coding/neurovim.nvim/neurovim.nvim.md`.
- Design: `$VAULT/25_Coding/neurovim/_SDD/2026-10-08-neurovim-nvim-design.md`.

## Abweichungen von der Leitkonvention

- Keine bekannt. README-Tier `nvim-plugin` (`_docs/readme/readme-spec.json`); README und `doc/neurovim.txt` beschreiben ehrlich den Entwicklungsstand, bis Phase 4/5 Befehle und Installation liefern.
