local error = require("std.error")

return function(term, errMsg, errLevel, errHandle)
    -- TODO: Use errHandle
    -- TODO: Test errMsg == nil
    errMsg = errMsg or "Assertion failed!"
    errLevel = errLevel or 1
    if not term then
        if errHandle then
            errHandle()
        else
            error(errMsg, 1 + errLevel)
        end
    end
end
