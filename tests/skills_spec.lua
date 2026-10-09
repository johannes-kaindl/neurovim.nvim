local T = require('neurovim.kit.test')
local missions = require('neurovim.missions')
local diff = require('neurovim.rules.diff')

-- The Ex commands a briefing names under its [!tip] SKILLS callout (backticked, starting with ':').
-- Heuristic from neurovim's spike (experiments/nvim-spike/headless.lua).
local function skills(briefing)
  local cmds, inside = {}, false
  for line in (briefing .. '\n'):gmatch('([^\n]*)\n') do
    if line:find('%[!tip%] SKILLS') then
      inside = true
    elseif inside and not line:match('^>%s*>') then
      inside = false
    end
    if inside then
      for span in line:gmatch('`(:[^`]+)`') do
        cmds[#cmds + 1] = span
      end
    end
  end
  return cmds
end

-- SKILLS that name a pattern or need a selection, not this mission's solution (measured 2026-10-09).
local PLACEHOLDERS = {
  ['M-04'] = '`:#` prints lines with numbers; it names a command, it edits nothing',
  ['M-07'] = "`:%s/old/new/g` is the general form, not this mission's words",
  ['M-09'] = '`:norm` without arguments names the command',
  ['M-12'] = '`:g/pattern/d` is the general form',
  ['M-16'] = '`:%s/\\v.../.../` leaves the pattern out on purpose',
  ['R-04'] = "`{range}` is a placeholder and `'<,'>` needs a visual selection",
}

local SOLVED = {
  'R-01',
  'R-02',
  'R-03',
  'R-05',
  'R-07',
  'R-08',
  'R-09',
  'R-11',
  'R-12',
  'R-13',
  'R-15',
  'R-16',
  'R-17',
  'R-18',
  'R-19',
  'R-20',
  'R-21',
  'R-22',
  'R-23',
  'R-24',
}

T.case(
  'the SKILLS commands of 20 briefings solve their mission in real Neovim; 6 are placeholders',
  function()
    local matched, mismatched = {}, {}
    for _, m in ipairs(missions.all()) do
      local cmds = skills(m.briefing or '')
      if #cmds > 0 then
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(m.transmission, '\n', { plain = true }))
        for _, c in ipairs(cmds) do
          pcall(vim.cmd, 'silent ' .. c:sub(2))
        end
        local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
        if diff.get_diff(text, m.solution).matches then
          matched[#matched + 1] = m.id
        else
          mismatched[m.id] = true
        end
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    T.eq(matched, SOLVED)
    for id in pairs(PLACEHOLDERS) do
      T.ok(
        mismatched[id],
        id .. ' is listed as a placeholder but now solves its mission — drop it from the list'
      )
    end
    for id in pairs(mismatched) do
      T.ok(
        PLACEHOLDERS[id],
        id .. ': its SKILLS no longer solve the mission and it is not a known placeholder'
      )
    end
  end
)
