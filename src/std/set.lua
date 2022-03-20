local set = {}

local types = require("std.types")
local setInstanceParent = {}

local function hasValue(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local function size(tbl)
    local i = 0
    for _ in pairs(tbl) do
        i = i + 1
    end
    return i
end

local function isContiguousArray(tbl)
    local len = size(tbl)
    local counter = 0
    for i in ipairs(tbl) do
        if not (i > 0 and i <= len) then
            return false
        end
        counter = counter + 1
    end
    if counter == len then
        return true
    else
        return false
    end
end

-- TODO: move to std.array
-- luacheck: ignore checkUniqueness
local function checkUniqueness(elems)
    -- NOTE: assumes this is a contiguous array
    local cache = {}
    for _, v in ipairs(elems) do
        if hasValue(cache, v) then
            return false
        end
        cache[#cache + 1] = v
    end
    return true
end

local function getUnique(tbl)
    local cache = {}
    for _, v in ipairs(tbl) do
        if not hasValue(cache, v) then
            cache[#cache + 1] = v
        end
    end
    return cache
end

--- Checks if this set has the same object in it (tests for ==)
---@param elem any
function setInstanceParent:contains(elem)
    for _, v in ipairs(self.members) do
        if v == elem then
            return true
        end
    end
    return false
end

-- TODO: Make setInstance.members private
function setInstanceParent:insert(elem)
    if not hasValue(self.members, elem) then
        return
    end
    self.members[#self.members + 1] = elem
end

function setInstanceParent.__newindex()
    error("Error: Can't set a property, because set is an immutable data structure.", 2)
end

function setInstanceParent:__index(value)
    -- TODO: Test
    for _, v in ipairs(self.members) do
        if v == value then
            return true
        end
    end
    return false
end
setmetatable(setInstanceParent, setInstanceParent)

function set.createSet(elems)
    if not (isContiguousArray(elems)) then
        error("Argument 1 must be an array (table with number-only indices indexed from 1).", 2)
    end
    return setmetatable({
        members = getUnique(elems)
    }, setInstanceParent)
end
set.type = "set"

function set.__newindex()
    error("Error: You're trying to assign a property to a class.", 2)
end

function set.__index()
    error("Indexing a class is not allowed")
end
setmetatable(set, set)
return types.makeType(set, "set")
