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
| `lua/neurovim/data.lua` | loads the vendored export `data/neurovim-data.json` through the kit's schema-checked loader |
| `lua/neurovim/kit/` | vendored from `nvim-kit` (`VENDOR.json`) — never edit |
| `data/`, `spec/conformance/` | vendored from `neurovim` (`data/VENDOR.json`): the content export and the conformance vectors — never edit |
| `tests/` | specs for the kit's headless runner; `tests/conformance_spec.lua` runs every vector against its Lua port |

## Commands

```bash
make check           # stylua --check · selene · tests in headless Neovim · vendor-check (../tools/kit/vendor.py)
make release-check   # Bibliothek gate over everything since the last tag (../tools/bibliothek/gate.py)
stylua lua tests     # format (skips lua/neurovim/kit/ via .styluaignore)
```

Tools: `brew install stylua selene`. Neovim ≥ 0.10. The Dach (`..`) must be present for `vendor-check` and `release-check`.

## Rules

- **Rules change in the TS core first**, then here: re-vendor neurovim's export and vectors, and the conformance spec shows which Lua ports lag behind. Never adjust a vector to fit the port.
- **Never edit vendored files** (`lua/neurovim/kit/`, `data/`, `spec/conformance/`). Fix upstream, re-vendor with `../tools/kit/vendor.py add`; `make check` fails on any drift.
- **Every module under `lua/neurovim/` except `kit/` carries `-- domain: neurovim` on line 1.** A module without it is gate-pflichtig under "Bibliothek ab Eins" (`../AGENTS.md`).
- Every test has a counter-check that shows it can fail.

## Gotchas

- **`vim.NIL` is truthy.** JSON goes through the kit's loader with `luanil`, so `null` inside objects is an absent field; `null` in arrays stays `vim.NIL`.
- **`nvim_feedkeys` needs the flag `t`** (`'ntx'`) for keys to count as typed (macros, keystroke counting).
- **StyLua must skip `kit/`** (`.styluaignore`); otherwise it reformats the vendored copies and `vendor-check` turns red.

## Memory

- Cockpit (SSOT for status and tasks): `$VAULT/25_Coding/neurovim.nvim/neurovim.nvim.md`.
- Design: `$VAULT/25_Coding/neurovim/_SDD/2026-10-08-neurovim-nvim-design.md`.

## Abweichungen von der Leitkonvention

- Keine bekannt.
