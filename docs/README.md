# Documentation

Everything about playing neurovim.nvim, sorted by what you need right now. The complete manual is also built into Neovim: `:help neurovim` ([`doc/neurovim.txt`](../doc/neurovim.txt)).

## Tutorial — learn it

- [**Getting started**](tutorials/getting-started.md) — install, solve your first mission, aim for gold, reach level 2.

## How-to guides — get something done

- [**Troubleshooting**](how-to/troubleshooting.md) — every message the plugin shows, what causes it and how to fix it; getting help.
- [Map keys](how-to/map-keys.md) — put `:NeuroVim`, check, reveal and restart on keys, in your config or in a lazy.nvim spec.
- [Back up, move or reset your progress](how-to/manage-progress.md) — the save file, between machines, from scratch, in two Neovims.

## Reference — look it up

- Commands, KATAs, `<Plug>` mappings, health check — `:help neurovim-commands` and the [manual](../doc/neurovim.txt).
- [Progression](reference/progression.md) — levels, unlocks per level, XP, par and tiers, streak.
- [Save file](reference/save-file.md) — every field of `state.json` and how it is written.

## Explanation — understand it

- [Scoring and progress](explanation/scoring-and-progress.md) — what counts as a key and why, par and tiers, why replays are part of the way.
- [How neurovim.nvim is built](explanation/design.md) — pure Lua, conformance vectors, content as data, Neovim as the interface.

## For contributors and maintainers

| File | What |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Architecture, commands, rules (conformance, vendoring), gotchas |
| [`releasing.md`](releasing.md) | Cutting a release: checks, CHANGELOG, tag, both forges, verifying the install |
| [`images/README.md`](images/README.md) | Every image the README embeds and how it is made |
| [`demo/`](demo/) | `demo.tape` and `init.lua` behind the README GIF (`make demo`) |
| [`CHANGELOG.md`](../CHANGELOG.md) | What changed in each release |

The tables in the reference pages are checked against the game data by `tests/docs_spec.lua`, and every relative link in `docs/` must point to an existing file.
