-- vendored from nvim-kit@0.3.0 (lua/nvim_kit/scratch.lua) — do not edit; re-vendor
-- A plugin's own view buffer: named, not backed by a file, with buffer-local keys only (a
-- plugin sets no global mappings). Opening a name again replaces the old buffer.
local M = {}

function M.find(name)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) == name then
      return b
    end
  end
  return nil
end

function M.set_lines(buf, lines)
  local was = vim.bo[buf].modifiable
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = was
end

function M.open(name, lines, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(opts.listed == true, true)
  local old = M.find(name)
  if old then
    vim.api.nvim_buf_delete(old, { force = true })
  end
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].bufhidden = opts.bufhidden or 'wipe'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = opts.modifiable == true
  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end
  for lhs, fn in pairs(opts.keys or {}) do
    vim.keymap.set('n', lhs, fn, { buffer = buf, nowait = true })
  end
  vim.api.nvim_set_current_buf(buf)
  return buf
end

return M
