local game = {}

-- requires
local animation = require("animation")
local talkies = require('talkies')
local enet = require("enet")
local t = require("timing")

-- variables
local backgroundImage
local playerImage
local testTileSet

local basicShaderA
local invertShaderA
local testShaderA
local blurShader
local uiBtnRoundingMask
local gradientShaderA
local applyAlphaA

local enethost
local enetclient
local clientpeer

-- test networking
local function beginServer()
    print("Starting the Server...")

    -- establish host for receiving msg
    enethost = enet.host_create("192.168.0.234:6750")

end
local function beginClient()
    print("Attempting to join the server...")

    -- establish a connection to host on same PC
    enetclient = enet.host_create()
    clientpeer = enetclient:connect("192.168.0.234:6750")
end
local connectedPeer
function ListenIfServer()
    if not enethost then
        return
    end
    local hostevent = enethost:service()
    if hostevent then
        -- print("Server detected message type: " .. hostevent.type)
        if hostevent.type == "connect" then
            print(hostevent.peer, "connected.")
        end
        if hostevent.type == "receive" then
            print("Received message: ", hostevent.data, hostevent.peer)
            t.delayCall(function()
                hostevent.peer:send("Hello from the server!")
            end, 2)
        end
    end
end

function SendIfClient()
    if not enetclient then
        return
    end
    local hostevent = enetclient:service()
    if not hostevent then
        return
    end
    if hostevent.type == "connect" then
        print("sending hi to server!")
        clientpeer:send("Hi")
    end
    if hostevent.type == "receive" then
        print("Client received message: ", hostevent.data, hostevent.peer)
        t.delayCall(function()
            clientpeer:send("communicating!")
        end, 2)
    end
end
local function handleNetworking()
    talkies.say("Networking", "Who do you want to be?", {
        rounding = 5,
        font = love.graphics.newFont("resources/fonts/Pixel UniCode.ttf", 48),
        options = {{"Server", function()
            beginServer()
        end}, {"Client", function()
            beginClient()
        end}}
    })
end

-- API
function game.init()
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- load assets
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    playerImage = animation.new("character")
    tilesetImage = animation.new("tileset")

    -- init logic:
    playerImage:play(3, "attack1", true, false)
    basicShaderA = love.graphics.newShader("resources/shaders/basic.glsl")
    invertShaderA = love.graphics.newShader("resources/shaders/invert.glsl")
    testShaderA = love.graphics.newShader("resources/shaders/test.glsl")
    blurShader = love.graphics.newShader("resources/shaders/blur.glsl")
    gradientShaderA = love.graphics.newShader("resources/shaders/gradient.glsl")
    applyAlphaA = love.graphics.newShader("resources/shaders/applyAlpha.glsl")

    uiBtnRoundingMask = love.graphics.newShader("resources/shaders/masks/uiBtnRoundingMask.glsl")

    handleNetworking()

    -- TODO: grayscale shader
    -- TODO: color pallette conversion shader
    -- TODO: luma shader
    -- TODO: draw floor, ceiling
    -- TODO: draw a chair in the scene
    -- TODO: basic interaction with chair transitions into level 0
    -- TODO: in-game log
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
    talkies.update(deltaTime)
    t.update()
    SendIfClient()
    ListenIfServer()
end

function game.draw()

    -- draw background
    -- FIXME: magic numbers
    local backgroundQuad = love.graphics.newQuad(0, 0, 2560, 1440, 2560, 1440)
    love.graphics.draw(backgroundImage, backgroundQuad, 0, 0, 0, 1, 1, 0, 0)

    -- draw scene
    local playfieldCanvas = love.graphics.newCanvas(1600, 720)

    playfieldCanvas:renderTo(function()
        love.graphics.clear(1.0, 1.0, 1.0)
        love.graphics.withShader(testShaderA, function()
            testShaderA:sendColor("color1", {0.9, 0.7, 0.9, 1.0})
            testShaderA:sendColor("color2", {0.7, 0.9, 0.9, 1.0})
            testShaderA:send("rectSize", {64, 64})
            love.graphics.rectangle("fill", 0, 0, 720, 720)
        end)
        love.graphics.withShader(basicShaderA, function()
            love.graphics.withShader(blurShader, function()
                blurShader:send("blurSize", 1 / (2560 / 8))
                blurShader:send("sigma", 3)
                local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
                playerImage:draw(playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
            end)
        end)
        talkies.draw()
    end)

    local playfieldScenePlacementQuad = love.graphics.newQuad(0, 0, 1600, 720, 1600, 720)
    love.graphics.draw(playfieldCanvas, playfieldScenePlacementQuad, 100, 100, 0, 1, 1, 0, 0, 0, 0)

    -- draw chatbox
    local chatboxDims = {640, 1280}
    local chatboxTexture = love.graphics.newCanvas(unpack(chatboxDims))
    local chatboxCanvas = love.graphics.newCanvas(unpack(chatboxDims))
    local chatboxAlpha = love.graphics.newCanvas(unpack(chatboxDims))

    chatboxAlpha:renderTo(function()
        love.graphics.withShader(uiBtnRoundingMask, function()
            uiBtnRoundingMask:send("rounding", 70)
            love.graphics.rectangle("fill", 0, 0, unpack(chatboxDims))
        end)
    end)

    -- the following is equivalent:

    -- chatboxTexture:renderTo(function()
    --     love.graphics.withShader(gradientShaderA, function()
    --         gradientShaderA:sendColor("top_left", {1, 0, 1, 1})
    --         gradientShaderA:sendColor("top_right", {1, 0, 0, 1})
    --         gradientShaderA:sendColor("bottom_right", {0, 1, 0, 1})
    --         gradientShaderA:sendColor("bottom_left", {0, 0, 1, 1})
    --         love.graphics.rectangle("fill", 0, 0, unpack(chatboxDims))
    --     end)
    -- end)

    love.graphics.applyShader(chatboxTexture, gradientShaderA, {
        top_left = {1, 0, 1, 1},
        top_right = {1, 0, 0, 1},
        bottom_right = {0, 1, 0, 1},
        bottom_left = {0, 0, 1, 1}
    })
    --

    chatboxCanvas:renderTo(function()
        -- TODO: use stencil shader instead
        love.graphics.withShader(applyAlphaA, function()
            applyAlphaA:send("alphaMask", chatboxAlpha)
            love.graphics.draw(chatboxTexture, 0, 0)
        end)
    end)

    local chatboxScenePlacementQuad = love.graphics.newQuad(0, 0, chatboxDims[1], chatboxDims[2], chatboxDims[1],
        chatboxDims[2])
    love.graphics.draw(chatboxCanvas, chatboxScenePlacementQuad, 1800, 100, 0, 1, 1, 0, 0, 0, 0)
end

function love.keypressed(key)
    if key == "space" then
        talkies.onAction()
    elseif key == "up" then
        talkies.prevOption()
    elseif key == "down" then
        talkies.nextOption()
    end
end

return game
