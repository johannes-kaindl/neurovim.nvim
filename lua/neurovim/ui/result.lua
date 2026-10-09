-- domain: neurovim
-- The result of a completed run, as markdown in Neovim's own floating preview (it closes when
-- the cursor moves, like every hover).
local progression = require('neurovim.rules.progression')
local missions = require('neurovim.missions')
local keytrack = require('neurovim.kit.keytrack')

local M = {}

function M.lines(outcome, s, m, metrics)
  local out = {
    ('# TRANSMISSION RESTORED — %s'):format(m.id),
    '',
    ('**+%d XP** · %d XP total · level %d'):format(
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
  if outcome.unverified then
    -- Parity with the Obsidian plugin: the win and its XP count, the bests do not.
    out[#out + 1] = ('No keystroke was counted (pasted or already solved?) — the win counts, bests stay as they were. Run %d.'):format(
      r.runs
    )
  else
    if outcome.tier then
      out[#out + 1] = ('Tier: **%s**'):format(outcome.tier:upper())
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
    out[#out + 1] = ''
    out[#out + 1] = ('## LEVEL UP: %d → %d'):format(outcome.level_up.old_level, outcome.level_up.new_level)
    for _, id in ipairs(outcome.level_up.unlocked_missions) do
      local u = missions.get(id)
      if u then
        out[#out + 1] = ('- unlocked %s  %s'):format(u.id, u.title)
      end
    end
  end
  return out
end

function M.show(lines)
  local _, win = vim.lsp.util.open_floating_preview(
    lines,
    'markdown',
    { border = 'rounded', focus_id = 'neurovim-result' }
  )
  return win
end

return M
