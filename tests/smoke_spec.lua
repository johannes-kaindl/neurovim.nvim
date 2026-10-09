local T = require('neurovim.kit.test')

T.case('the vendored test harness runs', function()
  T.eq(1 + 1, 2)
end)
