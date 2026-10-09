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
  local win = result.show({ '# Probe' })
  T.ok(vim.api.nvim_win_is_valid(win))
  T.eq(vim.api.nvim_win_get_config(win).relative ~= '', true)
  vim.api.nvim_win_close(win, true)
end)
