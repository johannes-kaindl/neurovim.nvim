# Documentation

Where each piece of neurovim.nvim's documentation lives. The player's manual is the Vim help, because `:help` is where Neovim users look; this folder holds what a contributor or maintainer needs besides it.

## For players

The manual is [`doc/neurovim.txt`](../doc/neurovim.txt), read in Neovim with `:help neurovim`. Its sections, by the kind of question they answer:

| Need | Section | Help tag |
|---|---|---|
| Learn it: the first mission, step by step | 4. Getting started | `:help neurovim-start` |
| Look it up: every command, the KATAs, the `<Plug>` mappings | 5. Commands | `:help neurovim-commands` |
| Understand it: XP, levels, replays, par tiers, bests, streak | 6. Progress | `:help neurovim-progress` |
| Understand it: what counts as a key | 5. Commands | `:help neurovim-keys` |
| Look it up: where progress is saved, what happens to a broken file | 7. Save file | `:help neurovim-save` |
| Fix it: `:checkhealth neurovim` and the usual questions | 8. Health, 9. Troubleshooting | `:help neurovim-troubleshooting` |

The [README](../README.md) is the short version of the same: install, the commands, the demo GIF.

## For contributors and maintainers

| File | What |
|---|---|
| [`../AGENTS.md`](../AGENTS.md) | Architecture, commands, rules (conformance, vendoring), gotchas |
| [`releasing.md`](releasing.md) | Cutting a release: checks, CHANGELOG, tag, both forges, verifying the install |
| [`images/README.md`](images/README.md) | Every image the README embeds and how it is made |
| [`demo/`](demo/) | `demo.tape` and `init.lua` behind the README GIF (`make demo`) |
| [`../CHANGELOG.md`](../CHANGELOG.md) | What changed in each release |
