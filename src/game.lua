local game = {}


-- requires
local animation = require("animation")


-- variables
local backgroundImage = nil
local playerImage = nil
local testTileSet = nil


-- API
function game.init()
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- load assets
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    tilesetImage = love.graphics.newImage("resources/images/tileset.png")
    -- love.utils.printTable(playerImage)
    -- parse assets
    -- playerImage = love.graphics.newImage("resources/images/character.png")
    -- assert(playerImage)
    -- playerImage = animation(playerImage, 32, {13, 8, 10, 10, 6, 4, 7, 13, 8, 10, 10, 10, 6, 4, 7}, {"idle", "run", "attack1", "attack2", "attack3", "jump", "hurt", "die"}, true)

    playerImage = animation("character")
    playerImage.to(1)

    -- FIXME:
    tilesetImage = animation(tilesetImage, 32, {3}, {"floor"}, true)

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


function game.tick(deltaTime)
end

function game.draw()
    
    -- draw background
    -- FIXME: magic numbers
    local backgroundQuad = love.graphics.newQuad(0, 0, 3840, 2160, 3840, 2160)
    love.graphics.draw(backgroundImage, backgroundQuad, 0, 0, 0, 1, 1, 0, 0)
    
    -- draw player animation
    local playfieldCanvas = love.graphics.newCanvas(1600,720)
    local playerSpriteQuad = love.graphics.newQuad(0, 0, 1600, 720, 3840, 2160)

    playfieldCanvas:renderTo(function()
        love.graphics.clear(1.0, 1.0, 1.0)
        playerImage.draw(playerSpriteQuad, 0, 0, 0, 1,1, 0, 0)
    end)
    love.graphics.draw(playfieldCanvas, playerSpriteQuad, 100, 100, 0, 1, 1, 0, 0, 0, 0)

    -- TODO: scene graph
end

return game
