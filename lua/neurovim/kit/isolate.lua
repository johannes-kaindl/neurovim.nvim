-- vendored from nvim-kit@0.7.2 (lua/nvim_kit/isolate.lua) — do not edit; re-vendor
-- A buffer in plain Neovim: what a user's setup changes about keys, options and editor helpers is
-- put back to what `nvim --clean` does, in this buffer only. For a plugin whose buffer has to
-- behave the same for everyone (a game that counts keys, an exercise with a par). Moved from
-- neurovim.nvim 1e4c619 (lua/neurovim/isolate.lua), where it was measured against LazyVim.
local MOD = ...
local M = {}

local MODES = { 'n', 'x', 'o' }

-- Keys that are Vim commands for editing, moving and scrolling, besides the printable ones. Window
-- keys (<C-w>, <C-h> …), <C-s>, function and Alt keys stay the user's.
local SPECIAL = {
  '<C-A>',
  '<C-B>',
  '<C-D>',
  '<C-E>',
  '<C-F>',
  '<C-O>',
  '<C-R>',
  '<C-U>',
  '<C-V>',
  '<C-X>',
  '<C-Y>',
  '<CR>',
  '<BS>',
  '<Up>',
  '<Down>',
  '<Left>',
  '<Right>',
}

-- Buffer switches of editor helpers that type, pair or complete text, or change motions and text
-- objects. Each is the plugin's own documented switch.
local SWITCHES = {
  completion = false, -- blink.cmp
  copilot_enabled = false, -- copilot.vim
  minuet_virtual_text_auto_trigger = false, -- minuet-ai
  miniai_disable = true,
  miniclue_disable = true,
  minicompletion_disable = true,
  minijump_disable = true,
  minijump2d_disable = true,
  minipairs_disable = true,
  minisurround_disable = true,
}

-- Options that change what a key does to the text, put back to Neovim's default.
local BUF_OPTIONS = {
  'autoindent',
  'cindent',
  'expandtab',
  'formatexpr',
  'formatoptions',
  'indentexpr',
  'iskeyword',
  'lisp',
  'matchpairs',
  'nrformats',
  'shiftwidth',
  'smartindent',
  'softtabstop',
  'tabstop',
  'textwidth',
  'wrapmargin',
}
local WIN_OPTIONS = { 'conceallevel', 'foldmethod', 'scrolloff', 'sidescrolloff', 'virtualedit' }

-- Global options with the same effect; a buffer cannot have its own value, so they are only
-- reported (:checkhealth).
local GLOBAL_OPTIONS = {
  'cpoptions',
  'gdefault',
  'ignorecase',
  'joinspaces',
  'selection',
  'smartcase',
  'startofline',
  'tildeop',
  'whichwrap',
  'wrapscan',
}

local function default(name)
  local value = vim.api.nvim_get_option_info2(name, {}).default
  -- An empty local value of a global-local option means "use the global one".
  if name == 'virtualedit' and value == '' then
    return 'NONE'
  end
  return value
end

local function first_key(lhs)
  if lhs:sub(1, 1) == '<' then
    local close = lhs:find('>', 2, true)
    if close then
      return lhs:sub(1, close)
    end
  end
  return vim.fn.strcharpart(lhs, 0, 1)
end

local function name(key)
  return vim.fn.keytrans(vim.api.nvim_replace_termcodes(key, true, true, true))
end

-- The keys that keep their Vim meaning: every printable key except <Leader> and <LocalLeader>
-- (mappings under those stay the user's), and SPECIAL.
local function keys()
  local set = {}
  for c = 32, 126 do
    set[vim.fn.keytrans(string.char(c))] = true
  end
  set[first_key(vim.fn.keytrans(vim.g.mapleader or '\\'))] = nil
  set[first_key(vim.fn.keytrans(vim.g.maplocalleader or '\\'))] = nil
  for _, k in ipairs(SPECIAL) do
    set[name(k)] = true
  end
  return set
end

-- Neovim's own mappings are part of plain Neovim and stay: the defaults (Y, &, gcc, ]d …) and
-- those of the plugins it ships and loads (matchit's %). Measured in `nvim --clean` 0.10 and 0.12:
-- a default's callback comes from vim/_defaults.lua or vim/_core/defaults, one without a callback
-- says ':help …-default'; neither has a script id to tell (-8, like any Lua mapping).
local function under_runtime(path)
  local runtime = vim.fs.normalize(vim.fn.resolve(vim.env.VIMRUNTIME or ''))
  path = vim.fs.normalize(vim.fn.resolve(path))
  return runtime ~= '' and vim.startswith(path, runtime .. '/')
end

local from_runtime = {} -- sid -> boolean
local function is_default(map)
  if map.callback then
    local src = debug.getinfo(map.callback, 'S').source
    if src:find('^@vim/_[%w_/]*defaults') or (src:sub(1, 1) == '@' and under_runtime(src:sub(2))) then
      return true
    end
  end
  if map.desc and map.desc:find('^:help %S+%-default$') then
    return true
  end
  local sid = map.sid
  if sid and sid > 0 then
    if from_runtime[sid] == nil then
      local info = vim.fn.getscriptinfo({ sid = sid })[1]
      from_runtime[sid] = info ~= nil and under_runtime(info.name)
    end
    return from_runtime[sid]
  end
  return false
end

--- The user's global mappings that change a Vim key: { { mode, lhs, desc }, ... }, sorted.
function M.overrides()
  local set, out = keys(), {}
  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      local lhs = vim.fn.keytrans(map.lhsraw)
      if not is_default(map) and set[first_key(lhs)] then
        out[#out + 1] = { mode = mode, lhs = lhs, desc = map.desc }
      end
    end
  end
  table.sort(out, function(a, b)
    return a.lhs == b.lhs and a.mode < b.mode or a.lhs < b.lhs
  end)
  return out
end

--- Global options that change Vim keys and differ from Neovim's default: { 'name=value', ... }.
function M.global_options()
  local out = {}
  for _, opt in ipairs(GLOBAL_OPTIONS) do
    local value = vim.api.nvim_get_option_value(opt, { scope = 'global' })
    if value ~= default(opt) then
      out[#out + 1] = ('%s=%s'):format(opt, tostring(value))
    end
  end
  return out
end

-- Every Vim key and every global mapping that starts with one maps to itself, non-recursively:
-- the key then does what Vim does. The exact lhs matters because Neovim takes the longest match
-- when the keys are already waiting (fast typing, a macro), buffer-local over global for the same
-- length. A mapping on each key also keeps trigger plugins (which-key, mini.clue) from adding
-- their own. Defaults are left alone, so Neovim's Y still is y$.
local function shadow(buf, desc)
  local set = keys()
  for _, mode in ipairs(MODES) do
    local own, defaults = {}, {}
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      local lhs = vim.fn.keytrans(map.lhsraw)
      if is_default(map) then
        defaults[lhs] = true
      elseif set[first_key(lhs)] then
        own[#own + 1] = lhs
      end
    end
    for k in pairs(set) do
      if not defaults[k] then
        own[#own + 1] = k
      end
    end
    for _, lhs in ipairs(own) do
      vim.keymap.set(mode, lhs, lhs, { buffer = buf, desc = desc })
    end
  end
end

-- which-key starts on its own when Operator-pending or Visual mode begins (ModeChanged), with no
-- mapping to cover, and counts the keys it replays twice. Its only switch for one buffer is its
-- filetype list; it may load after the buffer opened, so BufEnter asks again. A listed filetype
-- keeps which-key from building new modes for the buffer, but the modes it built on BufEnter, before
-- apply set the filetype, stay. Their triggers (<Space> among them, swallowing <Space>p) are not mapped there but by a
-- 0 ms timer: applied in the same tick, `clear` would find nothing mapped and drop the modes, and
-- the timer would map the triggers anyway. So the triggers each waiting mode holds are emptied
-- first, then `clear` unmaps whatever is mapped already; with the filetype listed, which-key builds
-- no mode again. `bufs`, `modes` and `triggers` are which-key internals (measured with which-key
-- 3aab214, 2026-10-14: 5 triggers left in the same tick without them, 0 with them); each is checked
-- by type, so a which-key without them only loses the same-tick case.
local function which_key_off(buf, filetype)
  local wk = package.loaded['which-key.config']
  -- rawget: which-key's config runs its setup() on the first read of a missing field, which would
  -- set it up with defaults before the user's own setup (measured).
  local options = type(wk) == 'table' and rawget(wk, 'options')
  local disable = type(options) == 'table' and options.disable
  local list = type(disable) == 'table' and disable.ft
  if not filetype or type(list) ~= 'table' then
    return
  end
  if not vim.tbl_contains(list, filetype) then
    table.insert(list, filetype)
  end
  local wb = package.loaded['which-key.buf']
  if type(wb) ~= 'table' then
    return
  end
  local state = type(wb.bufs) == 'table' and wb.bufs[buf]
  if type(state) == 'table' and type(state.modes) == 'table' then
    for _, mode in pairs(state.modes) do
      if type(mode) == 'table' and type(mode.triggers) == 'table' then
        mode.triggers = {}
      end
    end
  end
  if type(wb.clear) == 'function' then
    pcall(wb.clear, { buf = buf })
  end
end

local function window_options(win)
  for _, opt in ipairs(WIN_OPTIONS) do
    vim.api.nvim_set_option_value(opt, default(opt), { scope = 'local', win = win })
  end
end

--- Put buf into plain Neovim. opts.filetype replaces the buffer's filetype (one plugins do not
--- know, so Markdown rendering, linting and snippets leave it alone); opts.desc names the key
--- mappings in :map. Limits:
---   - Without opts.filetype which-key stays on: its only switch for one buffer is its filetype list.
---   - which-key set up after apply (LazyVim loads it on VeryLazy, so `nvim +Cmd` opening the buffer
---     at startup) adds its triggers while the buffer stays current; they go on the next BufEnter.
---   - The buffer's own keys belong on <Leader>, <LocalLeader> or <Plug>: apply maps every Vim key
---     to itself, also on each BufEnter, and removing mini.clue's triggers deletes any buffer-local
---     mapping on a trigger's lhs (<Leader> itself, <C-w>). Map them after apply.
function M.apply(buf, opts)
  opts = opts or {}
  local desc = opts.desc or 'plain Neovim key'
  -- mini.clue maps its triggers a tick after BufWinEnter, and once miniclue_disable is set it no
  -- longer unmaps them: remove them first (before shadow, which may map the same keys).
  local clue = package.loaded['mini.clue']
  if type(clue) == 'table' and type(clue.disable_buf_triggers) == 'function' then
    pcall(clue.disable_buf_triggers, buf)
  end
  for var, value in pairs(SWITCHES) do
    vim.b[buf][var] = value
  end
  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end
  -- After the filetype: a FileType autocmd of the user must not set them again.
  for _, opt in ipairs(BUF_OPTIONS) do
    vim.bo[buf][opt] = default(opt)
  end
  if vim.fn.exists('+autocomplete') == 1 then
    vim.api.nvim_set_option_value('autocomplete', false, { scope = 'local', buf = buf })
  end
  pcall(vim.diagnostic.enable, false, { bufnr = buf })
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    window_options(win)
  end
  shadow(buf, desc)
  which_key_off(buf, opts.filetype)
  local group = vim.api.nvim_create_augroup(('%s.%d'):format(MOD, buf), { clear = true })
  -- A plugin loaded later may map a Vim key; cover it the next time the buffer is entered.
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    buffer = buf,
    callback = function()
      shadow(buf, desc)
      which_key_off(buf, opts.filetype)
    end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    buffer = buf,
    callback = function()
      window_options(vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = buf,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end

return M
