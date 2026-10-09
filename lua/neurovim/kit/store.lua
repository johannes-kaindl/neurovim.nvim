-- vendored from nvim-kit@0.3.0 (lua/nvim_kit/store.lua) — do not edit; re-vendor
-- A JSON state file that two editors can share. Read exactly (null stays vim.NIL, {} stays an
-- object, so the file keeps its shape for other programs), written atomically (temp file, then
-- rename), and re-read right before every write so one editor never overwrites what another
-- saved in between. A file that is not valid JSON is moved aside, never silently dropped.
local M = {}

local uv = vim.uv or vim.loop

local function read_text(path)
  local f = io.open(path, 'rb')
  if not f then
    return nil
  end
  local text = f:read('*a')
  f:close()
  return text
end

--- Move path aside to <path>.broken-<UTC timestamp>[-n] and return the new path.
function M.set_aside(path)
  local base = ('%s.broken-%s'):format(path, os.date('!%Y%m%dT%H%M%SZ'))
  local aside, n = base, 1
  while uv.fs_stat(aside) do
    aside = ('%s-%d'):format(base, n)
    n = n + 1
  end
  local ok, err = uv.fs_rename(path, aside)
  if not ok then
    error(('nvim-kit store: cannot move %s aside: %s'):format(path, err))
  end
  return aside
end

--- Read path. Returns the decoded value (nil when the file does not exist) and an info table;
--- info.broken names where a file without valid JSON was moved.
function M.read(path)
  local text = read_text(path)
  if text == nil then
    return nil, {}
  end
  local ok, value = pcall(vim.json.decode, text)
  if ok then
    return value, {}
  end
  return nil, { broken = M.set_aside(path), error = value }
end

--- Write value as JSON: a temp file next to path, then one rename over it.
function M.write(path, value)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local tmp = ('%s.tmp-%d-%d'):format(path, uv.os_getpid(), uv.hrtime())
  local f = assert(io.open(tmp, 'wb'))
  f:write(vim.json.encode(value))
  f:close()
  local ok, err = uv.fs_rename(tmp, path)
  if not ok then
    os.remove(tmp)
    error(('nvim-kit store: cannot replace %s: %s'):format(path, err))
  end
end

local function finish(path, ...)
  M.write(path, (...))
  return ...
end

--- Re-read path, apply fn(value_or_nil, info), write fn's first return value, and return all
--- of fn's return values. There is no cache: every update starts from the file on disk.
function M.update(path, fn)
  local value, info = M.read(path)
  return finish(path, fn(value, info))
end

return M
