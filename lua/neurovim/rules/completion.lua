-- domain: neurovim
-- One completed mission run, ported from neurovim packages/core/src/engine/MissionCompletion.ts.
-- Proven by spec/conformance/. XP on every completion (replays too); a run without a single
-- keystroke (pasted, already solved, an outside edit) wins its XP but sets no bests.
local progression = require('neurovim.rules.progression')
local par = require('neurovim.rules.par')
local date = require('neurovim.kit.date')

local M = {}

local function bump_run_only(prev, today)
  prev = prev or {}
  return {
    best_time_ms = prev.best_time_ms or 0,
    best_keystrokes = prev.best_keystrokes or 0,
    best_ks_per_min = prev.best_ks_per_min or 0,
    runs = (prev.runs or 0) + 1,
    last_run = today,
  }
end

function M.complete_mission(d, mission, metrics, today)
  today = today or date.utc_today()
  local added = progression.add_xp(d, mission.xp_reward)
  local nd = vim.tbl_extend('force', {}, progression.record_completion(added.new_data, today))
  if not vim.tbl_contains(nd.completed_missions, mission.mission_id) then
    local list = vim.tbl_extend('force', {}, nd.completed_missions)
    list[#list + 1] = mission.mission_id
    nd.completed_missions = list
  end
  local unverified = metrics.keystrokes == 0
  local prev = nd.missions[mission.mission_id]
  local record = unverified and bump_run_only(prev, today)
    or progression.record_mission_run(prev, metrics, today)
  local missions = vim.tbl_extend('force', {}, nd.missions)
  missions[mission.mission_id] = record
  nd.missions = missions
  local p = par.resolve_par({ parOverride = mission.par_keystrokes, difficulty = mission.difficulty })
  return {
    data = nd,
    xp = mission.xp_reward,
    level_up = added.level_up,
    record = record,
    par = p,
    tier = par.tier_for(metrics.keystrokes, p),
    to_next_tier = par.keystrokes_to_next_tier(metrics.keystrokes, p),
    unverified = unverified,
  }
end

return M
