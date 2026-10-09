-- domain: neurovim
-- The vendored export of neurovim's missions and tables (data/neurovim-data.json), loaded once
-- through nvim-kit's schema-checked loader. Re-vendor from neurovim; never edit the JSON.
local kit_data = require('neurovim.kit.data')

local M = {}

local SCHEMA = 1
local cache

function M.path()
  local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
  return root .. '/data/neurovim-data.json'
end

function M.get()
  if not cache then
    cache = kit_data.load(M.path(), { schema = SCHEMA })
  end
  return cache
end

local defaults_json

-- PluginData defaults exactly as exported: decoded without luanil so null stays vim.NIL and {}
-- stays an object — the save file keeps the shape the other NeuroVim builds read.
function M.default_plugin_data()
  if not defaults_json then
    local f = assert(io.open(M.path(), 'rb'))
    local raw = vim.json.decode(f:read('*a'))
    f:close()
    defaults_json = vim.json.encode(raw.default_plugin_data)
  end
  return vim.json.decode(defaults_json)
end

return M
