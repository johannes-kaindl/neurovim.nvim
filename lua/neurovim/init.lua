-- domain: neurovim
-- plugin/neurovim.lua sets everything up when it loads; setup() only takes the options
-- (:help neurovim-options). Each call starts from the defaults, so setup({}) resets them.
local config = require('neurovim.config')

local M = {}

local TYPES = { isolate = 'boolean' }

function M.setup(opts)
  opts = opts or {}
  local unknown = {}
  for name in pairs(opts) do
    if not TYPES[name] then
      unknown[#unknown + 1] = tostring(name)
    end
  end
  if #unknown > 0 then
    table.sort(unknown)
    vim.notify(
      ('neurovim: unknown option — ignored: %s.'):format(table.concat(unknown, ', ')),
      vim.log.levels.WARN
    )
  end
  config.isolate = true
  for name, kind in pairs(TYPES) do
    local value = opts[name]
    if value ~= nil then
      if type(value) == kind then
        config[name] = value
      else
        vim.notify(('neurovim: %s must be true or false — ignored.'):format(name), vim.log.levels.WARN)
      end
    end
  end
end

return M
