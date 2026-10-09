-- domain: neurovim
-- Par tiers, ported from neurovim packages/core/src/engine/ParTier.ts. Proven by spec/conformance/.
local M = {}

M.SILVER_FACTOR = 1.5
M.BRONZE_FACTOR = 2.5
local PAR_BASE, PAR_PER_DIFFICULTY, FALLBACK_DIFFICULTY = 20, 20, 3

function M.default_par_keystrokes(difficulty)
  local d = (difficulty and difficulty > 0) and difficulty or FALLBACK_DIFFICULTY
  return PAR_BASE + d * PAR_PER_DIFFICULTY
end

function M.resolve_par(input)
  local override = input.parOverride
  if override and override > 0 then
    return override
  end
  return M.default_par_keystrokes(input.difficulty)
end

function M.tier_for(keys, par)
  if keys <= 0 or par <= 0 then
    return nil
  end
  if keys <= par then
    return 'gold'
  end
  if keys <= par * M.SILVER_FACTOR then
    return 'silver'
  end
  if keys <= par * M.BRONZE_FACTOR then
    return 'bronze'
  end
  return nil
end

function M.keystrokes_to_next_tier(keys, par)
  if keys <= 0 or par <= 0 then
    return nil
  end
  local current = M.tier_for(keys, par)
  if current == 'gold' then
    return nil
  end
  if current == 'silver' then
    return { nextTier = 'gold', delta = keys - par }
  end
  if current == 'bronze' then
    return { nextTier = 'silver', delta = keys - par * M.SILVER_FACTOR }
  end
  return { nextTier = 'bronze', delta = keys - par * M.BRONZE_FACTOR }
end

return M
