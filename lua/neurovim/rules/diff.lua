-- domain: neurovim
-- Scoring rules, ported from neurovim packages/core/src/utils/diff.ts. Proven by the vectors in
-- spec/conformance/ — change the TS core first, re-vendor, then follow here.
local M = {}

-- Characters JavaScript's `\s` matches beyond ASCII, as UTF-8 byte sequences. A port that strips
-- only ASCII whitespace fails the vectors (Option+Space types U+00A0 on macOS).
local UNICODE_SPACE = {
  '\194\160', -- U+00A0
  '\225\154\128', -- U+1680
  '\226\128\168', -- U+2028
  '\226\128\169', -- U+2029
  '\226\128\175', -- U+202F
  '\226\129\159', -- U+205F
  '\227\128\128', -- U+3000
  '\239\187\191', -- U+FEFF
}
for cp = 0x2000, 0x200A do
  table.insert(UNICODE_SPACE, string.char(0xE2, 0x80, 0x80 + (cp - 0x2000)))
end

local function rstrip(line)
  while true do
    local last = line:sub(-1)
    if last == ' ' or last == '\t' or last == '\r' or last == '\v' or last == '\f' then
      line = line:sub(1, -2)
    else
      local hit = false
      for _, seq in ipairs(UNICODE_SPACE) do
        if #line >= #seq and line:sub(-#seq) == seq then
          line = line:sub(1, -#seq - 1)
          hit = true
          break
        end
      end
      if not hit then
        return line
      end
    end
  end
end

-- Length of the match of /^---[ \t]*\r?\n(?:[^\r\n]*\r?\n)*?---[ \t]*(?:\r?\n|$)/, or 0.
-- The lazy repetition tries a closing fence before consuming each further line.
local function frontmatter_length(s)
  local first = s:match('^%-%-%-[ \t]*\r?\n')
  if not first then
    return 0
  end
  local pos = #first + 1
  while true do
    local close = s:match('^%-%-%-[ \t]*\r?\n', pos)
    if close then
      return pos - 1 + #close
    end
    if s:match('^%-%-%-[ \t]*$', pos) then
      return #s
    end
    local line = s:match('^[^\r\n]*\r?\n', pos)
    if not line then
      return 0
    end
    pos = pos + #line
  end
end

function M.normalize_mission_text(text)
  local bom = text:sub(1, 3) == '\239\187\191' and 3 or 0
  local body = text:sub(bom + 1)
  local head_len = frontmatter_length(body)
  local head = body:sub(1, head_len)
  local all = vim.split(body:sub(head_len + 1), '\n', { plain = true })
  for i, l in ipairs(all) do
    all[i] = rstrip(l)
  end
  local first, last = 1, #all
  while first <= #all and all[first] == '' do
    first = first + 1
  end
  while last >= first and all[last] == '' do
    last = last - 1
  end
  local head_lines = 0
  if head ~= '' then
    local _, newlines = head:gsub('\n', '')
    head_lines = head:sub(-1) == '\n' and newlines or newlines + 1
  end
  local lines = {}
  for i = first, last do
    lines[#lines + 1] = all[i]
  end
  return { lines = lines, offset = head_lines + first - 1 }
end

function M.get_diff(current, solution)
  local a = M.normalize_mission_text(current).lines
  local b = M.normalize_mission_text(solution).lines
  local first, off = -1, 0
  for i = 1, math.max(#a, #b) do
    if a[i] ~= b[i] then
      if first == -1 then
        first = i - 1
      end
      off = off + 1
    end
  end
  if off == 0 then
    return { matches = true, first_divergent_line = -1, lines_off = 0 }
  end
  return { matches = false, first_divergent_line = first, lines_off = off }
end

function M.get_divergent_lines(current, solution)
  local cur = M.normalize_mission_text(current)
  local b = M.normalize_mission_text(solution).lines
  local out = {}
  for i = 1, math.max(#cur.lines, #b) do
    if cur.lines[i] ~= b[i] then
      out[#out + 1] = i - 1 + cur.offset
    end
  end
  return out
end

return M
