local animations = {}

local assets = require("assets")
local tileAtlas = require("tileAtlas")
local types = require("std.types")
local array = require("std.array")
local tween = require("libs.tween")


local playingAnimations = array.wrap()

function animations.updateAnimations(dt)
    for _, v in pairs(playingAnimations) do
        v.tween:update(dt)
        -- looping
        if love.timer.getTime() > v.startTime + v.playbackDuration then
            -- TODO: Reset previous tween
            -- assert(v.ref.progress == 1, v.ref.progress)
            -- v.ref:play(v.playbackDuration, v.loopName, false, v.inReverse)
            v.startTime = v.startTime + v.playbackDuration
        end
    end
end
function animations.newCharacterAnimation(animName)
    local self = {}
    setmetatable(self, animations)
    local aConf = assets.get("animations")[animName]
    love.graphics.draw(assets.get(aConf.filepath))
    self.tileAtlas = tileAtlas.wrap(aConf.filepath, aConf.tileSize)
    self.frameCounts = aConf.frameCounts
    -- TODO: compute self.offsets
    self.offsets = {}
    self.widthInTiles = aConf.widthInTiles
    self.offsets[1] = 0
    for i, v in ipairs(self.frameCounts) do
        if self.offsets[i] then
            self.offsets[i + 1] = self.offsets[i] + math.ceil(v/self.widthInTiles) * self.widthInTiles
        end
    end
    self.progress = 0
    self.activeAnimation = 2
    return self
end

function animations:play(playbackDuration)
    -- TODO: isLooping, isBounce
    local frameCount = self.frameCounts[self.activeAnimation]
    local tweenRef = tween.new(playbackDuration, self, {
        progress = 1 - 1 / self.frameCounts[self.activeAnimation]
    }, "linear")
    playingAnimations:append{
        tween = tweenRef,
        startTime = love.timer.getTime(),
        playbackDuration = playbackDuration
    }
end

function animations:draw()
    -- TODO: positions and scaling
    local i = math.floor(self.offsets[self.activeAnimation] + self.frameCounts[self.activeAnimation] * self.progress)
    self.tileAtlas:drawTile(0, 0, i % self.widthInTiles,  math.floor(i / self.widthInTiles), 128, 128)
end

return types.makeType(animations, "animations")