local game = {}

-- requires
local animation = require("animation")
local talkies = require('talkies')
local enet = require("enet")
local t = require("timing")

-- variables
local font

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
local chatMessages = {}
local clientChatMessage = ""

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
local connectedPeers = {}
function handleEnetIfServer()
    if not enethost then
        return
    end
    local hostevent = enethost:service()
    if hostevent then
        -- print("Server detected message type: " .. hostevent.type)
        if hostevent.type == "connect" then
            print(hostevent.peer, "connected.")
            connectedPeers[#connectedPeers + 1] = hostevent.peer
        end
        -- TODO: log unregistered clients trying to send messages
        if not table.contains(connectedPeers, hostevent.peer) then
            return
        end
        if hostevent.type == "receive" then
            local data = hostevent.data
            if data:sub(1, #"message:") == "message:" then
                print(data)
                -- TODO: send to everybody
                hostevent.peer:send(data)
            end
            if data:sub(1, #"status:") == "status:" then
                print(hostevent.data, hostevent.peer)
                local tempHost = hostevent
                t.delayCall(function()
                    tempHost.peer:send("status:pong!")
                end, 2)
            end

        end
    end
    hostevent = nil
end

function handleEnetIfClient()
    -- TODO: reconnect if disconnected
    if not enetclient then
        return
    end
    local hostevent = enetclient:service()
    if not hostevent then
        return
    end
    if hostevent.type == "connect" then
        clientpeer:send("status:ping!")
    end
    if hostevent.type == "receive" then
        local data = hostevent.data
        if data:sub(1, #"status:") == "status:" then
            print(hostevent.data, hostevent.peer)
            t.delayCall(function()
                clientpeer:send("status:ping!")
            end, 2)
        end
        if data:sub(1, #"message:") == "message:" then
            print(data)
            chatMessages[#chatMessages + 1] = data
        end
    end
    hostevent = nil
end
local function handleNetworking(isServer)
    if isServer then
        beginServer()
    else
        beginClient()
    end
    -- talkies.say("Networking", "Who do you want to be?", {
    --     rounding = 5,
    --     font = font,
    --     options = {{"Server", function()
    --         beginServer()
    --     end}, {"Client", function()
    --         beginClient()
    --     end}}
    -- })
end

-- API
function game.init(options)
    options = options or {}
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- load assets
    font = love.graphics.newFont("resources/fonts/Pixel UniCode.ttf", 48)
    love.graphics.setFont(font)
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

    love.keyboard.setKeyRepeat(false)

    handleNetworking(options.isServer)

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
    handleEnetIfClient()
    handleEnetIfServer()
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
        love.graphics.withShader(blurShader, function()
            blurShader:send("blurSize", 1 / (2560 / 16))
            blurShader:send("sigma", 5)
            local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
            playerImage:draw(playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
        end)
        talkies.draw()
    end)

    local playfieldScenePlacementQuad = love.graphics.newQuad(0, 0, 1600, 720, 1600, 720)
    love.graphics.draw(playfieldCanvas, playfieldScenePlacementQuad, 100, 100, 0, 1, 1, 0, 0, 0, 0)

    -- draw chatbox
    local chatboxDims = {640, 1280}
    local chatboxTexture = love.graphics.newCanvas(unpack(chatboxDims))
    local chatboxCanvas = love.graphics.newCanvas(unpack(chatboxDims))
    local chatboxAlpha = love.graphics.newCanvas(chatboxDims.x, chatboxDims.y, {
        format = "stencil8"
    })

    -- shader simulated stencil buffer:
    -- the following is equivalent:

    -- chatboxAlpha:renderTo(function()
    --     love.graphics.withShader(uiBtnRoundingMask, function()
    --         uiBtnRoundingMask:send("rounding", 70)
    --         love.graphics.rectangle("fill", 0, 0, unpack(chatboxDims))
    --     end)
    -- end)

    -- love.graphics.applyShader(chatboxAlpha, uiBtnRoundingMask,{rounding = 75})

    -- create chatbox texture:
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

    -- love.graphics.applyShader(chatboxTexture, gradientShaderA, {
    --     top_left = {1, 0, 1, 1},
    --     top_right = {1, 0, 0, 1},
    --     bottom_right = {0, 1, 0, 1},
    --     bottom_left = {0, 0, 1, 1}
    -- })

    -- chatboxCanvas:renderTo(function()
    --     love.graphics.withShader(applyAlphaA, function()
    --         applyAlphaA:send("alphaMask", chatboxAlpha)
    --         love.graphics.draw(chatboxTexture, 0, 0)
    --     end)
    -- end)

    -- apply stencil buffer
    -- love.graphics.applyShader(chatboxCanvas, applyAlphaA, {alphaMask = chatboxAlpha}, {draw = chatboxTexture})

    -- stencil buffer
    love.graphics.push("all")
    love.graphics.setCanvas({
        chatboxCanvas,
        depthstencil = true
    })
    love.graphics.stencil(function()
        love.graphics.setShader(uiBtnRoundingMask)
        uiBtnRoundingMask:send("rounding", 20)
        love.graphics.rectangle("fill", 0, 0, unpack(chatboxDims))
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.applyShader({
        chatboxCanvas,
        depthstencil = true,
        getDimensions = function()
            return chatboxCanvas:getDimensions()
        end
    }, gradientShaderA, {
        top_left = {0.1, 0.1, 0.1, 1},
        top_right = {0.1, 0.1, 0.1, 1},
        bottom_right = {0.2, 0.2, 0.2, 1},
        bottom_left = {0.2, 0.2, 0.2, 1}
    })
    love.graphics.rectangle("fill", 0, 0, unpack(chatboxDims))
    love.graphics.pop()

    -- render messages
    love.graphics.push("all")
    chatboxCanvas:renderTo(function()
        love.graphics.setColor(0.65, 0.15, 0.15, 1)
        local yDiff = 40

        for i, messageText in ipairs(chatMessages) do
            love.graphics.print(messageText, 30, 10 - yDiff + yDiff * i)
        end

        love.graphics.print(clientChatMessage, 30, 1210)
    end)
    love.graphics.pop()

    local chatboxScenePlacementQuad = love.graphics.newQuad(0, 0, chatboxDims[1], chatboxDims[2], chatboxDims[1],
        chatboxDims[2])
    love.graphics.draw(chatboxCanvas, chatboxScenePlacementQuad, 1800, 100, 0, 1, 1, 0, 0, 0, 0)
end

function love.keypressed(key)
    -- talkies
    if key == "space" then
        talkies.onAction()
    elseif key == "up" then
        talkies.prevOption()
    elseif key == "down" then
        talkies.nextOption()
    end

    -- chat handling
    if key == "return" then
        print("Pressed Enter!")
        -- chatMessages[#chatMessages + 1] = clientChatMessage
        -- clientpeer:send("message:" .. clientChatMessage)
        -- clientChatMessage = ""
        if clientpeer then
            clientpeer:send("message:" .. clientChatMessage)
        end
        -- TODO: handle sends from the server
        clientChatMessage = ""
    elseif key == "backspace" then
        clientChatMessage = clientChatMessage:sub(1, #clientChatMessage - 1)
    end
end
function love.textinput(t)
    clientChatMessage = clientChatMessage .. t
end

return game
