-- domain: neurovim
-- The player's save: neurovim's PluginData as JSON under stdpath('data'). Fields are laid over
-- the exported defaults and unlocks repaired, as the web app does on load
-- (backfillUnlocks({ ...DEFAULT_PLUGIN_DATA, ...saved })). Saving goes through the kit's store:
-- re-read right before every write, written atomically, a broken file moved aside with a warning.
local store = require('neurovim.kit.store')
local data = require('neurovim.data')
local progression = require('neurovim.rules.progression')

local M = {}

function M.path()
  return vim.fn.stdpath('data') .. '/neurovim/state.json'
end

local function warn_aside(path, aside)
  vim.notify(
    ('neurovim: the save file %s could not be read and was moved to %s — starting from a fresh save.'):format(
      path,
      aside
    ),
    vim.log.levels.WARN
  )
end

local function is_object(v)
  return type(v) == 'table' and v ~= vim.NIL and (next(v) == nil or not vim.islist(v))
end

local function normalize(raw, info, path)
  if info.broken then
    warn_aside(path, info.broken)
    raw = nil
  elseif raw ~= nil and not is_object(raw) then
    warn_aside(path, store.set_aside(path))
    raw = nil
  end
  local d = data.default_plugin_data()
  for k, v in pairs(raw or {}) do
    d[k] = v
  end
  return progression.backfill_unlocks(d)
end

function M.load(path)
  path = path or M.path()
  local raw, info = store.read(path)
  return normalize(raw, info, path)
end

local function pass(...)
  return ...
end

function M.update(fn, path)
  path = path or M.path()
  return store.update(path, function(raw, info)
    return pass(fn(normalize(raw, info, path)))
  end)
end

return M
