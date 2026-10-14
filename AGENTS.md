# AGENTS.md — neurovim.nvim

> **Role:** context for AI agents working in this repo. Humans start in [`README.md`](README.md). The coordination rules of the Neovim plugins — above all "Bibliothek ab Eins" and its justification gate — live one level up, in `../AGENTS.md` (the `nvim-plugins` Dach).
>
> **Language:** code, comments, identifiers and docs are **English**; commit messages **German**, Conventional Commits. Tags SemVer without `v`.

## TL;DR

**neurovim.nvim** is NeuroVim — the Vim-learning spy thriller — as a Neovim plugin. The game logic (scoring, progression, par tiers) is written in Lua and proven against conformance vectors generated from neurovim's TypeScript core; missions and tables come from neurovim's JSON export. No Node, no helper process.

## Architecture

| Path | What |
|---|---|
| `lua/neurovim/rules/` | domain rules ported from the TS core (pure Lua, `-- domain: neurovim`) |
| `lua/neurovim/data.lua` | loads the vendored export `data/neurovim-data.json` through the kit's schema-checked loader; `default_plugin_data()` exact (null and {} kept) |
| `lua/neurovim/state.lua` | the save file (PluginData) under `stdpath('data')/neurovim/`, through `kit.store` |
| `lua/neurovim/missions.lua` | all 54 missions (40 story, 14 KATA), chapters + KATAS section, status per player, `next_unlock` for the replay hint |
| `lua/neurovim/ui/` | NEXUS, briefing, mission buffer (panel, winbar, keytrack, check, reveal, restart), result float |
| `lua/neurovim/health.lua` | `:checkhealth neurovim` from the kit's read-only health blocks |
| `lua/neurovim/command.lua`, `plugin/neurovim.lua` | `:NeuroVim`, Tab completion, `<Plug>` mappings, version check |
| `lua/neurovim/init.lua`, `lua/neurovim/config.lua` | `setup()` with its one option `isolate`; `config` holds the values a mission reads when it starts |
| `lua/neurovim/session.lua` | what a saved session or `:edit` leaves under `neurovim://`: sweep on `SessionLoadPost` and on load, `BufReadCmd` (autocmds in `plugin/neurovim.lua`) |
| `lua/neurovim/kit/` | vendored from `nvim-kit` (`VENDOR.json`) — never edit; among them `isolate` (a buffer in plain Neovim: mission buffers unless `isolate = false`) and `keytrack` (keys and time of a run) |
| `data/`, `spec/conformance/` | vendored from `neurovim` (`data/VENDOR.json`): the content export and the conformance vectors — never edit |
| `tests/` | specs for the kit's headless runner; `tests/conformance_spec.lua` runs every vector against its Lua port, `tests/docs_spec.lua` checks the reference tables in `docs/` against the game data and every relative link in `docs/` |
| `doc/neurovim.txt` | the manual, `:help neurovim` — commands and mappings live only here |
| `docs/` | user docs by Diátaxis (index `docs/README.md`: tutorial, how-to, reference, explanation) plus maintainer pages (`releasing.md`, `images/`, `demo/`) |

## Commands

```bash
make check           # stylua --check · selene · tests in headless Neovim · vendor-check (../tools/kit/vendor.py)
make release-check   # Bibliothek gate over everything since the last tag (../tools/bibliothek/gate.py)
make demo            # README GIF + MP4 from docs/demo/demo.tape (vhs, ffmpeg; throw-away save)
stylua lua tests     # format (skips lua/neurovim/kit/ via .styluaignore)
make test NVIM=/path/to/nvim   # the suite with another Neovim — the minimum version run:
# D=$(mktemp -d); curl -sfL https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-macos-arm64.tar.gz | tar -xz -C "$D"; xattr -cr "$D"
# make test NVIM="$D/nvim-macos-arm64/bin/nvim"
```

Tools: `brew install stylua selene`. Neovim ≥ 0.10. The Dach (`..`) must be present for `vendor-check` and `release-check`; without it they print `SKIPPED`, which is not a pass. Releases: [`docs/releasing.md`](docs/releasing.md).

## Rules

- **Rules change in the TS core first**, then here: re-vendor neurovim's export and vectors, and the conformance spec shows which Lua ports lag behind. Never adjust a vector to fit the port.
- **Never edit vendored files** (`lua/neurovim/kit/`, `data/`, `spec/conformance/`). Fix upstream, re-vendor with `../tools/kit/vendor.py add`; `make check` fails on any drift.
- **Every module under `lua/neurovim/` except `kit/` carries `-- domain: neurovim` on line 1.** A module without it is gate-pflichtig under "Bibliothek ab Eins" (`../AGENTS.md`).
- Every test has a counter-check that shows it can fail.
- **A user-visible change updates the docs in the same commit:** `doc/neurovim.txt` for commands, mappings and messages; `docs/how-to/troubleshooting.md` quotes every `vim.notify` text word for word — a new or changed message goes there too.

## Conformance

The rules in `lua/neurovim/rules/` are ports of neurovim's TS core (`packages/core/src/utils/diff.ts`, `engine/ProgressionEngine.ts`, `engine/ParTier.ts`, `engine/MissionCompletion.ts`, `engine/MetricsTracker.ts`). `tests/conformance_spec.lua` runs every vector file in `spec/conformance/` against its Lua function (table `IMPLS`, TS name → Lua function); a vector without a port is a red case, and the vector count is pinned (`15`) so a new function shows up.

After a rule change upstream:

1. Re-vendor from the new neurovim commit (from the Dach): `python3 tools/kit/vendor.py add neurovim.nvim --source ../apps/neurovim --ref <commit> --manifest data/VENDOR.json --license AGPL-3.0-only packages/content/export/neurovim-data.json:data/neurovim-data.json packages/core/conformance/:spec/conformance`.
2. `make test` names the red functions and cases; port the change until they pass. Never edit a vector.
3. A new vector function: add its port to `IMPLS` and raise the pinned count.
4. Tell the neurovim session about the new pin — neurovim's `consumers.json`/`CONSUMERS.md` track it.

## Gotchas

- **`vim.NIL` is truthy.** The game data goes through the kit's loader with `luanil`, so `null` inside objects is an absent field there. The save file and `data.default_plugin_data()` are read **without** `luanil` on purpose: `null` stays `vim.NIL` and `{}` stays an object, so the file keeps the shape NeuroVim's other builds read.
- **`nvim_feedkeys` needs the flag `t`** (`'ntx'`) for keys to count as typed (macros, keystroke counting); **without `n`** (`'tx'`) for keys that must hit a mapping (the briefing's and NEXUS's `<CR>`).
- **`tests/run.lua` points `XDG_DATA_HOME` at a temp dir** — never remove it, or tests write the player's real save.
- **Specs that complete missions use their own save** (`with_fresh_save` in `tests/e2e_spec.lua`) and give `XDG_DATA_HOME` back afterwards, also on failure — spec files share one Neovim, and later specs expect the save `tests/run.lua` set up.
- **`mission.start(id)` resumes a run that is still open** (also one an earlier spec left behind); a spec that needs a new run passes `{ fresh = true }`, and a spec that goes through the briefing's `<CR>` wipes `neurovim://<id>` first.
- **KATAs have no briefing** (`briefing == ''`): `briefing.open` starts their mission buffer directly.
- **`make demo`** needs `vhs`, `ttyd`, `ffmpeg`; vhs 0.12 writes 25 fps whatever the tape says, so the Makefile converts to the 20 fps GIF/MP4 (D13).
- **Typed keys in specs go through `:silent call feedkeys(g:neurovim_test_keys, "ntx")`**: it keeps the echo of searches and commands out of the test report and the keys still count. Don't build the command with `vim.fn.string(keys)` — a `<CR>` in it ends the command line.
- **Headless `nvim -l` never fires `CursorMoved`**; tests that depend on it raise it with `nvim_exec_autocmds`.
- **`T.eq(x, vim.NIL)` passes for `nil`** (`deep_equal`); check a JSON null with `rawequal(x, vim.NIL)` or compare with `T.json_eq`.
- **Scheduled reactions need `vim.wait` in specs.** Neovim's floating preview closes on `CursorMoved` through `vim.schedule`; a spec that raises the event and asserts at once measures nothing. Raise, `vim.wait(20)`, then assert (`tests/result_spec.lua`).
- **`vim.on_key` reports a mapping's whole lhs in one call** (`typed = "iw"`, `"<Space>p"`); keytrack counts the keys of that lhs since nvim-kit 0.7.0 (0.6.0 counted one per mapping).
- **Neovim's own default mappings have `sid = -8` in a normal start** (like any Lua mapping) but `sid = 1` under `nvim -l`; `kit/isolate.lua` tells them by callback source and `desc`, and a spec asks a real `nvim --clean` (`vim.system`), because the test runner's start differs.
- **Play tests in a real setup without touching it:** APFS-clone `~/.config/nvim`, `~/.local/share/nvim/{lazy,mason,site}` into a scratch dir (`cp -cR`), point `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` there, turn the lazy checker off in the copy; start `nvim --listen <sock>` in tmux (session name with PID), type with `tmux send-keys` at human pace (0.2 s; a bare `;` must be sent as `\;`, tmux reads it as a command separator), read state with `nvim --server <sock> --remote-expr`, and take the expected text from `nvim --clean`. Used for the isolate re-test of 2026-10-14 (task note „Missionsbuffer gegen das Nutzer-Setup abschirmen“).
- **Pass `vendor.py`'s `SRC:DEST` list as separate arguments.** A zsh variable holding the list is not split: `vendor.py` gets one argument and removes every other copy as "no longer in" the source.
- **StyLua must skip `kit/`** (`.styluaignore`); otherwise it reformats the vendored copies and `vendor-check` turns red.

## Memory

- Cockpit (SSOT for status and tasks): `$VAULT/25_Coding/neurovim.nvim/neurovim.nvim.md`.
- Design: `$VAULT/25_Coding/neurovim/_SDD/2026-10-08-neurovim-nvim-design.md`.

## Abweichungen von der Leitkonvention

- README-Tier `nvim-plugin` (`_docs/readme/readme-spec.json`).
- Nutzer-Doku doppelt angelegt, mit klarer Teilung: `:help neurovim` ist das Handbuch im Editor (dort suchen Neovim-Nutzer), `docs/` die Diátaxis-Doku online (CORE-META-04). Befehle und Mappings stehen nur in der Hilfe, `docs/` verlinkt sie; die Zahlen-Tabellen in `docs/reference/` prüft `tests/docs_spec.lua` gegen die Spieldaten, damit zwei Orte nicht still auseinanderlaufen (CORE-META-16).
