-- domain: neurovim
-- Run metrics, ported from neurovim packages/core/src/engine/MetricsTracker.ts (metricsResult).
-- Proven by spec/conformance/.
local M = {}

function M.metrics_result(keystrokes, elapsed_ms)
  local ks_per_min = 0
  if elapsed_ms > 0 then
    -- JavaScript Math.round(x) / 10: halves round up.
    ks_per_min = math.floor(keystrokes / elapsed_ms * 60000 * 10 + 0.5) / 10
  end
  return { elapsed_ms = elapsed_ms, keystrokes = keystrokes, ks_per_min = ks_per_min }
end

return M
