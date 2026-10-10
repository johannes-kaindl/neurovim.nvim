local T = require('neurovim.kit.test')
local data = require('neurovim.data')
local missions = require('neurovim.missions')
local progression = require('neurovim.rules.progression')

local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

local function read(rel)
  local f = assert(io.open(root .. '/' .. rel, 'rb'))
  local s = f:read('*a')
  f:close()
  return s
end

-- The rows of the first markdown table under a `## <heading>`, as lists of trimmed cells.
local function table_rows(text, heading)
  local rows, inside = {}, false
  for line in (text .. '\n'):gmatch('(.-)\n') do
    if line:match('^## ') then
      inside = line == '## ' .. heading
    elseif inside and #rows > 0 and not line:match('^|') then
      break
    elseif inside and line:match('^|') and not line:match('^|%-') then
      local cells = {}
      for cell in line:gmatch('|([^|]*)') do
        cells[#cells + 1] = vim.trim(cell)
      end
      cells[#cells] = nil -- after the closing |
      rows[#rows + 1] = cells
    end
  end
  table.remove(rows, 1) -- the header
  return rows
end

T.case('docs/reference/progression.md: the level table is the game data', function()
  local want = {}
  for _, l in ipairs(data.get().levels) do
    want[#want + 1] = { tostring(l.level), l.title, tostring(l.xp_required) }
  end
  T.eq(table_rows(read('docs/reference/progression.md'), 'Levels'), want)
end)

T.case('docs/reference/progression.md: the unlock table is the game data', function()
  local by = {}
  for _, m in ipairs(missions.all()) do
    local l = progression.unlock_level_for(m.id) or 1
    by[l] = by[l] or {}
    table.insert(by[l], m.id)
  end
  local want = {}
  for l = 1, #data.get().levels do
    if by[l] then
      want[#want + 1] = { tostring(l), table.concat(by[l], ' ') }
    end
  end
  T.eq(table_rows(read('docs/reference/progression.md'), 'Unlocks'), want)
end)

T.case('docs/reference/progression.md: one pass over every mission is the XP and level it names', function()
  local total = 0
  for _, m in ipairs(missions.all()) do
    total = total + m.xp_reward
  end
  local text = read('docs/reference/progression.md')
  local level = progression.get_level_for_xp(total)
  T.ok(
    text:find(('Solving each mission once earns %d XP — level %d.'):format(total, level), 1, true),
    total
  )
end)

T.case('docs/reference/save-file.md names every field of the save, and only those', function()
  local text = read('docs/reference/save-file.md')
  local named = {}
  for _, row in ipairs(table_rows(text, 'Fields neurovim.nvim reads and writes')) do
    named[#named + 1] = row[1]:match('^`(.-)`')
  end
  -- The list is the first sentence of the section: `a`, `b`, … `z`.
  local kept = text:match('## Fields kept for NeuroVim.-\n\n(.-)%. ')
  for field in kept:gmatch('`([%w_]+)`') do
    named[#named + 1] = field
  end
  table.sort(named)
  local want = vim.tbl_keys(data.default_plugin_data())
  table.sort(want)
  T.eq(named, want)
end)

T.case('every relative link in docs/ points to a file that exists', function()
  local dead = {}
  for _, path in ipairs(vim.fn.globpath(root .. '/docs', '**/*.md', false, true)) do
    local f = assert(io.open(path, 'rb'))
    local text = f:read('*a')
    f:close()
    for target in text:gmatch('%]%(([^)]+)%)') do
      local file = target:gsub('#.*$', '')
      if file ~= '' and not file:match('^%a+:') then
        local abs = vim.fn.fnamemodify(vim.fn.fnamemodify(path, ':h') .. '/' .. file, ':p')
        if vim.uv.fs_stat(abs) == nil then
          dead[#dead + 1] = path:sub(#root + 2) .. ' → ' .. target
        end
      end
    end
  end
  T.eq(dead, {})
end)
