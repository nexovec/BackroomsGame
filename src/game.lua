local game = {}

-- requires
local animation = require("animation")
local enet = require("enet")
local t = require("timing")
local uiBox = require("uiBox")
local array = require("std.array")
local string = require("std.string")
local network = require("network")
local tileAtlas = require("tileAtlas")
local assets = require("assets")


-- variables
local options
local testTileSet

local enetclient
local serverpeer

local mockResolution = {2560, 1440}

local chatboxMessageHistory = array.wrap()
local clientChatboxMessage = ""
local chatboxDims = {640, 1280}
local chatboxUIBox

local nicknamePickerEnabled
local nicknamePickerMessage = ""
local nicknamePickerPassword = ""
local nicknamePickerBoxDims = {750, 300}
local nicknamePickerUIBox

local logMessageBoxDims = {1600, 400}
local logMessageBox

local activeUIElemIndex = 1
local activeNicknamePickerField = "nickname"

local serverAddress = "192.168.0.234:6750"
local connectionFails = 0

-- helper functions

--- Corrects position for resolutionChanges
---@param pos table Of the form {width, height}
local function resolutionScaledPos(pos)
    return {(assets.get("settings").width / mockResolution[1]) * pos[1],(assets.get("settings").height / mockResolution[2]) * pos[2]}
end
local function resolutionScaledDraw(image, quad, x, y)
    local correctX, correctY = unpack(resolutionScaledPos{x, y})
    --TODO:
    local viewX, viewY, width, height = quad:getViewport()
    local scaleX, scaleY = quad:getTextureDimensions()
    local cviewX, cviewY = unpack(resolutionScaledPos{viewX,viewY})
    local cwidth, cheight = unpack(resolutionScaledPos{width, height})
    local cscaleX, cscaleY = unpack(resolutionScaledPos{scaleX, scaleY})
    local correctQuad = love.graphics.newQuad(cviewX, cviewY, cwidth, cheight, cscaleX, cscaleY)
    love.graphics.draw(image, correctQuad, correctX, correctY)
end

--- NETWORKING:

local function beginClient()
    chatboxMessageHistory:append("Attempting to join the server...")

    -- establish a connection to host on same PC
    enetclient = enet.host_create()
    serverpeer = enetclient:connect(serverAddress)
    serverpeer:timeout(0, 0, 5000)
end

local function sendMessage(...)
    local params = {...}
    local message = table.concat(params, ":")
    serverpeer:send(message)
end

local function receivedMessageHandle(hostevent)
    local data = hostevent.data
    local prefix, trimmedMessage  = network.getNetworkMessagePrefix(data)
    if prefix == "pingpong" then
        t.delayCall(function()
            sendMessage("pingpong","ping!")
        end, 2)
    elseif prefix == "message" then
        chatboxMessageHistory:append(trimmedMessage)
    elseif prefix == "logOut" then
        -- server tells you to disconnect
        -- TODO:
    else
        error(prefix .. "X" .. ":" ..trimmedMessage)
    end
end

local function handleEnetClient()
    local hostevent = enetclient:service()
    if serverpeer:state() == "disconnected" then
        connectionFails = connectionFails + 1
        if connectionFails < 6 then
            chatboxMessageHistory:append("Connection lost. Reconnecting...")
        end
        serverpeer:reset()
        serverpeer = enetclient:connect(serverAddress)
        serverpeer:timeout(0, 0, math.min(connectionFails, 6) * 5000)
    end
    if not enetclient then return end
    if not hostevent then return end
    -- if hostevent.peer == clientpeer then return end

    local type = hostevent.type
    if type == "connect" then
        sendMessage("pingpong", "ping!")
        chatboxMessageHistory:append("You've connected to the server!")
    end
    if type == "receive" then
        receivedMessageHandle(hostevent)
    end
    if type == "disconnected" then
        chatboxMessageHistory:append("You were disconnected")
        serverpeer = enetclient:connect(serverAddress)
    end
    hostevent = nil
end

--- UI
---- rendering

local function renderOldUI()
    -- render log message box
    love.graphics.push("all")
    local logMessageBoxCanvas = logMessageBox.textureCvs
    logMessageBox:clear()
    logMessageBoxCanvas:renderTo(function()
        love.graphics.print("This will show your log.", 30, 30)
    end)
    local logMessageBoxScenePlacementQuad = love.graphics.newQuad(0, 0, logMessageBoxDims[1], logMessageBoxDims[2], logMessageBoxDims[1],
        logMessageBoxDims[2])
    -- love.graphics.draw(logMessageBoxCanvas, logMessageBoxScenePlacementQuad, 100, 950, 0, 1, 1, 0, 0, 0, 0)
    resolutionScaledDraw(logMessageBoxCanvas, logMessageBoxScenePlacementQuad, 100, 950)


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
    resolutionScaledDraw(chatboxCanvas, chatboxScenePlacementQuad, 1800, 100)


    -- render log-in box
    if nicknamePickerEnabled then
        local nicknamePickerCanvas = nicknamePickerUIBox.textureCvs
        nicknamePickerUIBox:clear()
        nicknamePickerCanvas:renderTo(function()
            -- love.graphics.setColor(0.65, 0.15, 0.15, 1)
            local descX, fieldX, row1y, row2y = 50, 250, 80, 150
            love.graphics.print("name:", descX, row1y)
            love.graphics.print(nicknamePickerMessage, fieldX, row1y)
            love.graphics.print("password:", descX, row2y)
            love.graphics.print( string.rep("*", #nicknamePickerPassword), fieldX, row2y)
        end)
        local chatboxScenePlacementQuad = love.graphics.newQuad(0, 0, nicknamePickerBoxDims[1], nicknamePickerBoxDims[2],
            nicknamePickerBoxDims[1], nicknamePickerBoxDims[2])
        resolutionScaledDraw(nicknamePickerCanvas, chatboxScenePlacementQuad, 550, 550)
    end
    love.graphics.pop()
end

local function drawGrid(tileSize, color)
    if color then
        love.graphics.setColor(unpack(color))
    end
    for i = 1, math.floor(mockResolution[2] / tileSize) do
        local pos1 = {0, i * tileSize}
        local pos2 =  {mockResolution[1], i * tileSize}
        -- TODO: Investigate: This should probably be corrected like this:
        -- local cPos1 = resolutionScaledPos(pos1)
        -- local cPos2 = resolutionScaledPos(pos2)
        local cPos1 = pos1
        local cPos2 = pos2
        love.graphics.line(cPos1[1], cPos1[2], cPos2[1], cPos2[2])
    end
    for i = 1, math.floor(mockResolution[1] / tileSize) do
        local pos1 = {i * tileSize, 0}
        local pos2 =  {i * tileSize, mockResolution[2]}
        -- local cPos1 = resolutionScaledPos(pos1)
        -- local cPos2 = resolutionScaledPos(pos2)
        local cPos1 = pos1
        local cPos2 = pos2
        love.graphics.line(cPos1[1], cPos1[2], cPos2[1], cPos2[2])
    end
    if color then
        love.graphics.setColor(1, 1, 1, 1)
    end
end

local function tiledUIPanel(assetName, tileSize, scale, panelPos)
    local self = {
        assetName = assetName,
        tileSize = tileSize,
        scale = scale
    }
    function self:draw(xPosInTiles, yPosInTiles, widthInTiles, heightInTiles)
        local scaledTileSize = self.tileSize * self.scale
        assert(xPosInTiles >= 0 and yPosInTiles >= 0 and widthInTiles > 0 and widthInTiles > 0)
        local atlas = tileAtlas.wrap(self.assetName, self.tileSize)
        local startingX, startingY, panelWInTiles, panelHInTiles = 0, 4, 10, 10
        for xI = 0, widthInTiles - 1 do
            for yI = 0, heightInTiles - 1 do
                -- assigns which tile gets rendered at this position(at scaledTileSize * posInTiles + index)
                local tileX, tileY
                if yI == 0 then
                    tileY = startingY
                end
                if xI == 0 then
                    tileX = startingX
                end
                if yI == heightInTiles - 1 then
                    tileY = startingY + panelHInTiles - 1
                end
                if xI == widthInTiles - 1 then
                    tileX = startingX + panelWInTiles - 1
                end
                -- TODO: pick edge tiles randomly
                -- TODO: pick inner tiles randomly
                if not tileX then tileX = startingX + 1 end
                if not tileY then tileY = startingY + 1 end
                -- atlas:drawTile(st * (x + xI), st * (y + yI), 1, 1, st, st)
                atlas:drawTile((xPosInTiles + xI) * self.tileSize * self.scale, (yPosInTiles + yI) * self.tileSize * self.scale, tileX, tileY, self.scale * self.tileSize, self.scale * self.tileSize)
            end
        end
    end

    return self
end

function renderNewUI()
    -- TODO: Render tiled UI
    local x, y, width, height = 4, 4, 8, 3
    local tileSize = 16
    local scale = 5
    -- local x, y, width, height = 0, 0, 1, 6
    tiledUIPanel("uiPaperImage", tileSize, scale, {}):draw(x, y, width, height)
    -- drawGrid(tileSize * scale, {1, 0, 1, 1})
end

---- handling input

function handleChatKp(key)
    -- chat handling
    if key == "return" then
        if serverpeer then
            sendMessage("message", clientChatboxMessage)
        end
        -- TODO: Handle sends from the server
        clientChatboxMessage = ""
    elseif key == "backspace" then
        clientChatboxMessage = string.popped(clientChatboxMessage)
    end
end

function handleNickPickerKp(key)
    if key == "return" then
        if activeNicknamePickerField == "nickname" then activeNicknamePickerField = "password" return end
        -- TODO: Verify nickname
        sendMessage("status", "logIn", nicknamePickerMessage .. ":" .. nicknamePickerPassword)
        activeUIElemIndex = activeUIElemIndex + 1
        nicknamePickerEnabled = false
    elseif key == "backspace" then
        if activeNicknamePickerField == "nickname" then
            nicknamePickerMessage = string.popped(nicknamePickerMessage)
        else
            nicknamePickerPassword = string.popped(nicknamePickerPassword)
        end
    end
end

local UIElemHandlers = {{
    keypressed = handleNickPickerKp,
    textinput = function(t)
        if activeNicknamePickerField == "password" then
            nicknamePickerPassword = nicknamePickerPassword .. t
        else
            nicknamePickerMessage = nicknamePickerMessage .. t
        end
    end
}, {
    keypressed = handleChatKp,
    textinput = function(t)
        clientChatboxMessage = clientChatboxMessage .. t
    end
}}

--- API

function game.load(args)
    assert(type(args) == "table")
    options = args
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    love.keyboard.setKeyRepeat(true)
    love.graphics.setFont(assets.get("font"))
    assets.playerImage = animation.newCharacterAnimation("character")

    -- init logic:
    assets.playerImage:play(0.6, "run", true, false)

    chatboxUIBox = uiBox.makeBox(chatboxDims[1], chatboxDims[2], "gradientShaderA", {}, 20)
    nicknamePickerUIBox = uiBox.makeBox(nicknamePickerBoxDims[1], nicknamePickerBoxDims[2], "gradientShaderA", {}, 20)
    logMessageBox = uiBox.makeBox(logMessageBoxDims[1], logMessageBoxDims[2], "gradientShaderA", {}, 20)

    love.keyboard.setKeyRepeat(true)

    beginClient()
    nicknamePickerEnabled = true
end

function game.tick(deltaTime)
    t.update()
    animation.updateAnimations(deltaTime)
    assets.update(deltaTime)
    handleEnetClient()
end

function game.draw()
    -- draw background
    -- FIXME: Magic numbers
    local backgroundQuad = love.graphics.newQuad(0, 0, 2560, 1440, 2560, 1440)
    love.graphics.draw(assets.get("backgroundImage"), backgroundQuad, 0, 0, 0, 1, 1, 0, 0)

    -- draw scene
    -- TODO: Cache
    local playerAreaDims = array.wrap{720, 720}
    local playerAreaCanvas = love.graphics.newCanvas(unpack(playerAreaDims))

    playerAreaCanvas:renderTo(function()
        love.graphics.clear(1.0, 1.0, 1.0)
        love.graphics.withShader(assets.get("testShaderA"), function()
            assets.get("testShaderA"):sendColor("color1", {0.9, 0.7, 0.9, 1.0})
            assets.get("testShaderA"):sendColor("color2", {0.7, 0.9, 0.9, 1.0})
            assets.get("testShaderA"):send("rectSize", {64, 64})
            love.graphics.rectangle("fill", 0, 0, 720, 720)
        end)

        -- love.graphics.withShader(blurShader, function()
        --     blurShader:send("blurSize", 1 / (2560 / 16))
        --     blurShader:send("sigma", 5)
        --     local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
        --     assets.playerImage:draw(playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
        -- end)

        local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
        assets.playerImage:draw(playerSpriteQuad, 0, 0, 0, 1, 1, 0, 0)
    end)
    local playfieldScenePlacementQuad = love.graphics.newQuad(0, 0, unpack(playerAreaDims:rep(2)))
    resolutionScaledDraw(playerAreaCanvas, playfieldScenePlacementQuad, 100, 100)
    renderOldUI()
    renderNewUI()
end

function game.quit()
    print("Terminating the game")
    serverpeer:disconnect_now()
end

function love.keypressed(key)
    UIElemHandlers[activeUIElemIndex].keypressed(key)
end

function love.textinput(t)
    UIElemHandlers[activeUIElemIndex].textinput(t)
end

return game
