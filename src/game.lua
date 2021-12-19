local API = {}

love.utils = {}
function love.utils.printTable(a)
    assert(type(a) == "table", "Parameter is not a table, but a " .. type(a))
    local function inner(aa)
        print("{")
        local elemCount = 0
        for k,v in pairs(aa) do
            elemCount = elemCount + 1
            if type(v) == "table" then
                inner(v)
            else
                print(k..": "..v)
            end
        end
        if elemCount == 0 then
            print("This table is empty")
        end
        print("}")
    end
    inner(a)
end
printTable = love.utils.printTable

function love.utils.shallowCopy(a)
    assert(type(a) == "table", "This can only be used on tables")
    local self = {}
    for k,v in pairs(a) do
        self[k] = v
    end
    return self
end
shallowCopy = love.utils.shallowCopy

-- modules
local UI = require("immediateUI")

-- variables
local backgroundImage = nil
local playerImage = nil
local testTileSet = nil

function API.init()
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- make fullscreen
    love.window.requestAttention()
    love.window.setFullscreen(true, "desktop")

    -- load images
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    -- TODO: load as ArrayImage
    playerImage = love.graphics.newImage("resources/images/playersprite.png")
    
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
    
    -- FIXME: magic numbers
    -- local sceneCanvas = love.graphics.newCanvas(1280, 720)
    -- love.graphics.setCanvas(sceneCanvas)
    local smallQuad = love.graphics.newQuad(0, 0, 1280, 720, 1280, 720)
    love.graphics.draw(backgroundImage, smallQuad, 0, 0, 0, 1, 1, 0, 0)
    
    local playfieldCanvas = love.graphics.newCanvas(640, 480)
    local playerSpriteQuad = love.graphics.newQuad(0, 0, 512, 512, 512, 512)
    
    love.graphics.setCanvas(playfieldCanvas)
    love.graphics.clear(1.0, 1.0, 1.0)
    love.graphics.draw(playerImage, playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
    love.graphics.setCanvas()
    -- love.graphics.draw(playfieldCanvas, love.graphics.newQuad(0, 0, 640, 480, playfieldCanvas:getDimensions()), 100, 100, 0, 1, 1, 0, 0, 0, 0)
    -- TODO: better API, something like:
    UI.setPreferredLayoutBorders(100,100)
    UI.setPreferredLayoutPadding(50,50)
    UI.setMinimumLayoutCellSize(200,200)
    UI.startFlexLayout()
    -- rendering into a layout
    
    -- game
    -- love.graphics.draw(playfieldCanvas, love.graphics.newQuad(0, 0, 640, 480, playfieldCanvas), 100, 100, 0, 1, 1, 0, 0, 0, 0)
    -- log
    UI.renderCanvas(playfieldCanvas)
    UI.nextCol()
    -- actions
    UI.nextRow()
    
    -- inventory
    UI.nextCol()
    UI.popLayout()
end

return API
