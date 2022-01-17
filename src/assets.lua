local assets = {}
-- TODO: make this work with server!

local json = require("std.json")
local std = require("std")
local map = require("std.map")
local string = require("std.string")
local array = require("std.array")


local function decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end
local resources = map.wrap()

local funcsToCallBasedOnFileExtension
local function registerResourcesFromJson(file)
    local resTable = decodeJsonFile(file)
    for k, v in pairs(resTable) do
        if resources[k] == nil or resources[k].path ~= v.path then
            -- if resources[k].asset and resources[k].asset.release then
                --     resources[k].asset:release()
                -- end
            resources[k] = v
            local fileExtension = array.wrap(string.split(v.path, ".")):pop()
            resources[k].func = funcsToCallBasedOnFileExtension[fileExtension]
        end
    end
end

-- TODO: load based on assets.json
-- TODO: don't load if appropriate module is diabled
function assets.init()
    funcsToCallBasedOnFileExtension = {
        ["png"] = love.graphics.newArrayImage,
        ["glsl"] = love.graphics.newShader,
        ["json"] = decodeJsonFile,
        ["ttf"] = function(font) return love.graphics.newFont(font, 48) end
    }
    setmetatable(funcsToCallBasedOnFileExtension, {__index = function(tbl, key)
    assert(type(key) == "string", "You must index by a file extension", 2)
    error("Unsupported file extension " .. key .. "!")
    end})
    registerResourcesFromJson("data/assets.json")
end
-- resources.constants = {path = "data/constants.json", func = decodeJsonFile}
-- resources.settings = {path = "data/settings.json", func = decodeJsonFile}
-- resources.animations = {path = "data/animations.json", func = decodeJsonFile}


-- resources.backgroundImage = {path = "resources/images/background1.png", func = love.graphics.newArrayImage}
-- resources.uiPaperImage = {path = "resources/images/ui/uiPaperFlat.png", func = love.graphics.newArrayImage}


-- resources.font = {path = "resources/fonts/Pixel UniCode.ttf", func = function(d) return love.graphics.newFont(d, 48) end}

-- TODO: report unused assets
-- resources.basicShaderA = {path = "resources/shaders/basic.glsl", func = love.graphics.newShader}
-- resources.invertShaderA = {path = "resources/shaders/invert.glsl", func = love.graphics.newShader}
-- resources.testShaderA = {path = "resources/shaders/test.glsl", func = love.graphics.newShader}
-- resources.blurShader = {path = "resources/shaders/blur.glsl", func = love.graphics.newShader}
-- resources.gradientShaderA = {path = "resources/shaders/gradient.glsl", func = love.graphics.newShader}
-- resources.applyAlphaA = {path = "resources/shaders/applyAlpha.glsl", func = love.graphics.newShader}
-- resources.uiBtnRoundingMask = {path = "resources/shaders/masks/uiBtnRoundingMask.glsl", func = love.graphics.newShader}

-- TODO: scan whole folder recursively

local function reloadResource(k, path)
    -- TODO:
end



local function hotReloadAssets()
    -- TODO: don't reload if resource was runtime modified
    registerResourcesFromJson("data/assets.json")
    for k, v in pairs(resources) do
        v.cachedFileLastModified = v.cachedFileLastModified or 0
        local fileInfo = love.filesystem.getInfo(v.path)
        if v.cachedFileLastModified < fileInfo.modtime then
            -- reload assset
            -- TODO:
            if v.asset and v.asset.release then v.asset:release() end
            v.cachedFileLastModified = fileInfo.modtime
            print("Hot reloaded " .. v.path)
            resources[k].asset = v.func(v.path)
        end
    end
end

local deltaTime = 0
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