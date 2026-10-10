# Progression

The numbers behind XP, levels, unlocks and tiers. They come from NeuroVim's game data (`data/neurovim-data.json`) and its rules, ported from NeuroVim's TypeScript core and proven against it by the conformance vectors; `tests/docs_spec.lua` checks the tables on this page against the data, so they cannot drift silently. Why the game works this way: [Scoring and progress](../explanation/scoring-and-progress.md).

## Levels

| Level | Title | XP needed |
|---|---|---|
| 1 | SIGNAL LOST | 0 |
| 2 | GHOST OPERATOR | 66 |
| 3 | DEEP COVER | 186 |
| 4 | NEON WRAITH | 371 |
| 5 | CHROME RAVEN | 601 |
| 6 | SIGNAL HUNTER | 800 |
| 7 | PROTOCOL READER | 1150 |
| 8 | PATTERN BREAKER | 1550 |
| 9 | CIPHER ANALYST | 2000 |
| 10 | SIGNAL ARCHITECT | 2500 |

## Unlocks

| Level | Unlocks |
|---|---|
| 1 | M-01 M-02 M-03 M-04 KATA-01 |
| 2 | M-05 M-06 M-07 M-08 KATA-02 KATA-03 KATA-12 |
| 3 | M-09 M-10 M-11 M-12 KATA-04 KATA-13 |
| 4 | M-13 M-14 M-15 KATA-05 |
| 5 | M-16 R-01 R-02 R-03 R-04 KATA-06 |
| 6 | R-05 R-06 R-07 R-08 KATA-07 KATA-14 |
| 7 | R-09 R-10 R-11 R-12 R-13 R-14 R-15 R-16 KATA-08 KATA-09 |
| 8 | R-17 R-18 R-19 R-20 KATA-10 |
| 9 | R-21 R-22 R-23 R-24 KATA-11 |

Level 10 unlocks no mission. 54 missions in all: 40 story missions (M-01 to M-16, R-01 to R-24) in ten chapters of four, and 14 KATAs.

## XP

- Every solved run earns the mission's XP, replays included. Missions give between 10 and 80 XP; each one shows its value in the result window.
- Solving each mission once earns 1555 XP — level 8. The last two levels need replays.

## Par and tiers

- **Par** is `20 + 20 × difficulty` (difficulty 3 if a mission has none), unless the mission sets its own par — a few do. The winbar and the result show each mission's par.
- **Gold:** at most par keys. **Silver:** at most 1.5 × par. **Bronze:** at most 2.5 × par. More keys: solved, no tier.
- The result names the keys you would have needed for the next tier, for example `12 fewer keys for gold.`
- NEXUS shows the tier of your best run (`best_keystrokes`); a run without a counted key has no tier.

## Streak

Days in a row with at least one solved mission. Days roll over at 00:00 UTC: solving a mission the UTC day after your last one adds a day, a later day starts again at 1, the same day changes nothing.
