-- domain: neurovim
-- :checkhealth neurovim — what a player checks first when something looks wrong. Diagnosis only:
-- the save file is read, never moved or repaired (NeuroVim itself sets a broken one aside the next
-- time it reads it).
local kit = require('neurovim.kit.health')
local data = require('neurovim.data')
local state = require('neurovim.state')
local config = require('neurovim.config')
local isolate = require('neurovim.isolate')

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

  vim.health.start('Mission buffers')
  if config.isolate then
    vim.health.ok('mission buffers run in plain Neovim (isolate = true)')
  else
    local over = isolate.overrides()
    if #over == 0 then
      vim.health.ok('mission buffers run with your setup (isolate = false); no mapping changes a Vim key')
    else
      local shown = {}
      for i = 1, math.min(#over, 12) do
        shown[i] = over[i].mode .. ' ' .. over[i].lhs
      end
      vim.health.warn(
        ('mission buffers run with your setup (isolate = false): %d mapping%s change%s Vim keys: %s%s'):format(
          #over,
          #over == 1 and '' or 's',
          #over == 1 and 's' or '',
          table.concat(shown, ', '),
          #over > #shown and (', and %d more'):format(#over - #shown) or ''
        ),
        {
          'Objective, par and key count assume plain Vim keys: leave isolate on, see :help neurovim-isolate',
        }
      )
    end
  end
  local globals = isolate.global_options()
  if #globals > 0 then
    vim.health.info(
      ('global options that change Vim keys apply in missions too: %s'):format(table.concat(globals, ', '))
    )
  end

  vim.health.start('Vendored')
  kit.vendored(root .. '/lua/neurovim/kit/VENDOR.json', 'library')
  kit.vendored(root .. '/data/VENDOR.json', 'game data')
end

return M
