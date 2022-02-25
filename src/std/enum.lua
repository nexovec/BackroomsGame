local enum = {}
local types = require("std.types")

function enum.wrap(...)
    local res = {}
    for _, v in ipairs {...} do
        res[v] = v
    end
    return res
end
function enum.__index(v)
    error("Not an enum item: " .. tostring(v))
end

return types.makeType(enum, "enum")
