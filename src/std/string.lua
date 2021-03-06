local string = setmetatable({}, {
    __index = string
})

local types = require("std.types")
local utf8 = require("utf8")
local array = require("std.array")
local assert = require("std.assert")

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

function string.extension(str)
    local res = string.split(str, ".")
    return "." .. res[#res]
end

function string.startsWith(str, startingLetters)
    -- TODO: Test
    local comparedCodes = array.wrap()
    for _, c in utf8.codes(startingLetters) do
        -- NOTE: will likely produce false positives in non-ASCII
        -- TODO: Detect escape characters
        comparedCodes:append(c)
    end
    local i = 0
    for _, c in utf8.codes(str) do
        i = i + 1
        if i > #comparedCodes then
            return true
        end
        if c ~= comparedCodes[i] then
            return false
        end
    end
    if i < #comparedCodes then
        return false
    end
    return true
end

function string.endsWidth(str, endingLetters)
    -- TODO:
end

function string.split(str, sep)
    assert(utf8.len(sep) == 1, "Multi-character separators are not implemented yet", 2)
    local sepCode = utf8.codepoint(sep)
    local res = array.wrap()
    local lastSep = 0
    local charIndex = 0
    for p, c in utf8.codes(str) do
        charIndex = charIndex + 1
        if c == sepCode then
            res:append(string.sub(str, lastSep + 1, utf8.offset(str, charIndex) - 1))
            lastSep = p
            -- lastSep = utf8.offset(str, charIndex + 1)
        end
    end
    res:append(string.sub(str, lastSep + 1, #str))
    return res
end

return types.makeType(string, "string")
