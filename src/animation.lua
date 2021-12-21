local animation = {}


-- requires
local flux = require("flux")

-- helper functions
local function parseImageTilesetIntoArrayImage(image, tileSize)
    assert(type(image) == "userdata", "expected image: Image, got image: " .. image:type(), 2)
    assert(image:type() == "Image", "expected image: Image, got image: " .. image:type(), 2)
    assert(tileSize > 0, "Tile size must be positive", 2)
    local frames = {}
    local width, height = image:getDimensions()
    local canvas = love.graphics.newCanvas(image:getDimensions())
    local quad = nil
    local proc = function()
        love.graphics.clear()
        love.graphics.draw(image, quad, 0, 0, 0, 1, 1, 0, 0)
    end
    for i = 0, height / tileSize do
        for ii = 0, width / tileSize do
            quad = love.graphics.newQuad(ii * tileSize, i * tileSize, tileSize, tileSize, canvas:getDimensions())
            canvas:renderTo(proc)
            frames[#frames + 1] = canvas:newImageData()
        end
    end
    -- canvas:renderTo(function()
    --     for i = 0, height / tileSize do
    --         for ii = 0, width / tileSize do
    --             quad = love.graphics.newQuad(ii * tileSize, i * tileSize, tileSize, tileSize, canvas:getDimensions())
    --             proc()
    --             frames[#frames + 1] = canvas:newImageData()
    --         end
    --     end
    -- end)
    return love.graphics.newArrayImage(frames)
end

--- Constructor; Parses a multilayered Image into an animation
---@param image userdata The Image object to parse
---@param tileSize number Size of one image in the tilemap in pixels
---@param frameCounts table A table with number of frames per animation
---@param loopNames table Assigns names to individual loops of the animation
---@param skipToNextRowAfterLoop boolean true if there is one animation per row, false if they are tightly packed
---@return table
function animation.__call(_, image, tileSize, frameCounts, loopNames, skipToNextRowAfterLoop)
    assert(image)
    if type(image) == "string" then
        -- load from file
        -- TEMP:
        -- love.ddd.animations = love.decodeJsonFile("data/animations.json")
        assert(love.ddd.animations)
        local properties = love.ddd.animations[image]
        image = love.graphics.newImage(properties.filepath)
        tileSize = properties.tileSize
        frameCounts = properties.frameCounts
        loopNames = properties.loopNames
        skipToNextRowAfterLoop = properties.skipToNextRowAfterLoop
    end
    assert(tileSize)
    assert(skipToNextRowAfterLoop == true, "Not yet implemented.", 2)
    assert(frameCounts ~= nil and type(frameCounts) == "table")
    assert(loopNames)
    assert(skipToNextRowAfterLoop)

    local width, height = image:getDimensions()
    local self = {
        imageData = parseImageTilesetIntoArrayImage(image, tileSize),
        frameCounts = frameCounts,
        offsets = {},
        animationNames = loopNames,
        
        tilesPerRow = width / tileSize,
        tilesPerColumn = height / tileSize,
        
        activeLoop = 1,
        progress = 0
    }
    assert(isint(self.tilesPerRow))
    assert(isint(self.tilesPerColumn))

    self.offsets[1] = 1
    for i = 1, #self.frameCounts do
        local rowCount = math.floor((self.frameCounts[i] - 1) / self.tilesPerRow) + 1
        self.offsets[i+1] = self.offsets[i] + self.tilesPerRow * rowCount
    end

    -- TODO: clip self.progress in <0,1> range
    -- TODO: compute frameCounts
    -- TODO: discard unused tiles, search up current frame by adding progress * frameCount + offset
    -- TODO: load from file

    -- API
    function self.setAnimation(name)
        assert(type(name) == "string", "number indexing is not implemented yet")
        self.progress = 0
        self.activeLoop = table.invert(self.loopNames)[name]
    end

    function self.to(duration)
        flux.to(self, duration, {progress = 1})
    end
    
    function self.play(loopDuration, isLooping)
        self.progress = 0
        flux.to(self, loopDuration, {progress = 1})
    end

    --- Use this method to draw the current animation frame
    ---@param quad userdata :Quad The quad passed to love.graphics.draw call
    ---@param xPos number
    ---@param yPos number
    ---@param xScale number
    ---@param yScale number
    ---@return table
    function self.draw(quad, xPos, yPos, xScale, yScale)
        local frame = math.floor(self.progress * (self.frameCounts[self.activeLoop] - 1))
        return love.graphics.drawLayer(self.imageData, self.offsets[self.activeLoop] + frame, quad, xPos, yPos, xScale, yScale)
    end
    return self
end
setmetatable(animation, animation)
return animation