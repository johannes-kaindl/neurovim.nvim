-- vendored from nvim-kit@0.6.0 (lua/nvim_kit/keytrack.lua) — do not edit; re-vendor
-- Count the keys a person types in one buffer and time them from the first one. Only typed keys
-- count (vim.on_key's `typed`): a macro replay counts the keys that started it, not the ones it
-- replays. A plugin's own command (opts.exclude_cmdline) does not count, `:` included, and
-- neither do mouse and scroll wheel events. Unloading or wiping the buffer stops the tracker.
local MOD = ...
local M = {}

local uv = vim.uv or vim.loop

-- Mouse and wheel events arrive as typed keys too (mouse=nvi is Neovim's default); reading the
-- text with the mouse is not a keystroke.
local function is_mouse(typed)
  local name = vim.fn.keytrans(typed)
  return name:find('Mouse', 1, true) ~= nil
    or name:find('Release>', 1, true) ~= nil
    or name:find('Drag>', 1, true) ~= nil
    or name:find('ScrollWheel', 1, true) ~= nil
end

function M.format_clock(ms)
  local s = math.floor(ms / 1000)
  return ('%02d:%02d'):format(math.floor(s / 60), s % 60)
end

function M.start(buf, opts)
  opts = opts or {}
  local now = opts.now or function()
    return uv.hrtime() / 1e6
  end
  local count, first, stopped_at, stopped = 0, nil, nil, false
  local cmd_start, timer, key_ns
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

  key_ns = vim.on_key(function(_, typed)
    if stopped or typed == nil or typed == '' or vim.api.nvim_get_current_buf() ~= buf or is_mouse(typed) then
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
            if not stopped then
              opts.on_tick()
            end
          end)
        )
      end
    end
    count = count + 1
  end)

  if opts.exclude_cmdline then
    vim.api.nvim_create_autocmd('CmdlineEnter', {
      group = group,
      callback = function()
        if vim.fn.getcmdtype() == ':' and vim.api.nvim_get_current_buf() == buf then
          cmd_start = math.max(count - 1, 0) -- the key that opened the command line
        end
      end,
    })
    vim.api.nvim_create_autocmd('CmdlineLeave', {
      group = group,
      callback = function()
        if cmd_start and not vim.v.event.abort and vim.fn.getcmdline():match(opts.exclude_cmdline) then
          count = cmd_start
        end
        cmd_start = nil
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
      return math.floor((stopped_at or now()) - first)
    end,
    stop = stop,
  }
end

return M
