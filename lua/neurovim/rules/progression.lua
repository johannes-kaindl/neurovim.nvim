-- domain: neurovim
-- Progression rules, ported from neurovim packages/core/src/engine/ProgressionEngine.ts.
-- Proven by spec/conformance/. Dates are UTC YYYY-MM-DD strings; "yesterday" is calendar
-- arithmetic, never os.time (local time and DST would shift it).
local data = require('neurovim.data')

local M = {}

local function copy(t)
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

-- Days since 1970-01-01 for a proleptic Gregorian date, and back (H. Hinnant's algorithms).
local function days_from_civil(y, m, d)
  y = m <= 2 and y - 1 or y
  local era = math.floor(y / 400)
  local yoe = y - era * 400
  local doy = math.floor((153 * ((m + 9) % 12) + 2) / 5) + d - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

local function civil_from_days(z)
  z = z + 719468
  local era = math.floor(z / 146097)
  local doe = z - era * 146097
  local yoe =
    math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
  local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
  local mp = math.floor((5 * doy + 2) / 153)
  local d = doy - math.floor((153 * mp + 2) / 5) + 1
  local m = mp < 10 and mp + 3 or mp - 9
  local y = yoe + era * 400
  return m <= 2 and y + 1 or y, m, d
end

local function yesterday(day)
  local y, m, d = day:match('^(%d+)-(%d+)-(%d+)$')
  local yy, mm, dd = civil_from_days(days_from_civil(tonumber(y), tonumber(m), tonumber(d)) - 1)
  return ('%04d-%02d-%02d'):format(yy, mm, dd)
end

local function utc_today()
  return os.date('!%Y-%m-%d')
end

function M.record_completion(d, today)
  today = today or utc_today()
  if d.streak_last_date == today then
    return d
  end
  local r = copy(d)
  r.streak_current = d.streak_last_date == yesterday(today) and d.streak_current + 1 or 1
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
    last_run = today or utc_today(),
  }
end

M._data = data -- used by part 2 (task 7)

return M
