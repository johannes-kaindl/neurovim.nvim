-- vendored from nvim-kit@0.7.2 (lua/nvim_kit/test.lua) — do not edit; re-vendor
-- nvim-kit test runner: plain Lua specs, run in headless Neovim, no external test dependency.
--   nvim --headless -u NONE -l tests/run.lua
-- A spec file registers cases with T.case(name, fn); a case fails by raising (T.eq, T.ok, T.raises).
local M = {}

local registered = {}

function M.case(name, fn)
  table.insert(registered, { name = name, fn = fn })
end

local function is_nil(v)
  return v == nil or v == vim.NIL
end

-- vim.json.decode marks an empty object with this metatable; vim.json.encode writes it as {},
-- any other empty table as [].
local DICT_MT = getmetatable(vim.empty_dict())

--- Deep equality for test values: vim.NIL equals nil, numbers compare by value, metatables are
--- ignored — except that an empty object (vim.empty_dict(), or {} from vim.json.decode) differs
--- from an empty list, as {} and [] do in JSON.
function M.deep_equal(a, b)
  if is_nil(a) and is_nil(b) then
    return true
  end
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= 'table' then
    return a == b
  end
  if next(a) == nil and next(b) == nil then
    return (getmetatable(a) == DICT_MT) == (getmetatable(b) == DICT_MT)
  end
  for k, v in pairs(a) do
    if not M.deep_equal(v, b[k]) then
      return false
    end
  end
  for k, v in pairs(b) do
    if is_nil(a[k]) and not is_nil(v) then
      return false
    end
  end
  return true
end

function M.eq(actual, expected, msg)
  if not M.deep_equal(actual, expected) then
    error(
      ('%sexpected %s, got %s'):format(
        msg and (msg .. ': ') or '',
        vim.inspect(expected),
        vim.inspect(actual)
      ),
      2
    )
  end
end

--- Passes on a truthy value. vim.NIL (JSON null) fails like nil, although Lua counts it as true.
function M.ok(value, msg)
  if not value or value == vim.NIL then
    error(msg or 'expected a truthy value', 2)
  end
end

function M.raises(fn, substring)
  local ok, err = pcall(fn)
  if ok then
    error('expected an error, none was raised', 2)
  end
  if substring and not tostring(err):find(substring, 1, true) then
    error(('error %q does not contain %q'):format(tostring(err), substring), 2)
  end
end

-- Canonical JSON text: sorted keys; [] and {} and null stay what vim.json.encode makes of them.
-- deep_equal treats nil and vim.NIL alike — fine for values, wrong for data that is written to
-- disk, where an absent key and a null are different files.
local function canonical(v)
  if type(v) ~= 'table' or v == vim.NIL or next(v) == nil then
    return vim.json.encode(v)
  end
  local parts = {}
  if vim.islist(v) then
    for _, x in ipairs(v) do
      parts[#parts + 1] = canonical(x)
    end
    return '[' .. table.concat(parts, ',') .. ']'
  end
  local keys = vim.tbl_keys(v)
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  for _, k in ipairs(keys) do
    parts[#parts + 1] = vim.json.encode(tostring(k)) .. ':' .. canonical(v[k])
  end
  return '{' .. table.concat(parts, ',') .. '}'
end

--- Strict comparison for data that goes to disk: actual's canonical JSON must equal that of
--- expected_json_text. Unlike deep_equal it tells null from an absent key.
function M.json_eq(actual, expected_json_text, msg)
  local a, e = canonical(actual), canonical(vim.json.decode(expected_json_text))
  if a ~= e then
    error(('%sexpected %s, got %s'):format(msg and (msg .. ': ') or '', e, a), 2)
  end
end

local function out(line)
  io.write(line, '\n')
end

--- Run every *_spec.lua in dir and its subdirectories. Returns the number of passed and failed
--- cases; a spec that fails to load counts as one failure.
function M.run_dir(dir)
  local files = vim.fn.globpath(dir, '**/*_spec.lua', false, true)
  table.sort(files)
  local passed, failed = 0, 0
  for _, file in ipairs(files) do
    registered = {}
    local loaded, load_err = pcall(dofile, file)
    if not loaded then
      failed = failed + 1
      out(('FAIL %s (load): %s'):format(vim.fn.fnamemodify(file, ':t'), load_err))
    end
    for _, c in ipairs(registered) do
      local ok, err = pcall(c.fn)
      if ok then
        passed = passed + 1
      else
        failed = failed + 1
        out(('FAIL %s :: %s\n     %s'):format(vim.fn.fnamemodify(file, ':t'), c.name, err))
      end
    end
  end
  return passed, failed
end

--- Entry point for tests/run.lua. Exits 0 only when at least one case ran and none failed:
--- nothing measured is not a pass.
function M.main(dir)
  local passed, failed = M.run_dir(dir)
  out(('%d passed, %d failed'):format(passed, failed))
  os.exit((failed > 0 or passed == 0) and 1 or 0)
end

return M
