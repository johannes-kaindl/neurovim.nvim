local T = require('neurovim.kit.test')
local briefing = require('neurovim.ui.briefing')
local mission = require('neurovim.ui.mission')
local missions = require('neurovim.missions')

local function keys(k)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), 'ntx', false)
end

-- Mapped keys (the briefing's <CR>) need remapping: no n flag.
local function mapped(k)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), 'tx', false)
end

local function silence(fn)
  local seen, orig = {}, vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = orig
  assert(ok, err)
  return seen
end

T.case('briefing: a locked mission is refused', function()
  local seen = silence(function()
    T.eq(briefing.open('M-09'), nil)
  end)
  T.ok(seen[1].msg:find('locked', 1, true), seen[1].msg)
end)

T.case('briefing: read-only markdown; <CR> starts the mission', function()
  local buf = briefing.open('M-01')
  T.eq(vim.api.nvim_buf_get_name(buf), 'neurovim://briefing/M-01')
  T.eq(vim.bo[buf].modifiable, false)
  T.eq(vim.bo[buf].filetype, 'markdown')
  mapped('<CR>')
  T.eq(vim.api.nvim_buf_get_name(0), 'neurovim://M-01')
end)

T.case('mission buffer: raw text, editable, objective above line 1', function()
  local buf = mission.start('M-01')
  local m = missions.get('M-01')
  T.eq(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'), m.transmission)
  T.eq(vim.bo[buf].modifiable, true)
  T.eq(vim.fn.winsaveview().topfill > #m.objective, true)
end)

T.case('winbar: id, clock, keys, par — and only in the mission buffer', function()
  local buf = mission.start('M-01')
  local w = vim.api.nvim_get_current_win()
  local function shown()
    return vim.api.nvim_eval_statusline(vim.wo[w].winbar, { winid = w, use_winbar = true }).str
  end
  T.eq(shown(), 'M-01 · 00:00 · 0 keys · par 40')
  keys('x')
  T.ok(shown():find('· 1 key ·', 1, true), shown())
  vim.cmd('enew')
  T.eq(vim.wo[w].winbar, '')
  vim.api.nvim_set_current_buf(buf)
  T.ok(shown():find('M-01', 1, true), shown())
end)

T.case('restart: raw text back, counter at zero', function()
  local buf = mission.start('M-01')
  keys('xxx')
  T.eq(mission.run(buf).tracker.keys(), 3)
  local again = mission.restart(buf)
  T.eq(table.concat(vim.api.nvim_buf_get_lines(again, 0, -1, false), '\n'), missions.get('M-01').transmission)
  T.eq(mission.run(again).tracker.keys(), 0)
end)

T.case('long objective lines are wrapped to the window, not cut off', function()
  local buf = mission.start('M-01')
  local marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })
  local width = vim.api.nvim_win_get_width(0)
  for _, mk in ipairs(marks) do
    for _, vl in ipairs(mk[4].virt_lines or {}) do
      local text = ''
      for _, chunk in ipairs(vl) do
        text = text .. chunk[1]
      end
      T.ok(vim.fn.strdisplaywidth(text) <= width, text)
    end
  end
end)

T.case(':bdelete ends the run: no zombie mission after :buffer', function()
  local buf = mission.start('M-01')
  keys('x')
  vim.cmd('enew')
  vim.cmd('bdelete! ' .. buf)
  T.eq(mission.run(buf), nil)
end)

local function widest_virt_line(buf)
  local widest = 0
  for _, mk in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    for _, vl in ipairs(mk[4].virt_lines or {}) do
      local text = ''
      for _, chunk in ipairs(vl) do
        text = text .. chunk[1]
      end
      widest = math.max(widest, vim.fn.strdisplaywidth(text))
    end
  end
  return widest
end

local function textwidth(win)
  return vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
end

T.case('the objective fits beside number and sign columns, and again after a split', function()
  vim.cmd('silent! only')
  vim.o.number = true
  vim.o.signcolumn = 'yes'
  local buf = mission.start('M-01')
  local win = vim.api.nvim_get_current_win()
  T.ok(widest_virt_line(buf) <= textwidth(win), ('%d > %d'):format(widest_virt_line(buf), textwidth(win)))
  vim.cmd('vsplit')
  vim.api.nvim_exec_autocmds('VimResized', {}) -- headless has no redraw to raise it
  local narrow = math.min(textwidth(vim.fn.win_findbuf(buf)[1]), textwidth(vim.fn.win_findbuf(buf)[2]))
  T.ok(widest_virt_line(buf) <= narrow, ('%d > %d after the split'):format(widest_virt_line(buf), narrow))
  vim.cmd('silent! only')
  vim.o.number = false
  vim.o.signcolumn = 'auto'
end)

T.case('restart keeps the layout: both windows show the new run with its winbar', function()
  vim.cmd('silent! only')
  local buf = mission.start('M-01')
  vim.cmd('vsplit')
  local again = mission.restart(buf)
  local wins = vim.fn.win_findbuf(again)
  T.eq(#vim.api.nvim_tabpage_list_wins(0), 2)
  T.eq(#wins, 2)
  for _, w in ipairs(wins) do
    local bar = vim.api.nvim_eval_statusline(vim.wo[w].winbar, { winid = w, use_winbar = true }).str
    T.ok(bar:find('M-01', 1, true), 'winbar in window ' .. w .. ': ' .. bar)
  end
  vim.cmd('silent! only')
end)

T.case('u stops at the raw text; mouse scrolling is not a keystroke', function()
  local buf = mission.start('M-01')
  vim.o.mouse = 'nvi'
  vim.cmd('silent! normal! xuuuu')
  T.eq(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'), missions.get('M-01').transmission)
  local before = mission.run(buf).tracker.keys()
  keys('<ScrollWheelDown><ScrollWheelUp>')
  T.eq(mission.run(buf).tracker.keys(), before)
end)

T.case('a KATA has no briefing: mission <id> starts its buffer directly; locked ones stay locked', function()
  local buf = briefing.open('KATA-01')
  T.eq(vim.api.nvim_buf_get_name(buf), 'neurovim://KATA-01')
  T.eq(vim.bo[buf].modifiable, true)
  T.ok(mission.run(buf), 'a run is tracking')
  local seen = silence(function()
    T.eq(briefing.open('KATA-02'), nil)
  end)
  T.ok(seen[1].msg:find('level 2', 1, true), seen[1].msg)
end)
