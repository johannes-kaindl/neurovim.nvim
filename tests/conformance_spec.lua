local T = require('neurovim.kit.test')
local C = require('neurovim.kit.conformance')
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
local DIR = root .. '/spec/conformance'

local diff = require('neurovim.rules.diff')
local par = require('neurovim.rules.par')
local progression = require('neurovim.rules.progression')

-- TS function name → Lua port. Grows with tasks 5–7.
local IMPLS = {
  normalizeMissionText = diff.normalize_mission_text,
  getDiff = diff.get_diff,
  getDivergentLines = diff.get_divergent_lines,
  resolvePar = par.resolve_par,
  tierFor = par.tier_for,
  keystrokesToNextTier = par.keystrokes_to_next_tier,
  recordCompletion = progression.record_completion,
  recordMissionRun = progression.record_mission_run,
}

-- Ports not written yet. Phase 3 only: each is announced as PENDING on every run, never counted
-- as passed, and task 7 deletes this table together with the branch below that reads it.
local PENDING = {
  getLevelForXp = true,
  addXp = true,
  backfillUnlocks = true,
  getXpProgress = true,
}

local vectors = C.load_dir(DIR)
local names = vim.tbl_keys(vectors)
table.sort(names)

for _, name in ipairs(names) do
  if PENDING[name] then
    io.write('PENDING conformance: ' .. name .. '\n')
  else
    T.case('conformance: ' .. name, function()
      T.ok(IMPLS[name], 'no Lua port for ' .. name)
      T.eq(C.run(vectors[name], IMPLS[name]), {})
    end)
  end
end

T.case('every vector is ported or explicitly pending, and no pending entry is stale', function()
  for _, name in ipairs(names) do
    T.ok(IMPLS[name] or PENDING[name], name .. ' is neither ported nor pending')
  end
  for name in pairs(PENDING) do
    T.ok(vectors[name], name .. ' is pending but has no vector')
    T.ok(not IMPLS[name], name .. ' is ported and still pending')
  end
end)

T.case('the vector set is the one the port was written against', function()
  T.eq(#names, 12)
end)
