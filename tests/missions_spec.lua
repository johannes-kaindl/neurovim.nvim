local T = require('neurovim.kit.test')
local missions = require('neurovim.missions')
local data = require('neurovim.data')
local diff = require('neurovim.rules.diff')

T.case('story missions: 40, no KATA, in 10 chapters', function()
  T.eq(#missions.story(), 40)
  for _, m in ipairs(missions.story()) do
    T.ok(not m.kata, m.id)
  end
  T.eq(missions.get('KATA-01'), nil)
  T.eq(missions.get('M-01').title, 'The Three Modes')
  local n = 0
  for _, c in ipairs(missions.chapters()) do
    n = n + #c.missions
  end
  T.eq(#missions.chapters(), 10)
  T.eq(n, 40)
end)

T.case('every story mission: its solution matches, its raw text does not', function()
  for _, m in ipairs(missions.story()) do
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
