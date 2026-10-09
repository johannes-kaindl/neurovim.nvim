local ok, T = pcall(require, 'neurovim.kit.test')
if not ok then
  T = require('nvim_kit.test')
end

T.case('the test harness runs', function()
  T.eq(1 + 1, 2)
end)
