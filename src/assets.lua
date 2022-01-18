local assets = {}
-- TODO: make this work with server!

local json = require("std.json")
local std = require("std")
local map = require("std.map")
local string = require("std.string")
local array = require("std.array")


local resources = map.wrap()
local funcsToCallBasedOnFileExtension
local deltaTime = 0


-- helper functions
local function decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end

local function stubResourceHandle(path)
    local fileExtension = array.wrap(string.split(v.path, ".")):pop()
    print("Extension " .. fileExtension .. " cannot currently be loaded")
end

-- TODO: report unused assets
-- TODO: scan whole folder recursively
local function reloadResource(k, path)
    -- reload assset
    local v = resources[k]
    if v.asset and v.asset.release then v.asset:release() end
    -- TODO: check if it is the same kind of file
    v.cachedFileLastModified = love.filesystem.getInfo(v.path).modtime
    print("Hot reloaded " .. v.path)
    resources[k].asset = v.func(v.path)
end

local function registerResourcesFromJson(file)
    local resTable = decodeJsonFile(file)
    for k, v in pairs(resTable) do
        if resources[k] == nil or resources[k].path ~= v.path then
            resources[k] = v
            local fileExtension = array.wrap(string.split(v.path, ".")):pop()
            if funcsToCallBasedOnFileExtension[fileExtension] then
                -- TODO: handle nil resources(can't load, doesn't exist etc.)
                resources[k].func = funcsToCallBasedOnFileExtension[fileExtension]
            else
                resources[k].func = stubResourceHandle
            end
        end
    end
end

-- TODO: load based on assets.json
local function init(funcsToCallBasedOnFileExtensionArg)
    funcsToCallBasedOnFileExtension = funcsToCallBasedOnFileExtensionArg
    setmetatable(funcsToCallBasedOnFileExtension, {__index = function(tbl, key)
    assert(type(key) == "string", "You must index by a file extension", 2)
    end})
    registerResourcesFromJson("data/assets.json")
end

local function hotReloadAssets()
    -- TODO: don't reload if resource was runtime modified
    registerResourcesFromJson("data/assets.json")
    for k, v in pairs(resources) do
        v.cachedFileLastModified = v.cachedFileLastModified or 0
        local fileInfo = love.filesystem.getInfo(v.path)
        if v.cachedFileLastModified < fileInfo.modtime and v.func ~= stubResourceHandle then
            reloadResource(k, v.path)
        end
    end
end


-- API
function assets.initOnServer()
    init{
        ["json"] = decodeJsonFile
    }
end

function assets.initOnClient()
    init{
        ["png"] = love.graphics.newArrayImage,
        ["glsl"] = love.graphics.newShader,
        ["json"] = decodeJsonFile,
        ["ttf"] = function(font) return love.graphics.newFont(font, 48) end
    }
end

function assets.update(dt)
    deltaTime = deltaTime + dt
    if deltaTime < assets.get("settings").assetReloadUpdateFrequency then return end
    deltaTime = 0
    hotReloadAssets()
end

function assets.get(filePathOrResourceName)
    if not resources[filePathOrResourceName] then
        -- TODO: scan for duplicate resources
        -- tries to load from file
        local fileInfo = love.filesystem.getInfo(filePathOrResourceName)
        local fileExists = fileInfo ~= nil
        if not fileExists then
            error("Requested resource " .. filePathOrResourceName .. "doesn't exist", 2)
        end
        assert(fileInfo.type == file, "Loading folders is not yet implemented")
        local list = string.split(filePathOrResourceName, ".")
        local fileExtension = array.wrap(list):pop()
        local func = funcsToCallBasedOnFileExtension[fileExtension]
        if not func then error("Unknown file extension: " .. fileExtension, 2) end
        resources[filePathOrResourceName] = {
            path = filePathOrResourceName,
            func = func
        }
        return assets.get(filePathOrResourceName)
    end
    assert(resources[filePathOrResourceName], "This resource doesn't exist",  2)
    if not resources[filePathOrResourceName].asset then
        resources[filePathOrResourceName].asset = resources[filePathOrResourceName].func(resources[filePathOrResourceName].path)
    end
    return resources[filePathOrResourceName].asset
end

function assets.getModTime(asset)
    return assets.get(asset).cachedFileLastModified
end

function assets.set(key, resource)
    error("Not yet implemented.")
end

function assets.__index(where, what)
    error("You must use assets.get(filePathOrResourceName) to reference assets", 2)
end

assets.resources = resources
return setmetatable(assets, assets)