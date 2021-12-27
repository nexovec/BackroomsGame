local game = {}


-- requires
local animation = require("animation")
local talkies = require('talkies')


-- variables
local backgroundImage
local playerImage
local testTileSet
local basicShaderA
local invertShaderA
local testShaderA


-- API
function game.init()
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- load assets
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    playerImage = animation.new("character")
    tilesetImage = animation.new("tileset")


    -- init logic:
    local animation = playerImage.play(3, "idle", true, false)
    basicShaderA = love.graphics.newShader("resources/shaders/basic.glsl")
    invertShaderA = love.graphics.newShader("resources/shaders/invert.glsl")
    testShaderA = love.graphics.newShader("resources/shaders/test.glsl")

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
    talkies.say("MessageBoxTitle", {"Hi, am a message!", "Sup, I'm a message too"})
end


function game.tick(deltaTime)
    talkies.update(deltaTime)
end

function game.draw()
    
    -- draw background
    -- FIXME: magic numbers
    local backgroundQuad = love.graphics.newQuad(0, 0, 2560, 1440, 2560, 1440)
    love.graphics.draw(backgroundImage, backgroundQuad, 0, 0, 0, 1, 1, 0, 0)

    -- draw player animation
    local playfieldCanvas = love.graphics.newCanvas(1600,720)
    local playfieldQuad = love.graphics.newQuad(0,0,1600,720,1600,720)
    local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)

    playfieldCanvas:renderTo(function()
        love.graphics.clear(1.0, 1.0, 1.0)
        love.graphics.withShader(testShaderA, function()
            testShaderA:sendColor("color1", {0.9, 0.7, 0.9, 1.0})
            testShaderA:sendColor("color2", {0.7, 0.9, 0.9, 1.0})
            testShaderA:send("rectSize",{64,64})
            love.graphics.rectangle("fill", 0, 0, 720, 720)
        end)
        love.graphics.withShader(basicShaderA, function()
            playerImage.draw(playerSpriteQuad, 0, 0, 0, 1,1, 0, 0)
        end)
        talkies.draw()
    end)
    love.graphics.draw(playfieldCanvas, playfieldQuad, 100, 100, 0, 1, 1, 0, 0, 0, 0)
end

return game
