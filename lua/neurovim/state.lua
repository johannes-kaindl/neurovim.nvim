-- domain: neurovim
-- The player's save: neurovim's PluginData as JSON under stdpath('data'). Fields are laid over
-- the exported defaults and unlocks repaired, as the web app does on load
-- (backfillUnlocks({ ...DEFAULT_PLUGIN_DATA, ...saved })). Saving goes through the kit's store:
-- re-read right before every write, written atomically, a broken file moved aside with a warning.
-- A file that is there but cannot be read (no permission) is left alone: the game says so as an
-- error and writes nothing until it can read it again.
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

local function normalize(raw, info, path)
  if info.broken then
    warn_aside(path, info.broken)
    raw = nil
  end
  local d = data.default_plugin_data()
  for k, v in pairs(raw or {}) do
    d[k] = v
  end
  return progression.backfill_unlocks(d)
end

-- The kit raises this when a save exists but cannot be read; every other error is a real bug.
local function unreadable(err)
  return type(err) == 'string' and err:find('nvim-kit store: cannot read', 1, true) == 1
end

local function warn_unreadable(err)
  vim.notify(
    ('neurovim: %s. Progress is not saved until NeuroVim can read the file again.'):format(err),
    vim.log.levels.ERROR
  )
end

function M.load(path)
  path = path or M.path()
  local ok, raw, info = pcall(store.read, path, { expect = 'object' })
  if not ok then
    if not unreadable(raw) then
      error(raw, 0)
    end
    warn_unreadable(raw)
    return normalize(nil, {}, path)
  end
  return normalize(raw, info, path)
end

local function finish_update(ok, ...)
  if ok then
    return ...
  end
  local err = ...
  if not unreadable(err) then
    error(err, 0)
  end
  warn_unreadable(err)
  return nil
end

-- Returns what fn returns, or nil when the save cannot be read (and then writes nothing).
function M.update(fn, path)
  path = path or M.path()
  return finish_update(pcall(store.update, path, function(raw, info)
    return fn(normalize(raw, info, path))
  end, { expect = 'object' }))
end

return M
