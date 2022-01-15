local network = {}
local string = require("std.string")
function network.getNetworkMessagePrefix(data)
    print(data)
    -- for k = 1, #data do
    --     if string.sub(data, k, k) == ":" then return string.sub(data, 1, k-1), string.sub(data, k + 1, #data) end
    -- end
    -- error("This message has no prefix: " .. data, 2)


    local splitString = string.split(data, ":")
    if #splitString <= 1 then
    -- TODO: don't crash, just log this and return
    error("This message has no prefix: " .. data, 2)
    end
    local prefix = splitString[1]
    local rest = string.sub(data, #splitString[1] + 2, #data)
    return prefix, rest
end
return network