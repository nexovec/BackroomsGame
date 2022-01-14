local map = {}
local types = require("std.types")

function map:prettyPrint()
    if not self then
        return error('Table is nil!', 2)
    end
    if type(self) ~= 'table' then
        error('This is not a table. type: ' .. type(self) .. ((" " .. (self.type and self.type())) or ""), 2)
    end
    print('contents of a table:')
    print('-----------')
    for k, v in pairs(self) do
        local strv = tostring(v)
        print(tostring(k) .. string.rep(' ', math.max(50 - #strv, 0)) .. ':\t' .. strv)
    end
    print('-----------')
end
function map:contains(elem)
    for k, v in pairs(self) do
        if v == elem then
            return true
        end
    end
    return false
end
function map:indexOf(elem)
    for i, v in pairs(self) do
        if v == elem then return i end
    end
    return nil
end

function map:prettyPrint()
    table.prettyPrint(self)
end

function map:invert()
    local res = {}
    for k, v in pairs(self) do
        -- if not type(v) == "string" or type(v) == "number" then error("Table contains uninvertable type at index " .. k, 2) end
        res[v] = k
    end
    return res
end
function map.wrap(obj)
    return setmetatable(obj, map)
end
function map.new()
    local self = {}
    return map.wrap(self)
end
return types.makeType(map)