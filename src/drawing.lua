local drawing = {}
local types = require("std.types")
local assets = require("assets")
local string = require("std.string")

function drawing.resolutionScaledPos(x, y, width, height, returnTable)
    -- TODO: Take args more sensibly
    returnTable = returnTable or false
    if type(x) == "table" then
        if not not x.x and not not x.y and not not x.width and not not x.height then
            return drawing.resolutionScaledPos(x.x, x.y, x.width, x.height, true)
        elseif not not x[1] and not not x[2] then
            return drawing.resolutionScaledPos(x[1], x[2], nil, nil, true)
        end
    end
    if not x or not y then
        error("Invalid input: " .. string.join({tostring(x), tostring(y), tostring(width), tostring(height)}, ", "), 2)
    end
    local mockResolution = assets.get("settings").mockResolution
    local realResolution = assets.get("settings").realResolution
    local result = {x * (realResolution[1] / mockResolution[1]), y * (realResolution[2] / mockResolution[2])}
    if width and height then
        local rest = {width * (realResolution[1] / mockResolution[1]), height * (realResolution[2] / mockResolution[2])}
        local newResult = {
            x = result[1],
            y = result[2],
            width = rest[1],
            height = rest[2]
        }
        if returnTable then
            return newResult
        else
            return newResult.x, newResult.y, newResult.width, newResult.height
        end
    end
    if returnTable then
        return result
    else
        return result[1], result[2]
    end
end

function drawing.resolutionScaledDraw(image, quad, x, y)
    local correctX, correctY = unpack(drawing.resolutionScaledPos {x, y})
    local viewX, viewY, width, height = quad:getViewport()
    local scaleX, scaleY = quad:getTextureDimensions()
    local cviewX, cviewY = unpack(drawing.resolutionScaledPos {viewX, viewY})
    local cwidth, cheight = unpack(drawing.resolutionScaledPos {width, height})
    local cscaleX, cscaleY = unpack(drawing.resolutionScaledPos {scaleX, scaleY})
    local correctQuad = love.graphics.newQuad(cviewX, cviewY, cwidth, cheight, cscaleX, cscaleY)
    love.graphics.draw(image, correctQuad, correctX, correctY)
end

---@diagnostic disable-next-line: unused-function
function drawing.DEBUG_drawGrid(tileSize, color)
    if color then
        love.graphics.setColor(unpack(color))
    end
    local mockResolution = assets.get("settings").mockResolution
    for i = 1, math.floor(mockResolution[2] / tileSize) do
        local pos1 = {0, i * tileSize}
        local pos2 = {mockResolution[1], i * tileSize}
        -- TODO: Investigate: This should probably be corrected like this:
        -- local cPos1 = resolutionScaledPos(pos1)
        -- local cPos2 = resolutionScaledPos(pos2)
        local cPos1 = pos1
        local cPos2 = pos2
        love.graphics.line(cPos1[1], cPos1[2], cPos2[1], cPos2[2])
    end
    for i = 1, math.floor(mockResolution[1] / tileSize) do
        local pos1 = {i * tileSize, 0}
        local pos2 = {i * tileSize, mockResolution[2]}
        -- local cPos1 = resolutionScaledPos(pos1)
        -- local cPos2 = resolutionScaledPos(pos2)
        local cPos1 = pos1
        local cPos2 = pos2
        love.graphics.line(cPos1[1], cPos1[2], cPos2[1], cPos2[2])
    end
    if color then
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return types.makeType(drawing, "drawing")
