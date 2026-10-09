-- vendored from nvim-kit@0.3.0 (lua/nvim_kit/panel.lua) — do not edit; re-vendor
-- Virtual lines above line 1 (a heading, an objective): shown, never part of the text. Neovim
-- draws virtual lines above the first line only when the window's topfill makes room, and gg
-- resets topfill to 0; this module makes room again when the cursor is on line 1 without it.
local MOD = ...
local M = {}

local ns = vim.api.nvim_create_namespace(MOD)
local height = {} -- buf -> number of virtual lines

local function reveal(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local h = height[buf]
  if not h or h == 0 then
    return
  end
  vim.api.nvim_win_call(win, function()
    local view = vim.fn.winsaveview()
    -- The saved view's topline can be stale until the next redraw (after gg it still names the
    -- old top); line('w0') is current. Measured 2026-10-09.
    if vim.fn.line('w0') == 1 and view.topfill < h then
      view.topline = 1
      view.topfill = h
      vim.fn.winrestview(view)
    end
  end)
end

local function watch(buf)
  local group = vim.api.nvim_create_augroup(('%s.%d'):format(MOD, buf), { clear = true })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    buffer = buf,
    callback = function()
      reveal(vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = buf,
    callback = function()
      -- Only when the room is gone entirely (gg, k back to the top): a panel scrolled half away
      -- with <C-e> keeps topfill > 0 and stays as the person left it. No state between events,
      -- because Neovim skips CursorMoved while keys are still waiting (G and gg typed fast).
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_cursor(win)[1] == 1 and vim.fn.winsaveview().topfill == 0 then
        reveal(win)
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = buf,
    callback = function()
      height[buf] = nil
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end

function M.set(buf, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if #lines > 0 then
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { virt_lines = lines, virt_lines_above = true })
  end
  if height[buf] == nil then
    watch(buf)
  end
  height[buf] = #lines
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    reveal(win)
  end
end

function M.wrap(text, width)
  local out, line = {}, ''
  for word in text:gmatch('%S+') do
    while #word > width do
      if line ~= '' then
        out[#out + 1] = line
        line = ''
      end
      out[#out + 1] = word:sub(1, width)
      word = word:sub(width + 1)
    end
    if line == '' then
      line = word
    elseif #line + 1 + #word <= width then
      line = line .. ' ' .. word
    else
      out[#out + 1] = line
      line = word
    end
  end
  out[#out + 1] = line
  return out
end

return M
