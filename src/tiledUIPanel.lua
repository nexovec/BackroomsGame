local tiledUIPanel = {}

local assert = require("std.assert")
local tileAtlas = require("tileAtlas")
local drawing = require("drawing")

-- luacheck: ignore option
function tiledUIPanel:draw(xPosInTiles, yPosInTiles, widthInTiles, heightInTiles, option)
    if type(xPosInTiles) == "table" then
        local dims
        dims, option = xPosInTiles, yPosInTiles
        return self:draw(dims.x, dims.y, dims.width, dims.height, option)
    end
    assert(xPosInTiles >= 0 and yPosInTiles >= 0 and widthInTiles > 0 and widthInTiles > 0)
    local atlas = tileAtlas.wrap(self.assetName, self.tileSize)
    local startingX, startingY, panelWInTiles, panelHInTiles = self.panelPos[1], self.panelPos[2], self.panelPos[3],
        self.panelPos[4]
    for xI = 0, widthInTiles - 1 do
        for yI = 0, heightInTiles - 1 do
            -- assigns which tile gets rendered at this position(at scaledTileSize * posInTiles + index)
            local tileX, tileY
            if yI == 0 then
                tileY = startingY
            end
            if xI == 0 then
                tileX = startingX
            end
            if yI == heightInTiles - 1 then
                tileY = startingY + panelHInTiles - 1
            end
            if xI == widthInTiles - 1 then
                tileX = startingX + panelWInTiles - 1
            end
            if not tileX then
                tileX = startingX + 1
                -- TODO: Thin the edge folds of paper ui
                -- tileX = startingX + 1 + xI % (panelWInTiles - 2)
            end
            if not tileY then
                tileY = startingY + 1
                -- tileY = startingY + 1 + yI % (panelHInTiles - 2)
            end
            local unscaledPosX, unscaledPosY = (xPosInTiles + xI) * self.tileSize * self.scale,
                (yPosInTiles + yI) * self.tileSize * self.scale
            local unscaledPosWidth, unscaledPosHeight = self.scale * self.tileSize, self.scale * self.tileSize
            -- local scaledPosX, scaledPosY, scaledPosWidth, scaledPosHeight =
            drawing.resolutionScaledPos(unscaledPosX, unscaledPosY, unscaledPosWidth, unscaledPosHeight, false)
            -- TODO:
            -- atlas:drawTile(scaledPosX, scaledPosY, tileX, tileY, scaledPosWidth, scaledPosHeight)
            atlas:drawTile(unscaledPosX, unscaledPosY, tileX, tileY, unscaledPosWidth, unscaledPosHeight)
        end
    end
end

function tiledUIPanel.wrap(assetName, tileSize, scale, panelPos)
    assert(not panelPos or #panelPos == 4, "Invalid panelPos argument", 2)
    local res = {
        assetName = assetName,
        tileSize = tileSize,
        scale = scale,
        panelPos = panelPos or {0, 4, 10, 10},
        draw = tiledUIPanel.draw -- TODO: wtf??
    }
    -- TODO: Option is "flat" or "shadow", corresponds to whether it is hovered over with mouse or not
    return setmetatable(res, tiledUIPanel)
end
return tiledUIPanel
