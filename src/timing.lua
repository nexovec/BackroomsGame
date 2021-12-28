local timing = {}

-- TODO: user-defined timer, then move to std
local lua = require("std.luaOverrides")
local delayedCalls = {}
function timing.delayCall(func, delayInSeconds)
    -- TODO: test with callable metatables
    assert(isCallable)
    delayedCalls[#delayedCalls + 1] = {startTime = love.timer.getTime(), delay = delayInSeconds, call = func}
end
function timing.update()
    -- TODO: test
    for i, v in ipairs(delayedCalls) do
        if love.timer.getTime() - v.startTime > v.delay then
            v.call()
            table.remove(delayedCalls, i)
        end
    end
end
return timing