local array = {}

local error = require("std.error")
local assert = require("std.assert")
local types = require("std.types")
function array:shallowCopy()
    assert(self, "Call with : instead of .", 2)
    -- assert(type(a) == "table", "This can only be used on tables")
    local new = {}
    for k, v in ipairs(self) do
        new[k] = v
    end
    return new
end
function array:append(elem)
    assert(self, "Call with : instead of .", 2)
    self[#self + 1] = elem
    return self
end
function array:concat(tbl)
    assert(self, "Call with : instead of .", 2)
    assert(type(tbl) == "table" and tbl.type == "array")
    for k,v in ipairs(tbl) do
        self:append(v)
    end
end
function array:pop()
    assert(self, "Call with : instead of .", 2)
    local res = self[#self]
    self[#self] = nil
    return res
end
function array:prettyPrint()
    if not self then
        return error('Table is nil!', 2)
    end
    if type(self) ~= 'table' then
        error('This is not a table. type: ' .. type(self) .. ((" " .. (self.type and self.type())) or ""), 2)
    end
    print('contents of a table:')
    print('-----------')
    for k, v in ipairs(self) do
        local strv = tostring(v)
        print(tostring(k) .. string.rep(' ', math.max(50 - #strv, 0)) .. ':\t' .. strv)
    end
    print('-----------')
end
function array:contains(elem)
    assert(self, "Call with : instead of .", 2)
    for k, v in ipairs(self) do
        if v == elem then
            return true
        end
    end
    return false
end

function array:reverse()
    -- TODO: test
    local len = #self
    local res = array.wrap()
    for i = len, 1, -1 do
        res:append(self[i])
    end
    return res
end

function array:indexOf(elem)
    assert(self, "Call with : instead of .", 2)
    for k, v in ipairs(self) do
        if v == elem then return k end
    end
    return nil
end
--- Functional programming filter. Uses ipairs under the hood.
---@param func Gets called for every element of the array with value, key, array as parameters. Must return a boolean
function array:filter(func)
    assert(self, "Call with : instead of .", 2)
    -- TODO: test
    local new = {}
    for k, v in ipairs(self) do
        local res = func(v, k, self)
        if res == true then new[#new + 1] = v
        elseif res then else error("Filter function must return boolean", 2) end
    end
    return array.wrap(new)
end
--- Functional programming map. Uses ipairs under the hood.
---@param elem Gets called for every element of the array with value, key, array as parameters.
function array:map(elem)
    assert(self, "Call with : instead of .", 2)
    -- TODO: test
    local new = {}
    for k, v in ipairs(self) do
        new[k] = func(v, k, self)
    end
    return array.wrap(new)
end

function array:inverse()
    assert(self, "Call with : instead of .", 2)
    local res = {}
    for k, v in ipairs(self) do
        -- if not type(v) == "string" or type(v) == "number" then error("Table contains uninvertable type at index " .. k, 2) end
        res[v] = k
    end
    return array.wrap(res)
end

--- Returns a copy with no nil values
function array:squashed()
    local res = array.wrap()
    for i = 1, #self do
        if self[i] ~= nil then res:append(self[i]) end
    end
    return res
end

function array:remove(k)
    table.remove(k)
end

function array.wrap(obj)
    if type(obj) == "nil" then
        local emptyTable = {}
        return setmetatable(emptyTable, array)
    end
    assert(type(obj) == "table")
    setmetatable(obj, array)
    return obj
end
return types.makeType(array, "array")
