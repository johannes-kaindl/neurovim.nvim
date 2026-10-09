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
