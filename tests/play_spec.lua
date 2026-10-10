local T = require('neurovim.kit.test')
local mission = require('neurovim.ui.mission')
local state = require('neurovim.state')

local function keys(k)
  -- :silent keeps the echo of typed searches and commands out of the test report; keys still count.
  vim.g.neurovim_test_keys = vim.api.nvim_replace_termcodes(k, true, false, true)
  vim.cmd('silent call feedkeys(g:neurovim_test_keys, "ntx")')
  vim.g.neurovim_test_keys = nil
end

local function quiet(fn)
  local seen, orig = {}, vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, a = pcall(fn)
  vim.notify = orig
  assert(ok, a)
  return a, seen
end

T.case('a wrong text: lines off, nothing saved', function()
  local before = state.load().total_xp
  mission.start('M-01')
  local outcome, seen = quiet(function()
    return mission.check()
  end)
  T.eq(outcome, 'mismatch')
  T.ok(seen[1].msg:find('still corrupted', 1, true), seen[1].msg)
  T.eq(state.load().total_xp, before)
end)

T.case('reveal marks the divergent lines, clamped to the buffer', function()
  local buf = mission.start('M-01')
  local marked = mission.reveal(buf)
  T.ok(#marked > 0)
  local last = vim.api.nvim_buf_line_count(buf) - 1
  for _, l in ipairs(marked) do
    T.ok(l <= last, tostring(l))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'short' })
  local clamped = mission.reveal(buf)
  for _, l in ipairs(clamped) do
    T.eq(l, 0)
  end
end)

T.case('M-01 played with real keys: saved once, XP, unlocks, bests', function()
  local buf = mission.start('M-01')
  keys('gg0qa/\\C[XZ]<CR>xq29@a')
  local outcome = quiet(function()
    return mission.check(buf)
  end)
  T.eq(outcome, 'match')
  local s = state.load()
  T.eq(s.total_xp, 15)
  T.ok(vim.tbl_contains(s.completed_missions, 'M-01'))
  T.eq(s.missions['M-01'].runs, 1)
  T.eq(s.missions['M-01'].best_keystrokes, 19)
  T.eq(
    quiet(function()
      return mission.check(buf)
    end),
    'already'
  )
  T.eq(state.load().total_xp, 15)
end)

-- Runs after the M-01 case above (cases run in file order): M-01 has bests of 19 keys by now.
T.case('a solution pasted without a keystroke wins its XP but keeps the bests', function()
  local before = state.load()
  T.eq(before.missions['M-01'].best_keystrokes, 19)
  local buf = mission.start('M-01')
  local m = require('neurovim.missions').get('M-01')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(m.solution, '\n', { plain = true }))
  T.eq(
    quiet(function()
      return mission.check(buf)
    end),
    'match'
  )
  local s = state.load()
  T.eq(s.total_xp, before.total_xp + m.xp_reward)
  T.eq(s.missions['M-01'].runs, 2)
  T.eq(s.missions['M-01'].best_keystrokes, 19)
end)

T.case('check outside a mission buffer reports instead of throwing', function()
  vim.cmd('enew')
  local outcome, seen = quiet(function()
    return mission.check()
  end)
  T.eq(outcome, 'not-a-mission')
  T.eq(seen[1].level, vim.log.levels.ERROR)
end)
