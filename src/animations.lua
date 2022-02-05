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
function animations.newCharacterAnimation(animName)
    local self = {}
    setmetatable(self, animations)
    local aConf = assets.get("animations")[animName]
    love.graphics.draw(assets.get(aConf.filepath))
    self.animationNames = {}
    for i, v in ipairs(aConf.animationNames) do
        self.animationNames[v] = i
    end
    self.tileAtlas = tileAtlas.wrap(aConf.filepath, aConf.tileSize)
    self.frameCounts = aConf.frameCounts
    self.offsets = {}
    self.widthInTiles = aConf.widthInTiles
    self.offsets[1] = 0
    for i, v in ipairs(self.frameCounts) do
        if self.offsets[i] then
            self.offsets[i + 1] = self.offsets[i] + math.ceil(v / self.widthInTiles) * self.widthInTiles
        end
    end
    self.progress = 0
    self.activeAnimation = 2
    return self
end

function animations:play(playbackDuration, animationName, isLooping)
    if animationName then
        self.activeAnimation = self.animationNames[animationName]
    end
    local frameCount = self.frameCounts[self.activeAnimation]
    self.progress = 0
    local tweenRef = tween.new(playbackDuration, self, {
        progress = 1 - 1 / self.frameCounts[self.activeAnimation]
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
    local i = math.floor(self.offsets[self.activeAnimation] + self.frameCounts[self.activeAnimation] * self.progress)
    self.tileAtlas:drawTile(x or 0, y or 0, i % self.widthInTiles, math.floor(i / self.widthInTiles), width or 128,
        height or 128)
    -- TODO: Positions and scaling

end

return types.makeType(animations, "animations")
