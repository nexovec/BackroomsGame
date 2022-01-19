local callback = {}
local assert = require("std.assert")
local types = require("std.types")


function types.isCallable(var)
    return type(var) == "function" or (type(var) == "table" and getmetatable(var).__call)
end

function callback:connect(eventHandle)
    -- TODO:
    assert()
end
function callback.wrap(func)
    assert(isCallable(func))
    return setmetatable(func, func)
end
return types.makeType(callback)