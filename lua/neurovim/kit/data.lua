-- vendored from nvim-kit@0.2.0 (lua/nvim_kit/data.lua) — do not edit; re-vendor
-- Load a JSON data file that declares its schema version. Fails loudly on a missing file,
-- broken JSON or a different schema — never returns half-understood data. Nulls inside
-- objects are absent fields (luanil).
local M = {}

function M.load(path, opts)
  if type(opts) ~= 'table' or type(opts.schema) ~= 'number' then
    error('nvim-kit data: opts.schema (number) is required', 2)
  end
  local f = io.open(path, 'r')
  if not f then
    error(('nvim-kit data: cannot read %s'):format(path), 2)
  end
  local text = f:read('*a')
  f:close()
  local ok, decoded = pcall(vim.json.decode, text, { luanil = { object = true } })
  if not ok then
    error(('nvim-kit data: %s is not valid JSON: %s'):format(path, decoded), 2)
  end
  local schema = type(decoded) == 'table' and decoded.schema or nil
  if schema ~= opts.schema then
    error(('nvim-kit data: %s has schema %s, expected %s'):format(path, tostring(schema), opts.schema), 2)
  end
  return decoded
end

return M
