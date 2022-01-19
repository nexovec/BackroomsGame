local callback = {}
local assert = require("std.assert")
local types = require("std.types")

function callback:connect(eventHandle)
    -- TODO:
    assert()
end

function callback.wrap()
    return setmetatable(func, callback)
end

return types.makeType(callback, "callback")