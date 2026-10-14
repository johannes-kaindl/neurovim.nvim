-- What counts as a key (:help neurovim-keys), decisions Johannes 2026-10-14: the keys of a mapping
-- always count (F1); a :NeuroVim command typed in the mission buffer is free, run or abandoned,
-- other abandoned commands count (F2); a command after which the mission buffer is no longer
-- current and unchanged is free (F3). Time stops while the mission buffer is not current.
local T = require('neurovim.kit.test')
local mission = require('neurovim.ui.mission')

-- Keys go in through mappings (no n flag): F1 is about mappings. :silent keeps the echo of typed
-- commands out of the test report; the keys still count.
local function typed(k)
  vim.g.neurovim_test_keys = vim.api.nvim_replace_termcodes(k, true, false, true)
  vim.cmd('silent call feedkeys(g:neurovim_test_keys, "tx")')
  vim.g.neurovim_test_keys = nil
end

local function quiet(fn)
  local orig = vim.notify
  vim.notify = function() end
  local ok, err = pcall(fn)
  vim.notify = orig
  if not ok then
    error(err, 0)
  end
end

-- Plays k in a fresh M-01 run and returns the keys it cost, back in the mission buffer. F3 takes
-- the cost back in a scheduled callback, after the command ran: wait for it before going back.
local function cost(k)
  local buf = mission.start('M-01', { fresh = true })
  quiet(function()
    typed(k)
  end)
  vim.wait(20)
  vim.cmd('silent! only')
  vim.api.nvim_set_current_buf(buf)
  return mission.run(buf).tracker.keys(), buf
end

T.case('F2: :NeuroVim typed out or abbreviated is free, run or abandoned', function()
  T.eq(cost(':NeuroVim reveal<CR>'), 0)
  T.eq(cost(':Neuro reveal<CR>'), 0)
  T.eq(cost(':silent NeuroVim reveal<CR>'), 0)
  T.eq(cost(':NeuroVim che<Esc>'), 0)
end)

T.case('counter-check F2: other commands count, abandoned ones too', function()
  T.eq(cost(':Ne<Esc>'), 4) -- :Ne is :Next, not :NeuroVim
  T.eq(cost(':s/foo<Esc>'), 7)
  T.eq(cost('/foo<Esc>'), 5)
end)

T.case('F1: the keys of a mapping count, also when it runs :NeuroVim', function()
  local leader = vim.g.mapleader
  vim.g.mapleader = ' '
  vim.keymap.set('n', '<F5>', ':NeuroVim reveal<CR>')
  vim.keymap.set('n', '<leader>c', ':NeuroVim reveal<CR>')
  vim.keymap.set('n', '<leader>p', '<Plug>(neurovim-reveal)')
  local ok, err = pcall(function()
    T.eq(cost('<F5>'), 1)
    T.eq(cost(' c'), 2)
    T.eq(cost(' p'), 2)
  end)
  for _, lhs in ipairs({ '<F5>', '<leader>c', '<leader>p' }) do
    pcall(vim.keymap.del, 'n', lhs)
  end
  vim.g.mapleader = leader
  assert(ok, err)
end)

-- q: costs the q; the : and what is typed in the window belong to the command.
T.case('q: with a :NeuroVim command costs the q, with another command every key', function()
  T.eq(cost('q:iNeuroVim reveal<CR>'), 1)
  T.eq(cost('q:i1d<CR>'), 6)
end)

T.case('F3: a command that leaves the mission buffer unchanged is free', function()
  T.eq(cost(':help<CR>'), 0)
  T.eq(cost(':enew<CR>'), 0)
end)

T.case('counter-check F3: a command that changes the text and leaves counts', function()
  T.eq(cost(':1d|enew<CR>'), 9)
  T.eq(cost(':1d<CR>'), 4)
end)

-- A command typed in a command-line window opened from the mission buffer is typed in the
-- mission: its edit is not one from outside.
T.case('an edit run from q: is not an edit from outside', function()
  local _, buf = cost('xq:i1d<CR>')
  T.eq(mission.run(buf).outside, nil)
end)

T.case('counter-check: the same edit typed in another buffer is one from outside', function()
  local buf = mission.start('M-01', { fresh = true })
  vim.cmd('enew')
  quiet(function()
    typed((':call nvim_buf_set_lines(%d, 0, 1, v:false, [])<CR>'):format(buf))
  end)
  vim.api.nvim_set_current_buf(buf)
  T.eq(mission.run(buf).outside, true)
end)

T.case('time stops while the mission buffer is not current', function()
  local buf = mission.start('M-01', { fresh = true })
  typed('l')
  vim.cmd('enew')
  vim.wait(300)
  vim.api.nvim_set_current_buf(buf)
  T.ok(mission.run(buf).tracker.elapsed_ms() < 150, tostring(mission.run(buf).tracker.elapsed_ms()))
end)

T.case('counter-check: time runs while the mission buffer stays current', function()
  local buf = mission.start('M-01', { fresh = true })
  typed('l')
  vim.wait(300)
  T.ok(mission.run(buf).tracker.elapsed_ms() >= 250, tostring(mission.run(buf).tracker.elapsed_ms()))
end)
