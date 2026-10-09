# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/), and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Game rules ported from NeuroVim's TypeScript core, proven by its conformance vectors (12 functions, 83 cases): mission text normalization and scoring (`neurovim.rules.diff`), par tiers (`neurovim.rules.par`), XP, levels, unlocks, streaks and per-mission bests (`neurovim.rules.progression`).
- `neurovim.data` — loads the vendored content export (missions, chapters, levels, unlock map) with a schema check.
- Vendored `nvim-kit` 0.1.1 (test runner, conformance runner, data loader) under `lua/neurovim/kit/`, and NeuroVim's content export and conformance vectors under `data/` and `spec/conformance/`; `make check` fails on any drift from the pinned sources.
