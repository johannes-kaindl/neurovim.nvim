-- domain: neurovim
-- A mission run: the raw text in an editable buffer, the objective above line 1, a winbar with
-- id, clock, keys and par. Keys and time count from the first key typed in this buffer; the
-- player's own :NeuroVim commands do not count.
local missions = require('neurovim.missions')
local scratch = require('neurovim.kit.scratch')
local panel = require('neurovim.kit.panel')
local keytrack = require('neurovim.kit.keytrack')

local M = {}

local runs = {} -- buf -> { id, mission, tracker, done }

local function objective(m, width)
  local lines = { { { m.id .. ' — ' .. m.title, 'Title' } } }
  for _, step in ipairs(m.objective) do
    for i, part in ipairs(panel.wrap(step, math.max(width - 4, 20))) do
      lines[#lines + 1] = { { (i == 1 and '  ▸ ' or '    ') .. part, 'Comment' } }
    end
  end
  lines[#lines + 1] = { { '' } }
  return lines
end

local function set_winbar(buf, win)
  local expr = ("%%{%%v:lua.require'neurovim.ui.mission'.winbar(%d)%%}"):format(buf)
  vim.api.nvim_set_option_value('winbar', expr, { scope = 'local', win = win })
end

function M.winbar(buf)
  local run = runs[buf]
  if not run then
    return ''
  end
  local keys = run.tracker.keys()
  return ('%s · %s · %d key%s · par %d'):format(
    run.id,
    keytrack.format_clock(run.tracker.elapsed_ms()),
    keys,
    keys == 1 and '' or 's',
    missions.par(run.mission)
  )
end

function M.run(buf)
  return runs[buf or vim.api.nvim_get_current_buf()]
end

function M.start(id)
  local m = missions.get(id)
  local buf = scratch.open('neurovim://' .. id, vim.split(m.transmission, '\n', { plain = true }), {
    filetype = 'markdown',
    modifiable = true,
    bufhidden = 'hide',
    listed = true,
  })
  local win = vim.api.nvim_get_current_win()
  panel.set(buf, objective(m, vim.api.nvim_win_get_width(win)))
  runs[buf] = {
    id = id,
    mission = m,
    done = false,
    tracker = keytrack.start(buf, {
      exclude_cmdline = '^%s*NeuroVim',
      on_tick = function()
        vim.cmd('redrawstatus!')
      end,
    }),
  }
  set_winbar(buf, win)
  local group = vim.api.nvim_create_augroup('neurovim.mission.' .. buf, { clear = true })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    buffer = buf,
    callback = function()
      set_winbar(buf, vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = buf,
    callback = function()
      runs[buf] = nil
    end,
  })
  return buf
end

function M.restart(buf)
  local run = M.run(buf)
  if not run then
    return nil
  end
  run.tracker.stop()
  return M.start(run.id)
end

return M
