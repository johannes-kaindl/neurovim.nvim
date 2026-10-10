-- domain: neurovim
-- :checkhealth neurovim — what a player checks first when something looks wrong. Diagnosis only:
-- the save file is read, never moved or repaired (NeuroVim itself sets a broken one aside the next
-- time it reads it).
local kit = require('neurovim.kit.health')
local data = require('neurovim.data')
local state = require('neurovim.state')

local M = {}

function M.check()
  local root = vim.fn.fnamemodify(data.path(), ':h:h')
  vim.health.start('Neovim')
  kit.neovim('0.10')

  vim.health.start('Game data')
  local d = kit.json(data.path(), {
    label = 'missions and tables',
    schema = 1,
    advice = { 'Re-vendor data/ from neurovim (AGENTS.md § Conformance), or reinstall the plugin.' },
  })
  if d then
    local kata = 0
    for _, m in ipairs(d.missions) do
      kata = kata + (m.kata and 1 or 0)
    end
    vim.health.info(('%d missions: %d story, %d KATA'):format(#d.missions, #d.missions - kata, kata))
  end

  vim.health.start('Save file')
  kit.json(state.path(), {
    label = 'save',
    expect = 'object',
    missing = 'ok',
    missing_text = 'no save yet — it is written after the first solved mission',
    invalid = 'warn',
    advice = {
      'Broken: NeuroVim keeps it as state.json.broken-<time> the next time NeuroVim reads it (any :NeuroVim) and begins a fresh save.',
      'Cannot be read: fix its permissions — NeuroVim leaves it untouched and saves nothing until then.',
    },
  })
  kit.writable(vim.fn.fnamemodify(state.path(), ':h'), 'save directory')

  vim.health.start('Vendored')
  kit.vendored(root .. '/lua/neurovim/kit/VENDOR.json', 'library')
  kit.vendored(root .. '/data/VENDOR.json', 'game data')
end

return M
