-- Minimal config for the README demo (make demo): this checkout, Neovim's defaults, nothing else.
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
vim.opt.rtp:prepend(root)
vim.o.number = true
vim.o.termguicolors = true
vim.o.laststatus = 2
vim.o.hlsearch = false -- the macro's search would mark every X, also in "XP" of the result
vim.o.shortmess = vim.o.shortmess .. 'I'
vim.cmd.runtime('plugin/neurovim.lua')
