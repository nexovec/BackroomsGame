local assert = require("std.assert")
-- ! sets some globals
-- overrides for lua built-ins
-- local oldreq = require
-- require = function(s)
--     -- TODO: requireLibraryLocation() function
--     local res = nil
--     local function srcreq()
--         res = oldreq("src." .. s)
--     end
--     local function libsreq()
--         res = oldreq("libs." .. s)
--     end
--     xpcall(srcreq, function()
--         xpcall(libsreq, function()error("Module " .. s .. "not found", 2)end)
--     end)
--     return res
-- end
-- local oldreq = nil
--- Throw an error if var is none of the specified types.
---@param var any
---@param ... string variable arguments
---@return nil
local function assertType(var, ...)
    local params = {...}
    for k, v in ipairs(params) do
        assert(type(v) == "string", "Argument #" .. tostring(k) .. " has unexpected type " .. type(v), nil, nil)
        if type(var) == v then
            return
        end
        if type(var) == "userdata" and var.type() == v then
            return
        end
    end
    error("Type assert failed", 2)
end
local function isCallable(var)
    -- TODO: Test
    return type(var) == "function" or (type(var) == "table" and getmetatable(var).__call)
end

return {
    isCallable = isCallable,
    assertType = assertType
}
