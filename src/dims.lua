local dims = {}

local types = require("std.types")

function dims.wrap(x, y, width, height)
    if type(y) == "nil" then
        assert(x)
        return dims.wrap(x.x, x.y, x.width, x.height)
    end
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(width) == "number")
    assert(type(height) == "number")
    local self = {
        x = x,
        y = y,
        width = width,
        height = height
    }
    setmetatable(self, dims)
    return self
end

function dims:unpack()
    return self.x, self.y, self.width, self.height
end

return types.makeType(dims, "dims")
