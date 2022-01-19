local assert = {}

-- API

function assert.__call(term, errMsg, errLevel, errHandle)
    -- TODO: Use errHandle
    -- TODO: Test errMsg == nil
    errMsg = errMsg or "assertion failed!"
    errLevel = errLevel or 1
    if not term then
        error(errMsg, 1 + errLevel)
    end
end
setmetatable(assert, assert)
return assert