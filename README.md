# neurovim.nvim

**NeuroVim — a Vim-learning spy thriller — as a Neovim plugin: story missions you solve with real Vim motions, in your own editor.**

[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE) [![Release](https://img.shields.io/github/v/tag/johannes-kaindl/neurovim.nvim?label=release)](CHANGELOG.md)

<img src="https://raw.githubusercontent.com/johannes-kaindl/neurovim.nvim/main/docs/images/demo.gif" width="800" alt="Playing mission M-01 in Neovim: NEXUS lists the missions, the briefing opens, a recorded macro deletes every stray X and Z, and :NeuroVim check shows the result with XP and tier">

**Status:** first release, 0.1.0. All 54 missions — 40 story missions with briefings and 14 KATA drills — are playable in Neovim and tested end to end; the game logic passes all 103 conformance vectors from NeuroVim's TypeScript core.

## Requirements

- Neovim ≥ 0.10
- Nothing else: no Node, no helper process, no other plugin.

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "johannes-kaindl/neurovim.nvim" }
```

From a local checkout:

```lua
{ dir = "~/path/to/neurovim.nvim" }
```

The plugin defines `:NeuroVim` and four `<Plug>` mappings when it loads; calling `setup()` is not needed. Missions run in plain Neovim even inside a full setup (see [Configuration](#configuration)).

## Usage

| Command | What it does |
|---|---|
| `:NeuroVim` | NEXUS: your level, XP, streak and the missions by chapter, then the KATAs (✓ solved with its tier, 🔒 locked with the level that unlocks it). `<CR>` opens the mission under the cursor, `q` closes. |
| `:NeuroVim mission <id>` | The briefing of a mission (Tab completes the ids). `<CR>` starts it, `q` closes. A KATA has no briefing and starts at once. |
| `:NeuroVim check` | Scores the mission buffer: either how many lines are still corrupted, or the result with XP, tier, bests and unlocks. |
| `:NeuroVim result` | Shows the last result of this session again. |
| `:NeuroVim reveal` | Highlights the lines that still differ from the solution, with a mark at the line end; a mark goes once its line is right. |
| `:NeuroVim restart` | Reloads the corrupted text and resets time and keys. |

A mission is a scratch buffer `neurovim://<id>` with the objective above line 1 and a winbar like `M-01 · 01:23 · 37 keys · par 40`. Time and keys count from your first key in that buffer; `:NeuroVim …` itself, mouse clicks, the scroll wheel and a paste from the terminal do not count (`:help neurovim-keys`). The result opens in a floating window that closes when the cursor moves; `:NeuroVim result` shows it again.

The plugin sets no global keys. Map the `<Plug>` mappings yourself — `<Plug>(neurovim-nexus)`, `<Plug>(neurovim-check)`, `<Plug>(neurovim-reveal)`, `<Plug>(neurovim-restart)` — under `<Leader>` or a function key (in a mission buffer the other keys are plain Vim keys):

```lua
vim.keymap.set("n", "<leader>nc", "<Plug>(neurovim-check)")
```

Every solved mission earns XP, also when you replay it; levels unlock new missions. The missions alone do not reach the last levels: when every free mission is solved, NEXUS tells you to replay for XP and which level unlocks what (`:help neurovim-progress`).

Progress is saved in `stdpath('data')/neurovim/state.json`, in the same format as NeuroVim's other builds. A broken file is kept as `state.json.broken-<time>` and you start fresh, with a warning; a file NeuroVim has no permission to read is left untouched, and an error says so. Streak days roll over at 00:00 UTC.

## Configuration

One option, `isolate` (default `true`). A mission buffer then runs in plain Neovim, as `nvim --clean` would run it, so that the objective, par and the key count mean what they say: the Vim keys in Normal, Visual and Operator-pending mode do what Vim does, options that change the text take Neovim's defaults, and completion, auto-pairs, Markdown rendering and linting stay out. Your mappings under `<Leader>`, function keys and window keys keep working. The full list is in `:help neurovim-isolate`.

To play with your whole setup instead:

```lua
{ "johannes-kaindl/neurovim.nvim", opts = { isolate = false } }
```

## Troubleshooting

Run `:checkhealth neurovim` first: it checks the Neovim version, the game data, the save file and its directory, and changes nothing. `:help neurovim-troubleshooting` covers the usual questions: an objective you cannot see, a result window that closed, more keys than you typed, a locked mission, a save that seems gone.

## Documentation

The manual lives in Neovim: `:help neurovim`. Online, sorted by what you need: the [documentation index](https://github.com/johannes-kaindl/neurovim.nvim/blob/main/docs/README.md), with [Getting started](https://github.com/johannes-kaindl/neurovim.nvim/blob/main/docs/tutorials/getting-started.md) and [Troubleshooting](https://github.com/johannes-kaindl/neurovim.nvim/blob/main/docs/how-to/troubleshooting.md). Contributor notes: [`AGENTS.md`](AGENTS.md); changes: [`CHANGELOG.md`](CHANGELOG.md).

## License

- **Code:** AGPL-3.0-only ([`LICENSE`](LICENSE)); dual licensing in [`LICENSING.md`](LICENSING.md), contributions under the [`CLA.md`](CLA.md).
- **Docs and texts:** CC BY-SA 4.0 ([`LICENSE-DOCS`](LICENSE-DOCS)).

Copyright © 2026 Johannes Kaindl.
