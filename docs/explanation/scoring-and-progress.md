# Scoring and progress

Why NeuroVim counts what it counts, and why the way through the game includes replays. The numbers themselves are in [Progression](../reference/progression.md); this page is about the reasons.

## What the score measures

NeuroVim trains Vim, and Vim rewards saying more with fewer keys: a count, a motion, a macro, a search instead of holding `j`. So a run is scored by the keys you typed, against a par for that mission. Time is recorded too, as a best and as keys per minute, but the tier depends on keys only: a calm, precise run beats a fast, clumsy one.

The clock and the counter start with your first key in the mission buffer, not when the buffer opens. Reading the objective and thinking about a plan cost nothing. The clock stops while another buffer is current — the help, NEXUS, a file of yours — and goes on when you come back: a look elsewhere is not part of the run.

## What counts as a key

The rule is "what you pressed", not "what Vim executed":

- **Every key you type in the mission buffer counts,** in any mode, including the keys of a search (`/pattern<CR>`) or an Ex command (`:s/…`) — also one you abandon with `<Esc>`, because the keys were pressed. Keys typed in a command-line window opened from the mission (`q:`, `<C-f>` on the command line) count the same: it is another way to type the command.
- **A macro counts once:** the keys that record and start it (`qa…q`, `29@a`), not the keys it replays. That is the point of macros, and the game should reward it.
- **A mapping costs the keys you press for it,** whatever it runs: `<F5>` mapped to `:NeuroVim check<CR>` costs 1, `<Space>c` costs 2, and so does a mapping to one of NeuroVim's `<Plug>` mappings. NeuroVim sees the keys you press, and cannot tell a mapping you made for the game from one you made for something else.
- **`:NeuroVim` commands you type do not count,** abbreviated too (`:Neuro check`), and also when you abandon one with `<Esc>`. Checking your work should never cost you a tier. Only the command typed out is free: from `q:` the `q` counts, and a mapping costs its keys.
- **Leaving the mission does not count.** A command after which the mission buffer is no longer current and its text is unchanged — `:help`, `:e notes.txt`, `:b 2` — costs nothing: looking something up is not part of the solution. A command that changes the text and then leaves (`:%s/x//g|b#`) counts.
- **Mouse clicks and the scroll wheel do not count.** They are not Vim skills, and scrolling to read should be free.
- **A terminal paste costs no key at all.** Terminals with bracketed paste deliver a paste as one block, not as typed keys. A terminal without it sends the characters as if you had typed them, and then they count.

## Why par and tiers

A bare key count says little: 40 keys is excellent for one mission and wasteful for another. Par puts each mission on its own scale — derived from its difficulty, or set by hand where the formula does not fit the mission — and the tiers turn it into a target you can aim for: gold at par, silver within half again, bronze within two and a half times. Missing a tier is not a failure: the run still counts, earns its XP, and the result tells you how many keys fewer would have reached the next tier.

## Why a run without keys earns XP but no bests

If you paste a solution, or the text was already right, the run has zero counted keys. NeuroVim still counts the win and its XP — it cannot tell a paste from a memory of the answer, and refusing the win would feel like a bug. But it sets no best time, no best key count and no tier, so bests and tiers keep meaning "this is how well I did it in Vim". The rule comes from NeuroVim's core, like all scoring rules here.

The same holds when the text was changed from outside the mission buffer — with `:bufdo` or `:windo`, or a command typed in another buffer. Keys count only where the mission is, so such an edit would otherwise be free. The result says which of the two happened.

## Why replays

Solving every mission once earns 1555 XP, which is level 8; the last two levels need more. Earlier on there are gaps as well: right after the start, M-01 to M-04 give 65 XP and level 2 needs 66, so KATA-01 or a replay bridges it. The thresholds come from NeuroVim's game data, not from this plugin.

Replays are part of the design: every solved run earns XP again, and replaying a mission you know is exactly where you try a shorter route and climb from bronze to gold. When every mission you can play is solved and only replays lead on, NEXUS says so — "Replay solved missions for XP — level N (X XP) unlocks …" — so you are never stuck without knowing why.

KATAs are the shortest route to that kind of practice: drills on one skill, no story, no briefing, and they unlock with levels like the story missions.

## Why the streak uses UTC

A day is a calendar day in UTC, as in NeuroVim's core, and the same on every machine. Local time would make the streak depend on where you are and on daylight saving: a mission at 00:30 after the clocks change could count for the wrong day, or a trip across time zones could break a streak you kept.
