local map = {}
local types = require("std.types")
local array = require("std.array")

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

function map:prettyPrintRecursive(passed)
    local passed = passed or array.wrap()
    passed:append(self)
    if not self then
        return error('Table is nil!', 2)
    end
    -- TODO: typecheck against array
    if type(self) ~= 'table' then
        error('This is not a table. type: ' .. type(self) .. ((" " .. (self.type and self.type())) or ""), 2)
    end
    print('contents of a map ' .. tostring(self) .. ':')
    print('-----------')
    for k, v in pairs(self) do
        if type(v) == "table" then
            if passed:contains(self) == true then
                print("<previous " .. tostring(self) .. " >")
            else
                map.prettyPrintRecursive(v, passed)
            end
        else
            local strv = tostring(v)
            print(tostring(k) .. string.rep(' ', math.max(50 - #strv, 0)) .. ':\t' .. strv)
        end
    end
    print('-----------')
end

function map:put(key, val)
    self[key] = val
end

function map:get(key)
    return self[key]
end

function map:contains(elem)
    for k, v in pairs(self) do
        if v == elem then
            return true
        end
    end
    return false
end

function map:iter()
    return pairs(self)
end

function map:indexOf(elem)
    for i, v in pairs(self) do
        if v == elem then
            return i
        end
    end
    return nil
end

function map:extend(other)
    for k, v in pairs(other) do
        self[k] = v
    end
    return self
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
    if type(obj) == "nil" then
        local emptyTable = {}
        return setmetatable(emptyTable, array)
    end
    assert(type(obj) == "table")
    return setmetatable(obj, map)
end

return types.makeType(map, "map")
