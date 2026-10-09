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

return M
