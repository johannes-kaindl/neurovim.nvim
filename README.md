# neurovim.nvim

**NeuroVim — a Vim-learning spy thriller — as a Neovim plugin: story missions you solve with real Vim motions, in your own editor.**

[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

**Status:** in development (phase 4 of 5 done). The 40 story missions are playable in Neovim: NEXUS, briefings, missions with a timer and a keystroke count, results and a save file. The game logic passes all 103 conformance vectors from NeuroVim's TypeScript core. End-to-end tests over every mission, `:checkhealth` and the full manual follow in phase 5. The repository is private and not released yet.

## Requirements

- Neovim ≥ 0.10
- Nothing else: no Node, no helper process, no other plugin.

## Install

Not installable yet — the repository is private. Once it is published, it installs with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "johannes-kaindl/neurovim.nvim" }
```

## Usage

| Command | What it does |
|---|---|
| `:NeuroVim` | NEXUS: your level, XP, streak and the missions by chapter (✓ solved with its tier, 🔒 locked with the level that unlocks it). `<CR>` opens the mission under the cursor, `q` closes. |
| `:NeuroVim mission <id>` | The briefing of a mission (Tab completes the ids). `<CR>` starts it, `q` closes. |
| `:NeuroVim check` | Scores the mission buffer: either how many lines are still corrupted, or the result with XP, tier, bests and unlocks. |
| `:NeuroVim reveal` | Highlights the lines that still differ from the solution. |
| `:NeuroVim restart` | Reloads the corrupted text and resets time and keys. |

A mission is a scratch buffer `neurovim://<id>` with the objective above line 1 and a winbar like `M-01 · 01:23 · 37 keys · par 40`. Time and keys count from your first key in that buffer; `:NeuroVim …` itself does not count. The result opens in a floating window that closes when the cursor moves.

The plugin sets no global keys. Map the `<Plug>` mappings yourself — `<Plug>(neurovim-nexus)`, `<Plug>(neurovim-check)`, `<Plug>(neurovim-reveal)`, `<Plug>(neurovim-restart)`:

```lua
vim.keymap.set("n", "<leader>nc", "<Plug>(neurovim-check)")
```

Progress is saved in `stdpath('data')/neurovim/state.json`, in the same format as NeuroVim's other builds. A file that cannot be read is kept as `state.json.broken-<time>` and you start fresh, with a warning. Streak days roll over at 00:00 UTC.

## Configuration

No options yet.

## Documentation

The manual lives in Neovim: `:help neurovim`. Contributor notes: [`AGENTS.md`](AGENTS.md); changes: [`CHANGELOG.md`](CHANGELOG.md).

## License

- **Code:** AGPL-3.0-only ([`LICENSE`](LICENSE)); dual licensing in [`LICENSING.md`](LICENSING.md), contributions under the [`CLA.md`](CLA.md).
- **Docs and texts:** CC BY-SA 4.0 ([`LICENSE-DOCS`](LICENSE-DOCS)).

Copyright © 2026 Johannes Kaindl.
