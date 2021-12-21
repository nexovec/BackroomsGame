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
    return love.graphics.newArrayImage(frames)
end

--- Parses an image into an animation (from )
---@param image userdata The Image object to parse
---@param tileSize number Size of one image in the tilemap in pixels
---@param frameCounts table A table with number of frames per animation
---@param loopNames table Assigns names to individual loops of the animation
---@param skipToNextRowAfterLoop boolean true if there is one animation per row, false if they are tightly packed
---@return table
function animation.new(image, tileSize, frameCounts, loopNames, skipToNextRowAfterLoop)
    if type(image) == "string" then

        -- load spritesheet from file from file
        assert(love.ddd.animations)
        local properties = love.ddd.animations[image]
        -- TODO: make the image shared and the ArrayImage as well
        image = love.graphics.newImage(properties.filepath)
        tileSize = properties.tileSize
        frameCounts = properties.frameCounts
        loopNames = properties.loopNames
        skipToNextRowAfterLoop = properties.skipToNextRowAfterLoop
    end
    assert(type(image) == "userdata" and image:type() == "Image", "Couldn't load image.", 2)
    assert(type(tileSize) == "number", "You must specify .tileSize property as a number. (hint: animations.json)", 2)
    assert(type(frameCounts) == "table", "You must specify .frameCounts property as an array. (hint: animations.json)", 2)
    assert(type(loopNames) == "table", "You must specify .tileSize property as an array. (hint: animations.json)", 2)
    assert(type(skipToNextRowAfterLoop) == "boolean", "You must specify .skipToNextRowAfterLoop property as a boolean. (hint: animations.json)")

    assert(skipToNextRowAfterLoop == true, "Not yet implemented.", 2)

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
    -- TODO: discard unused tiles

    -- API
    function self.setAnimation(name)
        assert(type(name) == "string", "number indexing is not implemented yet")
        self.progress = 0
        self.activeLoop = table.invert(self.loopNames)[name]
    end

    function self.to(duration)
        return flux.to(self, duration, {progress = 1})
    end
    
    function self.play(playbackDuration, loopName, isLooping)
        assert(not isLooping, "Not yet implemented.", 2)
        assert(playbackDuration > 0, nil, 2)
        self.progress = 0
        flux.to(self, playbackDuration, {progress = 1})
    end

    function self.draw(quad, xPos, yPos, xScale, yScale)
        local frame = math.floor(self.progress * (self.frameCounts[self.activeLoop] - 1))
        return love.graphics.drawLayer(self.imageData, self.offsets[self.activeLoop] + frame, quad, xPos, yPos, xScale, yScale)
    end
    return self
end
return animation