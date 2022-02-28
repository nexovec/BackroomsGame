local tileAtlas = {}

local types = require("std.types")
local assets = require("assets")
local assert = require("std.assert")

-- API

function tileAtlas:drawTile(tileX, tileY, posX, posY, width, height)
    -- TODO: Check bounds on the texture
    if not not tileX and not tileY then
        assert(tileX)
        types.assertIsDimensions(tileX)
        assert(not not tileX.tileX and not not tileX.tileY)
        return self:drawTile(tileX.tileX, tileX.tileY, tileX.x, tileX.y, tileX.width, tileX.height)
    end
    -- luacheck: ignore width
    width = width or self.tileSize
    height = height or self.tileSize
    local asset = assets.get(self.assetName)
    local textureDimsX, textureDimsY = asset:getDimensions()
    local scalingFactor = (height / self.tileSize)
    local sWidth = textureDimsX * scalingFactor
    local sHeight = textureDimsY * scalingFactor
    -- local sWidth = textureDimsX
    -- local sHeight = textureDimsY
    local tileXInPixels = tileX * (self.tileSize + self.stride)
    local tileYInPixels = tileY * (self.tileSize + self.stride)

    local quad = love.graphics.newQuad(tileXInPixels * scalingFactor, tileYInPixels * scalingFactor,
        self.tileSize * scalingFactor, self.tileSize * scalingFactor, sWidth, sHeight)
    love.graphics.draw(asset, quad, posX, posY)
end

function tileAtlas.wrap(drawableNameOrDrawable, tileSize, stride)
    -- assert(type(drawableNameOrDrawable) == "string", "Not yet implemented", 2)
    return setmetatable({
        assetName = drawableNameOrDrawable,
        tileSize = tileSize,
        stride = stride or 0
    }, tileAtlas)
end

return types.makeType(tileAtlas, "tileAtlas")
