# Save file

Your progress: one JSON object in `state.json`, under Neovim's data directory (`stdpath('data')/neurovim/state.json`; `:checkhealth neurovim` shows the path). The format is NeuroVim's `PluginData`, the save format of NeuroVim's core, so neurovim.nvim keeps every field — also the ones it does not use — with the value it found.

## Fields neurovim.nvim reads and writes

| Field | Type | Meaning |
|---|---|---|
| `total_xp` | number | All XP ever earned, replays included. Your level follows from it ([Progression](progression.md)). |
| `unlocked` | array of ids | Missions you may start, plus the loot ids (`LOOT-01` …) each level-up adds for NeuroVim's other builds. Starts as `["M-01", "M-02", "M-03", "M-04", "KATA-01"]`; a level-up adds its missions. On load, missions your level should have unlocked are added back if missing. |
| `completed_missions` | array of ids | Missions solved at least once, in the order you first solved them. |
| `missions` | object | Per mission id, the record of your runs (below). |
| `streak_current` | number | Days in a row with at least one solved mission. |
| `streak_last_date` | string | The last day you solved a mission, `YYYY-MM-DD` in UTC; `""` before the first. |

A mission record:

| Field | Type | Meaning |
|---|---|---|
| `best_time_ms` | number | Fastest run in milliseconds, from the first key to the check; `0` = no best yet. |
| `best_keystrokes` | number | Fewest keys in a run; `0` = no best yet. Your tier in NEXUS comes from this. |
| `best_ks_per_min` | number | Highest keys per minute in a run. |
| `runs` | number | Solved runs, replays included. |
| `last_run` | string | Day of the last solved run, `YYYY-MM-DD` in UTC. |

A run without a single counted key (a terminal paste, a buffer that was already right) adds a run and its XP but leaves the three bests as they were.

## Fields kept for NeuroVim's other builds

`ambient_enabled`, `healedFrontmatters`, `onboarded`, `railPin`, `sandbox_bests`, `sidebar_module_state`, `vimPrimerSeen`. neurovim.nvim writes them back unchanged, including `null` values and empty objects, so the file keeps the full `PluginData` shape.

## Example

Shortened: after these five wins, `missions` holds a record for each of them; only M-01's is shown.

```json
{
  "total_xp": 75,
  "unlocked": ["M-01", "M-02", "M-03", "M-04", "KATA-01", "M-05", "M-06", "M-07", "M-08", "KATA-02", "KATA-03", "KATA-12", "LOOT-01"],
  "completed_missions": ["M-02", "M-03", "M-04", "KATA-01", "M-01"],
  "missions": {
    "M-01": { "best_time_ms": 41250, "best_keystrokes": 19, "best_ks_per_min": 27.6, "runs": 1, "last_run": "2026-10-10" }
  },
  "streak_current": 1,
  "streak_last_date": "2026-10-10",
  "ambient_enabled": false,
  "healedFrontmatters": {},
  "onboarded": false,
  "railPin": null,
  "sandbox_bests": { "easy": null, "normal": null, "hard": null },
  "sidebar_module_state": { "mission": true, "progress": false, "cheatsheet": false },
  "vimPrimerSeen": false
}
```

## How it is written

- **Atomically:** to a temporary file next to it, then renamed over `state.json`. A crash while writing never leaves half a file.
- **Re-read first:** each save reads the file again right before writing and applies only its own change, so two Neovim instances do not overwrite each other.
- **A file that is not valid save data** is moved to `state.json.broken-<time>` with a warning, and the game starts fresh.
- **A file that exists but cannot be read** (no permission) is left untouched, an error says so, and nothing is saved until it can be read.

How to back it up, move or reset it: [Back up, move or reset your progress](../how-to/manage-progress.md).
