-- vendored from nvim-kit@0.5.1 (lua/nvim_kit/store.lua) — do not edit; re-vendor
-- A JSON state file that two editors can share. Read exactly (null stays vim.NIL, {} stays an
-- object, so the file keeps its shape for other programs), written atomically (temp file, then
-- rename), and re-read right before every write so one editor never overwrites what another
-- saved in between. A file that is not valid JSON is moved aside, never silently dropped.
local M = {}

local uv = vim.uv or vim.loop

-- nil only when the file does not exist. A file that exists but cannot be read (permissions) is an
-- error: treating it as missing would let the next write replace it silently.
local function read_text(path)
  local f, err = io.open(path, 'rb')
  if not f then
    if uv.fs_stat(path) == nil then
      return nil
    end
    error(('nvim-kit store: cannot read %s (%s) — left untouched'):format(path, tostring(err)), 0)
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

--- A JSON object as vim.json.decode returns it: a non-list table, or an empty one marked as {}.
function M.is_object(v)
  return type(v) == 'table'
    and (next(v) == nil and getmetatable(v) ~= nil or (next(v) ~= nil and not vim.islist(v)))
end

--- Read path. Returns the decoded value (nil when the file does not exist) and an info table;
--- raises when the file exists but cannot be read, so that update never overwrites it;
--- info.broken names where a file without valid JSON was moved. opts.expect = 'object' also moves
--- aside valid JSON that is not an object (a list, a string, a number).
function M.read(path, opts)
  local text = read_text(path)
  if text == nil then
    return nil, {}
  end
  local ok, value = pcall(vim.json.decode, text)
  if not ok then
    return nil, { broken = M.set_aside(path), error = value }
  end
  if opts and opts.expect == 'object' and not M.is_object(value) then
    return nil, { broken = M.set_aside(path), error = 'not a JSON object' }
  end
  return value, {}
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

--- Re-read path (with opts as for read), apply fn(value_or_nil, info), write fn's first return
--- value, and return all of fn's return values. There is no cache: every update starts from the
--- file on disk.
function M.update(path, fn, opts)
  local value, info = M.read(path, opts)
  return finish(path, fn(value, info))
end

return M
