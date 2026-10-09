# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/), and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `:NeuroVim` with Tab completion: NEXUS (level, XP bar, streak, missions by chapter), `mission <id>` (briefing), `check`, `reveal`, `restart`; the 40 story missions are playable.
- Mission buffer with the objective above line 1 and a winbar (id, time, keys, par); keys and time count from the first typed key, `:NeuroVim` commands excluded.
- Result in a floating window: XP, tier, bests, streak, level-up and unlocked missions; a run without a keystroke counts but sets no bests.
- Save file `stdpath('data')/neurovim/state.json` in NeuroVim's `PluginData` format: re-read before every write, written atomically, a broken file kept as `.broken-<time>`.
- `<Plug>(neurovim-nexus|check|reveal|restart)` mappings; no global keys.
- Ports of `completeMission`, `metricsResult` and `unlockLevelFor` (15 functions, 103 conformance cases).
- Game rules ported from NeuroVim's TypeScript core, proven by its conformance vectors (12 functions, 83 cases): mission text normalization and scoring (`neurovim.rules.diff`), par tiers (`neurovim.rules.par`), XP, levels, unlocks, streaks and per-mission bests (`neurovim.rules.progression`).
- `neurovim.data` — loads the vendored content export (missions, chapters, levels, unlock map) with a schema check.
- Vendored `nvim-kit` 0.3.0 (test runner, conformance runner, data loader, calendar dates, state store, view buffers, panel, keystroke tracking) under `lua/neurovim/kit/`, and NeuroVim's content export and conformance vectors under `data/` and `spec/conformance/`; `make check` fails on any drift from the pinned sources.
