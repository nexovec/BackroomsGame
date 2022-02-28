local animations = {}

local assets = require("assets")
local tileAtlas = require("tileAtlas")
local types = require("std.types")
local array = require("std.array")
local tween = require("libs.tween")

local playingAnimations = array.wrap()

function animations.updateAnimations(dt)
    for k, v in pairs(playingAnimations) do
        v.tween:update(dt)
        if love.timer.getTime() > v.startTime + v.playbackDuration then
            v.startTime = v.startTime + v.playbackDuration
            if v.isLooping then
                v.animRef:play(v.playbackDuration, nil, true)
            end
            table.remove(playingAnimations, k)
        end
    end
end

local function newRowPaddedAnimation(self, aConf)
    self.offsets = {}
    self.widthInTiles = aConf.widthInTiles
    self.offsets[1] = 0
    for i, v in ipairs(self.frameCounts) do
        if self.offsets[i] then
            self.offsets[i + 1] = self.offsets[i] + math.ceil(v / self.widthInTiles) * self.widthInTiles
        end
    end
    self.progress = 0
    self.activeSequence = 2
    return self
end

local function newContiguousAnimation(self, aConf)
    self.offsets = {0}
    local width = assets.get(self.tileAtlas.assetName):getDimensions()
    self.widthInTiles = width / aConf.tileSize
    return self
end

function animations.loadAnimation(animName)
    local self = {}
    setmetatable(self, animations)
    local aConf = assets.get("animations")[animName]
    assert(aConf, "Animation " .. animName .. " not found in animations.json!!")
    assert(aConf.animationType)
    -- love.graphics.draw(assets.get(aConf.filepath))
    self.sequenceNames = {}
    for i, v in ipairs(aConf.animationNames) do
        self.sequenceNames[v] = i
    end
    self.tileAtlas = tileAtlas.wrap(aConf.filepath, aConf.tileSize)
    self.frameCounts = aConf.frameCounts
    if aConf.animationType == "oneAnimationPerRow" then
        return newRowPaddedAnimation(self, aConf)
    elseif aConf.animationType == "oneContiguousAnimation" then
        -- TODO:
        return newContiguousAnimation(self, aConf)
        -- error("Not yet implemented!")
    else
        error("Not yet implemented!")
    end
end

function animations:play(playbackDuration, sequenceName, isLooping)
    if sequenceName then
        self.activeSequence = self.sequenceNames[sequenceName]
    end
    self.progress = 0
    local tweenRef = tween.new(playbackDuration, self, {
        progress = 1 - 1 / self.frameCounts[self.activeSequence]
    }, "linear")
    playingAnimations:append{
        animRef = self,
        tween = tweenRef,
        startTime = love.timer.getTime(),
        playbackDuration = playbackDuration,
        isLooping = isLooping
    }
end

function animations:draw(x, y, width, height)
    local i = math.floor(self.offsets[self.activeSequence] + self.frameCounts[self.activeSequence] * self.progress)
    self.tileAtlas:drawTile(i % self.widthInTiles, math.floor(i / self.widthInTiles), x or 0, y or 0, width or 128,
        height or 128)
    -- TODO: Positions and scaling
end

return types.makeType(animations, "animations")
