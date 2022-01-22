local cbkHandle = {}


local assert = require("std.assert")
local types = require("std.types")
local array = require("std.array")

-- API

function cbkHandle:connect(callback)
    assert(self)
    assert(types.isCallable(callback), "This is not a valid callback function!")
    self.subscribers:append(callback)
end

function cbkHandle:fire(...)
    for i, v in self.subscribers:iter() do
        v(...)
    end
end

function cbkHandle.wrap()
    local res = {subscribers = array:wrap()}
    return setmetatable(res, cbkHandle)
end

return types.makeType(cbkHandle, "cbkHandle")