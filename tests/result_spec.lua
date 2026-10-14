local T = require('neurovim.kit.test')
local result = require('neurovim.ui.result')
local missions = require('neurovim.missions')

local function has(lines, needle)
  for _, l in ipairs(lines) do
    if l:find(needle, 1, true) then
      return true
    end
  end
  return false
end

T.case('result text: XP, time, keys, tier, bests, streak', function()
  local m = missions.get('M-01')
  local outcome = {
    xp = 15,
    par = 40,
    tier = 'silver',
    to_next_tier = { nextTier = 'gold', delta = 12 },
    record = {
      best_time_ms = 70000,
      best_keystrokes = 50,
      best_ks_per_min = 40,
      runs = 2,
      last_run = '2026-10-09',
    },
  }
  local s = { total_xp = 30, streak_current = 2 }
  local lines = result.lines(outcome, s, m, { elapsed_ms = 83000, keystrokes = 52, ks_per_min = 37.6 })
  T.ok(has(lines, 'TRANSMISSION RESTORED — M-01'), vim.inspect(lines))
  T.ok(has(lines, '+15 XP'))
  T.ok(has(lines, '01:23 · 52 keys · par 40'))
  T.ok(has(lines, 'SILVER'))
  T.ok(has(lines, '12 fewer keys for gold'))
  T.ok(has(lines, 'Best: 01:10 · 50 keys'))
  T.ok(has(lines, 'Streak: 2 days'))
end)

T.case('result text: level-up lists the unlocked missions and KATAs by title', function()
  local m = missions.get('M-04')
  local outcome = {
    xp = 20,
    par = 60,
    record = { best_time_ms = 1, best_keystrokes = 1, best_ks_per_min = 1, runs = 1, last_run = '' },
    level_up = {
      old_level = 1,
      new_level = 2,
      unlocked_missions = { 'M-05', 'KATA-02' },
      unlocked_loot = { 'LOOT-01' },
    },
  }
  local lines = result.lines(
    outcome,
    { total_xp = 70, streak_current = 1 },
    m,
    { elapsed_ms = 1, keystrokes = 1, ks_per_min = 0 }
  )
  T.ok(has(lines, 'LEVEL UP'), vim.inspect(lines))
  T.ok(has(lines, 'M-05'))
  T.ok(has(lines, 'KATA-02'), 'KATA unlocks are shown')
end)

T.case('result text: a run without a keystroke counts, its bests do not', function()
  local m = missions.get('M-01')
  local outcome = {
    xp = 15,
    par = 40,
    unverified = true,
    record = { best_time_ms = 0, best_keystrokes = 0, best_ks_per_min = 0, runs = 1, last_run = '2026-10-09' },
  }
  local lines = result.lines(
    outcome,
    { total_xp = 15, streak_current = 1 },
    m,
    { elapsed_ms = 900, keystrokes = 0, ks_per_min = 0 }
  )
  T.ok(has(lines, 'No keystroke was counted'), vim.inspect(lines))
  T.ok(not has(lines, 'Best:'))
  T.ok(not has(lines, 'Tier:'))
end)

T.case('the float opens without any language server', function()
  local win = result.show({ 'Probe' })
  T.ok(vim.api.nvim_win_is_valid(win))
  T.eq(vim.api.nvim_win_get_config(win).relative ~= '', true)
  vim.api.nvim_win_close(win, true)
end)

local function level_up_lines()
  return result.lines(
    {
      xp = 20,
      par = 60,
      record = { best_time_ms = 1, best_keystrokes = 1, best_ks_per_min = 1, runs = 1, last_run = '' },
      level_up = { old_level = 1, new_level = 2, unlocked_missions = { 'M-05' }, unlocked_loot = {} },
    },
    { total_xp = 70, streak_current = 1 },
    missions.get('M-04'),
    { elapsed_ms = 1, keystrokes = 1, ks_per_min = 0 }
  )
end

T.case('result text: plain text, no Markdown marks (the float does not render Markdown)', function()
  for _, l in ipairs(level_up_lines()) do
    T.ok(not l:find('^#') and not l:find('**', 1, true), l)
  end
end)

T.case('result text: a level-up names the new level; the last line says what comes next', function()
  local lines = level_up_lines()
  T.ok(has(lines, 'LEVEL UP: 1 → 2 · GHOST OPERATOR'), vim.inspect(lines))
  T.ok(lines[#lines]:find(':NeuroVim opens NEXUS', 1, true), lines[#lines])
end)

-- Measured 2026-10-14 in a terminal: after a "Press ENTER" prompt (three :s in one line), the
-- CursorMoved of the :s jump fires only after :NeuroVim check, and closed the float at once.
-- Headless Neovim never fires CursorMoved itself, so the test raises it.
T.case('the float survives a CursorMoved that arrives late, without the cursor moving', function()
  vim.cmd('enew')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  local win = result.show({ 'Probe' })
  vim.wait(20) -- the event loop runs, as it does after the prompt; scheduled work is done
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = 0 })
  vim.wait(20) -- a close may be scheduled too
  T.eq(vim.api.nvim_win_is_valid(win), true)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = 0 })
  vim.wait(20)
  T.eq(vim.api.nvim_win_is_valid(win), false)
  vim.cmd('bwipeout!')
end)

T.case('the title and the level-up line are highlighted', function()
  local win = result.show(level_up_lines())
  local buf = vim.api.nvim_win_get_buf(win)
  local hl = {}
  for _, mk in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    hl[mk[2] + 1] = mk[4].hl_group
  end
  vim.api.nvim_win_close(win, true)
  T.eq(hl[1], 'Title')
  local lines = level_up_lines()
  for i, l in ipairs(lines) do
    if l:find('^LEVEL UP') then
      T.eq(hl[i], 'Title', l)
    end
  end
end)

T.case(':NeuroVim result shows the last result again; one float, not two', function()
  local first = result.show({ 'Result one' })
  vim.api.nvim_win_close(first, true)
  require('neurovim.command').run({ 'result' })
  local floats = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= '' then
      floats[#floats + 1] = w
    end
  end
  T.eq(#floats, 1)
  T.eq(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(floats[1]), 0, -1, false), { 'Result one' })
  local again = require('neurovim.command').run({ 'result' })
  local n = 0
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    n = n + (vim.api.nvim_win_get_config(w).relative ~= '' and 1 or 0)
  end
  T.eq(n, 1)
  vim.api.nvim_win_close(again, true)
end)
