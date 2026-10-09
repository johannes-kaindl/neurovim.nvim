# neurovim.nvim

**NeuroVim — a Vim-learning spy thriller — as a Neovim plugin: story missions you solve with real Vim motions, in your own editor.**

[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

<img src="https://raw.githubusercontent.com/johannes-kaindl/neurovim.nvim/main/docs/images/demo.gif" width="800" alt="Playing mission M-01 in Neovim: NEXUS lists the missions, the briefing opens, a recorded macro deletes every stray X and Z, and :NeuroVim check shows the result with XP and tier">

**Status:** ready for a first release, still private. All 54 missions — 40 story missions with briefings and 14 KATA drills — are playable in Neovim and tested end to end; the game logic passes all 103 conformance vectors from NeuroVim's TypeScript core.

## Requirements

- Neovim ≥ 0.10
- Nothing else: no Node, no helper process, no other plugin.

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim), once the repository is public (it is private until the first release):

```lua
{ "johannes-kaindl/neurovim.nvim" }
```

From a local checkout:

```lua
{ dir = "~/path/to/neurovim.nvim" }
```

There is no `setup()`: the plugin defines `:NeuroVim` and four `<Plug>` mappings when it loads.

## Usage

| Command | What it does |
|---|---|
| `:NeuroVim` | NEXUS: your level, XP, streak and the missions by chapter, then the KATAs (✓ solved with its tier, 🔒 locked with the level that unlocks it). `<CR>` opens the mission under the cursor, `q` closes. |
| `:NeuroVim mission <id>` | The briefing of a mission (Tab completes the ids). `<CR>` starts it, `q` closes. A KATA has no briefing and starts at once. |
| `:NeuroVim check` | Scores the mission buffer: either how many lines are still corrupted, or the result with XP, tier, bests and unlocks. |
| `:NeuroVim reveal` | Highlights the lines that still differ from the solution. |
| `:NeuroVim restart` | Reloads the corrupted text and resets time and keys. |

A mission is a scratch buffer `neurovim://<id>` with the objective above line 1 and a winbar like `M-01 · 01:23 · 37 keys · par 40`. Time and keys count from your first key in that buffer; `:NeuroVim …` itself, mouse clicks, the scroll wheel and a paste from the terminal do not count (`:help neurovim-keys`). The result opens in a floating window that closes when the cursor moves.

The plugin sets no global keys. Map the `<Plug>` mappings yourself — `<Plug>(neurovim-nexus)`, `<Plug>(neurovim-check)`, `<Plug>(neurovim-reveal)`, `<Plug>(neurovim-restart)`:

```lua
vim.keymap.set("n", "<leader>nc", "<Plug>(neurovim-check)")
```

Every solved mission earns XP, also when you replay it; levels unlock new missions. The missions alone do not reach the last levels: when every free mission is solved, NEXUS tells you to replay for XP and which level unlocks what (`:help neurovim-progress`).

Progress is saved in `stdpath('data')/neurovim/state.json`, in the same format as NeuroVim's other builds. A file that cannot be read is kept as `state.json.broken-<time>` and you start fresh, with a warning. Streak days roll over at 00:00 UTC.

## Configuration

No options yet.

## Troubleshooting

`:help neurovim-troubleshooting` covers the usual questions: an objective you cannot see, a result window that closed, more keys than you typed, a locked mission, a save that seems gone.

## Documentation

The manual lives in Neovim: `:help neurovim`. Contributor notes: [`AGENTS.md`](AGENTS.md); changes: [`CHANGELOG.md`](CHANGELOG.md).

## License

- **Code:** AGPL-3.0-only ([`LICENSE`](LICENSE)); dual licensing in [`LICENSING.md`](LICENSING.md), contributions under the [`CLA.md`](CLA.md).
- **Docs and texts:** CC BY-SA 4.0 ([`LICENSE-DOCS`](LICENSE-DOCS)).

Copyright © 2026 Johannes Kaindl.
