local json = require("std.json")


local assets = {}
local std = require("std")
local map = require("std.map")


local function decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end
-- TODO: hot-reload json data
-- TODO: hot-reload shaders
-- TODO: hot-reload images
local resources = map.wrap()
resources.constants = {path = "data/constants.json", func = decodeJsonFile}
resources.settings = {path = "data/settings.json", func = decodeJsonFile}
resources.animations = {path = "data/animations.json", func = decodeJsonFile}
resources.backgroundImage = {path = "resources/images/background1.png", func = love.graphics.newImage}


resources.font = {path = "resources/fonts/Pixel UniCode.ttf", func = function(d) return love.graphics.newFont(d, 48) end}

-- TODO: report missing assets
resources.basicShaderA = {path = "resources/shaders/basic.glsl", func = love.graphics.newShader}
resources.invertShaderA = {path = "resources/shaders/invert.glsl", func = love.graphics.newShader}
resources.testShaderA = {path = "resources/shaders/test.glsl", func = love.graphics.newShader}
resources.blurShader = {path = "resources/shaders/blur.glsl", func = love.graphics.newShader}
resources.gradientShaderA = {path = "resources/shaders/gradient.glsl", func = love.graphics.newShader}
resources.applyAlphaA = {path = "resources/shaders/applyAlpha.glsl", func = love.graphics.newShader}
resources.uiBtnRoundingMask = {path = "resources/shaders/masks/uiBtnRoundingMask.glsl", func = love.graphics.newShader}

local function hotReloadAssets()
    for k, v in pairs(resources) do
        v.cachedFileLastModified = v.cachedFileLastModified or 0
        local fileInfo = love.filesystem.getInfo(v.path)
        if v.cachedFileLastModified < fileInfo.modtime then
            -- reload assset
            -- if assets[k] and assets[k].release then assets[k]:release() end
            v.cachedFileLastModified = fileInfo.modtime
            print("Hot reloaded " .. v.path)
            assets[k] = v.func(v.path)
        end
    end
end
local hotReloadFreq = 2
local deltaTime = 0
local modTime = love.filesystem.getInfo("resources/hotReloadTest.txt").modtimeSS
function assets.update(dt)
    deltaTime = deltaTime + dt
    if deltaTime < hotReloadFreq then return end
    deltaTime = 0
    hotReloadAssets()
end
hotReloadAssets()
return assets