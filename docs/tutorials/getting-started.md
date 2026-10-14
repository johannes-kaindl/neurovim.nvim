# Getting started

From installing neurovim.nvim to your first level-up, in about fifteen minutes. You need Neovim 0.10 or newer and nothing else. Along the way you solve M-01, the first mission, and see how the game scores a run.

## 1. Install

With [lazy.nvim](https://github.com/folke/lazy.nvim), add one line to your plugin specs and restart Neovim:

```lua
{ "johannes-kaindl/neurovim.nvim" }
```

There is nothing to configure. To make sure everything is in place, run:

```vim
:checkhealth neurovim
```

No line should be a warning or an error; "no save yet" is expected on a fresh install.

## 2. Open NEXUS

```vim
:NeuroVim
```

NEXUS is the mission list. At the top you see your level (1, SIGNAL LOST), your XP and a bar towards level 2. Below it are the ten story chapters and the KATAs. Five missions are open from the start: M-01 to M-04 and KATA-01. The others show 🔒 and the level that unlocks them.

## 3. Read the briefing of M-01

Move the cursor to the line with `M-01` and press `<CR>`. The briefing opens: a short message from CIPHER and the Vim skill this mission trains. Read it, then press `<CR>` again to start the mission (`q` would close the briefing instead).

## 4. Look at the mission buffer

The mission is an ordinary Neovim buffer called `neurovim://M-01`. Three things are new:

- **The objective** stands above line 1. For M-01: delete every stray capital `X` and `Z`, 30 characters in all, and change nothing else. If it scrolls away, `gg` brings it back.
- **The winbar** shows `M-01 · 00:00 · 0 keys · par 40`. Time and keys start with your first key in this buffer.
- **The text** is a corrupted transmission. Words like `YoXur` should read `Your`.

Everything else is your Neovim: your colours, your options, your mappings.

## 5. Repair the text

Any way that works is fine. Two ways, from simple to quick:

- **One by one:** move to each `X` or `Z` and press `x`. That works, but costs many keys.
- **Search and repeat:** type `/\C[XZ]` and `<CR>` to jump to the first stray letter (`\C` makes the search case-sensitive), press `x`, then `n` to jump to the next one and `x` again.

When you think you are done, check it:

```vim
:NeuroVim check
```

If lines are still wrong, Neovim says how many, for example `2 lines still corrupted.` Then `:NeuroVim reveal` highlights them and marks them `◀ differs` at the line end; a mark goes away once its line is right. Fix them and check again.

## 6. Read the result

When the text is right, a window shows the result: the XP you earned (15 for M-01), your time, your keys against par, and your tier. Gold means at most par keys (40 for M-01), silver at most 1.5 × par, bronze at most 2.5 × par. If you missed a tier, the window says how many keys fewer would have reached the next one. The window closes when you move the cursor; `:NeuroVim result` brings it back.

Your progress is saved now. `:NeuroVim` shows M-01 with ✓ and its tier.

## 7. Try for gold

Play M-01 again with `:NeuroVim restart` (in the mission buffer) and record a macro this time: `gg0`, then `qa/\C[XZ]<CR>xq` records "find the next stray letter and delete it" into register `a`, and `29@a` replays it for the other 29 letters. That is 19 keys, well under par: gold. The README's demo shows exactly this run.

Replays earn XP as well, so nothing is lost by playing a mission again.

## 8. Reach level 2

Level 2 needs 66 XP. Solve M-02 to M-04 the same way you solved M-01 (open them from NEXUS). Together with M-01 they give 65 XP, one short of it; your replay of M-01 in step 7 already bridges the gap (80 XP in all). Without the replay, solve KATA-01 as well: KATAs are short drills without a briefing, and `:NeuroVim mission KATA-01` starts it straight away. Once you cross 66 XP, the result window shows **LEVEL UP: 1 → 2** and the missions it unlocked: M-05 to M-08 and three more KATAs.

## Where to go next

- [Troubleshooting](../how-to/troubleshooting.md) if something does not behave as described here.
- [Map keys](../how-to/map-keys.md) for `:NeuroVim check` and friends.
- [Scoring and progress](../explanation/scoring-and-progress.md) for why the game counts keys the way it does and why you will replay missions later on.
- `:help neurovim` for the full manual.
