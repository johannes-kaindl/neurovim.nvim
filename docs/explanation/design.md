# How neurovim.nvim is built

NeuroVim's game core is written in TypeScript. neurovim.nvim brings the same game into Neovim without bringing that runtime along. This page explains the choices behind it; contributors find the working rules in [AGENTS.md](../../AGENTS.md).

## Pure Lua, no Node, no helper process

Neovim plugins are Lua; a plugin that needs Node or a background process keeps many people from installing it. The game logic that matters for playing — scoring a text against its solution, XP, levels, unlocks, streaks, par tiers, run records — is small, so neurovim.nvim ports it to Lua (`lua/neurovim/rules/`) instead of calling the TypeScript core.

## One game, proven by conformance vectors

Two implementations of the same rules drift apart, quietly. To keep them identical, NeuroVim's TypeScript core generates conformance vectors: for each rule function, a set of inputs with the outputs the TypeScript code produces. neurovim.nvim vendors those vectors (`spec/conformance/`) and its test suite runs every one against the Lua port. A rule that changes in the core shows up here as failing tests, not as a game that scores differently in Neovim. The rules always change in the core first.

## Content as data

Missions, briefings, chapters, levels and unlocks are not written twice either. NeuroVim exports them as one JSON file, which neurovim.nvim vendors unchanged (`data/neurovim-data.json`) and loads with a schema check. `make check` fails if the vendored file differs from the pinned NeuroVim commit, and `:checkhealth neurovim` names that commit.

## The same save as the other builds

The save file uses NeuroVim's `PluginData` format and keeps every field, also the ones Neovim does not use. One format for every build means a save is not tied to one editor, and a future score export can rely on it. Writing it is careful because progress is the one thing a player cannot recreate: atomic writes, a re-read before every write so two Neovims do not overwrite each other, a broken file kept aside instead of dropped, and an unreadable file never overwritten.

## Neovim is the interface

The plugin draws only what Neovim lacks: a mission list (NEXUS), the objective as virtual lines above the text, a winbar with time, keys and par, and the result in Neovim's own floating preview. Everything else is the player's Neovim — colour scheme, options, mappings, plugins. That is the point: you train in the editor you actually use, with the setup you actually have.

For the same reason there are no global keys and no options. The plugin defines `:NeuroVim` and four `<Plug>` mappings; `setup()` exists only so that a plugin manager calling it does no harm.

## A small library underneath

Parts that any Neovim plugin could use — a headless test runner, the conformance runner, a JSON loader with schema check, the careful save file, the objective panel, keystroke tracking, health checks — live in a separate library, nvim-kit. neurovim.nvim vendors it under its own namespace (`lua/neurovim/kit/`): Neovim loads only one version of a module name, so two plugins sharing a library as a dependency could silently collide. Vendored copies are never edited; a fix goes into the library and is vendored again.
