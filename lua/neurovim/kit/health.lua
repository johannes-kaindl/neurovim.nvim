-- vendored from nvim-kit@0.7.2 (lua/nvim_kit/health.lua) — do not edit; re-vendor
-- Building blocks for a plugin's :checkhealth. Diagnosis only: a check reads and reports; it never
-- moves, repairs, creates or writes anything (a broken file stays exactly as the person left it).
local M = {}
-- Relative require: a vendored copy loads its sibling under the plugin's namespace.
local store = require(((...):gsub('health$', 'store')))

local function say(level, msg, advice)
  if level == 'ok' then
    vim.health.ok(msg)
  elseif level == 'info' then
    vim.health.info(msg)
  elseif level == 'warn' then
    vim.health.warn(msg, advice)
  else
    vim.health.error(msg, advice)
  end
end

function M.neovim(min)
  local v = tostring(vim.version())
  if vim.fn.has('nvim-' .. min) == 1 then
    vim.health.ok(('Neovim %s (needs %s or newer)'):format(v, min))
    return true
  end
  vim.health.error(
    ('Neovim %s is older than %s'):format(v, min),
    { ('Install Neovim %s or newer.'):format(min) }
  )
  return false
end

function M.json(path, opts)
  opts = opts or {}
  local label = opts.label or path
  local f, err = io.open(path, 'rb')
  if not f then
    if (vim.uv or vim.loop).fs_stat(path) then
      -- exists but unreadable: never "missing", or the plugin's next write would replace it
      say(
        opts.invalid or 'error',
        ('%s: %s cannot be read (%s)'):format(label, path, tostring(err)),
        opts.advice
      )
    else
      say(
        opts.missing or 'error',
        ('%s: %s'):format(label, opts.missing_text or ('not found at ' .. path)),
        opts.advice
      )
    end
    return nil
  end
  local text = f:read('*a')
  f:close()
  local ok, value = pcall(vim.json.decode, text)
  local problem
  if not ok then
    problem = 'is not valid JSON'
  elseif opts.expect == 'object' and not store.is_object(value) then
    problem = 'is JSON but not an object'
  elseif opts.schema and (type(value) ~= 'table' or value.schema ~= opts.schema) then
    problem = ('has schema %s, expected %d'):format(
      tostring(type(value) == 'table' and value.schema or nil),
      opts.schema
    )
  end
  if problem then
    say(opts.invalid or 'error', ('%s: %s %s'):format(label, path, problem), opts.advice)
    return nil
  end
  vim.health.ok(('%s: %s'):format(label, path))
  return value
end

function M.writable(dir, label)
  label = label or dir
  local probe = dir
  while vim.fn.isdirectory(probe) == 0 and probe ~= vim.fn.fnamemodify(probe, ':h') do
    probe = vim.fn.fnamemodify(probe, ':h')
  end
  if vim.fn.filewritable(probe) == 2 then
    vim.health.ok(('%s: %s%s'):format(label, dir, probe ~= dir and ' (created when first needed)' or ''))
    return true
  end
  vim.health.error(
    ('%s: %s is not writable'):format(label, probe),
    { 'Check the permissions of ' .. probe .. '.' }
  )
  return false
end

function M.vendored(manifest_path, label)
  local f = io.open(manifest_path, 'rb')
  if not f then
    vim.health.error(
      ('%s: no %s'):format(label or manifest_path, manifest_path),
      { 'Re-vendor with tools/kit/vendor.py.' }
    )
    return
  end
  local m = vim.json.decode(f:read('*a'))
  f:close()
  local commit = type(m.commit) == 'string' and m.commit:sub(1, 7) or '?'
  local ref = type(m.tag) == 'string' and ('%s (%s)'):format(m.tag, commit) or commit
  vim.health.info(('%s: %s@%s'):format(label or manifest_path, tostring(m.source), ref))
end

return M
