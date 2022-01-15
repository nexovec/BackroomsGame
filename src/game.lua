local game = {}

-- requires
local animation = require("animation")
local enet = require("enet")
local t = require("timing")
local uiBox = require("uiBox")
local array = require("std.array")


-- variables
local options
local font

local backgroundImage
local playerImage
local testTileSet

local basicShaderA
local invertShaderA
local testShaderA
local blurShader
local gradientShaderA
local applyAlphaA

local enetclient
local clientpeer

local chatboxMessageHistory = {}
local clientChatboxMessage = ""
local chatboxDims = {640, 1280}
local chatboxUIBox

local nicknamePickerEnabled
local nicknamePickerMessage = ""
local nicknamePickerBoxDims = {750, 300}
local nicknamePickerUIBox

local logMessageBoxDims = {1600, 400}
local logMessageBox

-- test networking
local function beginClient()
    print("Attempting to join the server...")

    -- establish a connection to host on same PC
    enetclient = enet.host_create()
    clientpeer = enetclient:connect("192.168.0.234:6750")
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
            t.delayCall(function()
                clientpeer:send("status:ping!")
            end, 2)
        end
        if data:sub(1, #"message:") == "message:" then
            chatboxMessageHistory[#chatboxMessageHistory + 1] = data:sub(#"message:" + 1, #data)
        end
    end
    hostevent = nil
end
local function handleNetworking(isServer)
    if not isServer then
        beginClient()
    end
end
-- API
function game.load(args)
    assert(type(args) == "table")
    options = args
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- load assets
    font = love.graphics.newFont("resources/fonts/Pixel UniCode.ttf", 48)
    love.graphics.setFont(font)
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    playerImage = animation.new("character")
    tilesetImage = animation.new("tileset")

    -- init logic:
    playerImage:play(3, "run", true, false)
    basicShaderA = love.graphics.newShader("resources/shaders/basic.glsl")
    invertShaderA = love.graphics.newShader("resources/shaders/invert.glsl")
    testShaderA = love.graphics.newShader("resources/shaders/test.glsl")
    blurShader = love.graphics.newShader("resources/shaders/blur.glsl")
    gradientShaderA = love.graphics.newShader("resources/shaders/gradient.glsl")
    applyAlphaA = love.graphics.newShader("resources/shaders/applyAlpha.glsl")

    chatboxUIBox = uiBox.makeBox(chatboxDims[1], chatboxDims[2], gradientShaderA, {}, 20)
    nicknamePickerUIBox = uiBox.makeBox(nicknamePickerBoxDims[1], nicknamePickerBoxDims[2], gradientShaderA, {}, 20)
    logMessageBox = uiBox.makeBox(logMessageBoxDims[1], logMessageBoxDims[2], gradientShaderA, {}, 20)

    love.keyboard.setKeyRepeat(false)

    handleNetworking(options.isServer)
    nicknamePickerEnabled = true
end

function game.tick(deltaTime)
    t.update()
    handleEnetIfClient()
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

        -- love.graphics.withShader(blurShader, function()
        --     blurShader:send("blurSize", 1 / (2560 / 16))
        --     blurShader:send("sigma", 5)
        --     local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
        --     playerImage:draw(playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
        -- end)

        local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
        playerImage:draw(playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
    end)

    local playfieldScenePlacementQuad = love.graphics.newQuad(0, 0, 1600, 720, 1600, 720)
    love.graphics.draw(playfieldCanvas, playfieldScenePlacementQuad, 100, 100, 0, 1, 1, 0, 0, 0, 0)

    -- TODO: create buttons
    -- render log message box
    love.graphics.push("all")
    local logMessageBoxCanvas = logMessageBox.textureCvs
    logMessageBox:clear()
    logMessageBoxCanvas:renderTo(function()
        love.graphics.print("This will show your log.", 30, 30)
    end)
    local logMessageBoxScenePlacementQuad = love.graphics.newQuad(0, 0, logMessageBoxDims[1], logMessageBoxDims[2], logMessageBoxDims[1],
        logMessageBoxDims[2])
    love.graphics.draw(logMessageBoxCanvas, logMessageBoxScenePlacementQuad, 100, 950, 0, 1, 1, 0, 0, 0, 0)


    -- render messages
    local chatboxCanvas = chatboxUIBox.textureCvs
    chatboxUIBox:clear()
    chatboxCanvas:renderTo(function()
        -- FIXME:
        -- love.graphics.setColor(0.65, 0.15, 0.15, 1)
        local yDiff = 40

        for i, messageText in ipairs(chatboxMessageHistory) do
            love.graphics.print(messageText, 30, 10 - yDiff + yDiff * i)
        end

        love.graphics.print(clientChatboxMessage, 30, 1210)
    end)

    local chatboxScenePlacementQuad = love.graphics.newQuad(0, 0, chatboxDims[1], chatboxDims[2], chatboxDims[1],
        chatboxDims[2])
    love.graphics.draw(chatboxCanvas, chatboxScenePlacementQuad, 1800, 100, 0, 1, 1, 0, 0, 0, 0)


    -- render log-in box
    if nicknamePickerEnabled then
        local nicknamePickerCanvas = nicknamePickerUIBox.textureCvs
        nicknamePickerUIBox:clear()
        nicknamePickerCanvas:renderTo(function()
            -- love.graphics.setColor(0.65, 0.15, 0.15, 1)
            love.graphics.print("Enter your name:", 30, 10)
            love.graphics.print(nicknamePickerMessage, 30, 200)
        end)
        local chatboxScenePlacementQuad = love.graphics.newQuad(0, 0, nicknamePickerBoxDims[1], nicknamePickerBoxDims[2],
            nicknamePickerBoxDims[1], nicknamePickerBoxDims[2])
        love.graphics.draw(nicknamePickerCanvas, chatboxScenePlacementQuad, 550, 550, 0, 1, 1, 0, 0, 0, 0)
    end
    love.graphics.pop()

    if options.isServer then love.graphics.print("SERVER")end

end

local activeUIElemIndex = 1
function handleChatKp(key)
    -- chat handling
    if key == "return" then
        if clientpeer then
            clientpeer:send("message:" .. clientChatboxMessage)
        end
        -- TODO: handle sends from the server
        clientChatboxMessage = ""
    elseif key == "backspace" then
        clientChatboxMessage = clientChatboxMessage:sub(1, #clientChatboxMessage - 1)
    end
end
function handleNickPickerKp(key)
    if key == "return" then
        clientpeer:send("status:addPlayer:" .. nicknamePickerMessage)
        activeUIElemIndex = activeUIElemIndex + 1
        nicknamePickerEnabled = false
    elseif key == "backspace" then
        nicknamePickerMessage = nicknamePickerMessage:sub(1, #nicknamePickerMessage - 1)
    end
end
local UIElemHandlers = {{
    keypressed = handleNickPickerKp,
    textinput = function(t)
        nicknamePickerMessage = nicknamePickerMessage .. t
    end
}, {
    keypressed = handleChatKp,
    textinput = function(t)
        clientChatboxMessage = clientChatboxMessage .. t
    end
}}
function love.keypressed(key)
    UIElemHandlers[activeUIElemIndex].keypressed(key)
end
function love.textinput(t)
    UIElemHandlers[activeUIElemIndex].textinput(t)
end

return game
