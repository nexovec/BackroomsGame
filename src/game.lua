local game = {}

-- requires
local animations = require("animations")
local enet = require("enet")
local t = require("timing")
local uiBox = require("uiBox")
local assert = require("std.assert")
local array = require("std.array")
local map = require("std.map")
local string = require("std.string")
local network = require("network")
local tileAtlas = require("tileAtlas")
local cbkHandle = require("std.cbkHandle")
local assets = require("assets")

-- variables
local options
local testTileSet

local enetclient
local serverpeer

local mockResolution = {2560, 1440}

local playerAreaCanvas
local playerAreaDims = array.wrap {720, 720}

local playerAnimation

local tempCanvas
local characterSpriteCanvas

local chatboxMessageHistory = array.wrap()
local clientChatboxMessage = ""
local chatboxDims = {640, 1280}
local chatboxUIBox

local loginBoxEnabled
local loginBoxUsernameText = ""
local loginBoxPasswordText = ""
local loginBoxErrorText = ""
local nicknamePickerBoxDims = {750, 300}
local nicknamePickerUIBox

local logMessageBoxDims = {1600, 400}
local logMessageBox

local activeUIElemIndex = 1
local activeLoginBoxField = "nickname"

local serverAddress = "192.168.0.234:6750"
local connectionFails = 0
local hasConnected = false

local delta = 0

-- helper functions

--- Corrects position for resolutionChanges
---@param pos table Of the form {width, height}
local function resolutionScaledPos(pos)
    return {(assets.get("settings").width / mockResolution[1]) * pos[1],
            (assets.get("settings").height / mockResolution[2]) * pos[2]}
end
local function resolutionScaledDraw(image, quad, x, y)
    local correctX, correctY = unpack(resolutionScaledPos {x, y})
    local viewX, viewY, width, height = quad:getViewport()
    local scaleX, scaleY = quad:getTextureDimensions()
    local cviewX, cviewY = unpack(resolutionScaledPos {viewX, viewY})
    local cwidth, cheight = unpack(resolutionScaledPos {width, height})
    local cscaleX, cscaleY = unpack(resolutionScaledPos {scaleX, scaleY})
    local correctQuad = love.graphics.newQuad(cviewX, cviewY, cwidth, cheight, cscaleX, cscaleY)
    love.graphics.draw(image, correctQuad, correctX, correctY)
end

-- TODO: Make function that ensures no additional globals are defined

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

local function attemptLogin(username, password)
    -- TODO: Encrypt password
    sendMessage("status", "logIn", username .. ":" .. password)
end

local function loginPrompt(msg)
    local msg = msg or ""
    activeUIElemIndex = 1
    activeNicknamePickerField = "nickname"
    loginBoxEnabled = true
    loginBoxErrorText = msg
end

local function disableLoginPrompt()
    loginBoxEnabled = false
    -- TODO: Enum for active elements
    activeUIElemIndex = 2
end

local function receivedMessageHandle(hostevent)
    local data = hostevent.data
    local prefix, trimmedMessage = network.getNetworkMessagePrefix(data)
    if prefix == "pingpong" then
        t.delayCall(function()
            sendMessage("pingpong", "ping!")
        end, 2)
    elseif prefix == "message" then
        chatboxMessageHistory:append(trimmedMessage)
    elseif prefix == "status" then
        local prefix, trimmedMessage = network.getNetworkMessagePrefix(trimmedMessage)
        if prefix == "logOut" then
            loginPrompt(trimmedMessage)
            -- server tells you to disconnect
            -- TODO:
        elseif prefix == "connected" then
            -- TODO:
        else
            error("Enet: message prefix " .. prefix .. " is unhandled!")
        end
    else
        -- TODO: Don't crash
        error(prefix .. ":" .. trimmedMessage)
    end
end

local function handleEnetClient()
    local hostevent = enetclient:service()
    -- FIXME: When pc sleeps
    --     AL lib: (EE) ALCwasapiPlayback_mixerProc: WaitForSingleObjectEx error: 0x102
    -- Error: src/game.lua:113: Error during service
    if serverpeer:state() == "disconnected" then
        connectionFails = connectionFails + 1
        if connectionFails < 6 and hasConnected then
            chatboxMessageHistory:append("Connection lost. Reconnecting...")
        elseif connectionFails < 2 and not hasConnected then
            -- TODO: Notify user you're waiting for a response from the server
            chatboxMessageHistory:append("Can't connect to the server.")
        end
        serverpeer:reset()
        serverpeer = enetclient:connect(serverAddress)
        serverpeer:timeout(0, 0, math.min(connectionFails, 6) * 5000)
    end
    if not enetclient then
        return
    end
    if not hostevent then
        return
    end
    -- if hostevent.peer == clientpeer then return end

    local type = hostevent.type
    if type == "connect" then
        sendMessage("pingpong", "ping!")
        connectionFails = 0
        hasConnected = true
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
    local logMessageBoxScenePlacementQuad = love.graphics.newQuad(0, 0, logMessageBoxDims[1], logMessageBoxDims[2],
        logMessageBoxDims[1], logMessageBoxDims[2])
    -- love.graphics.draw(logMessageBoxCanvas, logMessageBoxScenePlacementQuad, 100, 950, 0, 1, 1, 0, 0, 0, 0)
    resolutionScaledDraw(logMessageBoxCanvas, logMessageBoxScenePlacementQuad, 100, 950)

    -- render messages
    local chatboxCanvas = chatboxUIBox.textureCvs
    chatboxUIBox:clear()
    chatboxCanvas:renderTo(function()
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
    if loginBoxEnabled then
        local nicknamePickerCanvas = nicknamePickerUIBox.textureCvs
        nicknamePickerUIBox:clear()
        nicknamePickerCanvas:renderTo(function()
            -- love.graphics.setColor(0.65, 0.15, 0.15, 1)
            local descX, fieldX, row1y, row2y = 50, 250, 80, 150
            love.graphics.print("name:", descX, row1y)
            love.graphics.print(loginBoxUsernameText, fieldX, row1y)
            love.graphics.print("password:", descX, row2y)
            love.graphics.print(string.rep("*", #loginBoxPasswordText), fieldX, row2y)
        end)
        local chatboxScenePlacementQuad = love.graphics.newQuad(0, 0, nicknamePickerBoxDims[1],
            nicknamePickerBoxDims[2], nicknamePickerBoxDims[1], nicknamePickerBoxDims[2])
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
        local pos2 = {mockResolution[1], i * tileSize}
        -- TODO: Investigate: This should probably be corrected like this:
        -- local cPos1 = resolutionScaledPos(pos1)
        -- local cPos2 = resolutionScaledPos(pos2)
        local cPos1 = pos1
        local cPos2 = pos2
        love.graphics.line(cPos1[1], cPos1[2], cPos2[1], cPos2[2])
    end
    for i = 1, math.floor(mockResolution[1] / tileSize) do
        local pos1 = {i * tileSize, 0}
        local pos2 = {i * tileSize, mockResolution[2]}
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
    assert(not panelPos or #panelPos == 4, "Invalid panelPos argument", 2)
    -- assert(type(panelPos) == "nil" and panelPos[1] and panelPos[4], "Invlid panelPos", 2)
    local self = {
        assetName = assetName,
        tileSize = tileSize,
        scale = scale,
        panelPos = panelPos or {0, 4, 10, 10}
    }
    -- option is "flat" or "shadow"
    function self:draw(xPosInTiles, yPosInTiles, widthInTiles, heightInTiles, option)
        local scaledTileSize = self.tileSize * self.scale
        assert(xPosInTiles >= 0 and yPosInTiles >= 0 and widthInTiles > 0 and widthInTiles > 0)
        local atlas = tileAtlas.wrap(self.assetName, self.tileSize)
        local startingX, startingY, panelWInTiles, panelHInTiles = self.panelPos[1], self.panelPos[2], self.panelPos[3],
            self.panelPos[4]
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
                if not tileX then
                    tileX = startingX + 1
                    -- TODO: Thin the edge folds of paper ui
                    -- tileX = startingX + 1 + xI % (panelWInTiles - 2)
                end
                if not tileY then
                    tileY = startingY + 1
                    -- tileY = startingY + 1 + yI % (panelHInTiles - 2)
                end
                atlas:drawTile((xPosInTiles + xI) * self.tileSize * self.scale,
                    (yPosInTiles + yI) * self.tileSize * self.scale, tileX, tileY, self.scale * self.tileSize,
                    self.scale * self.tileSize)
            end
        end
    end

    return self
end

local UITileSize = 16
local UIScale = 5
local shouldHandleLoginClick = false
local loginBoxSize = {
    x = 4,
    y = 4,
    width = 8,
    height = 3
}

local loginBoxTextFieldsSizes = {
    username = {
        x = loginBoxSize.x * UITileSize * UIScale + 270,
        y = loginBoxSize.y * UITileSize * UIScale + 60,
        width = 300,
        margins = 2
    },
    password = {
        x = loginBoxSize.x * UITileSize * UIScale + 270,
        y = loginBoxSize.y * UITileSize * UIScale + 110,
        width = 300,
        margins = 2
    }
}

local function focusChat()
    if not loginBoxEnabled then
        return
    end
    activeLoginBoxField = "nickname"
end

function loginClicked()
    attemptLogin(loginBoxUsernameText, loginBoxPasswordText)
    activeLoginBoxField = "password"
    disableLoginPrompt()
    focusChat()
end

function pointIntersectsQuad(pX, pY, qX, qY, qW, qH)
    return pX >= qX and pX < qX + qW and pY >= qY and pY < qY + qH
end

local function handleLoginBoxFieldFocusOnMouseClick(xIn, yIn, mb, repeating)
    if not loginBoxEnabled then
        return
    end
    if pointIntersectsQuad(xIn, yIn, loginBoxTextFieldsSizes.username.x, loginBoxTextFieldsSizes.username.y,
        loginBoxTextFieldsSizes.username.width,
        assets.get("font"):getAscent() + loginBoxTextFieldsSizes.username.margins) then
        activeLoginBoxField = "nickname"
    elseif pointIntersectsQuad(xIn, yIn, loginBoxTextFieldsSizes.password.x, loginBoxTextFieldsSizes.password.y,
        loginBoxTextFieldsSizes.password.width,
        assets.get("font"):getAscent() + loginBoxTextFieldsSizes.password.margins) then
        activeLoginBoxField = "password"
    end
end

local function handleLoginClick(xIn, yIn, mb, repeating)
    if not shouldHandleLoginClick then
        return
    end
    if pointIntersectsQuad(xIn, yIn, UITileSize / 2 * UIScale * (loginBoxSize.x * 2 + 10 - 0.5),
        UITileSize / 2 * UIScale * (loginBoxSize.y * 2 + 4 - 0.1), 3 * UITileSize * UIScale, UITileSize * UIScale) then
        loginClicked()
        shouldHandleLoginClick = false
    end
end

local function tintedTextField(x, y, width, vertMargins)
    local ascent = assets.get("font"):getAscent()
    love.graphics.setColor(0, 0, 0, 0.1)
    love.graphics.rectangle("fill", x, y, width, ascent + 2 * vertMargins)
    love.graphics.setColor(0, 0, 0, 1)
end

-- TODO: Draw rectangle around image

function drawChatBox()
    local tileSize, scale = 16, 5
    local x, y, width, height = 16.5, 1, 7, 12
    local underscore
    if delta % 1 < 0.5 then
        underscore = "_"
    else
        underscore = ""
    end

    local font = assets.get("font")
    local ascent = font:getAscent()
    local scrollDistance = math.max(#chatboxMessageHistory * ascent - 1000, 0)
    tiledUIPanel("uiImage", tileSize, scale):draw(x, y, width, height)
    love.graphics.setColor(0, 0, 0, 1)
    -- TODO: Fade out top of the chat window
    -- TODO: Smooth chat scrolling
    -- TODO: Implement maximum chat message length
    local rowIndex = 0
    local maxRowWidth = 500
    local firstRowY = y * tileSize * scale + 30 - ascent
    for _, messageText in chatboxMessageHistory:iter() do
        local msgWidth, listOfRows = font:getWrap(messageText, maxRowWidth)
        -- local toSkip = math.ceil(msgWidth % maxRowWidth)
        for k, v in ipairs(listOfRows) do
            love.graphics.print(v, x * tileSize * scale + 30, firstRowY + ascent * rowIndex)
            rowIndex = rowIndex + 1
        end
        -- love.graphics.printf(messageText, x * tileSize * scale + 30, y * tileSize * scale + 30 - ascent + ascent * rowIndex, maxRowWidth)
        -- rowIndex = rowIndex + #listOfRows - 1
    end
    tintedTextField(x * tileSize * scale + 30, y * tileSize * scale + 880, 450, 2)
    local a = ""
    if activeUIElemIndex == 2 then
        a = underscore
    end
    love.graphics.print(clientChatboxMessage .. a, x * tileSize * scale + 30, y * tileSize * scale + 880)
    -- TODO: Render send button (choose an icon)
    love.graphics.setColor(1, 1, 1, 1)
end

function drawLoginBox()
    local tileSize, scale = UITileSize, UIScale
    local x, y, width, height = loginBoxSize.x, loginBoxSize.y, loginBoxSize.width, loginBoxSize.height
    local caret
    if delta % 1 < 0.5 then
        caret = "_"
    else
        caret = ""
    end
    -- TODO: Don't flicker the login box if credentials are rejected. (fade-out ?)
    -- render loginbox
    if not loginBoxEnabled then
        return
    end

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, unpack(resolutionScaledPos(mockResolution)))
    love.graphics.setColor(1, 1, 1)

    shouldHandleLoginClick = true

    tiledUIPanel("uiImage", tileSize, scale):draw(x, y, width, height)
    tiledUIPanel("uiImage", tileSize / 2, scale, {20, 20, 4, 4}):draw(x * 2 + 10 - 0.5, y * 2 + 4 - 0.1, 6, 2)
    love.graphics.setColor(0, 0, 0, 1)
    -- TODO: Disable after logging in.
    love.graphics.print("login", (x + 5.8) * tileSize * scale, (y + 2.1) * tileSize * scale)
    love.graphics.print("username:", x * tileSize * scale + 50, y * tileSize * scale + 60)
    usernameTextFieldSizes = loginBoxTextFieldsSizes.username
    tintedTextField(usernameTextFieldSizes.x, usernameTextFieldSizes.y, usernameTextFieldSizes.width,
        usernameTextFieldSizes.margins)
    local usernameCaret = ""
    if activeLoginBoxField == "nickname" then
        usernameCaret = caret
    end
    love.graphics.print(loginBoxUsernameText .. usernameCaret, x * tileSize * scale + 270, y * tileSize * scale + 60)
    love.graphics.print("password:", x * tileSize * scale + 50, y * tileSize * scale + 110)
    love.graphics.setColor(0, 0, 0, 0.1)

    local passwordTextFieldSizes = loginBoxTextFieldsSizes.password
    tintedTextField(passwordTextFieldSizes.x, passwordTextFieldSizes.y, passwordTextFieldSizes.width,
        passwordTextFieldSizes.margins)
    love.graphics.setColor(0, 0, 0, 1)
    local pwdCaret = ""
    if activeLoginBoxField == "password" then
        pwdCaret = caret
    end
    love.graphics.print(string.rep("*", #loginBoxPasswordText) .. pwdCaret, x * tileSize * scale + 270,
        y * tileSize * scale + 110)
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.setFont(assets.get("resources/fonts/JPfallback.ttf", 24))
    love.graphics.printf(loginBoxErrorText, x * tileSize * scale + 32, y * tileSize * scale + 170, 300, "left")
    love.graphics.setFont(assets.get("font"))
    love.graphics.setColor(1, 1, 1, 1)
end

local slotIconsAtlas = tileAtlas.wrap("resources/images/slotIcons.png", 32, 6)

function renderUIBtn()
    -- TODO:
end

function renderNewUI()
    local tileSize = UITileSize
    local scale = UIScale

    -- equipment view
    -- inventory tabs
    local x, y, width, height = 8, 0, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 4, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 2, 1,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    local x, y, width, height = 10, 0, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 4, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 7, 1,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    local x, y, width, height = 12, 0, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 4, 2, 2}):draw(x, y, width, height)
    -- TODO: Scale down
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 8, 1,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    -- panel
    local x, y, width, height = 7, 1.5 - 0.1, 9, 7
    tiledUIPanel("uiImage", tileSize, scale, {0, 14, 10, 10}):draw(x, y, width, height)

    -- character view
    local x, y, width, height = 0.5, 0.5, 8, 8
    tiledUIPanel("uiImage", tileSize, scale):draw(x, y, width, height)

    -- drawGrid(tileSize * scale, {1, 0, 1, 1})
    -- render logbox
    local x, y, width, height = 1, 9, 15, 4
    tiledUIPanel("uiImage", tileSize, scale):draw(x, y, width, height)
    drawChatBox()
end

---- handling input

function handleChatKp(key)
    -- chat handling
    if key == "return" then
        print(serverpeer:state())
        if serverpeer then
            sendMessage("message", clientChatboxMessage)
        end
        -- TODO: Handle sends from the server
        clientChatboxMessage = ""
    elseif key == "backspace" then
        clientChatboxMessage = string.popped(clientChatboxMessage)
    end
end

function handleLoginBoxKp(key)

    local function switchFields()
        if activeLoginBoxField == "nickname" then
            activeLoginBoxField = "password"
        elseif activeLoginBoxField == "password" then
            activeLoginBoxField = "nickname"
        end
    end
    -- TODO: Render blinking cursor in the active field
    if key == "return" then
        -- TODO: Verify nickname
        -- TODO: Lettercount limits
        loginClicked()

        if not serverpeer then
            chatboxMessageHistory:append("Server is nil.")
            return
        end

        if serverpeer:state() == "disconnected" then
            chatboxMessageHistory:append("Not connected to the server.")
        elseif serverpeer:state() == "connecting" then
            chatboxMessageHistory:append("Still connecting to the server.")
        else
            -- TODO:
        end
    elseif key == "tab" then
        switchFields()
    elseif key == "backspace" then
        if activeLoginBoxField == "nickname" then
            loginBoxUsernameText = string.popped(loginBoxUsernameText)
        else
            loginBoxPasswordText = string.popped(loginBoxPasswordText)
        end
    end
end

local UIElemHandlers = {{
    keypressed = handleLoginBoxKp,
    textinput = function(t)
        if activeLoginBoxField == "password" then
            loginBoxPasswordText = loginBoxPasswordText .. t
        else
            loginBoxUsernameText = loginBoxUsernameText .. t
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
    playerAnimation = animations.newCharacterAnimation("character")

    -- init logic:
    -- FIXME: Fix rendering when scaling
    playerAreaCanvas = love.graphics.newCanvas(unpack(playerAreaDims))
    tempCanvas = love.graphics.newCanvas(32, 32)
    characterSpriteCanvas = love.graphics.newCanvas(32, 32)
    playerAnimation:play(2, "idle", true)

    chatboxUIBox = uiBox.makeBox(chatboxDims[1], chatboxDims[2], "gradientShaderA", {}, 20)
    nicknamePickerUIBox = uiBox.makeBox(nicknamePickerBoxDims[1], nicknamePickerBoxDims[2], "gradientShaderA", {}, 20)
    logMessageBox = uiBox.makeBox(logMessageBoxDims[1], logMessageBoxDims[2], "gradientShaderA", {}, 20)

    love.keyboard.setKeyRepeat(true)

    beginClient()
    loginPrompt()
end

function game.tick(deltaTime)
    t.update()
    animations.updateAnimations(deltaTime)
    assets.update(deltaTime)
    delta = delta + deltaTime
    handleEnetClient()
end

function game.draw()
    -- draw background
    -- FIXME: Magic numbers
    local backgroundQuad = love.graphics.newQuad(0, 0, 2560, 1440, 2560, 1440)
    love.graphics.draw(assets.get("backgroundImage"), backgroundQuad, 0, 0, 0, 1, 1, 0, 0)

    -- renderOldUI()
    renderNewUI()
    -- draw scene
    local tileSize = 16
    local scale = 5

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

        local playerAreaQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
        love.graphics.draw(assets.get("resources/images/background2.png"), playerAreaQuad)
        playerAnimation:draw(0, 0, 720, 720)
    end)
    local playfieldScenePlacementQuad = love.graphics.newQuad(0, 0, unpack(playerAreaDims:rep(2)))
    -- FIXME: Magic numbers
    local pos = scale * tileSize * (0.5 - (8 - 720 / (tileSize * scale)))
    resolutionScaledDraw(playerAreaCanvas, playfieldScenePlacementQuad, pos, pos)

    -- render character silhouette
    -- FIXME: Fix rendering when scaling
    -- TODO: Use stencil (like src/uiBox.lua:15)
    characterSpriteCanvas:renderTo(function()
        love.graphics.clear()
        characterSpriteCanvas:setFilter("linear", "linear", 4)
        local asset = assets.get("resources/images/character.png")
        local width, height = asset:getDimensions()
        local characterSheetQuad = love.graphics.newQuad(0, 0, 32, 32, width, height)
        love.graphics.draw(asset, characterSheetQuad, 0, 0)
    end)

    tempCanvas:setFilter("linear", "linear", 4)
    local maskShader = assets.get("resources/shaders/masks/maskFromTexture.glsl")
    tempCanvas:renderTo(function()
        love.graphics.withShader(maskShader, function()
            love.graphics.clear()
            maskShader:send("Tex", characterSpriteCanvas)
            love.graphics.draw(characterSpriteCanvas, love.graphics.newQuad(0, 0, 24, 32, 24, 32), 0, 0)
        end)
    end)

    local quad = love.graphics.newQuad(0, 0, 800, 800, 800, 800)
    resolutionScaledDraw(tempCanvas, quad, 1040, 80)

    -- draw equipment slots.
    local tileSize = 16
    local scale = 5

    -- equipment view
    local x, y, width, height = 9 - 0.2, 4, 2, 2
    -- love.graphics.draw(itemBoxCanvas, love.graphics.newQuad(0, 0, width, height, width, height), x * tileSize * scale, y * tileSize * scale)
    tiledUIPanel("uiImage", tileSize, scale, {10, 6, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 3, 1,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    local x, y, width, height = 9 - 0.2, 6, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 6, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 3, 1,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    local x, y, width, height = 13, 2, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 6, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 1, 0,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    local x, y, width, height = 13.5, 4, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 6, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 0, 0,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    local x, y, width, height = 13, 6, 2, 2
    tiledUIPanel("uiImage", tileSize, scale, {10, 6, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile((x + 0.1) * tileSize * scale, (y + 0.15) * tileSize * scale, 7, 0,
        (width - 0.5) * tileSize * scale, (height - 0.5) * tileSize * scale)

    -- local x, y, width, height = 11.8, 6, 2, 2
    -- tiledUIPanel("uiImage", tileSize, scale, {10, 4, 2, 2}):draw(x, y, width, height)
    -- TODO: Render setting button (choose an icon)
    drawLoginBox()
end

function game.quit()
    print("Terminating the game")
    serverpeer:disconnect_now()
end

function love.mousepressed(x, y, width, height)
    handleLoginClick(x, y, width, height)
    handleLoginBoxFieldFocusOnMouseClick(x, y, width, height)
end

function love.keypressed(key)
    UIElemHandlers[activeUIElemIndex].keypressed(key)
    if love.keyboard.isDown("f5") then
        love.event.quit("restart")
    end
end

function love.textinput(t)
    UIElemHandlers[activeUIElemIndex].textinput(t)
end

return game
