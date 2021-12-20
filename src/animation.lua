local animation = {}


local function parseImageTilesetIntoArrayImage(image, tileSize)
    assert(image:type() == "Image")
    assert(tileSize > 0)
    local frames = {}
    local width, height = image:getDimensions()
    local canvas = love.graphics.newCanvas(image:getDimensions())
    local quad = nil
    local proc = function()
        love.graphics.clear()
        love.graphics.draw(image, quad, 0, 0, 0, 1, 1, 0, 0)
    end
    for i = 0, width / tileSize do
        for ii = 0, height / tileSize do
            quad = love.graphics.newQuad(i * tileSize, ii * tileSize, tileSize, tileSize, canvas:getDimensions())
            canvas:renderTo(proc)
            frames[#frames + 1] = canvas:newImageData()
        end
    end
    return love.graphics.newArrayImage(frames)
end

--- Parses a multilayered Image into an animation
---@param image userdata The Image object to parse
---@param tileSize number Size of one image in the tilemap in pixels
---@param frameCounts table A table with number of frames per animation
---@param animationNames table Assigns names to animations
---@return table
function animation.__call(_,image, tileSize, frameCounts, animationNames)
    local width, height = image:getDimensions()
    local self = {
        imageData = parseImageTilesetIntoArrayImage(image, tileSize),
        frameCounts = frameCounts,
        offsets = {},
        
        tilesPerRow = width / tileSize,
        tilesPerColumn = height / tileSize,
        
        activeAnimation = 1,
        progress = 0
    }

    for i = 1, self.tilesPerRow + 1 do
        self.offsets[i] = 0
    end

    -- TODO: clip self.progress in <0,1> range
    -- TODO: compute frameCounts
    -- TODO: discard unused tiles, search up current frame by adding progress * frameCount + offset
    -- TODO: load from file

    --- Use this method to draw the current animation frame
    ---@param quad userdata :Quad The quad passed to love.graphics.draw call
    ---@param xPos number
    ---@param yPos number
    ---@param xScale number
    ---@param yScale number
    ---@return table
    function self.draw(quad, xPos, yPos, xScale, yScale)
        local frame = math.floor(self.progress)
        return love.graphics.drawLayer(self.imageData, self.activeAnimation + frame, quad, xPos, yPos, xScale, yScale)
    end
    return self
end
setmetatable(animation, animation)
return animation