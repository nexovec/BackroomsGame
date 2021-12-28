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

local oldassert = assert
--- Throws error if not term.
---@param term any
---@param errMsg string
---@param errLevel 
---@param errHandle any
function assert(term, errMsg, errLevel, errHandle)
    -- TODO: use errHandle
    -- TODO: test errMsg == nil
    errMsg = errMsg or "assertion failed!"
    errLevel = errLevel or 1
    if not term then
        error(errMsg, 1 + errLevel)
    end
end
oldassert = nil

--- Throw an error if var is none of the specified types.
---@param var any
---@param ... string variable arguments
---@return nil
function assertType(var, ...)
    local params = {...}
    for k,v in ipairs(params) do
        assert(type(v) == "string", "Argument #" .. tostring(k) .. " has unexpected type " .. type(v), nil, nil)
        if type(var) == v then return end
        if type(var) == "userdata" and var.type() == v then return end
    end
    error("Type assert failed", 2)
end
function isCallable(var)
    -- TODO: test
    if type(var) == "function" then return true
    elseif type(var) == "table" and getmetatable(var).__call then return true
    else return false end
end

function wrapRequirePath(path, moduleNameOrFunc, passCurrentRequirePaths)
    -- TODO: test
    assert(type(path) == "string" and (type(moduleNameOrFunc) == "string" or type(moduleNameOrFunc) == "function"),
        "Unexpected moduleNameOrFunc argument type", 2, nil)
    local module
    local oldPath = love.filesystem.getRequirePath()
    if not passCurrentRequirePaths then
        love.filesystem.setRequirePath(path)
    else
        love.filesystem.setRequirePath(oldPath .. path)
    end
    if type(moduleNameOrFunc) == "string" then
        module = require(moduleNameOrFunc)
    elseif isCallable(moduleNameOrFunc) then
        moduleNameOrFunc(path, moduleNameOrFunc, passCurrentRequirePaths)
    end
    love.filesystem.setRequirePath(oldPath)
    return module
end

function requireDirectory(pathToDir, localRequires)
    -- TODO: test
    assert(type(pathToDir) == "string" ,nil, nil, nil)
    local requirePaths = localRequires .. ";"
    if localRequires then requirePaths = requirePaths .. love.filesystem.getRequirePath() end
    -- TODO: make sure .init.lua is in requirePath.
    return wrapRequirePath(pathToDir, localRequires)
end
return {
    assert = assert,
    requireDirectory = requireDirectory,
    wrapRequirePath = wrapRequirePath,
    isCallable = isCallable,
    assertType = assertType
}