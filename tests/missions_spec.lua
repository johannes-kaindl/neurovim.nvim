local T = require('neurovim.kit.test')
local missions = require('neurovim.missions')
local data = require('neurovim.data')
local diff = require('neurovim.rules.diff')

T.case('54 missions: 40 story in 10 chapters, then 14 KATAs in their own section', function()
  T.eq(#missions.all(), 54)
  T.eq(#missions.story(), 40)
  T.eq(#missions.katas(), 14)
  local chapters = missions.chapters()
  T.eq(#chapters, 11)
  T.eq(chapters[11].label, 'KATAS')
  T.eq(#chapters[11].missions, 14)
  T.eq(missions.get('KATA-01').title, 'Word Sprint')
end)

T.case('every mission: its solution matches, its raw text does not', function()
  for _, m in ipairs(missions.all()) do
    T.ok(diff.get_diff(m.solution, m.solution).matches, m.id .. ' solution')
    T.ok(not diff.get_diff(m.transmission, m.solution).matches, m.id .. ' raw text')
  end
end)

T.case('status: open, done with tier, locked with its unlock level', function()
  local s = data.default_plugin_data()
  T.eq(missions.status(s, missions.get('M-01')), { kind = 'open' })
  T.eq(missions.status(s, missions.get('M-09')), { kind = 'locked', unlock_level = 3 })
  s.completed_missions = { 'M-01' }
  s.missions =
    { ['M-01'] = { best_keystrokes = 10, best_time_ms = 1, best_ks_per_min = 1, runs = 1, last_run = '' } }
  T.eq(missions.status(s, missions.get('M-01')), { kind = 'done', tier = 'gold' })
end)

local function solved(ids, xp)
  local s = data.default_plugin_data()
  s.unlocked, s.completed_missions, s.total_xp = vim.deepcopy(ids), vim.deepcopy(ids), xp
  return s
end

T.case('next_unlock: nil while a free mission is open', function()
  T.eq(missions.next_unlock(data.default_plugin_data()), nil)
end)

T.case('next_unlock: the next level, its XP and what it unlocks, once everything free is solved', function()
  local n = missions.next_unlock(solved({ 'M-01', 'M-02', 'M-03', 'M-04', 'KATA-01' }, 60))
  T.eq(n.level, 2)
  T.eq(n.xp, 66)
  T.eq(n.ids, { 'M-05', 'M-06', 'M-07', 'M-08', 'KATA-02', 'KATA-03', 'KATA-12' })
end)

T.case('next_unlock: nil when nothing is locked any more', function()
  local ids = vim.tbl_map(function(m)
    return m.id
  end, missions.all())
  T.eq(missions.next_unlock(solved(ids, 2500)), nil)
end)
