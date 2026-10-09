local T = require('neurovim.kit.test')
local data = require('neurovim.data')

T.case('loads the vendored export with schema 1', function()
  local d = data.get()
  T.eq(d.schema, 1)
  T.eq(#d.missions, 54)
  T.eq(d.levels[1].xp_required, 0)
  T.eq(d.default_unlocked[1], 'M-01')
  T.ok(d.unlock_map['2'], 'unlock_map keys are strings')
end)

T.case('every mission carries a solution and an objective', function()
  for _, m in ipairs(data.get().missions) do
    T.ok(type(m.solution) == 'string' and #m.solution > 0, m.id .. ' solution')
    T.ok(type(m.objective) == 'table' and #m.objective > 0, m.id .. ' objective')
  end
end)

T.case('counter-check: a file with another schema is refused', function()
  local kit = require('neurovim.kit.data')
  T.raises(function()
    kit.load(data.path(), { schema = 2 })
  end, 'expected 2')
end)

T.case('default_plugin_data is exact: nulls and empty objects survive', function()
  local d = data.default_plugin_data()
  T.eq(d.unlocked, data.get().default_unlocked)
  T.eq(d.railPin, vim.NIL)
  T.eq(d.sandbox_bests.easy, vim.NIL)
  T.json_eq(d.missions, '{}')
  T.json_eq(d.healedFrontmatters, '{}')
end)

T.case('default_plugin_data hands out a fresh copy every time', function()
  local a = data.default_plugin_data()
  a.unlocked[1] = 'CHANGED'
  T.eq(data.default_plugin_data().unlocked[1], 'M-01')
end)
