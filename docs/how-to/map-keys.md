# Map keys

NeuroVim sets no keys of its own; it offers four `<Plug>` mappings for you to put on keys you like. Typing `:NeuroVim check` works just as well and never counts as keys (see the note at the end).

| `<Plug>` mapping | Does |
|---|---|
| `<Plug>(neurovim-nexus)` | `:NeuroVim` — open NEXUS |
| `<Plug>(neurovim-check)` | `:NeuroVim check` |
| `<Plug>(neurovim-reveal)` | `:NeuroVim reveal` |
| `<Plug>(neurovim-restart)` | `:NeuroVim restart` |

## In your config

```lua
vim.keymap.set('n', '<leader>nn', '<Plug>(neurovim-nexus)', { desc = 'NeuroVim: NEXUS' })
vim.keymap.set('n', '<leader>nc', '<Plug>(neurovim-check)', { desc = 'NeuroVim: check' })
vim.keymap.set('n', '<leader>nr', '<Plug>(neurovim-reveal)', { desc = 'NeuroVim: reveal' })
vim.keymap.set('n', '<leader>nR', '<Plug>(neurovim-restart)', { desc = 'NeuroVim: restart' })
```

No `remap = true` is needed: Neovim always applies a `<Plug>` in the right-hand side, even in a non-recursive mapping (`:help <Plug>`). Outside a mission buffer, check, reveal and restart only say that this is not a mission buffer.

## With lazy.nvim

Put the keys into the plugin spec; lazy.nvim then also loads the plugin on the first key press:

```lua
{
  "johannes-kaindl/neurovim.nvim",
  cmd = "NeuroVim",
  keys = {
    { "<leader>nn", "<Plug>(neurovim-nexus)", desc = "NeuroVim: NEXUS" },
    { "<leader>nc", "<Plug>(neurovim-check)", desc = "NeuroVim: check" },
  },
}
```

## The keys of your mapping count

Inside a mission buffer, the keys you press for your mapping count like any other keys: `<leader>nc` costs keys (up to one per key of the mapping, depending on how they reach Neovim), a typed `:NeuroVim check` costs none. For a run where every key matters, type the command. [What counts as a key](../explanation/scoring-and-progress.md#what-counts-as-a-key) has the full rules.
