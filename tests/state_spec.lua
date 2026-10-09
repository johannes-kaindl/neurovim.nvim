local T = require('neurovim.kit.test')
local state = require('neurovim.state')
local store = require('neurovim.kit.store')
local data = require('neurovim.data')

-- The exported defaults, decoded here independently of the code under test (no luanil).
local function exported_defaults_json()
  local f = assert(io.open(data.path(), 'rb'))
  local raw = vim.json.decode(f:read('*a'))
  f:close()
  return vim.json.encode(raw.default_plugin_data)
end

local function tmp()
  return vim.fn.tempname() .. '/state.json'
end

local function capture_notify(fn)
  local seen, orig = {}, vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = orig
  assert(ok, err)
  return seen
end

T.case('the save lives under stdpath data, and tests use a temp data dir', function()
  T.eq(state.path(), vim.fn.stdpath('data') .. '/neurovim/state.json')
  T.ok(not state.path():find(vim.env.HOME .. '/.local/share', 1, true), state.path())
end)

T.case('no file: the exported defaults', function()
  local d = state.load(tmp())
  T.eq(d.total_xp, 0)
  T.eq(d.unlocked, data.get().default_unlocked)
end)

T.case('load then save keeps the exact shape of PluginData', function()
  local p = tmp()
  state.update(function(d)
    return d
  end, p)
  T.json_eq(store.read(p), exported_defaults_json())
end)

T.case('an old save gets the missing fields and its unlocks repaired', function()
  local p = tmp()
  store.write(p, { total_xp = 200, unlocked = {}, completed_missions = {} })
  local d = state.load(p)
  T.eq(d.total_xp, 200)
  T.ok(rawequal(d.railPin, vim.NIL), 'railPin stays null')
  T.ok(vim.tbl_contains(d.unlocked, 'M-09'), vim.inspect(d.unlocked))
end)

T.case('a broken save is moved aside with a warning, never dropped', function()
  local p = tmp()
  vim.fn.mkdir(vim.fn.fnamemodify(p, ':h'), 'p')
  vim.fn.writefile({ '{ broken' }, p)
  local d
  local seen = capture_notify(function()
    d = state.load(p)
  end)
  T.eq(d.total_xp, 0)
  T.eq(#seen, 1)
  T.eq(seen[1].level, vim.log.levels.WARN)
  T.ok(seen[1].msg:find('.broken-', 1, true), seen[1].msg)
  T.eq(#vim.fn.glob(p .. '.broken-*', false, true), 1)
end)

T.case('a save that is JSON but not an object is moved aside too', function()
  local p = tmp()
  store.write(p, { 1, 2, 3 })
  local seen = capture_notify(function()
    state.load(p)
  end)
  T.eq(#seen, 1)
  T.eq(#vim.fn.glob(p .. '.broken-*', false, true), 1)
end)

T.case('a second Neovim saving in between is not overwritten', function()
  local p = tmp()
  state.update(function(d)
    d.completed_missions = { 'M-01' }
    return d
  end, p)
  -- the other instance:
  local other = store.read(p)
  other.completed_missions = { 'M-01', 'M-02' }
  other.total_xp = 999
  store.write(p, other)
  local after, extra = state.update(function(d)
    table.insert(d.completed_missions, 'M-03')
    return d, 'extra'
  end, p)
  T.eq(after.completed_missions, { 'M-01', 'M-02', 'M-03' })
  T.eq(after.total_xp, 999)
  T.eq(extra, 'extra')
  T.eq(state.load(p).completed_missions, { 'M-01', 'M-02', 'M-03' })
end)
