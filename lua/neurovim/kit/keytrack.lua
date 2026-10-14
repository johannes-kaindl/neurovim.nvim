-- vendored from nvim-kit@0.7.1 (lua/nvim_kit/keytrack.lua) — do not edit; re-vendor
-- Count the keys a person types in one buffer and time them from the first one. Only typed keys
-- count (vim.on_key's `typed`): a macro replay counts the keys that started it, not the ones it
-- replays, and a mapping counts the keys of its lhs. Keys typed in a command-line window opened
-- from the buffer (q:, q/) count too. A plugin's own command (opts.exclude_cmdline) does not count,
-- `:` included, and neither do mouse and scroll wheel events. Unloading or wiping the buffer stops
-- the tracker.
local MOD = ...
local M = {}

local uv = vim.uv or vim.loop

-- Mouse and wheel events arrive as typed keys too (mouse=nvi is Neovim's default); reading the
-- text with the mouse is not a keystroke.
local function is_mouse(name)
  return name:find('Mouse', 1, true) ~= nil
    or name:find('Release>', 1, true) ~= nil
    or name:find('Drag>', 1, true) ~= nil
    or name:find('ScrollWheel', 1, true) ~= nil
end

-- Keys in one report. A mapping arrives as its whole lhs in one call, at its first rhs key
-- (measured on 0.10.4 and 0.12.6: o-mapping iw → typed "iw", <Space>p → "<Space>p"). In
-- keytrans form a special key is one <…> name, every other character one key.
local function key_count(name)
  local rest, specials = name:gsub('<[^<>]+>', '')
  return specials + vim.fn.strchars(rest)
end

function M.format_clock(ms)
  local s = math.floor(ms / 1000)
  return ('%02d:%02d'):format(math.floor(s / 60), s % 60)
end

--- Start counting keys typed in buf. opts:
---   now             clock in ms (tests)
---   on_tick         called every second after the first key (not while paused)
---   exclude_cmdline Lua pattern or function(cmdline) → boolean: a ':' command line it matches
---                   costs nothing, also when it was abandoned. Only a typed ':' is part of the
---                   command; a mapping that opened the command line keeps its keys.
---   free_if_left    a ':' command after which buf is no longer current and unchanged costs
---                   nothing (:enew, :help)
---   pause_outside   time stops while buf is not the current buffer (a command-line window
---                   opened from it counts as buf)
function M.start(buf, opts)
  opts = opts or {}
  local now = opts.now or function()
    return uv.hrtime() / 1e6
  end
  local exclude = opts.exclude_cmdline
  local count, first, stopped_at, stopped = 0, nil, nil, false
  local cmd_start, last_key, cmdwin, cmdwin_line, left_at, paused = nil, nil, false, nil, nil, 0
  local timer, key_ns
  local group = vim.api.nvim_create_augroup(('%s.%d'):format(MOD, buf), { clear = true })

  local function stop()
    if stopped then
      return
    end
    stopped = true
    stopped_at = first and now() or nil
    vim.on_key(nil, key_ns)
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  -- The tracked buffer, or a command-line window opened from it.
  local function active()
    return vim.api.nvim_get_current_buf() == buf or (cmdwin and vim.fn.getcmdwintype() ~= '')
  end

  local function excluded(line)
    if type(exclude) == 'function' then
      return exclude(line) == true
    end
    return line:match(exclude) ~= nil
  end

  key_ns = vim.on_key(function(_, typed)
    if stopped or typed == nil or typed == '' or not active() then
      return
    end
    local name = vim.fn.keytrans(typed)
    if is_mouse(name) then
      return
    end
    if not first then
      first = now()
      if opts.on_tick then
        timer = uv.new_timer()
        timer:start(
          1000,
          1000,
          vim.schedule_wrap(function()
            if not stopped and not left_at then
              opts.on_tick()
            end
          end)
        )
      end
    end
    count = count + key_count(name)
    last_key = name
  end)

  -- A command-line window belongs to the buffer whose window opened it (the previous window).
  vim.api.nvim_create_autocmd('CmdwinEnter', {
    group = group,
    callback = function()
      local from = vim.fn.win_getid(vim.fn.winnr('#'))
      cmdwin = from ~= 0 and vim.api.nvim_win_get_buf(from) == buf
      if cmdwin then
        left_at = nil -- BufLeave came first; typing in the window is part of the run
      end
    end,
  })
  vim.api.nvim_create_autocmd('CmdwinLeave', {
    group = group,
    callback = function()
      -- The line the window holds is the command; leaving with :q ends the outer command line
      -- with an empty line and abort (measured), so CmdlineLeave reads it from here.
      cmdwin_line = cmdwin and vim.api.nvim_get_current_line() or nil
      cmdwin = false
    end,
  })

  if exclude or opts.free_if_left then
    -- q: and q/ open their window from a command line of the same type, so the ':' lines run
    -- from a command-line window come through here as well (measured).
    vim.api.nvim_create_autocmd('CmdlineEnter', {
      group = group,
      callback = function()
        if vim.fn.getcmdtype() == ':' and vim.api.nvim_get_current_buf() == buf then
          cmd_start = last_key == ':' and math.max(count - 1, 0) or count
          cmdwin_line = nil
        end
      end,
    })
    vim.api.nvim_create_autocmd('CmdlineLeave', {
      group = group,
      callback = function()
        -- A nested command line (:q in a command-line window, <C-r>=) is not the open command.
        if not cmd_start or vim.fn.getcmdtype() ~= ':' or vim.api.nvim_get_current_buf() ~= buf then
          return
        end
        local start, line = cmd_start, vim.fn.getcmdline()
        cmd_start = nil
        if line == '' and vim.v.event.abort and cmdwin_line then
          line = cmdwin_line
        end
        cmdwin_line = nil
        if exclude and excluded(line) then
          count = start
          return
        end
        if opts.free_if_left and not vim.v.event.abort then
          -- The command runs after CmdlineLeave. Its cost is taken back afterwards, not the count
          -- reset: keys typed in the meantime stay counted.
          local cost, tick = count - start, vim.api.nvim_buf_get_changedtick(buf)
          vim.schedule(function()
            if
              not stopped
              and vim.api.nvim_buf_is_valid(buf)
              and vim.api.nvim_get_current_buf() ~= buf
              and vim.api.nvim_buf_get_changedtick(buf) == tick
            then
              count = count - cost
            end
          end)
        end
      end,
    })
  end

  if opts.pause_outside then
    vim.api.nvim_create_autocmd('BufLeave', {
      group = group,
      buffer = buf,
      callback = function()
        if first and not stopped and not left_at then
          left_at = now()
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      buffer = buf,
      callback = function()
        if left_at then
          paused = paused + (now() - left_at)
          left_at = nil
        end
      end,
    })
  end
  -- :bdelete unloads without wiping; either way the text is gone and the run is over.
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, { group = group, buffer = buf, callback = stop })

  return {
    keys = function()
      return count
    end,
    started = function()
      return first ~= nil
    end,
    elapsed_ms = function()
      if not first then
        return 0
      end
      local t = stopped_at or now()
      local idle = paused + (left_at and (t - left_at) or 0)
      return math.floor(t - first - idle)
    end,
    stop = stop,
  }
end

return M
