local T = require('neurovim.kit.test')
local nexus = require('neurovim.ui.nexus')
local data = require('neurovim.data')

local function find(lines, needle)
  for i, l in ipairs(lines) do
    if l:find(needle, 1, true) then
      return i, l
    end
  end
end

T.case('render: status block, chapters, marks', function()
  local s = data.default_plugin_data()
  s.total_xp = 100
  s.streak_current = 3
  s.unlocked = { 'M-01', 'M-02', 'M-03', 'M-04', 'M-05' }
  s.completed_missions = { 'M-01' }
  s.missions =
    { ['M-01'] = { best_keystrokes = 10, best_time_ms = 1, best_ks_per_min = 1, runs = 1, last_run = '' } }
  local r = nexus.render(s)
  T.ok(find(r.lines, 'Level 2 · GHOST OPERATOR · 100 XP'), vim.inspect(r.lines))
  T.ok(find(r.lines, '28%'), 'xp bar')
  T.ok(find(r.lines, 'Streak: 3 days'))
  T.ok(find(r.lines, '01 INDOCTRINATION'))
  local i1, l1 = find(r.lines, 'M-01')
  T.ok(l1:find('✓', 1, true) and l1:find('gold', 1, true), l1)
  T.eq(r.rows[i1], 'M-01')
  local _, l9 = find(r.lines, 'M-09')
  T.ok(l9:find('🔒', 1, true) and l9:find('level 3', 1, true), l9)
  T.ok(find(r.lines, 'KATAS'), 'KATA section')
  T.ok(find(r.lines, 'KATA-01'), 'KATA-01 listed')
end)

T.case('render at max level shows a full bar without a next level', function()
  local s = data.default_plugin_data()
  s.total_xp = 99999
  local r = nexus.render(s)
  T.ok(find(r.lines, 'max level'), vim.inspect(r.lines))
end)

T.case('show: <CR> on a locked mission says so and opens nothing', function()
  local seen = {}
  local orig = vim.notify
  vim.notify = function(msg)
    seen[#seen + 1] = msg
  end
  local buf = nexus.show()
  local lnum
  for i, id in pairs(vim.b[buf].neurovim_rows) do
    if id == 'M-09' then
      lnum = tonumber(i)
    end
  end
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'tx', false) -- mapped key: no n flag
  vim.notify = orig
  T.eq(vim.api.nvim_get_current_buf(), buf)
  T.ok(seen[1] and seen[1]:find('M-09 is locked', 1, true), vim.inspect(seen))
end)

T.case('NEXUS shows the replay hint only when every free mission is solved', function()
  local s = data.default_plugin_data()
  T.eq(find(nexus.render(s).lines, 'Replay solved missions'), nil)
  s.completed_missions = vim.deepcopy(s.unlocked)
  s.total_xp = 60
  local _, line = find(nexus.render(s).lines, 'Replay solved missions')
  T.eq(
    line,
    'Replay solved missions for XP — level 2 (66 XP) unlocks M-05, M-06, M-07, M-08, KATA-02, KATA-03, KATA-12.'
  )
end)
