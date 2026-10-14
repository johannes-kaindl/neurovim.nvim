local T = require('neurovim.kit.test')
local state = require('neurovim.state')
local missions = require('neurovim.missions')
local mission = require('neurovim.ui.mission')
local completion = require('neurovim.rules.completion')
local progression = require('neurovim.rules.progression')
local data = require('neurovim.data')

vim.g.loaded_neurovim = nil
vim.cmd.runtime('plugin/neurovim.lua')

-- Each case plays from its own empty save and gives the data dir back afterwards, also when it fails:
-- spec files share one Neovim, and later specs expect the save tests/run.lua set up.
local function with_fresh_save(fn)
  local before = vim.env.XDG_DATA_HOME
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  local ok, err = pcall(fn)
  vim.env.XDG_DATA_HOME = before
  if not ok then
    error(err, 0)
  end
end

local function quiet(fn)
  local seen, orig = {}, vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = orig
  assert(ok, err)
  return seen
end

local function close_floats()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= '' then
      vim.api.nvim_win_close(w, true)
    end
  end
end

local function float_text()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= '' then
      return table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false), '\n')
    end
  end
  return ''
end

local function typed(k)
  -- :silent keeps the echo of typed searches and commands out of the test report; keys still count.
  vim.g.neurovim_test_keys = vim.api.nvim_replace_termcodes(k, true, false, true)
  vim.cmd('silent call feedkeys(g:neurovim_test_keys, "ntx")')
  vim.g.neurovim_test_keys = nil
end

local function mapped(k)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), 'tx', false)
end

local function open_through_command(m)
  -- A run of this mission left open by an earlier spec would be resumed, not started.
  local old = vim.fn.bufnr('neurovim://' .. m.id)
  if old > 0 then
    vim.cmd('bwipeout! ' .. old)
  end
  quiet(function()
    vim.cmd('NeuroVim mission ' .. m.id)
  end)
  if m.briefing ~= '' then
    T.eq(vim.api.nvim_buf_get_name(0), 'neurovim://briefing/' .. m.id, m.id .. ' briefing')
    mapped('<CR>')
  end
  T.eq(vim.api.nvim_buf_get_name(0), 'neurovim://' .. m.id, m.id .. ' mission buffer')
  return vim.api.nvim_get_current_buf()
end

T.case('all 54 missions through :NeuroVim — raw text fails, the solution wins and is saved', function()
  with_fresh_save(function()
    state.update(function(s)
      s.unlocked = vim.tbl_map(function(m)
        return m.id
      end, missions.all())
      return s
    end)
    for _, m in ipairs(missions.all()) do
      local before = state.load()
      local buf = open_through_command(m)
      local seen = quiet(function()
        vim.cmd('NeuroVim check')
      end)
      T.ok(seen[1] and seen[1].msg:find('still corrupted', 1, true), m.id .. ': raw text must not pass')
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(m.solution, '\n', { plain = true }))
      quiet(function()
        vim.cmd('NeuroVim check')
      end)
      T.ok(float_text():find('TRANSMISSION RESTORED — ' .. m.id, 1, true), m.id .. ': result float')
      close_floats()
      local after = state.load()
      T.ok(vim.tbl_contains(after.completed_missions, m.id), m.id .. ' completed')
      T.eq(after.total_xp, before.total_xp + m.xp_reward, m.id .. ' xp')
      T.eq(after.missions[m.id].runs, 1, m.id .. ' runs')
    end
    local r = require('neurovim.ui.nexus').render(state.load())
    for _, l in ipairs(r.lines) do
      T.ok(not l:find('🔒', 1, true), 'still locked: ' .. l)
    end
  end)
end)

T.case('M-01 with real keys and the typed :NeuroVim check: level 2, unlocks, bests, NEXUS', function()
  with_fresh_save(function()
    -- 60 XP from the other free missions (pasted), so that M-01's 15 XP crosses level 2 at 66.
    for _, id in ipairs({ 'M-02', 'M-03', 'M-04', 'KATA-01' }) do
      local m = missions.get(id)
      local buf = open_through_command(m)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(m.solution, '\n', { plain = true }))
      quiet(function()
        vim.cmd('NeuroVim check')
      end)
      close_floats()
    end
    T.eq(state.load().total_xp, 60)
    local buf = open_through_command(missions.get('M-01'))
    quiet(function()
      typed('gg0qa/\\C[XZ]<CR>xq29@a:NeuroVim check<CR>')
    end)
    local f = float_text()
    T.ok(f:find('LEVEL UP: 1 → 2', 1, true), f)
    T.ok(f:find('M-05', 1, true) and f:find('KATA-02', 1, true), f)
    local par = missions.par(missions.get('M-01'))
    T.ok(19 <= par, 'M-01 par ' .. par .. ' must allow GOLD at 19 keys')
    T.ok(f:find(('Time %%d%%d:%%d%%d · 19 keys · par %d'):format(par)), f)
    T.ok(f:find('Tier: GOLD', 1, true), f)
    close_floats()
    local s = state.load()
    T.eq(s.total_xp, 75)
    T.eq(s.missions['M-01'].best_keystrokes, 19)
    T.eq(type(s.missions['M-01'].best_time_ms), 'number')
    T.ok(vim.tbl_contains(s.unlocked, 'M-05'))
    local r = require('neurovim.ui.nexus').render(s)
    for _, l in ipairs(r.lines) do
      if l:find('M-05', 1, true) then
        T.ok(not l:find('🔒', 1, true), l)
      end
    end
    T.ok(mission.run(buf).done)
  end)
end)

T.case('the way through the game: every mission reachable, replays only at the measured walls', function()
  local s = progression.backfill_unlocks(data.default_plugin_data())
  local played, walls = {}, {}
  local function play(m)
    s = completion.complete_mission(s, {
      mission_id = m.id,
      xp_reward = m.xp_reward,
      par_keystrokes = m.par_keystrokes,
      difficulty = m.difficulty,
    }, { elapsed_ms = 1000, keystrokes = 10, ks_per_min = 600 }, '2026-10-09').data
  end
  while vim.tbl_count(played) < #missions.all() do
    local any = false
    for _, m in ipairs(missions.all()) do
      if not played[m.id] and vim.tbl_contains(s.unlocked, m.id) then
        play(m)
        played[m.id] = true
        any = true
      end
    end
    if not any then
      walls[#walls + 1] = s.total_xp
      T.ok(missions.next_unlock(s), 'a wall without a replay hint at ' .. s.total_xp .. ' XP')
      local best
      for id in pairs(played) do
        local m = missions.get(id)
        if not best or m.xp_reward > best.xp_reward then
          best = m
        end
      end
      play(best)
    end
  end
  T.eq(walls, { 955, 1035, 1115, 1465, 1545, 1780, 1860, 1940 })
end)

T.case(
  'a save that cannot be read: check wins nothing and keeps the run, a second check after the fix saves it',
  function()
    close_floats() -- a float left open by a failed case before would read as this case's result
    with_fresh_save(function()
      state.update(function(s)
        return s
      end)
      local m = missions.get('M-01')
      local buf = open_through_command(m)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(m.solution, '\n'))
      vim.fn.setfperm(state.path(), '---------')
      local first
      local seen = quiet(function()
        first = mission.check(buf)
      end)
      vim.fn.setfperm(state.path(), 'rw-r--r--')
      T.eq(first, 'save-failed')
      T.ok(
        vim.iter(seen):any(function(n)
          return n.level == vim.log.levels.ERROR and n.msg:find('cannot read', 1, true) ~= nil
        end),
        vim.inspect(seen)
      )
      T.eq(float_text(), '')
      T.eq(state.load().completed_missions, {})
      local second
      quiet(function()
        second = mission.check(buf)
      end)
      T.eq(second, 'match')
      T.eq(state.load().completed_missions, { 'M-01' })
      close_floats()
      vim.cmd('bwipeout!')
    end)
  end
)

T.case('a second check of a solved run points to :NeuroVim result, which shows that result', function()
  with_fresh_save(function()
    close_floats()
    local m = missions.get('M-01')
    local buf = mission.start(m.id, { fresh = true })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(m.solution, '\n', { plain = true }))
    quiet(function()
      mission.check(buf)
    end)
    local first = float_text()
    close_floats()
    local seen = quiet(function()
      mission.check(buf)
    end)
    T.eq(
      seen[1].msg,
      'Transmission already restored — :NeuroVim result shows the result again, :NeuroVim restart plays the mission again.'
    )
    require('neurovim.command').run({ 'result' })
    T.eq(float_text(), first)
    T.ok(first:find('TRANSMISSION RESTORED — M-01', 1, true), first)
    close_floats()
  end)
end)

-- Keys count only in the mission buffer, so an edit made from another buffer (:bufdo, :windo, a
-- command typed elsewhere) would be free. Decision Johannes 2026-10-14: such a run is unverified —
-- its XP counts, its bests do not, as for a paste.
local function solve_from(where)
  local m = missions.get('M-01')
  vim.g.neurovim_test_solution = m.solution
  local buf = mission.start(m.id, { fresh = true })
  typed('x')
  if where == 'outside' then
    vim.cmd('split')
    vim.cmd('enew')
  end
  typed(
    (':lua vim.api.nvim_buf_set_lines(%d, 0, -1, false, vim.split(vim.g.neurovim_test_solution, "\\n"))<CR>'):format(
      buf
    )
  )
  vim.cmd('silent! only')
  vim.api.nvim_set_current_buf(buf)
  quiet(function()
    T.eq(mission.check(buf), 'match')
  end)
  vim.g.neurovim_test_solution = nil
  return float_text()
end

T.case('an edit made from outside the mission buffer wins the XP but sets no best', function()
  with_fresh_save(function()
    close_floats()
    local f = solve_from('outside')
    close_floats()
    T.ok(f:find('changed from outside the mission buffer', 1, true), f)
    local s = state.load()
    T.eq(s.total_xp, missions.get('M-01').xp_reward)
    T.eq(s.missions['M-01'].best_keystrokes, 0)
  end)
end)

T.case('counter-check: the same command typed in the mission buffer is a normal run', function()
  with_fresh_save(function()
    close_floats()
    local f = solve_from('inside')
    close_floats()
    T.ok(not f:find('outside', 1, true), f)
    T.ok(state.load().missions['M-01'].best_keystrokes > 0)
  end)
end)
