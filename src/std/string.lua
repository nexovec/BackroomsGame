local string = setmetatable({}, {
    __index = string
})

local types = require("std.types")
local utf8 = require("utf8")
local array = require("std.array")

function string.__call()
    error("Not yet implemented.")
end
function string.popped(str)
    str = string.sub(str, 1, utf8.offset(str, utf8.len(str)) - 1)
    return str
end
function string.join(tableOfStrings, separator)
    if not separator then
        separator = " "
    end
    assert(type(tableOfStrings) == "table")
    return table.concat(tableOfStrings, separator)
end
function string.split(str, sep)
    assert(utf8.len(sep) == 1, "Multi-character separators are not implemented yet", 2)
    local sepCode = utf8.codepoint(sep)
    local res = array.wrap()
    local lastSep = 0
    local charIndex = 0
    for o, c in utf8.codes(str) do
        charIndex = charIndex + 1
        if c == sepCode then
            res:append(string.sub(str, lastSep + 1, utf8.offset(str, charIndex) - 1))
            lastSep = o
            -- lastSep = utf8.offset(str, charIndex + 1)
        end
    end
    res:append(string.sub(str, lastSep + 1, #str))
    return res
end

return types.makeType(string, "string")
