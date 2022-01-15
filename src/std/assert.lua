local assert = {}
local types = require("std.types")
function assert.__call(term, errMsg, errLevel, errHandle)
    -- TODO: use errHandle
    -- TODO: test errMsg == nil
    errMsg = errMsg or "assertion failed!"
    errLevel = errLevel or 1
    if not term then
        error(errMsg, 1 + errLevel)
    end
end
setmetatable(assert, assert)
return types.makeType(assert)