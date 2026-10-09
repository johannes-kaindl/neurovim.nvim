-- domain: neurovim
-- Progression rules, ported from neurovim packages/core/src/engine/ProgressionEngine.ts.
-- Proven by spec/conformance/. Dates are UTC YYYY-MM-DD strings; "yesterday" is the kit's
-- calendar arithmetic, never os.time (local time and DST would shift it).
local data = require('neurovim.data')
local date = require('neurovim.kit.date')

local M = {}

local function copy(t)
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

function M.record_completion(d, today)
  today = today or date.utc_today()
  if d.streak_last_date == today then
    return d
  end
  local r = copy(d)
  r.streak_current = d.streak_last_date == date.add_days(today, -1) and d.streak_current + 1 or 1
  r.streak_last_date = today
  return r
end

function M.record_mission_run(prev, metrics, today)
  prev = prev or {}
  local function lower(cur, nxt)
    if cur > 0 then
      return math.min(cur, nxt)
    end
    return nxt
  end
  return {
    best_time_ms = lower(prev.best_time_ms or 0, metrics.elapsed_ms),
    best_keystrokes = lower(prev.best_keystrokes or 0, metrics.keystrokes),
    best_ks_per_min = math.max(prev.best_ks_per_min or 0, metrics.ks_per_min),
    runs = (prev.runs or 0) + 1,
    last_run = today or date.utc_today(),
  }
end

local function levels()
  return data.get().levels
end

local function contains(list, x)
  for _, v in ipairs(list) do
    if v == x then
      return true
    end
  end
  return false
end

function M.get_level_for_xp(xp)
  local level = 1
  for _, l in ipairs(levels()) do
    if xp >= l.xp_required then
      level = l.level
    end
  end
  return level
end

-- Records today's behaviour: a jump over several levels grants only the target level's
-- unlocks (backfill_unlocks repairs the rest on load) — exactly what the vectors expect.
function M.add_xp(d, amount)
  local old_level = M.get_level_for_xp(d.total_xp)
  local new_xp = d.total_xp + amount
  local new_level = M.get_level_for_xp(new_xp)
  local unlocked = {}
  for i, v in ipairs(d.unlocked or {}) do
    unlocked[i] = v
  end
  local level_up
  if new_level > old_level then
    local u = data.get().unlock_map[tostring(new_level)] or { missions = {}, loot = {} }
    for _, list in ipairs({ u.missions, u.loot }) do
      for _, id in ipairs(list) do
        if not contains(unlocked, id) then
          unlocked[#unlocked + 1] = id
        end
      end
    end
    level_up =
      { old_level = old_level, new_level = new_level, unlocked_missions = u.missions, unlocked_loot = u.loot }
  end
  local new_data = copy(d)
  new_data.total_xp = new_xp
  new_data.unlocked = unlocked
  return { new_data = new_data, level_up = level_up }
end

function M.backfill_unlocks(d)
  local out, seen = {}, {}
  local function add(id)
    if not seen[id] then
      seen[id] = true
      out[#out + 1] = id
    end
  end
  for _, id in ipairs(d.unlocked or {}) do
    add(id)
  end
  for _, id in ipairs(data.get().default_unlocked) do
    add(id)
  end
  for lvl = 2, M.get_level_for_xp(d.total_xp) do
    local u = data.get().unlock_map[tostring(lvl)]
    if u then
      for _, id in ipairs(u.missions) do
        add(id)
      end
      for _, id in ipairs(u.loot) do
        add(id)
      end
    end
  end
  for _, id in ipairs(d.completed_missions or {}) do
    add(id)
  end
  local r = copy(d)
  r.unlocked = out
  return r
end

function M.get_xp_progress(xp)
  local level = M.get_level_for_xp(xp)
  local cur, nxt = levels()[1], nil
  for _, l in ipairs(levels()) do
    if l.level == level then
      cur = l
    elseif l.level == level + 1 then
      nxt = l
    end
  end
  if not nxt then
    return { level = level, into = 0, span = 0, pct = 100 }
  end
  local span = nxt.xp_required - cur.xp_required
  local into = xp - cur.xp_required
  -- JavaScript Math.round: halves round up.
  local pct = span > 0 and math.min(100, math.floor(into / span * 100 + 0.5)) or 100
  return {
    level = level,
    into = into,
    span = span,
    pct = pct,
    nextLevelXp = nxt.xp_required,
    nextTitle = nxt.title,
  }
end

function M.unlock_level_for(id)
  local levels_with_unlocks = {}
  for k in pairs(data.get().unlock_map) do
    levels_with_unlocks[#levels_with_unlocks + 1] = tonumber(k)
  end
  table.sort(levels_with_unlocks)
  for _, lvl in ipairs(levels_with_unlocks) do
    local u = data.get().unlock_map[tostring(lvl)]
    if contains(u.missions, id) or contains(u.loot, id) then
      return lvl
    end
  end
  return nil
end

return M
