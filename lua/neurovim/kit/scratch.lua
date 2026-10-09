-- vendored from nvim-kit@0.4.0 (lua/nvim_kit/scratch.lua) — do not edit; re-vendor
-- A plugin's own view buffer: named, not backed by a file, with buffer-local keys only (a
-- plugin sets no global mappings). Opening a name again replaces the old buffer in every window
-- that showed it; the initial text is not part of the undo history.
local MOD = ...
local M = {}

local ns = vim.api.nvim_create_namespace(MOD)

function M.find(name)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) == name then
      return b
    end
  end
  return nil
end

--- Replace the lines (keeping the modifiable setting) and paint whole-line highlights:
--- marks = { { lnum (1-based), hl_group }, ... }; earlier marks are cleared.
function M.set_lines(buf, lines, marks)
  local was = vim.bo[buf].modifiable
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = was
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, mk in ipairs(marks or {}) do
    vim.api.nvim_buf_set_extmark(buf, ns, mk[1] - 1, 0, { line_hl_group = mk[2] })
  end
end

function M.open(name, lines, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(opts.listed == true, true)
  vim.bo[buf].bufhidden = opts.bufhidden or 'wipe'
  -- Without undo while the text goes in: u must stop at the text the buffer opened with.
  local levels = vim.bo[buf].undolevels
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].undolevels = levels
  vim.bo[buf].modifiable = opts.modifiable == true
  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end
  for lhs, fn in pairs(opts.keys or {}) do
    vim.keymap.set('n', lhs, fn, { buffer = buf, nowait = true })
  end
  local old = M.find(name)
  if old then
    -- Hand every window over to the new buffer first; deleting a shown buffer closes its windows.
    for _, win in ipairs(vim.fn.win_findbuf(old)) do
      vim.api.nvim_win_set_buf(win, buf)
    end
    if vim.api.nvim_buf_is_valid(old) then -- bufhidden=wipe may have taken it already
      vim.api.nvim_buf_delete(old, { force = true })
    end
  end
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_set_current_buf(buf)
  return buf
end

return M
