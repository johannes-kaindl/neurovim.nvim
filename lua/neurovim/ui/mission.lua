-- domain: neurovim
-- A mission run: the raw text in an editable buffer, the objective above line 1, a winbar with
-- id, clock, keys and par. Keys and time count from the first key typed in this buffer; the
-- player's own :NeuroVim commands do not count.
local missions = require('neurovim.missions')
local scratch = require('neurovim.kit.scratch')
local panel = require('neurovim.kit.panel')
local keytrack = require('neurovim.kit.keytrack')
local diff = require('neurovim.rules.diff')
local metrics = require('neurovim.rules.metrics')
local completion = require('neurovim.rules.completion')
local state = require('neurovim.state')

local M = {}

local runs = {} -- buf -> { id, mission, tracker, done }
local reveal_ns = vim.api.nvim_create_namespace('neurovim.reveal')

local function not_a_mission()
  vim.notify('neurovim: not a mission buffer — open one with :NeuroVim mission <id>.', vim.log.levels.ERROR)
end

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
  -- :bdelete unloads without wiping: the text is gone, so the run ends either way.
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
    group = group,
    buffer = buf,
    callback = function()
      if runs[buf] then
        runs[buf].tracker.stop()
        runs[buf] = nil
      end
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
  return buf
end

function M.restart(buf)
  local run = M.run(buf)
  if not run then
    not_a_mission()
    return nil
  end
  run.tracker.stop()
  return M.start(run.id)
end

local function text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
end

function M.check(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local run = runs[buf]
  if not run then
    not_a_mission()
    return 'not-a-mission'
  end
  if run.done then
    vim.notify('Transmission already restored — :NeuroVim restart plays it again.', vim.log.levels.INFO)
    return 'already'
  end
  local d = diff.get_diff(text(buf), run.mission.solution)
  if not d.matches then
    vim.notify(
      ('%d line%s still corrupted.'):format(d.lines_off, d.lines_off == 1 and '' or 's'),
      vim.log.levels.WARN
    )
    return 'mismatch'
  end
  run.done = true
  run.tracker.stop()
  vim.api.nvim_buf_clear_namespace(buf, reveal_ns, 0, -1)
  local mt = metrics.metrics_result(run.tracker.keys(), run.tracker.elapsed_ms())
  local m = run.mission
  local s, outcome = state.update(function(cur)
    local o = completion.complete_mission(cur, {
      mission_id = m.id,
      xp_reward = m.xp_reward,
      par_keystrokes = m.par_keystrokes,
      difficulty = m.difficulty,
    }, mt)
    return o.data, o
  end)
  require('neurovim.ui.result').show(require('neurovim.ui.result').lines(outcome, s, m, mt))
  require('neurovim.ui.nexus').refresh()
  return 'match'
end

function M.reveal(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local run = runs[buf]
  if not run then
    not_a_mission()
    return nil
  end
  vim.api.nvim_buf_clear_namespace(buf, reveal_ns, 0, -1)
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local marked = {}
  for _, l in ipairs(diff.get_divergent_lines(text(buf), run.mission.solution)) do
    -- A missing line lies past the end of the buffer; mark the last line instead.
    local at = math.min(l, last)
    vim.api.nvim_buf_set_extmark(buf, reveal_ns, at, 0, { line_hl_group = 'DiffChange' })
    marked[#marked + 1] = at
  end
  return marked
end

return M
