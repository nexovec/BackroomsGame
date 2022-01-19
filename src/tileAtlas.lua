local tileAtlas = {}

local types = require("std.types")
local assert = require("std.assert")
local assets = require("assets")

-- API

function tileAtlas:drawTile(posX, posY, x, y, width, height)
    -- TODO: check bounds on the texture
    local width = width or self.tileSize
    local height = height or self.tileSize
    local tileX = x * self.tileSize
    local tileY = y * self.tileSize
    local asset = assets.get(self.assetName)assets.get(self.assetName)
    local textureDimsX, textureDimsY = asset:getDimensions()
    local sWidth = (width / self.tileSize) * textureDimsX
    local sHeight = (height / self.tileSize) * textureDimsY

    local quad = love.graphics.newQuad(tileX, tileY, width, height, sWidth, sHeight)
    love.graphics.draw(asset, quad, posX, posY)
end
function tileAtlas.wrap(drawableNameOrDrawable, tileSize)
    assert(type(drawableNameOrDrawable) == "string", "Not yet implemented", 2)
    return setmetatable({
        assetName = drawableNameOrDrawable,
        tileSize = tileSize
    }, tileAtlas)
end

return types.makeType(tileAtlas)