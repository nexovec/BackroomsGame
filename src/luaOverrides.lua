-- overrides for lua built-ins
local oldreq = require
require = function(s)
    -- TODO: requireLibraryLocation() function
    local res = nil
    local function srcreq()
        res = oldreq("src." .. s)
    end
    local function libsreq()
        res = oldreq("libs." .. s)
    end
    xpcall(srcreq, function() xpcall(libsreq, function() error("Module " .. s .. "not found", 2) end) end)
    return res
end
local oldreq = nil

local oldassert = assert
function assert(term, errMsg, errLevel, errHandle)
    errMsg = errMsg or "assertion failed!"
    errLevel = errLevel or 1
    if not term then error(errMsg, 1 + errLevel) end
end
oldassert = nil

love.settings = {
    targetFPS = 60,
    performanceLoggingPeriodInSeconds = 5
}