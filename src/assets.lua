local assets = {}
-- TODO: make this work with server!

local json = require("std.json")
local std = require("std")
local map = require("std.map")
local string = require("std.string")
local array = require("std.array")


-- TODO: move!
local hotReloadFreq = 2


local function decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end
local resources = map.wrap()
resources.constants = {path = "data/constants.json", func = decodeJsonFile}
resources.settings = {path = "data/settings.json", func = decodeJsonFile}
resources.animations = {path = "data/animations.json", func = decodeJsonFile}


resources.backgroundImage = {path = "resources/images/background1.png", func = love.graphics.newArrayImage}
resources.uiPaperImage = {path = "resources/images/ui/uiPaperFlat.png", func = love.graphics.newArrayImage}


resources.font = {path = "resources/fonts/Pixel UniCode.ttf", func = function(d) return love.graphics.newFont(d, 48) end}

-- TODO: report unused assets
resources.basicShaderA = {path = "resources/shaders/basic.glsl", func = love.graphics.newShader}
resources.invertShaderA = {path = "resources/shaders/invert.glsl", func = love.graphics.newShader}
resources.testShaderA = {path = "resources/shaders/test.glsl", func = love.graphics.newShader}
resources.blurShader = {path = "resources/shaders/blur.glsl", func = love.graphics.newShader}
resources.gradientShaderA = {path = "resources/shaders/gradient.glsl", func = love.graphics.newShader}
resources.applyAlphaA = {path = "resources/shaders/applyAlpha.glsl", func = love.graphics.newShader}
resources.uiBtnRoundingMask = {path = "resources/shaders/masks/uiBtnRoundingMask.glsl", func = love.graphics.newShader}

local function hotReloadAssets()
    -- TODO: don't reload if resource has changed
    for k, v in pairs(resources) do
        v.cachedFileLastModified = v.cachedFileLastModified or 0
        local fileInfo = love.filesystem.getInfo(v.path)
        if v.cachedFileLastModified < fileInfo.modtime then
            -- reload assset
            -- TODO:
            -- if assets[k] and assets[k].release then assets[k]:release() end
            v.cachedFileLastModified = fileInfo.modtime
            print("Hot reloaded " .. v.path)
            resources[k].asset = v.func(v.path)
        end
    end
end

local deltaTime = 0
function assets.update(dt)
    deltaTime = deltaTime + dt
    if deltaTime < hotReloadFreq then return end
    deltaTime = 0
    hotReloadAssets()
end
-- TODO: load based on assets.json
-- TODO: don't load if appropriate module is diabled
funcsToCallBasedOnFileExtension = {
    ["png"] = love.graphics.newArrayImage,
    ["glsl"] = love.graphics.newShader,
    ["json"] = decodeJsonFile
}

function assets.get(filePathOrResourceName)
    if not resources[filePathOrResourceName] then
        -- TODO: scan for duplicate resources
        -- tries to load from file
        local fileInfo = love.filesystem.getInfo(filePathOrResourceName)
        local fileExists = fileInfo ~= nil
        if not fileExists then
            error("Requested resource doesn't exist", 2)
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

function assets.set(key, resource)
    error("Not yet implemented.")
end

function assets.__index(where, what)
    error("You must use assets.get(filePathOrResourceName) to reference assets", 2)
end
assets.resources = resources
return setmetatable(assets, assets)