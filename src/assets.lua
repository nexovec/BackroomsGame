local std = require("std")
local json = std.json

local assets = {}
local function decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end
-- TODO: hot-reload json data
-- TODO: hot-reload shaders
-- TODO: hot-reload images
assets.constants = decodeJsonFile("data/constants.json")
assets.settings = decodeJsonFile("data/settings.json")
assets.animations = decodeJsonFile("data/animations.json")


assets.backgroundImage = love.graphics.newImage("resources/images/background1.png")


assets.font = love.graphics.newFont("resources/fonts/Pixel UniCode.ttf", 48)

-- TODO: report missing assets
assets.basicShaderA = love.graphics.newShader("resources/shaders/basic.glsl")
assets.invertShaderA = love.graphics.newShader("resources/shaders/invert.glsl")
assets.testShaderA = love.graphics.newShader("resources/shaders/test.glsl")
assets.blurShader = love.graphics.newShader("resources/shaders/blur.glsl")
assets.gradientShaderA = love.graphics.newShader("resources/shaders/gradient.glsl")
assets.applyAlphaA = love.graphics.newShader("resources/shaders/applyAlpha.glsl")
assets.uiBtnRoundingMask = love.graphics.newShader("resources/shaders/masks/uiBtnRoundingMask.glsl")

local hotReloadFreq = 2
local deltaTime = 0
local modTime = love.filesystem.getInfo("resources/hotReloadTest.txt").modtime
function assets.update(dt)
    deltaTime = deltaTime + dt
    if deltaTime < hotReloadFreq then return end
    deltaTime = 0
    local info = love.filesystem.getInfo("resources/hotReloadTest.txt")
    if modTime < info.modtime then
        modTime = info.modtime
        print("Hot reloaded hotReloadTest.txt")
    end
end
return assets