local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.rtp:prepend(root)
-- Tests never touch the player's real save: stdpath('data') follows XDG_DATA_HOME at call time.
vim.env.XDG_DATA_HOME = vim.fn.tempname()
-- Keep mode messages and the search count out of the test report.
vim.o.showmode = false
vim.opt.shortmess:append('Sq')
require('neurovim.kit.test').main(root .. '/tests')
