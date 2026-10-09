-- domain: neurovim
-- The missions — story chapters, then the KATAs (drills without a briefing) — and their state for
-- one player.
local data = require('neurovim.data')
local par = require('neurovim.rules.par')
local progression = require('neurovim.rules.progression')

local M = {}

local all, story, katas, by_id

local function index()
  if all then
    return
  end
  all, story, katas, by_id = {}, {}, {}, {}
  for _, m in ipairs(data.get().missions) do
    all[#all + 1] = m
    by_id[m.id] = m
    if m.kata then
      katas[#katas + 1] = m
    else
      story[#story + 1] = m
    end
  end
end

function M.all()
  index()
  return all
end

function M.story()
  index()
  return story
end

function M.katas()
  index()
  return katas
end

function M.get(id)
  index()
  return by_id[id]
end

function M.chapters()
  index()
  local out = {}
  for _, c in ipairs(data.get().chapters) do
    local list = {}
    for _, id in ipairs(c.missions) do
      if by_id[id] then
        list[#list + 1] = by_id[id]
      end
    end
    if #list > 0 then
      out[#out + 1] = { label = c.label, missions = list }
    end
  end
  out[#out + 1] = { label = 'KATAS', missions = katas }
  return out
end

function M.par(m)
  return par.resolve_par({ parOverride = m.par_keystrokes, difficulty = m.difficulty })
end

function M.status(s, m)
  if vim.tbl_contains(s.completed_missions or {}, m.id) then
    local rec = (s.missions or {})[m.id]
    local tier = rec
        and rec.best_keystrokes
        and rec.best_keystrokes > 0
        and par.tier_for(rec.best_keystrokes, M.par(m))
      or nil
    return { kind = 'done', tier = tier }
  end
  if vim.tbl_contains(s.unlocked or {}, m.id) then
    return { kind = 'open' }
  end
  return { kind = 'locked', unlock_level = progression.unlock_level_for(m.id) }
end

return M
