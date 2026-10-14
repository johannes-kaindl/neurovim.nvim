-- domain: neurovim
-- Buffers named neurovim://… exist only while NeuroVim made them. A saved session brings back a
-- window that showed one as an empty, normal buffer of that name (`file neurovim://M-02`), and
-- :edit empties a mission buffer, because there is no file behind it.
local M = {}

local PREFIX = 'neurovim://'

--- Clear the empty normal buffers a session left under neurovim:// (NeuroVim's own are nofile).
function M.sweep()
  local n, empty = 0, nil
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(b)
      and vim.startswith(vim.api.nvim_buf_get_name(b), PREFIX)
      and vim.bo[b].buftype == ''
    then
      -- Deleting the buffer of the last window fails (E444) while a session loads: give its
      -- windows an empty buffer first, as :bdelete would.
      for _, win in ipairs(vim.fn.win_findbuf(b)) do
        empty = empty or vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(win, empty)
      end
      vim.api.nvim_buf_delete(b, { force = true })
      n = n + 1
    end
  end
  if n > 0 then
    vim.notify(
      ('neurovim: %d buffer%s from a saved session cleared — missions are not restored; :NeuroVim opens NEXUS.'):format(
        n,
        n == 1 and '' or 's'
      ),
      vim.log.levels.INFO
    )
  end
  return n
end

--- BufReadCmd neurovim://*: a mission whose run :edit just ended starts over; anything else
--- read under that name is left over and goes.
function M.read(buf)
  local mission = require('neurovim.ui.mission')
  local id = mission.ended(buf)
  vim.schedule(function()
    if id then
      mission.start(id, { fresh = true })
      vim.notify(
        ('neurovim: :edit reloaded %s — a mission has no file, so the run starts over.'):format(id),
        vim.log.levels.INFO
      )
    elseif vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

return M
