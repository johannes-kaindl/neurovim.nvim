-- domain: neurovim
-- NeuroVim has no options; plugin/neurovim.lua sets everything up when it loads. setup() exists so
-- that a plugin manager calling it (lazy.nvim with `opts = {}`) does no harm.
local M = {}

function M.setup(opts)
  local names = vim.tbl_keys(opts or {})
  if #names > 0 then
    table.sort(names)
    vim.notify(
      ('neurovim: there are no options — ignored: %s.'):format(table.concat(names, ', ')),
      vim.log.levels.WARN
    )
  end
end

return M
