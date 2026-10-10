-- vendored from nvim-kit@0.5.0 (lua/nvim_kit/conformance.lua) — do not edit; re-vendor
-- Conformance runner: checks a port of rules against JSON vectors produced by the reference
-- implementation — { schema, function, cases = { { name, args, expected } } }.
-- Null handling: nulls inside objects are absent (luanil), top-level null arguments arrive
-- as nil at their position, and the comparison treats vim.NIL as nil.
local M = {}
-- Relative require: a vendored copy lives under the plugin's namespace (lua/<plugin>/kit/),
-- and must load its sibling from there, never a global nvim_kit of another version.
local T = require(((...):gsub('conformance$', 'test')))

local function read(path)
  local f = io.open(path, 'r')
  if not f then
    error(('nvim-kit conformance: cannot read %s'):format(path))
  end
  local text = f:read('*a')
  f:close()
  return text
end

-- Validates the raw decode, where JSON null is still vim.NIL: after luanil an `expected: null`
-- and a missing `expected` look the same, and a stub returning nil would pass the latter.
local function validate(file, raw)
  if type(raw) ~= 'table' or type(raw['function']) ~= 'string' or type(raw.cases) ~= 'table' then
    error(('nvim-kit conformance: %s is not a vector file'):format(file))
  end
  if #raw.cases == 0 then
    error(('nvim-kit conformance: %s has no cases'):format(file))
  end
  for i, c in ipairs(raw.cases) do
    if type(c.args) ~= 'table' or (next(c.args) ~= nil and #c.args == 0) then
      error(('nvim-kit conformance: %s case %d has no args list'):format(file, i))
    end
    if c.expected == nil then
      error(('nvim-kit conformance: %s case %d has no expected value'):format(file, i))
    end
  end
end

function M.load_dir(dir)
  local files = vim.fn.globpath(dir, '*.json', false, true)
  table.sort(files)
  if #files == 0 then
    error(('nvim-kit conformance: no vector files in %s'):format(dir))
  end
  local vectors = {}
  for _, file in ipairs(files) do
    local text = read(file)
    validate(file, vim.json.decode(text))
    local v = vim.json.decode(text, { luanil = { object = true } })
    if vectors[v['function']] then
      error(('nvim-kit conformance: function %s is defined twice (%s)'):format(v['function'], file))
    end
    vectors[v['function']] = v
  end
  return vectors
end

function M.run(vector, impl)
  local failures = {}
  for _, c in ipairs(vector.cases) do
    local n = #c.args
    local args = {}
    for i = 1, n do
      local a = c.args[i]
      if a == vim.NIL then
        a = nil
      end
      args[i] = a
    end
    local ok, actual = pcall(impl, unpack(args, 1, n))
    if not ok then
      table.insert(failures, { name = c.name, expected = c.expected, error = actual })
    elseif not T.deep_equal(actual, c.expected) then
      table.insert(failures, { name = c.name, expected = c.expected, actual = actual })
    end
  end
  return failures
end

--- Run every vector in dir against impls (function name → function). A vector without an
--- implementation is a failure: nothing measured is not a pass.
function M.run_dir(dir, impls)
  local vectors = M.load_dir(dir)
  local names = vim.tbl_keys(vectors)
  table.sort(names)
  local report = { cases = 0, failures = {} }
  for _, name in ipairs(names) do
    local v = vectors[name]
    report.cases = report.cases + #v.cases
    if not impls[name] then
      table.insert(report.failures, { ['function'] = name, name = '(no implementation)' })
    else
      for _, f in ipairs(M.run(v, impls[name])) do
        f['function'] = name
        table.insert(report.failures, f)
      end
    end
  end
  return report
end

return M
