local API = {}

local TileSet = require("TileSet")

local backgroundImage = nil
local playerImage = nil
local testTileSet = nil

function API.init()
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- make fullscreen
    love.window.requestAttention()
    love.window.setFullscreen(true,"desktop")

    -- load images
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    playerImage = love.graphics.newImage("resources/images/playersprite.png")
    testTileSet = TileSet:fromCanvas(playerImage, 16, 16)
    -- TODO: parse tileset
    -- TODO: draw floor, ceiling
    -- TODO: draw a chair in the scene
    -- TODO: make the player move
    -- TODO: basic interaction with chair transitions into level 0
    -- TODO: in-game log
    -- TODO: narration dialogue boxes
    -- TODO: scripted entity encounter
    -- TODO: entity cards
    -- TODO: display entity on the field
    -- TODO: scripted wanderer encounter
    -- TODO: background shader
    -- TODO: craft UI layouts
    -- TODO: settings menu
    -- TODO: fade-in, fade-out on level transition
    -- TODO: post-FX
    -- TODO: particles
    -- TODO: UI animations
    -- TODO: phone
    -- TODO: BeautifulBread logo on startup
    -- TODO: narrate intro and level 0
    -- TODO: add outpost
    -- TODO: add inventory
    -- TODO: add drinkable almond water
end

function API.tick(deltaTime)
    
end

function API.draw()
    -- draw textures to buffer
    local smallQuad = love.graphics.newQuad(0, 0, 1280, 720, 1280, 720)
    love.graphics.draw(backgroundImage, smallQuad, 0, 0, 0, 1, 1, 0, 0)
    
    local playerSpriteQuad = love.graphics.newQuad(0, 0, 512, 512, 512, 512)
    love.graphics.draw(playerImage, playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
    testTileSet:draw(6,4,12,12)
end

return API
