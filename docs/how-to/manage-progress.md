# Back up, move or reset your progress

All progress lives in one file: `state.json` in NeuroVim's folder under Neovim's data directory. `:checkhealth neurovim` shows the exact path; on Linux and macOS it is usually `~/.local/share/nvim/neurovim/state.json`, or `$XDG_DATA_HOME/nvim/neurovim/state.json` if you set `XDG_DATA_HOME`. The file exists only after your first solved mission. What is inside: [the save file reference](../reference/save-file.md).

## Back it up

Copy the file anywhere:

```sh
cp ~/.local/share/nvim/neurovim/state.json ~/neurovim-backup.json
```

Copying while Neovim runs is safe: NeuroVim writes the file atomically (a temporary file renamed over the old one), so a copy is always either the old or the new save, never half of each.

## Move it to another machine

Copy `state.json` into the same place on the other machine, while Neovim is closed there. The other machine needs neurovim.nvim, nothing else. Make sure your user can read and write the copy (`chmod u+rw`): a save NeuroVim cannot read is left alone and nothing is saved until it can — see [Troubleshooting](troubleshooting.md).

## Reset it

Close Neovim and move the file away (or delete it):

```sh
mv ~/.local/share/nvim/neurovim/state.json ~/neurovim-old.json
```

The next `:NeuroVim` starts at level 1 with M-01 to M-04 and KATA-01 open. Moving it back restores everything.

## Play in two Neovims at once

That is fine. Each save re-reads the file right before it writes and applies only its own change, so two Neovim instances do not overwrite each other's wins. NEXUS in the other instance shows the new state the next time it is drawn (open it again with `:NeuroVim`).
