# Troubleshooting

Find the message you see, or the symptom, and follow the fix. When in doubt, start with `:checkhealth neurovim`: it checks the Neovim version, the game data, the save file and its directory, and changes nothing.

## Messages

### `neurovim.nvim needs Neovim 0.10 or newer.`

**Cause:** your Neovim is older than 0.10; the plugin does not load. **Fix:** update Neovim (`nvim --version` shows yours).

### `E492: Not an editor command: NeuroVim`

**Cause:** the plugin is not on the runtimepath — not installed, or your plugin manager has not loaded it. **Fix:** check the plugin spec (`{ "johannes-kaindl/neurovim.nvim" }` with lazy.nvim), run `:Lazy` to see whether it is installed, then restart Neovim.

### `neurovim: unknown option — ignored: ….`

**Cause:** your plugin spec passes an option NeuroVim does not have, for example `opts = { keys = true }`. The only option is `isolate` (`:help neurovim-options`). **Fix:** remove the others; `opts = {}` or no `opts` at all is fine. For keys, see [Map keys](map-keys.md).

### `neurovim: isolate must be true or false — ignored.`

**Cause:** `isolate` got something other than `true` or `false`, for example `opts = { isolate = "no" }`. NeuroVim keeps the default, `true`. **Fix:** write `isolate = false` without quotes.

### `M-05 is locked — it unlocks at level 2.`

**Cause:** the mission needs a higher level. **Fix:** earn XP with the missions that are open. If every open mission is solved, NEXUS says "Replay solved missions for XP — level N (X XP) unlocks …": replays earn XP too, and that is how you get past those levels. [Scoring and progress](../explanation/scoring-and-progress.md) explains why.

### `neurovim: no mission M-99.`

**Cause:** there is no mission with that id. **Fix:** type `:NeuroVim mission ` and press Tab for the list; ids work in lower case too (`m-05`).

### `3 lines still corrupted.`

**Cause:** the text differs from the original in that many lines. **Fix:** `:NeuroVim reveal` highlights them. A line can be wrong because of a character you changed by accident or a blank line missing or added inside the text (spaces at the end of a line and blank lines at the very start or end do not count); `u` undoes your edits back to the corrupted text the mission started with, and `:NeuroVim restart` starts over.

### `Transmission already restored — :NeuroVim result shows the result again, :NeuroVim restart plays the mission again.`

**Cause:** you already solved this run; one run counts once. **Fix:** `:NeuroVim restart` to play it again (it earns XP again), or `:NeuroVim` for your progress.

### `neurovim: no result yet in this session — :NeuroVim check scores a mission.`

**Cause:** `:NeuroVim result` shows the last result since Neovim started, and there is none yet. Results are not kept across restarts. **Fix:** solve a mission and `:NeuroVim check` it; NEXUS (`:NeuroVim`) shows your XP, level and tiers at any time.

### `neurovim: unknown subcommand … — use mission, check, reveal, restart or result.`

**Cause:** `:NeuroVim` got a word it does not know, often a typo. **Fix:** type `:NeuroVim ` and press Tab for the list; `:help neurovim-commands` describes each one.

### `Usage: :NeuroVim mission <id>`

**Cause:** `:NeuroVim mission` without an id. **Fix:** add the id, for example `:NeuroVim mission M-01`; Tab completes the ids.

### `M-01 is still running — back to it. :NeuroVim restart starts it over.`

**Cause:** you opened a mission whose run is not finished, from NEXUS or with `:NeuroVim mission`. NeuroVim takes you back to it with your text, time and keys. **Fix:** nothing to fix; to begin again, `:NeuroVim restart` in the mission buffer.

### `neurovim: :edit reloaded M-01 — a mission has no file, so the run starts over.`

**Cause:** `:edit` (or `:e!`) in a mission buffer. There is no file behind a mission, so Neovim emptied the buffer; NeuroVim started the mission over instead of leaving it empty. **Fix:** `u` does not bring the old text back; play on from the start. To undo edits, use `u` instead of `:e!`.

### `neurovim: 1 buffer from a saved session cleared — missions are not restored; :NeuroVim opens NEXUS.`

**Cause:** a saved session (`:mksession`, persistence.nvim and the like) had a mission on screen and brought back an empty buffer under its name. NeuroVim removed it. **Fix:** nothing to fix; open the mission again from NEXUS.

### `E382: Cannot write, 'buftype' option is set`

**Cause:** `:w` (or a save mapping such as `<C-s>`) in a mission buffer. A mission is not a file and is not saved; your progress is saved by `:NeuroVim check`. **Fix:** nothing to fix; `:NeuroVim check` when the text is right.

### `neurovim: not a mission buffer — open one with :NeuroVim mission <id>.`

**Cause:** `check`, `reveal` and `restart` work only in a mission buffer (`neurovim://<id>`), and the current buffer is another one — or the mission buffer was deleted, which ends its run. **Fix:** switch to the mission window, or open the mission again.

### `neurovim: the save file …/state.json could not be read and was moved to …/state.json.broken-<time> — starting from a fresh save.`

**Cause:** the save file is not valid save data — cut off by a full disk, edited by hand, or not JSON. NeuroVim kept it next to the save and started fresh. **Fix:** if the old progress matters, open the `.broken-<time>` file and repair the JSON (compare with [the save file reference](../reference/save-file.md)), then move it back to `state.json` while Neovim is closed. Otherwise delete it.

### `neurovim: nvim-kit store: cannot read …/state.json (… Permission denied) — left untouched. Progress is not saved until NeuroVim can read the file again.`

**Cause:** the save file exists, but your user may not read it — usually after copying it from another account or with `sudo`. NeuroVim does not touch it and saves nothing, so your old progress is safe. **Fix:** give it back read and write permission, for example `chmod u+rw ~/.local/share/nvim/neurovim/state.json` (`:checkhealth neurovim` shows the exact path). If the file belongs to another user (after `sudo`), take it back first: `sudo chown $USER ~/.local/share/nvim/neurovim/state.json`. The mission stays open: run `:NeuroVim check` again and the win is saved.

## Symptoms without a message

### The objective is gone

It stands above line 1 and scrolls with the text. `gg` brings it back; so does `<C-y>` at the top of the buffer.

### The result window disappeared

It closes when the cursor moves. `:NeuroVim result` shows it again, until you quit Neovim; `:NeuroVim` shows your XP, level and tiers.

### A run won its XP but set no best

Either no key was counted (a paste, or the text was already right), or the text was changed from outside the mission buffer — with `:bufdo`, `:windo`, or a command typed in another window. The result window says which. [Scoring and progress](../explanation/scoring-and-progress.md#why-a-run-without-keys-earns-xp-but-no-bests) explains why.

### More keys than I typed

A mapping costs the keys you press for it, also one to a `<Plug>` mapping or to `:NeuroVim check` (`<Space>c` costs 2). A terminal without bracketed paste sends a paste as typed keys. With `isolate = false`, which-key replays the keys of a prefix it waited on, and they count twice. The same happens in a KATA opened as Neovim starts (`nvim '+NeuroVim mission KATA-01'`), before which-key has loaded: the keys of your `<Leader>` mappings count twice in that run, until you first switch buffers. Start from `:NeuroVim` (NEXUS), or switch buffers once. [What counts as a key](../explanation/scoring-and-progress.md#what-counts-as-a-key) has the full rules.

### A paste won the mission but set no best

A run without a single counted key — a terminal paste, or a buffer that was already right — earns its XP but sets no best time or key count, so bests stay comparable.

### My progress is gone

Look for `state.json.broken-<time>` next to the save (`:checkhealth neurovim` shows where): NeuroVim moves an unreadable file there instead of dropping it. See the message above.

## Getting help

If none of this fits, open an issue at <https://github.com/johannes-kaindl/neurovim.nvim/issues> with your Neovim version (`nvim --version`), the output of `:checkhealth neurovim`, and the message you saw.
