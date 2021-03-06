-- luacheck:ignore
local animation = {}

-- requires
local tween = require("libs.tween")

local array = require("std.array")
local std = require("std")
local types = require("std.types")
local assets = require("assets")
local assert = std.assert

-- helper functions

local function parseImageTilesetIntoArrayImage(imagedata, tileSize)
    assert(type(imagedata) == "userdata" and imagedata:type() == "ImageData",
        "expected: ImageData, got: " .. (imagedata.type and imagedata:type()) or type(imagedata), 2)
    assert(tileSize > 0, "Tile size must be positive", 2)
    local frames = {}
    local width, height = imagedata:getDimensions()
    for i = 0, height / tileSize do
        for j = 0, width / tileSize do
            local frame = love.image.newImageData(tileSize, tileSize)
            frame:paste(imagedata, 0, 0, j * tileSize, i * tileSize, tileSize, tileSize)
            -- TODO: This other line causes emtpy frames to appear, investigate
            -- frames[#frames + 1] = frame
            -- NOTE: This one doesn't work at all:
            -- frames[#frames + math.floor(imagedata:getDimensions() / tileSize)] = frame
            frames[i * math.floor(imagedata:getDimensions() / tileSize) + j + 1] = frame
        end
    end
    return love.graphics.newArrayImage(frames)
end

-- local function parseImageTilesetIntoArrayImage(filename, tileSize)
--     local image = filename
--     -- if type(image) == "string" or (image.type and image:type() == "ImageData") then
--         image = love.graphics.newImage(filename)
--     -- elseif image.type and image:type() == "Image" then
--     --     image = filename
--     -- else
--     --     error("",2)
--     -- end
--     local cols, rows = math.floor(image:getWidth() / tileSize), math.floor(image:getHeight() / tileSize)
--     local canvas = love.graphics.newCanvas(cols * tileSize, rows * tileSize)
--     canvas:renderTo(function() love.graphics.draw(image) end)
--     local subimages = {}
--     for y = 0, rows - 1 do
--         for x = 0, cols - 1 do
--             local i = y * cols + x + 1
--             subimages[i] = canvas:newImageData(nil, 1, x * tileSize, y * tileSize, tileSize, tileSize)
--             -- subimages[i] = love.graphics.newImage(subimages[i])
--         end
--     end
--     return love.graphics.newArrayImage(subimages)
-- end

local playingAnimations = array.wrap()
local animationObjects = array.wrap()
-- TODO: asset:release()
function animation.updateAnimations(dt)
    for _, v in pairs(playingAnimations) do
        v.tween:update(dt)
        -- looping
        if love.timer.getTime() > v.startTime + v.playbackDuration then
            -- TODO: Reset previous tween
            -- assert(v.ref.progress == 1, v.ref.progress)
            v.ref:play(v.playbackDuration, v.loopName, false, v.inReverse)
            v.startTime = v.startTime + v.playbackDuration
        end
    end
    for _, v in pairs(animationObjects) do
        if v.assetLastModified ~= assets.getModTime(v.assetFilePath) then
            -- TODO: Reload asset and restitch animation
        end
    end
end

-- API
function animation:setAnimation(name)
    if type(name) == "string" then
        -- PERFORMANCE:
        self.activeLoop = array.wrap(self.loopNames):inverse()[name]
    elseif type(name) == "number" then
        self.activeLoop = name
    else
        error("Unexpected type " .. type(name) .. ", number | string expected", 2)
    end
    self.progress = 0
end

function animation:to(duration)
    error("Not yet implemented.")
end
function animation:play(playbackDuration, loopName, isLooping, inReverse)
    local loopName = loopName or self.activeLoop
    self:setAnimation(loopName)
    assert(not inReverse, "Not yet implemented.")
    assert(type(playbackDuration) == "number",
        "Unexpected playbackDuration: " .. type(playbackDuration) .. ", number expected", 2)
    assert(playbackDuration > 0, nil, 2)
    -- TODO: Stop old tween
    local tweenRef = tween.new(playbackDuration, self, {
        progress = 1 - 1 / self.frameCounts[self.activeLoop]
    }, "linear")
    self.loopingAnimationsIndex = self.loopingAnimationsIndex or (#playingAnimations + 1)
    local argWrap = {
        isLooping = isLooping,
        tween = tweenRef,
        ref = self,
        playbackDuration = playbackDuration,
        loopName = loopName,
        inReverse = inReverse,
        startTime = love.timer.getTime()
    }
    playingAnimations[self.loopingAnimationsIndex] = argWrap
end

function animation:draw(quad, xPos, yPos, xScale, yScale)
    local frame = math.floor(self.progress * (self.frameCounts[self.activeLoop]))
    return love.graphics.drawLayer(self.imageData, self.offsets[self.activeLoop] + frame, quad, xPos, yPos, xScale,
        yScale)
end
--- Parses an image into an animation (from )
---@param image userdata The Image object to parse
---@param tileSize number Size of one image in the tilemap in pixels
---@param frameCounts table A table with number of frames per animation
---@param loopNames table Assigns names to individual loops of the animation
---@param skipToNextRowAfterLoop boolean true if there is one animation per row, false if they are tightly packed
---@return table
function animation.newCharacterAnimation(image, tileSize, frameCounts, loopNames, skipToNextRowAfterLoop)
    local self
    local assetFilePath
    -- TODO: Use a tileatlas object instead of ArrayImage
    if type(image) == "string" then

        -- load spritesheet from file from file
        assert(assets.get("animations"))
        local properties = assets.get("animations")[image]
        image = love.image.newImageData(properties.filepath)
        assetFilePath = properties.filepath
        tileSize = properties.tileSize
        frameCounts = properties.frameCounts
        loopNames = properties.loopNames
        skipToNextRowAfterLoop = properties.skipToNextRowAfterLoop
    end
    -- TODO: Test when type(image) == "userdata"

    local width, height = image:getDimensions()
    self = {
        imageData = parseImageTilesetIntoArrayImage(image, tileSize),
        frameCounts = frameCounts,
        offsets = {},
        loopNames = loopNames or {},

        assetFilePath = assetFilePath,
        assetLastModified = love.filesystem.getInfo(assetFilePath).modtime,

        tilesPerRow = math.floor(width / tileSize),
        tilesPerColumn = math.floor(height / tileSize),

        activeLoop = 1,
        progress = 0,
        loopingAnimationsIndex = nil
    }
    assert(type(image) == "userdata" and image:type() == "ImageData", "Couldn't load image.", 2)
    assert(types.isuint(tileSize), "You must specify .tileSize property as a number. (hint: animations.json)", 2)
    assert(type(frameCounts) == "table", "You must specify .frameCounts property as an array. (hint: animations.json)",
        2)
    assert(type(loopNames) == "table", "You must specify .tileSize property as an array. (hint: animations.json)", 2)
    assert(type(skipToNextRowAfterLoop) == "boolean",
        "You must specify .skipToNextRowAfterLoop property as a boolean. (hint: animations.json)")
    assert(skipToNextRowAfterLoop == true, "Not yet implemented.", 2)
    assert(types.isint(self.tilesPerRow))
    assert(types.isint(self.tilesPerColumn))

    self.offsets[1] = 1
    for i = 1, #self.frameCounts - 1 do
        local rowCount = math.floor((self.frameCounts[i] - 1) / self.tilesPerRow) + 1
        -- self.offsets[i] = self.offsets[i - 1] + self.tilesPerRow * rowCount + 1
        self.offsets[i + 1] = self.offsets[i] + rowCount * self.tilesPerRow
    end

    -- discard resources
    -- TODO: Discard unused tiles
    animationObjects:append(self)
    image:release()
    return setmetatable(self, {
        __index = animation
    })
end

return types.makeType(animation, "animation")
