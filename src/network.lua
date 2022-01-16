local network = {}


local assert = require("std.assert")
local string = require("std.string")


function network.getNetworkMessagePrefix(data)
    assert(type(data) == "string", "The parameter must be string data", 2)
    local splitString = string.split(data, ":")
    if #splitString <= 1 then
    -- TODO: don't crash, just log this and return
    -- error("This message has no prefix: " .. data, 2)
        return nil, data
    end
    local prefix = splitString[1]
    local rest = string.sub(data, #splitString[1] + 2, #data)
    return prefix, rest
end

return network