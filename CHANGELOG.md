# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/), and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

First release. NeuroVim — a Vim-learning spy thriller — as a Neovim plugin, with no Node and no helper process.

### Added
- `:NeuroVim` with Tab completion: NEXUS (level, XP bar, streak, the ten story chapters and the KATAs), `mission <id>`, `check`, `reveal`, `restart`. All 54 missions are playable: 40 story missions with briefings and 14 KATA drills that start without one.
- Mission buffer `neurovim://<id>`: the objective above line 1, wrapped to the text width beside number and sign columns and again after a resize or split; a winbar with id, time, keys and par; `u` stops at the corrupted text the mission started with.
- Keystroke counting from the first key typed in the mission buffer: a macro counts the keys that start it; `:NeuroVim` commands, mouse clicks, the scroll wheel and a terminal paste do not count.
- Result in Neovim's floating preview: XP, time, keys, tier (gold, silver, bronze), how many keys fewer reach the next tier, bests, streak, level-up and what it unlocked. A run without a single key earns its XP but sets no bests.
- NEXUS shows the way past the walls: when every free mission is solved, "Replay solved missions for XP — level N (X XP) unlocks …".
- Save file `stdpath('data')/neurovim/state.json` in NeuroVim's `PluginData` format: re-read right before every write (two Neovim instances do not overwrite each other), written atomically, a broken file kept as `.broken-<time>` with a warning.
- `:checkhealth neurovim`: Neovim version, game data, save file and directory, vendored versions — read-only.
- `<Plug>(neurovim-nexus|check|reveal|restart)` mappings; no global keys, no `setup()`.
- The game rules in Lua — scoring, progression, par tiers, mission completion, run metrics — proven by 103 conformance cases over 15 functions from NeuroVim's TypeScript core.
- Vendored: `nvim-kit` 0.5.0 under `lua/neurovim/kit/`, NeuroVim's content export and conformance vectors (commit 981d25c) under `data/` and `spec/conformance/`; `make check` fails on any drift from the pinned sources.
- The manual `:help neurovim`: install, getting started, commands, KATAs, mappings, what counts as a key, progress, save file, health, troubleshooting.
- Tests in headless Neovim: end to end through `:NeuroVim` over all 54 missions, M-01 with real keys up to the first level-up, the way through the game, the SKILLS commands of the briefings against real Neovim; `make test NVIM=<path>` runs them with another Neovim (0.10.4 measured green). `make demo` records the README GIF.
