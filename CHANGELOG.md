# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/), and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- NeuroVim's game data from commit abb1ec4 (was 981d25c): the briefings no longer open with the wrong line "Timer starts on file open" (time starts with the first key you type in the mission). The conformance vectors are unchanged.
- Vendored `nvim-kit` 0.7.0 (was 0.5.1). It brings the isolation of mission buffers as the kit module `isolate`, a key count that follows the rules in `:help neurovim-keys`, a test runner that tells an empty object from an empty list, and a conformance loader that rejects `null` in an array argument.
- Mission buffers run in plain Neovim, as `nvim --clean` would run them, so that the objective, par and the key count mean what they say in a full setup too (`:help neurovim-isolate`). In the mission buffer only: the Vim keys in Normal, Visual and Operator-pending mode — and every mapping that starts with one — do what Vim does, Neovim's own default mappings and matchit stay; options that change the text (`'textwidth'`, `'shiftwidth'`, `'nrformats'`, `'iskeyword'`, `'conceallevel'`, `'scrolloff'` and others) take Neovim's defaults; the filetype is `neurovim-mission` instead of `markdown`, so Markdown rendering, linting and snippets stay out; diagnostics are off; completion (blink.cmp), mini.nvim's ai, pairs, surround and jump, minuet-ai and copilot.vim are switched off by their buffer switches. Mappings under `<Leader>` and `<LocalLeader>`, function keys and window keys stay yours. Found in a play test in LazyVim: which-key counted prefix keys twice, flash.nvim made `f` jump across lines, blink.cmp inserted snippets on `<CR>`, mini.ai changed the text objects, render-markdown hid the brackets the objective names.

### Fixed
- The result window no longer vanishes when `:NeuroVim check` is typed at a "Press ENTER" prompt (for example after three `:s` in one command line): the `CursorMoved` of the jump before the prompt arrived only after the check and closed the window at once, while XP, level-up and unlocks were saved unseen. The window now closes only when the cursor has really moved.
- The result window shows plain text with highlighted headings instead of raw Markdown (`# TRANSMISSION RESTORED`, `**+15 XP**`).
- Opening a mission that is still running — from NEXUS or with `:NeuroVim mission` — goes back to it with its text, time and keys, instead of starting it over without a word. `:NeuroVim restart` still starts over; a solved mission opens fresh.
- `:edit` in a mission buffer emptied it and ended the run silently; it now starts the mission over and says so.
- Mission buffers are no longer listed, so they stay out of bufferline and out of the buffer list a session saves. Empty buffers a saved session brings back under `neurovim://` are cleared when the session loads (or when NeuroVim loads after it), with a message.
- A run whose text was changed from outside the mission buffer (`:bufdo`, `:windo`, a command typed in another buffer) no longer counts as a normal run with only the keys typed in the mission: like a paste it earns its XP and sets no bests, and the result says why.
- The briefing wraps at word boundaries (`'linebreak'`) instead of mid-word.
- NEXUS lines up the ids of locked missions with the others (🔒 is two cells wide).
- A `reveal` mark goes once its line is right, instead of staying until the next `reveal`.

### Added
- `:NeuroVim result` shows the last result of this session again; a second `:NeuroVim check` of a solved run points to it.
- The result names the new level on a level-up (`LEVEL UP: 1 → 2 · GHOST OPERATOR`) and ends with the next step: `:NeuroVim` opens NEXUS.
- NEXUS and the briefing show in their winbar what `<CR>` and `q` do.
- `reveal` marks each line with `◀ differs` at its end and uses its own highlight groups, `NeuroVimReveal` (default `DiffChange`) and `NeuroVimRevealMark` (default `DiagnosticWarn`), so it stays visible in colour schemes where `DiffChange` barely differs from the background.
- The option `isolate` (default `true`); `opts = { isolate = false }` plays missions with your whole setup, as in 0.1.0. `setup()` warns about unknown options and a wrong type.
- `:checkhealth neurovim` has a section *Mission buffers*: whether they are isolated, the mappings that change Vim keys when they are not, and the global options that change Vim keys (`'ignorecase'`, `'smartcase'` …), which a buffer cannot isolate.

## [0.1.0] — 2026-10-10

First release. NeuroVim — a Vim-learning spy thriller — as a Neovim plugin, with no Node and no helper process.

### Added
- `:NeuroVim` with Tab completion: NEXUS (level, XP bar, streak, the ten story chapters and the KATAs), `mission <id>`, `check`, `reveal`, `restart`. All 54 missions are playable: 40 story missions with briefings and 14 KATA drills that start without one.
- Mission buffer `neurovim://<id>`: the objective above line 1, wrapped to the text width beside number and sign columns and again after a resize or split; a winbar with id, time, keys and par; `u` stops at the corrupted text the mission started with.
- Keystroke counting from the first key typed in the mission buffer: a macro counts the keys that start it; `:NeuroVim` commands, mouse clicks, the scroll wheel and a terminal paste do not count.
- Result in Neovim's floating preview: XP, time, keys, tier (gold, silver, bronze), how many keys fewer reach the next tier, bests, streak, level-up and what it unlocked. A run without a single key earns its XP but sets no bests.
- NEXUS shows the way past the walls: when every free mission is solved, "Replay solved missions for XP — level N (X XP) unlocks …".
- Save file `stdpath('data')/neurovim/state.json` in NeuroVim's `PluginData` format: re-read right before every write (two Neovim instances do not overwrite each other), written atomically, a broken file kept as `.broken-<time>` with a warning, a file without read permission left untouched with an error (the mission stays open and can be checked again once the file is readable).
- `:checkhealth neurovim`: Neovim version, game data, save file and directory, vendored versions — read-only.
- `<Plug>(neurovim-nexus|check|reveal|restart)` mappings; no global keys and no options (`setup()` only so that lazy.nvim's `opts = {}` does no harm).
- The game rules in Lua — scoring, progression, par tiers, mission completion, run metrics — proven by 103 conformance cases over 15 functions from NeuroVim's TypeScript core.
- Vendored: `nvim-kit` 0.5.1 under `lua/neurovim/kit/`, NeuroVim's content export and conformance vectors (commit 981d25c) under `data/` and `spec/conformance/`; `make check` fails on any drift from the pinned sources.
- The manual `:help neurovim`: install, getting started, commands, KATAs, mappings, what counts as a key, progress, save file, health, troubleshooting.
- Tests in headless Neovim: end to end through `:NeuroVim` over all 54 missions, M-01 with real keys up to the first level-up, the way through the game, the SKILLS commands of the briefings against real Neovim; `make test NVIM=<path>` runs them with another Neovim (0.10.4 measured green). `make demo` records the README GIF.

[0.1.0]: https://github.com/johannes-kaindl/neurovim.nvim/releases/tag/0.1.0
