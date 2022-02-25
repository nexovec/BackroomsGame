local ref = {}
local types = require("std.types")
-- local assert = require("std.assert")

function ref.wrap(obj)
    -- assert(obj, "Can't make an empty reference.", 2)
    return setmetatable({
        val = obj
    }, ref)
end

return types.makeType(ref, "ref")
