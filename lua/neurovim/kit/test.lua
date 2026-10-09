-- vendored from nvim-kit@0.2.0 (lua/nvim_kit/test.lua) — do not edit; re-vendor
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

--- Deep equality for test values: vim.NIL equals nil, metatables are ignored (vim.json.decode
--- marks empty objects with one), numbers compare by value.
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

function M.ok(value, msg)
  if not value then
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
