-- vendored from nvim-kit@0.7.1 (lua/nvim_kit/winbar.lua) — do not edit; re-vendor
-- A winbar that belongs to one buffer: set window-locally wherever the buffer is shown, so another
-- buffer in the same window has none. The buffer number is part of the expression because
-- g:statusline_winid is not set for nvim_eval_statusline (measured). The provider's text is shown
-- literally (%{…}, not %{%…%}), so a % in it needs no escaping.
local MOD = ...
local M = {}

local providers = {} -- buf -> function(buf) -> string

function M.render(buf)
  local provider = providers[buf]
  if not provider then
    return ''
  end
  return provider(buf)
end

local function apply(buf, win)
  local expr = ("%%{v:lua.require'%s'.render(%d)}"):format(MOD, buf)
  vim.api.nvim_set_option_value('winbar', expr, { scope = 'local', win = win })
end

--- Show provider(buf)'s text as the winbar of every window that shows buf, now and later.
--- Redraw with :redrawstatus! when the text changes; unloading the buffer ends it.
function M.attach(buf, provider)
  providers[buf] = provider
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    apply(buf, win)
  end
  local group = vim.api.nvim_create_augroup(('%s.%d'):format(MOD, buf), { clear = true })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    buffer = buf,
    callback = function()
      apply(buf, vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
    group = group,
    buffer = buf,
    callback = function()
      providers[buf] = nil
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end

return M
