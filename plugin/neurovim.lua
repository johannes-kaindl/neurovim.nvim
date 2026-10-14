if vim.g.loaded_neurovim then
  return
end
vim.g.loaded_neurovim = true

if vim.fn.has('nvim-0.10') == 0 then
  vim.notify('neurovim.nvim needs Neovim 0.10 or newer.', vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command('NeuroVim', function(o)
  require('neurovim.command').run(o.fargs)
end, {
  nargs = '*',
  desc = 'NeuroVim: NEXUS, missions, check',
  complete = function(arglead, cmdline)
    return require('neurovim.command').complete(arglead, cmdline)
  end,
})

for name, args in pairs({ nexus = {}, check = { 'check' }, reveal = { 'reveal' }, restart = { 'restart' } }) do
  vim.keymap.set('n', ('<Plug>(neurovim-%s)'):format(name), function()
    require('neurovim.command').run(args)
  end, { desc = 'NeuroVim: ' .. name })
end

local group = vim.api.nvim_create_augroup('neurovim', { clear = true })
vim.api.nvim_create_autocmd('SessionLoadPost', {
  group = group,
  callback = function()
    require('neurovim.session').sweep()
  end,
})
vim.api.nvim_create_autocmd('BufReadCmd', {
  group = group,
  pattern = 'neurovim://*',
  callback = function(ev)
    require('neurovim.session').read(ev.buf)
  end,
})
-- Loaded lazily (lazy.nvim `cmd`), the plugin comes after the session: clear what it left now.
if vim.v.vim_did_enter == 1 then
  require('neurovim.session').sweep()
end
