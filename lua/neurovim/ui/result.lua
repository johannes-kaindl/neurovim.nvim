-- domain: neurovim
-- The result of a completed run in a float of its own: plain text with highlights (no Markdown to
-- render), closed when the cursor really moves, and shown again by :NeuroVim result.
local progression = require('neurovim.rules.progression')
local missions = require('neurovim.missions')
local keytrack = require('neurovim.kit.keytrack')

local M = {}

local ns = vim.api.nvim_create_namespace('neurovim.result')
local last, shown -- the lines of the last result, and its float while open

--- opts.outside: the text was changed from another buffer (the run is unverified for that reason).
function M.lines(outcome, s, m, metrics, opts)
  local out = {
    ('TRANSMISSION RESTORED — %s'):format(m.id),
    '',
    ('+%d XP · %d XP total · level %d'):format(
      outcome.xp,
      s.total_xp,
      progression.get_xp_progress(s.total_xp).level
    ),
    ('Time %s · %d keys · par %d'):format(
      keytrack.format_clock(metrics.elapsed_ms),
      metrics.keystrokes,
      outcome.par
    ),
  }
  local r = outcome.record
  if outcome.unverified and opts and opts.outside then
    out[#out + 1] = ('The text was changed from outside the mission buffer — the win counts, bests stay as they were. Run %d.'):format(
      r.runs
    )
  elseif outcome.unverified then
    -- Parity with the Obsidian plugin: the win and its XP count, the bests do not.
    out[#out + 1] = ('No keystroke was counted (pasted or already solved?) — the win counts, bests stay as they were. Run %d.'):format(
      r.runs
    )
  else
    if outcome.tier then
      out[#out + 1] = ('Tier: %s'):format(outcome.tier:upper())
    else
      out[#out + 1] = 'No tier this run.'
    end
    if outcome.to_next_tier then
      out[#out + 1] = ('%d fewer keys for %s.'):format(
        math.ceil(outcome.to_next_tier.delta),
        outcome.to_next_tier.nextTier
      )
    end
    out[#out + 1] = ('Best: %s · %d keys · run %d'):format(
      keytrack.format_clock(r.best_time_ms),
      r.best_keystrokes,
      r.runs
    )
  end
  out[#out + 1] = ('Streak: %d day%s'):format(s.streak_current, s.streak_current == 1 and '' or 's')
  if outcome.level_up then
    local new = outcome.level_up.new_level
    out[#out + 1] = ''
    out[#out + 1] = ('LEVEL UP: %d → %d · %s'):format(
      outcome.level_up.old_level,
      new,
      missions.level_title(new) or ''
    )
    for _, id in ipairs(outcome.level_up.unlocked_missions) do
      local u = missions.get(id)
      if u then
        out[#out + 1] = ('  unlocked %s  %s'):format(u.id, u.title)
      end
    end
  end
  out[#out + 1] = ''
  out[#out + 1] = 'Next: :NeuroVim opens NEXUS · move the cursor to close this'
  return out
end

local function close()
  if shown and vim.api.nvim_win_is_valid(shown) then
    vim.api.nvim_win_close(shown, true)
  end
  shown = nil
end

function M.show(lines)
  close()
  last = lines
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.max(math.min(width, vim.o.columns - 4), 1)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  for i, l in ipairs(lines) do
    if i == 1 or l:find('^LEVEL UP') then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = #l, hl_group = 'Title' })
    end
  end
  for _, lhs in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', lhs, close, { buffer = buf, nowait = true })
  end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    row = 1,
    col = math.max(math.floor((vim.o.columns - width) / 2) - 1, 0),
    width = width,
    height = math.min(#lines, math.max(vim.o.lines - 4, 1)),
    style = 'minimal',
    border = 'rounded',
    focusable = true,
  })
  vim.wo[win].wrap = true
  shown = win
  -- Close when the cursor really moves. A CursorMoved can arrive late: after a "Press ENTER"
  -- prompt it fires for the jump made before the prompt, once :NeuroVim check has run.
  local origin, at = vim.api.nvim_get_current_win(), vim.api.nvim_win_get_cursor(0)
  local group = vim.api.nvim_create_augroup('neurovim.result', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'WinEnter', 'BufLeave' }, {
    group = group,
    callback = function(ev)
      if not vim.api.nvim_win_is_valid(win) then
        return true
      end
      local here = vim.api.nvim_get_current_win()
      if here == win then
        return -- the player stepped into the result to read or scroll it
      end
      if ev.event == 'CursorMoved' and here == origin then
        local pos = vim.api.nvim_win_get_cursor(here)
        if pos[1] == at[1] and pos[2] == at[2] then
          return
        end
      end
      close()
      return true
    end,
  })
  return win
end

--- :NeuroVim result — the last result of this session again.
function M.again()
  if not last then
    vim.notify(
      'neurovim: no result yet in this session — :NeuroVim check scores a mission.',
      vim.log.levels.INFO
    )
    return nil
  end
  return M.show(last)
end

return M
