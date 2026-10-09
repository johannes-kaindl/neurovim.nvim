local T = require('neurovim.kit.test')
local C = require('neurovim.kit.conformance')
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
local DIR = root .. '/spec/conformance'

local diff = require('neurovim.rules.diff')
local par = require('neurovim.rules.par')
local progression = require('neurovim.rules.progression')
local metrics = require('neurovim.rules.metrics')
local completion = require('neurovim.rules.completion')

-- TS function name → Lua port.
local IMPLS = {
  normalizeMissionText = diff.normalize_mission_text,
  getDiff = diff.get_diff,
  getDivergentLines = diff.get_divergent_lines,
  resolvePar = par.resolve_par,
  tierFor = par.tier_for,
  keystrokesToNextTier = par.keystrokes_to_next_tier,
  recordCompletion = progression.record_completion,
  recordMissionRun = progression.record_mission_run,
  getLevelForXp = progression.get_level_for_xp,
  addXp = progression.add_xp,
  backfillUnlocks = progression.backfill_unlocks,
  getXpProgress = progression.get_xp_progress,
  completeMission = completion.complete_mission,
  metricsResult = metrics.metrics_result,
  unlockLevelFor = progression.unlock_level_for,
}

local vectors = C.load_dir(DIR)
local names = vim.tbl_keys(vectors)
table.sort(names)

for _, name in ipairs(names) do
  T.case('conformance: ' .. name, function()
    T.ok(IMPLS[name], 'no Lua port for ' .. name)
    T.eq(C.run(vectors[name], IMPLS[name]), {})
  end)
end

T.case('every vector has a Lua port', function()
  for _, name in ipairs(names) do
    T.ok(IMPLS[name], 'no Lua port for ' .. name)
  end
end)

T.case('the vector set is the one the port was written against', function()
  T.eq(#names, 15)
end)
