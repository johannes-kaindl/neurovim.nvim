-- domain: neurovim
-- A mission run: the raw text in an editable buffer, the objective above line 1, a winbar with
-- id, clock, keys and par. Keys and time count from the first key typed in this buffer; the
-- player's own :NeuroVim commands do not count.
local missions = require('neurovim.missions')
local scratch = require('neurovim.kit.scratch')
local panel = require('neurovim.kit.panel')
local keytrack = require('neurovim.kit.keytrack')
local winbar = require('neurovim.kit.winbar')
local diff = require('neurovim.rules.diff')
local metrics = require('neurovim.rules.metrics')
local completion = require('neurovim.rules.completion')
local state = require('neurovim.state')
local config = require('neurovim.config')
local isolate = require('neurovim.isolate')

local M = {}

local runs = {} -- buf -> { id, mission, tracker, done }
local reveal_ns = vim.api.nvim_create_namespace('neurovim.reveal')

-- reveal's highlights, yours to override (:help neurovim-reveal). A colour scheme clears them,
-- so they come back with every :colorscheme.
local function reveal_highlights()
  vim.api.nvim_set_hl(0, 'NeuroVimReveal', { link = 'DiffChange', default = true })
  vim.api.nvim_set_hl(0, 'NeuroVimRevealMark', { link = 'DiagnosticWarn', default = true })
end
reveal_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('neurovim.reveal', { clear = true }),
  callback = reveal_highlights,
})

local function not_a_mission()
  vim.notify('neurovim: not a mission buffer — open one with :NeuroVim mission <id>.', vim.log.levels.ERROR)
end

-- width is the text width the panel may use (the narrowest window, without number and sign
-- columns); the kit calls this again after every resize or split.
local function objective(m, width)
  local lines = {}
  for _, part in ipairs(panel.wrap(m.id .. ' — ' .. m.title, math.max(width, 20))) do
    lines[#lines + 1] = { { part, 'Title' } }
  end
  for _, step in ipairs(m.objective) do
    for i, part in ipairs(panel.wrap(step, math.max(width - 4, 20))) do
      lines[#lines + 1] = { { (i == 1 and '  ▸ ' or '    ') .. part, 'Comment' } }
    end
  end
  lines[#lines + 1] = { { '' } }
  return lines
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

-- ended[buf] = id for a run that ended by unloading its buffer; :edit unloads and then reads it.
local ended = {}

-- Keys count only in the mission buffer. A change to its text while the keys go to another buffer
-- (:bufdo, :windo, a command typed elsewhere) makes the run unverified, like a paste: XP yes,
-- bests no (decision Johannes 2026-10-14).
local typed_in, key_ns
local function watch(buf)
  key_ns = key_ns
    or vim.on_key(function(_, typed)
      if typed and typed ~= '' then
        typed_in = vim.api.nvim_get_current_buf()
      end
    end)
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      local run = runs[buf]
      if not run then
        return true
      end
      if typed_in ~= buf then
        run.outside = true
      end
    end,
  })
end

function M.ended(buf)
  return ended[buf]
end

--- Start mission id, or go back to its run while that is not solved yet. opts.fresh always
--- starts over (:NeuroVim restart).
function M.start(id, opts)
  local m = missions.get(id)
  local running = scratch.find('neurovim://' .. id)
  if running and runs[running] and not runs[running].done and not (opts and opts.fresh) then
    vim.api.nvim_set_current_buf(running)
    vim.notify(
      ('%s is still running — back to it. :NeuroVim restart starts it over.'):format(id),
      vim.log.levels.INFO
    )
    return running
  end
  local buf = scratch.open('neurovim://' .. id, vim.split(m.transmission, '\n', { plain = true }), {
    filetype = not config.isolate and 'markdown' or nil,
    modifiable = true,
    bufhidden = 'hide',
    listed = false,
  })
  if config.isolate then
    isolate.apply(
      buf,
      { filetype = 'neurovim-mission', desc = 'neurovim: plain Neovim key (:help neurovim-isolate)' }
    )
  end
  panel.set(buf, function(width)
    return objective(m, width)
  end)
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
  watch(buf)
  winbar.attach(buf, M.winbar)
  local group = vim.api.nvim_create_augroup('neurovim.mission.' .. buf, { clear = true })
  -- :bdelete unloads without wiping: the text is gone, so the run ends either way.
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
    group = group,
    buffer = buf,
    callback = function()
      if runs[buf] then
        runs[buf].tracker.stop()
        runs[buf] = nil
        ended[buf] = id
        vim.schedule(function()
          ended[buf] = nil
        end)
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
  return M.start(run.id, { fresh = true })
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
    vim.notify(
      'Transmission already restored — :NeuroVim result shows the result again, :NeuroVim restart plays the mission again.',
      vim.log.levels.INFO
    )
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
  local mt = metrics.metrics_result(run.tracker.keys(), run.tracker.elapsed_ms())
  -- The core's rule for "unverified" is a run without a keystroke.
  local scored = run.outside and metrics.metrics_result(0, mt.elapsed_ms) or mt
  local m = run.mission
  local s, outcome = state.update(function(cur)
    local o = completion.complete_mission(cur, {
      mission_id = m.id,
      xp_reward = m.xp_reward,
      par_keystrokes = m.par_keystrokes,
      difficulty = m.difficulty,
    }, scored)
    return o.data, o
  end)
  -- The save could not be read (state said so): the run stays open, a later check can still save it.
  if not s then
    return 'save-failed'
  end
  run.done = true
  run.tracker.stop()
  vim.api.nvim_buf_clear_namespace(buf, reveal_ns, 0, -1)
  require('neurovim.ui.result').show(
    require('neurovim.ui.result').lines(outcome, s, m, mt, { outside = run.outside })
  )
  require('neurovim.ui.nexus').refresh()
  return 'match'
end

-- The rows (0-based) that differ from the solution; a missing line lies past the end of the
-- buffer and counts for the last line.
local function divergent(buf, run)
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local rows = {}
  for _, l in ipairs(diff.get_divergent_lines(text(buf), run.mission.solution)) do
    rows[math.min(l, last)] = true
  end
  return rows
end

function M.reveal(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local run = runs[buf]
  if not run then
    not_a_mission()
    return nil
  end
  vim.api.nvim_buf_clear_namespace(buf, reveal_ns, 0, -1)
  local marked = {}
  for at in pairs(divergent(buf, run)) do
    vim.api.nvim_buf_set_extmark(buf, reveal_ns, at, 0, {
      line_hl_group = 'NeuroVimReveal',
      virt_text = { { ' ◀ differs', 'NeuroVimRevealMark' } },
      virt_text_pos = 'eol',
    })
    marked[#marked + 1] = at
  end
  table.sort(marked)
  -- A mark goes once its line is right; reveal never adds marks on its own.
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('neurovim.reveal.' .. buf, { clear = true }),
    buffer = buf,
    callback = function()
      local still = runs[buf] and vim.api.nvim_buf_get_extmarks(buf, reveal_ns, 0, -1, {}) or {}
      if #still == 0 then
        return true
      end
      -- Replacing or moving lines can push a mark onto a marked line: keep one per line.
      local off, seen = divergent(buf, runs[buf]), {}
      for _, mk in ipairs(still) do
        if not off[mk[2]] or seen[mk[2]] then
          vim.api.nvim_buf_del_extmark(buf, reveal_ns, mk[1])
        end
        seen[mk[2]] = true
      end
    end,
  })
  return marked
end

return M
