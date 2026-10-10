local T = require('neurovim.kit.test')
local command = require('neurovim.command')

local function keys(k)
  -- :silent keeps the echo of typed searches and commands out of the test report; keys still count.
  vim.g.neurovim_test_keys = vim.api.nvim_replace_termcodes(k, true, false, true)
  vim.cmd('silent call feedkeys(g:neurovim_test_keys, "ntx")')
  vim.g.neurovim_test_keys = nil
end

T.case('the plugin file adds the command and only <Plug> mappings', function()
  local before = {}
  for _, m in ipairs(vim.api.nvim_get_keymap('n')) do
    before[m.lhs] = true
  end
  vim.g.loaded_neurovim = nil
  vim.cmd.runtime('plugin/neurovim.lua')
  T.eq(vim.fn.exists(':NeuroVim'), 2)
  local added = {}
  for _, m in ipairs(vim.api.nvim_get_keymap('n')) do
    if not before[m.lhs] then
      added[#added + 1] = m.lhs
    end
  end
  table.sort(added)
  T.eq(added, {
    '<Plug>(neurovim-check)',
    '<Plug>(neurovim-nexus)',
    '<Plug>(neurovim-restart)',
    '<Plug>(neurovim-reveal)',
  })
end)

T.case('completion: subcommands, then mission ids (story, then KATA)', function()
  T.eq(command.complete('', 'NeuroVim '), { 'check', 'mission', 'restart', 'reveal' })
  T.eq(command.complete('m', 'NeuroVim m'), { 'mission' })
  T.eq(#command.complete('M-0', 'NeuroVim mission M-0'), 9)
  T.eq(#command.complete('KATA', 'NeuroVim mission KATA'), 14)
  T.eq(
    command.complete('kata-1', 'NeuroVim mission kata-1'),
    { 'KATA-10', 'KATA-11', 'KATA-12', 'KATA-13', 'KATA-14' }
  )
  T.eq(#command.complete('r-2', 'NeuroVim mission r-2'), 5)
end)

T.case('an unknown subcommand is reported', function()
  local seen, orig = {}, vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  command.run({ 'bogus' })
  vim.notify = orig
  T.eq(seen[1].level, vim.log.levels.ERROR)
  T.ok(seen[1].msg:find('bogus', 1, true))
end)

T.case('typing :NeuroVim check does not count as keystrokes', function()
  vim.cmd.runtime('plugin/neurovim.lua')
  local orig = vim.notify
  vim.notify = function() end
  local mission = require('neurovim.ui.mission')
  local buf = mission.start('M-02')
  keys('x:NeuroVim check<CR>')
  vim.notify = orig
  T.eq(mission.run(buf).tracker.keys(), 1)
end)

local function notices(fn)
  local seen, orig = {}, vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = orig
  assert(ok, err)
  return seen
end

T.case('mission ids in lower case go through :NeuroVim mission too', function()
  notices(function()
    command.run({ 'mission', 'm-01' })
  end)
  T.eq(vim.api.nvim_buf_get_name(0), 'neurovim://briefing/M-01')
  vim.cmd('bwipeout!')
end)

T.case("setup() exists for lazy.nvim's opts = {}: it changes nothing and says nothing", function()
  local maps = #vim.api.nvim_get_keymap('n')
  local seen = notices(function()
    require('neurovim').setup()
    require('neurovim').setup({})
  end)
  T.eq(seen, {})
  T.eq(#vim.api.nvim_get_keymap('n'), maps)
end)

T.case('setup() with options warns that NeuroVim has none, naming them', function()
  local seen = notices(function()
    require('neurovim').setup({ keys = true })
  end)
  T.eq(#seen, 1)
  T.eq(seen[1].level, vim.log.levels.WARN)
  T.ok(seen[1].msg:find('keys', 1, true), seen[1].msg)
end)
