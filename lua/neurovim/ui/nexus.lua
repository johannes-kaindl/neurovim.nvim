-- domain: neurovim
-- NEXUS: the player's status and the mission list by chapter, as a read-only buffer.
local missions = require('neurovim.missions')
local progression = require('neurovim.rules.progression')
local state = require('neurovim.state')
local scratch = require('neurovim.kit.scratch')
local kit_text = require('neurovim.kit.text')

local M = {}

local NAME = 'neurovim://nexus'
local BAR = 20

function M.render(s)
  local lines, rows, marks = {}, {}, {}
  local function add(text, hl)
    lines[#lines + 1] = text
    if hl then
      marks[#marks + 1] = { #lines, hl }
    end
  end
  local p = progression.get_xp_progress(s.total_xp)
  local title
  for _, l in ipairs(require('neurovim.data').get().levels) do
    if l.level == p.level then
      title = l.title
    end
  end
  add('NEUROVIM // NEXUS', 'Title')
  add(('Level %d · %s · %d XP'):format(p.level, title, s.total_xp))
  if p.nextLevelXp then
    add(('%s %d%% · next: %s at %d XP'):format(kit_text.bar(p.pct, BAR), p.pct, p.nextTitle, p.nextLevelXp))
  else
    add(kit_text.bar(100, BAR) .. ' max level')
  end
  add(('Streak: %d day%s'):format(s.streak_current or 0, (s.streak_current or 0) == 1 and '' or 's'))
  local n = missions.next_unlock(s)
  if n then
    add(
      ('Replay solved missions for XP — level %d (%d XP) unlocks %s.'):format(
        n.level,
        n.xp,
        table.concat(n.ids, ', ')
      ),
      'DiagnosticWarn'
    )
  end
  for _, c in ipairs(missions.chapters()) do
    add('')
    add(c.label, 'Title')
    for _, m in ipairs(c.missions) do
      local st = missions.status(s, m)
      if st.kind == 'done' then
        add(('  ✓ %s  %s%s'):format(m.id, m.title, st.tier and ('  ◆ ' .. st.tier) or ''), 'DiagnosticOk')
      elseif st.kind == 'open' then
        add(('    %s  %s'):format(m.id, m.title))
      else
        add(
          ('  🔒 %s  %s%s'):format(
            m.id,
            m.title,
            st.unlock_level and ('  (level ' .. st.unlock_level .. ')') or ''
          ),
          'Comment'
        )
      end
      rows[#lines] = m.id
    end
  end
  return { lines = lines, rows = rows, marks = marks }
end

local function paint(buf, r)
  scratch.set_lines(buf, r.lines, r.marks)
  local rows = {}
  for lnum, id in pairs(r.rows) do
    rows[tostring(lnum)] = id
  end
  vim.b[buf].neurovim_rows = rows
end

local function open_under_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local id = (vim.b[buf].neurovim_rows or {})[tostring(vim.api.nvim_win_get_cursor(0)[1])]
  if not id then
    return
  end
  local st = missions.status(state.load(), missions.get(id))
  if st.kind == 'locked' then
    vim.notify(
      ('%s is locked%s.'):format(
        id,
        st.unlock_level and (' — it unlocks at level ' .. st.unlock_level) or ''
      ),
      vim.log.levels.INFO
    )
    return
  end
  require('neurovim.ui.briefing').open(id)
end

function M.show()
  local r = M.render(state.load())
  local buf = scratch.open(NAME, r.lines, {
    filetype = 'neurovim',
    keys = {
      ['<CR>'] = open_under_cursor,
      q = function()
        vim.api.nvim_buf_delete(0, { force = true })
      end,
    },
  })
  paint(buf, r)
  return buf
end

function M.refresh()
  local buf = scratch.find(NAME)
  if buf then
    paint(buf, M.render(state.load()))
  end
end

return M
