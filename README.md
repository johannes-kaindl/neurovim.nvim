# neurovim.nvim

**NeuroVim — a Vim-learning spy thriller — as a Neovim plugin: story missions you solve with real Vim motions, in your own editor.**

[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

**Status:** in development (phase 3 of 5 done). The game logic — scoring, progression, par tiers — is ported to Lua and passes all 83 conformance vectors from NeuroVim's TypeScript core. The interface (NEXUS, briefings, missions) follows in phase 4. The repository is private and not released yet.

## Requirements

- Neovim ≥ 0.10
- Nothing else: no Node, no helper process, no other plugin.

## Install

Not installable yet — the repository is private and the plugin defines no commands. Once it is published, it installs with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "johannes-kaindl/neurovim.nvim" }
```

## Usage

No commands yet. Phase 4 adds `:NeuroVim` (NEXUS with status and missions), `:NeuroVim mission <id>`, `:NeuroVim check`, `:NeuroVim reveal` and `:NeuroVim restart`. The plugin will set no global keys; it will offer `<Plug>` mappings.

## Configuration

No options yet.

## Documentation

The manual lives in Neovim: `:help neurovim`. Contributor notes: [`AGENTS.md`](AGENTS.md); changes: [`CHANGELOG.md`](CHANGELOG.md).

## License

- **Code:** AGPL-3.0-only ([`LICENSE`](LICENSE)); dual licensing in [`LICENSING.md`](LICENSING.md), contributions under the [`CLA.md`](CLA.md).
- **Docs and texts:** CC BY-SA 4.0 ([`LICENSE-DOCS`](LICENSE-DOCS)).

Copyright © 2026 Johannes Kaindl.
