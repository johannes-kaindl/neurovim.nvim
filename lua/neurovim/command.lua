-- domain: neurovim
-- :NeuroVim and its subcommands.
local M = {}

local SUB = { 'check', 'mission', 'restart', 'reveal' }

function M.run(fargs)
  local sub = fargs[1]
  if not sub then
    return require('neurovim.ui.nexus').show()
  end
  if sub == 'mission' then
    if not fargs[2] then
      vim.notify('Usage: :NeuroVim mission <id>', vim.log.levels.ERROR)
      return
    end
    return require('neurovim.ui.briefing').open(fargs[2]:upper())
  end
  local mission = require('neurovim.ui.mission')
  if sub == 'check' then
    return mission.check()
  elseif sub == 'reveal' then
    return mission.reveal()
  elseif sub == 'restart' then
    return mission.restart()
  end
  vim.notify(
    ('neurovim: unknown subcommand %s — use mission, check, reveal or restart.'):format(sub),
    vim.log.levels.ERROR
  )
end

local function starting(list, lead)
  local out = {}
  for _, x in ipairs(list) do
    if x:lower():sub(1, #lead) == lead:lower() then
      out[#out + 1] = x
    end
  end
  return out
end

function M.complete(arglead, cmdline)
  local words = vim.split(cmdline, '%s+', { trimempty = true })
  local n = #words - (arglead == '' and 0 or 1) -- words before the one being completed
  if n <= 1 then
    return starting(SUB, arglead)
  end
  if n == 2 and words[2] == 'mission' then
    local ids = {}
    for _, m in ipairs(require('neurovim.missions').story()) do
      ids[#ids + 1] = m.id
    end
    return starting(ids, arglead)
  end
  return {}
end

return M
