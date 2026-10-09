local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.rtp:prepend(root)
local ok, T = pcall(require, 'neurovim.kit.test')
if not ok then
  vim.opt.rtp:append(root .. '/../nvim-kit')
  T = require('nvim_kit.test')
end
T.main(root .. '/tests')
