local T = require('neurovim.kit.test')
local state = require('neurovim.state')

-- Each case looks at its own save and gives the data dir back afterwards, also when it fails.
local function with_fresh_save(fn)
  local before = vim.env.XDG_DATA_HOME
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  local ok, err = pcall(fn)
  vim.env.XDG_DATA_HOME = before
  if not ok then
    error(err, 0)
  end
end

local function checkhealth()
  vim.cmd('silent checkhealth neurovim') -- silent: no progress line in the test report
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  vim.cmd('bwipeout!')
  return text
end

T.case('a fresh install: Neovim, game data, no save yet, vendored pins — and no ERROR', function()
  with_fresh_save(function()
    local out = checkhealth()
    T.ok(out:find('OK Neovim', 1, true), out)
    T.ok(out:find('54 missions: 40 story, 14 KATA', 1, true), out)
    T.ok(out:find('no save yet', 1, true), out)
    T.ok(out:find('nvim-kit@0.5.1', 1, true), out)
    T.ok(out:find('neurovim@', 1, true), out)
    T.eq(out:find('ERROR', 1, true), nil, out)
  end)
end)

T.case('a broken save is a WARNING, and checkhealth leaves the file exactly as it was', function()
  with_fresh_save(function()
    local p = state.path()
    vim.fn.mkdir(vim.fn.fnamemodify(p, ':h'), 'p')
    local before = '{ broken\r\n\0 no final newline'
    local f = assert(io.open(p, 'wb'))
    f:write(before)
    f:close()
    local out = checkhealth()
    T.ok(out:find('WARNING save', 1, true), out)
    f = assert(io.open(p, 'rb'))
    T.eq(f:read('*a'), before)
    f:close()
    T.eq(vim.fn.glob(p .. '.broken-*', false, true), {})
  end)
end)

T.case('a save directory that cannot be written is an ERROR', function()
  with_fresh_save(function()
    local base = vim.env.XDG_DATA_HOME
    vim.fn.mkdir(base, 'p')
    vim.fn.setfperm(base, 'r-xr-xr-x')
    local ok, out = pcall(checkhealth)
    vim.fn.setfperm(base, 'rwxr-xr-x')
    assert(ok, out)
    T.ok(out:find('ERROR save directory', 1, true), out)
  end)
end)

T.case('a save that cannot be read is a WARNING, and checkhealth leaves it exactly as it was', function()
  with_fresh_save(function()
    local p = state.path()
    vim.fn.mkdir(vim.fn.fnamemodify(p, ':h'), 'p')
    vim.fn.writefile({ '{"total_xp":5}' }, p)
    vim.fn.setfperm(p, '---------')
    local ok, out = pcall(checkhealth)
    vim.fn.setfperm(p, 'rw-r--r--')
    assert(ok, out)
    T.ok(out:find('WARNING save', 1, true), out)
    T.ok(out:find('cannot be read', 1, true), out)
    T.ok(out:find('next time NeuroVim reads it', 1, true), out)
    T.eq(vim.fn.readfile(p), { '{"total_xp":5}' })
    T.eq(vim.fn.glob(p .. '.broken-*', false, true), {})
  end)
end)
