-- domain: neurovim
-- The briefing of a mission: read-only markdown; <CR> starts the mission, q closes it.
local missions = require('neurovim.missions')
local state = require('neurovim.state')
local scratch = require('neurovim.kit.scratch')

local M = {}

function M.open(id)
  local m = missions.get(id)
  if not m then
    vim.notify(('neurovim: no mission %s.'):format(id), vim.log.levels.ERROR)
    return nil
  end
  local st = missions.status(state.load(), m)
  if st.kind == 'locked' then
    vim.notify(
      ('%s is locked%s.'):format(
        id,
        st.unlock_level and (' — it unlocks at level ' .. st.unlock_level) or ''
      ),
      vim.log.levels.INFO
    )
    return nil
  end
  if (m.briefing or '') == '' then
    -- KATAs are drills without a briefing: straight to the mission buffer.
    return require('neurovim.ui.mission').start(id)
  end
  return scratch.open('neurovim://briefing/' .. id, vim.split(m.briefing, '\n', { plain = true }), {
    filetype = 'markdown',
    keys = {
      ['<CR>'] = function()
        require('neurovim.ui.mission').start(id)
      end,
      q = function()
        vim.api.nvim_buf_delete(0, { force = true })
      end,
    },
  })
end

return M
