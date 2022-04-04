local game = {}
-- FIXME: Add the fire lading circles image (downscaled, so the repo size doesn't go through the roof)

-- requires
local assert = require("std.assert")
local array = require("std.array")
local map = require("std.map")
local json = require("std.json")
local string = require("std.string")
local ref = require("std.ref")
local t = require("timing")
local animations = require("animations")
local tileAtlas = require("tileAtlas")
local assets = require("assets")
local drawing = require("drawing")
local tiledUIPanel = require("tiledUIPanel")
local macro = require("macro")
local client = require("client")
local messaging = require("messaging")
local dims = require("dims")
local sizes = nil

-- variables
-- local scaled = drawing.resolutionScaledPos -- function alias

local playerAnimation = nil
local sceneviewCanvas = nil

local testMugItemInfo = {
    tileX = 2,
    tileY = 14,
    visible = true
}

local tempCanvas = nil
local characterSpriteCanvas = nil
local tintDrawn = false

local UIElemHandlers = nil

local loginboxEnabled = false
local settingsEnabled = false

local shouldHandleSettingsBtnClick = true
local shouldHandleChatboxSendBtnClick = true

local activeUIElemStack = array.wrap()

local chatboxMessageHistory = messaging.chatboxMessageHistory
local localPlayerChatMessageHistory = array.wrap()
local sceneType = "playerCloseUpView"
local chatboxHistoryPointerRef = ref.wrap()
local clientChatBoxMessageRef = ref.wrap("")

local devConsoleMessageRef = ref.wrap("")
local devConsoleEnabled = false
local playedMacro = nil
local devConsoleMessageHistory = messaging.devConsoleMessageHistory
local devConsoleHistoryPointer = ref.wrap()

local currentMacroName = nil
local recordedMacroesCount = 1

local loginboxUsernameText = ""
local loginboxPasswordText = ""
local loginboxErrorText = ""
local slotIconsAtlas = tileAtlas.wrap("resources/images/slotIcons.png", 32, 6)
local itemsAtlas = tileAtlas.wrap("resources/images/items.png", 16, 0)

-- local itemsInScene = array.wrap()
local draggedItem = nil
local equipmentSlotsEquipment = {
    mainHand = nil,
    offHand = nil,
    headGear = nil,
    bodyArmor = nil,
    shoeGear = nil
}

local activeLoginBoxField = "nickname"

local shouldHandleLoginClick = false

function client.onLogOut(trimmedMessage)
    if not loginboxEnabled then
        client.loginPromptToggle(trimmedMessage)
    end
end

local delta = 0

local function loginPromptToggle(msg)
    msg = msg or ""
    loginboxEnabled = not loginboxEnabled
    if not loginboxEnabled then
        loginboxEnabled = false
        activeUIElemStack:pop()
        return
    end
    activeUIElemStack:append("loginbox")
    -- TODO: Enum for active elements
    -- activeNicknamePickerField = "nickname"
    loginboxErrorText = msg
end

local function devConsoleTogglePrompt()
    devConsoleEnabled = not devConsoleEnabled
    if devConsoleEnabled then
        activeUIElemStack:append("devConsole")
    else
        activeUIElemStack:pop()
    end
end

local function executeDevConsoleCommand(cmd)
    local macroDevCommandArgs = string.split(cmd, " ") -- :std.array
    local command = macroDevCommandArgs:dequeue()
    if command == "macro" then
        local macrosDir = "macros"
        local subCommand = macroDevCommandArgs:dequeue()
        if subCommand == "record" then
            if not macro.startRecordingPlayerInputs() then
                devConsoleMessageHistory:append(
                    "You are already recording a macro, use macro stop|pause to stop/pause/unpause this macro.")
            end
            currentMacroName = macroDevCommandArgs:dequeue()
            devConsoleMessageHistory:append("You are recording a macro...")
        elseif subCommand == "pause" then
            if not macro.pauseRecordingPlayerInputs() then
                devConsoleMessageHistory:append("Can't pause, no macro is being recorded")
            end
        elseif subCommand == "stop" then
            local arg1 = macroDevCommandArgs:dequeue()
            local currentMacro, success = macro.stopRecordingPlayerInputs()
            if not success then
                devConsoleMessageHistory:append("Can't use this command, because no macro is being recorded.")
                return
            end
            if not currentMacroName then
                currentMacroName = arg1 or ("macro" .. tostring(recordedMacroesCount))
            end
            local path = macrosDir .. "/" .. currentMacroName
            if not love.filesystem.createDirectory(macrosDir) then
                error("Can't create the macro folder")
            end
            if not path then
                -- TODO: Don't overwrite macro1.json if it is already stored
                path = macrosDir .. "/" .. currentMacroName
            end
            local macroJsonToWrite = json.encode(currentMacro)
            local s, m = love.filesystem.write(path .. ".json", macroJsonToWrite, #macroJsonToWrite)
            if not s then
                devConsoleMessageHistory:append("Couldn't save macro: " .. m)
                return
            end
            recordedMacroesCount = recordedMacroesCount + 1
            devConsoleMessageHistory:append("Macro " .. currentMacroName .. " stored in " .. path .. ".json")
            currentMacroName = nil
        elseif subCommand == "cancel" then
            devConsoleMessageHistory:append("Not yet implemented.")
        elseif subCommand == "list" then
            -- TODO: Use settings.pathToMacros
            if not love.filesystem.createDirectory(macrosDir) then
                error("Can't create the macro folder")
            end
            assert(love.filesystem.getInfo(macrosDir).type == "directory")
            local macros = map.wrap(love.filesystem.getDirectoryItems(macrosDir))
            if macros:length() == 0 then
                devConsoleMessageHistory:append("There are no recorded macros.")
                return
            end
            local macroNames = array.wrap()
            for _, v in pairs(macros) do
                local path = "macros/" .. v
                if not love.filesystem.getInfo(path, "file") then
                    return devConsoleMessageHistory:append("Macro " .. path .. " is not a file")
                end
                if not string.extension(v) == ".json" then
                    return devConsoleMessageHistory:append("Macro " .. path .. " is not a json file")
                end
                local macroNameSplit = string.split(v, ".")
                local macroNameWithNoExt = string.join(macroNameSplit:sub(1, #macroNameSplit - 1), ".")
                macroNames:append(macroNameWithNoExt)
            end
            devConsoleMessageHistory:append(string.join(macroNames, ", "))
        elseif subCommand == "open" then
            love.system.openURL(love.filesystem.getSaveDirectory() .. "/" .. macrosDir)
            return devConsoleMessageHistory:append("Opening the macros folder")
        elseif subCommand == "play" then
            local macroName = macroDevCommandArgs:dequeue()
            if not macroName then
                return devConsoleMessageHistory:append("Usage: macro play <name of macro>")
            end
            -- local macros = map.wrap(love.filesystem.getDirectoryItems(workingDir))
            local fileContents, success = love.filesystem.read(macrosDir .. "/" .. macroName .. ".json")
            if not fileContents then
                return devConsoleMessageHistory:append("Couldn't read macro file: " .. tostring(success))
            end
            playedMacro = map.wrap(json.decode(fileContents))
            macro.startPlayingMacro(playedMacro)
            -- TODO: Play them
            -- TODO: Play them faster
            -- TODO: CLI option --test that runs predetermined macroes
            return devConsoleMessageHistory:append("Playing a macro with " .. tostring(#playedMacro) .. " events")
        else
            devConsoleMessageHistory:append("Usage: macro record|stop|play|pause|list|open")
        end
    else
        devConsoleMessageHistory:append("Unknown command:\t" .. command)
    end
end

local function handleMessageHistoryRewindKp(key, refToHistoryPointer, history, messageRef)
    if key == "up" then
        if #history == 0 then
            return false
        end
        if not refToHistoryPointer.val then
            refToHistoryPointer.val = #history
        else
            refToHistoryPointer.val = math.max(refToHistoryPointer.val - 1, 1)
        end
        messageRef.val = history[refToHistoryPointer.val]
        -- devConsoleMessage = history[refToHistoryPointer.val]
    elseif key == "down" then
        if not refToHistoryPointer.val then
            return false
        end
        refToHistoryPointer.val = refToHistoryPointer.val + 1
        if refToHistoryPointer.val > #history then
            refToHistoryPointer.val = nil
            -- TODO: Retain history
            messageRef.val = ""
        else
            messageRef.val = history[refToHistoryPointer.val]
        end
        return true
    end
    return false
end

local function focusChat()
    if not loginboxEnabled then
        activeLoginBoxField = "nickname"
    end
    activeUIElemStack:append("chatbox")
end

local function onLoginClicked()
    client.attemptLogin(loginboxUsernameText, loginboxPasswordText)
    loginPromptToggle()
    focusChat()
    shouldHandleLoginClick = false
end

local function pointIntersectsQuad(pX, pY, qX, qY, qW, qH)
    if type(qX) == "table" then
        assert(qX.type == "dims")
        return pointIntersectsQuad(pX, pY, qX:unpack())
    end
    return pX >= qX and pX < qX + qW and pY >= qY and pY < qY + qH
end

-- luacheck:no unused args
local function handleLoginBoxFieldFocusOnMouseClick(xIn, yIn, mb, isTouch, repeating)
    if not loginboxEnabled then
        return
    end
    if pointIntersectsQuad(xIn, yIn, sizes.loginboxTextFieldsSizes.username.x, sizes.loginboxTextFieldsSizes.username.y,
        sizes.loginboxTextFieldsSizes.username.width,
        assets.get("font"):getAscent() + sizes.loginboxTextFieldsSizes.username.margins) then
        activeLoginBoxField = "nickname"
    elseif pointIntersectsQuad(xIn, yIn, sizes.loginboxTextFieldsSizes.password.x,
        sizes.loginboxTextFieldsSizes.password.y, sizes.loginboxTextFieldsSizes.password.width,
        assets.get("font"):getAscent() + sizes.loginboxTextFieldsSizes.password.margins) then
        activeLoginBoxField = "password"
    end
end
-- luacheck:unused args

local function handleChatKp(key)
    -- chat handling
    if key == "return" then
        if client.isConnected() == true then
            local maxChatMessageLength = assets.get("settings").maximumChatMessageLength
            if #clientChatBoxMessageRef.val == 0 or #clientChatBoxMessageRef.val > maxChatMessageLength then
                return
            end
            client.sendMessage("message", clientChatBoxMessageRef.val)
            localPlayerChatMessageHistory:append(clientChatBoxMessageRef.val)
            chatboxHistoryPointerRef.val = nil -- refreshes scrolling in the chat history.
        end
        -- TODO: Handle sends from the server
        clientChatBoxMessageRef.val = ""
    elseif key == "backspace" then
        clientChatBoxMessageRef.val = string.popped(clientChatBoxMessageRef.val)
    else
        handleMessageHistoryRewindKp(key, chatboxHistoryPointerRef, localPlayerChatMessageHistory,
            clientChatBoxMessageRef)
    end
end

---@return boolean returns whether the settings are active.
local function toggleSettings()
    if settingsEnabled then
        settingsEnabled = false
        if loginboxEnabled then
            shouldHandleLoginClick = true
        end
        activeUIElemStack:pop()
        return false
    end
    settingsEnabled = true
    if loginboxEnabled then
        shouldHandleLoginClick = false
    end
    activeUIElemStack:append("settings")
    return true
end

local function isPosOutOfSettingsPanel(x, y)
    local multiplier = sizes.UITileSize * sizes.UIScale
    return not pointIntersectsQuad(x, y, sizes.settingsBoxDimensionsInTiles.x * multiplier,
        sizes.settingsBoxDimensionsInTiles.y * multiplier, sizes.settingsBoxDimensionsInTiles.width * multiplier,
        sizes.settingsBoxDimensionsInTiles.height * multiplier)
end
-- optionally can take no parameters to omit checks
-- luacheck:no unused args
local function handleSettingsClose(x, y, mb)
    if not settingsEnabled then
        return
    end
    local multiplier = sizes.UITileSize * sizes.UIScale
    if not not x and pointIntersectsQuad(x, y, sizes.settingsBoxDimensionsInTiles.x * multiplier,
        sizes.settingsBoxDimensionsInTiles.y * multiplier, sizes.settingsBoxDimensionsInTiles.width * multiplier,
        sizes.settingsBoxDimensionsInTiles.height * multiplier) then
        return
    else
        print("I am running")
        toggleSettings()
    end
end
-- luacheck: unused args

local function tintedTextField(x, y, width, vertMargins, color)
    local ascent = assets.get("font"):getAscent()
    local oldColor = {love.graphics.getColor()}
    color = color or {0, 0, 0, 0.1}
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, width, ascent + 2 * vertMargins)
    love.graphics.setColor(unpack(oldColor))
end

local function drawOutline(obj, color, ...)
    if type(obj) == "number" then
        local vargs = {...}
        if #vargs <= 1 then
            -- this is a point
            return drawOutline({obj, color}, vargs[1])
        elseif #vargs <= 3 then
            -- this is a rectangle
            return drawOutline({
                x = obj,
                y = color,
                width = vargs[1],
                height = vargs[2]
            }, vargs[3])
        end
    end
    local oldColor = {love.graphics.getColor()}
    color = color or {1, 0, 0, 1}
    love.graphics.setColor(unpack(color))
    if not not obj[1] and not not obj[2] then
        -- TODO: obj is a point. Draw circle!
        -- xts + 480, yts + 870, 64, 64
        error("Not yet implemented.")
    elseif not not obj.x and not not obj.y and not not obj.width and obj.height then
        -- TODO: obj is a rectangle (a dimensions object)
        love.graphics.rectangle("line", dims.wrap(obj):unpack())
    else
        local typeText = obj.type or type(obj)
        error("You can't draw an outline of " .. tostring(typeText), 2)
    end
    love.graphics.setColor(unpack(oldColor))
end

local function drawMessageList(messages, boundingBox, startFromBottom)
    local font = assets.get("font")
    local ascent = font:getAscent()
    local rowIndex = 0
    local maxRowWidth = boundingBox.width
    if startFromBottom then
        local firstRowYOffset = boundingBox.y + boundingBox.height - 30 * sizes.resolutionConversionRatio - ascent
        for _, messageText in array.wrap(messages):reverse():iter() do
            local _, listOfRows = font:getWrap(messageText, maxRowWidth)
            for _, v in ipairs(listOfRows) do
                love.graphics.print(v, boundingBox.x + 30 * sizes.resolutionConversionRatio,
                    firstRowYOffset * sizes.resolutionConversionRatio - ascent * rowIndex)
                rowIndex = rowIndex + 1
            end
        end
    else
        local firstRowYOffset = boundingBox.y + 30 * sizes.resolutionConversionRatio - ascent
        -- local scrollDistance = math.max(#chatboxMessageHistory * ascent - 1000, 0)
        for _, messageText in ipairs(messages) do
            local _, listOfRows = font:getWrap(messageText, maxRowWidth)
            for _, v in array.wrap(listOfRows):iter() do
                love.graphics.print(v, boundingBox.x + 30 * sizes.resolutionConversionRatio,
                    firstRowYOffset + ascent * rowIndex)
                rowIndex = rowIndex + 1
            end
        end
    end
end

local function drawTextInputField(x, y, hasCaret, text, width, margins, color)
    tintedTextField(x, y, width, margins, color)
    text = text or ""
    local underscore
    if delta % 1 < 0.5 then
        underscore = "_"
    else
        underscore = ""
    end
    if hasCaret then
        text = text .. underscore
    end
    love.graphics.print(text, x, y)
end

local function tintScreen()
    if tintDrawn == false then
        local oldColor = {love.graphics.getColor()}
        love.graphics.setColor(0, 0, 0, 0.8)
        local realResolution = assets.get("settings").realResolution
        love.graphics.rectangle("fill", 0, 0, unpack(realResolution))
        love.graphics.setColor(unpack(oldColor))
        tintDrawn = true
    end
end

local function renderUITab(x, y, width, height, horizontalIconTileIndex, verticalIconTileIndex)
    assert(tiledUIPanel.wrap("uiImage", sizes.UITileSize, sizes.UIScale, {10, 4, 2, 2}).draw)
    tiledUIPanel.wrap("uiImage", sizes.UITileSize, sizes.UIScale, {10, 4, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile(horizontalIconTileIndex, verticalIconTileIndex,
        (x + 0.1) * sizes.UITileSize * sizes.UIScale, (y + 0.15) * sizes.UITileSize * sizes.UIScale,
        (width - 0.5) * sizes.UITileSize * sizes.UIScale, (height - 0.5) * sizes.UITileSize * sizes.UIScale)
end

local function renderUIPanel(x, y, width, height, shape)
    tiledUIPanel.wrap("uiImage", sizes.UITileSize, sizes.UIScale, shape):draw(x, y, width, height)
end

local function drawAtEquipmentSlot(iconX, iconY, itemX, itemY, itemAtlas, x, y, width, height)
    if type(x) == "table" then
        assert(not y)
        return drawAtEquipmentSlot(iconX, iconY, itemX, itemY, tileAtlas, x:unpack())
    end
    tiledUIPanel.wrap("uiImage", sizes.UITileSize, sizes.UIScale, {10, 6, 2, 2}):draw(x, y, width, height)
    slotIconsAtlas:drawTile(iconX, iconY, (x + 0.1) * sizes.UITileSize * sizes.UIScale,
        (y + 0.15) * sizes.UITileSize * sizes.UIScale, (width - 0.5) * sizes.UITileSize * sizes.UIScale,
        (height - 0.5) * sizes.UITileSize * sizes.UIScale)
    if not not itemX and not not itemY then
        itemAtlas:drawTile(itemX, itemY, (x + 0.1) * sizes.UITileSize * sizes.UIScale,
            (y + 0.15) * sizes.UITileSize * sizes.UIScale, (width - 0.5) * sizes.UITileSize * sizes.UIScale,
            (height - 0.5) * sizes.UITileSize * sizes.UIScale)
    elseif not not itemX and not itemY then
        error("Drawing items by id not yet implemented.")
    end
end

---- handling input

local function handleChatTextInput(key)
    local maxChatMessageLength = assets.get("settings").maximumChatMessageLength
    if #clientChatBoxMessageRef.val > maxChatMessageLength then
        return
    end
    clientChatBoxMessageRef.val = clientChatBoxMessageRef.val .. key
end

local function handleLoginBoxKp(key)

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
        onLoginClicked()

        -- TODO: Probably not needed:
        if not client.serverpeer then
            chatboxMessageHistory:append("Server is nil.")
            return
        end

        if client.serverpeer:state() == "disconnected" then
            chatboxMessageHistory:append("Not connected to the server.")
        elseif client.serverpeer:state() == "connecting" then
            chatboxMessageHistory:append("Still connecting to the server.")
            -- TODO: else:
        end
    elseif key == "tab" then
        switchFields()
    elseif key == "backspace" then
        if activeLoginBoxField == "nickname" then
            loginboxUsernameText = string.popped(loginboxUsernameText)
        else
            loginboxPasswordText = string.popped(loginboxPasswordText)
        end
    end
end

local function handleLoginBoxTextInput(key)
    if activeLoginBoxField == "password" then
        loginboxPasswordText = loginboxPasswordText .. key
    else
        loginboxUsernameText = loginboxUsernameText .. key
    end
end

local function handleDevConsoleKp(key)
    if not devConsoleEnabled then
        return
    end
    if key == "return" then
        if #devConsoleMessageRef.val ~= 0 then
            devConsoleMessageHistory:append(devConsoleMessageRef.val)
            devConsoleHistoryPointer.val = nil
            executeDevConsoleCommand(devConsoleMessageRef.val)
        end
        devConsoleMessageRef.val = ""
    elseif key == "backspace" then
        devConsoleMessageRef.val = string.popped(devConsoleMessageRef.val)
    else
        handleMessageHistoryRewindKp(key, devConsoleHistoryPointer, devConsoleMessageHistory, devConsoleMessageRef)
    end
end

local function handleDevConsoleTextInput(key)
    if not devConsoleEnabled then
        return
    end
    assert(devConsoleMessageRef, devConsoleHistoryPointer.val, 2)
    devConsoleMessageRef.val = devConsoleMessageRef.val .. key
end

function game.initRendering()
    love.graphics.setFont(assets.get("font"))
    playerAnimation = animations.loadAnimation("character")
    sceneviewCanvas = love.graphics.newCanvas(sizes.sceneviewDims.width, sizes.sceneviewDims.height)
    tempCanvas = love.graphics.newCanvas(32, 32)
    characterSpriteCanvas = love.graphics.newCanvas(32, 32)
    playerAnimation:play(2, "idle", true)
    characterSpriteCanvas:renderTo(function()
        -- TODO: Resample fireCircles.png:
        -- playerAnimation = animations.loadAnimation("fireCircles")

        -- init logic:
        -- FIXME: Fix rendering when scaling
        love.graphics.clear()
        characterSpriteCanvas:setFilter("linear", "linear", 4)
        local asset = assets.get("resources/images/character.png")
        local width, height = asset:getDimensions()
        local characterSheetQuad = love.graphics.newQuad(0, 0, 32, 32, width, height)
        love.graphics.draw(asset, characterSheetQuad, 0, 0)
    end)

    tempCanvas:setFilter("linear", "linear", 4)
    local maskShader = assets.get("resources/shaders/masks/maskFromTexture.glsl")
    local function useMaskShaderToDrawCharacter()
        love.graphics.withShader(maskShader, function()
            love.graphics.clear()
            maskShader:send("Tex", characterSpriteCanvas)
            love.graphics.draw(characterSpriteCanvas, love.graphics.newQuad(0, 0, 24, 32, 24, 32), 0, 0)
        end)
    end
    tempCanvas:renderTo(useMaskShaderToDrawCharacter)
    -- playerAnimation:play(2, "circle", true)
end

--- API

function game.load(args)
    assert(type(args) == "table")
    love.window.setMode(assets.get("settings").realResolution[1], assets.get("settings").realResolution[2])
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    love.keyboard.setKeyRepeat(true)
    UIElemHandlers = {
        loginbox = {
            keypressed = handleLoginBoxKp,
            textinput = handleLoginBoxTextInput
        },
        chatbox = {
            keypressed = handleChatKp,
            textinput = handleChatTextInput
        },
        devConsole = {
            keypressed = handleDevConsoleKp,
            textinput = handleDevConsoleTextInput
        },
        settings = {
            keypressed = function()
            end,
            textinput = function()
            end
        }
    }
    sizes = require("sizes_of_things")
    activeUIElemStack:append("chatboxMessageHistory")
    loginPromptToggle()
    love.keyboard.setKeyRepeat(true)
    -- itemsInScene:append(testMugItem)
    game.initRendering()

    client.beginClient(assets.get("settings").serverAddress)
end

function game.tick(deltaTime)
    t.update()
    animations.updateAnimations(deltaTime)
    assets.update(deltaTime)
    if loginboxEnabled then
        shouldHandleLoginClick = true
    end
    delta = delta + deltaTime
    client.handleEnetClient()
end

function game.draw()
    -- draw background
    tintDrawn = false
    local mockResolution = assets.get("settings").mockResolution
    local backgroundQuad = love.graphics.newQuad(0, 0, mockResolution[1], mockResolution[2], mockResolution[1],
        mockResolution[2])
    love.graphics.draw(assets.get("backgroundImage"), backgroundQuad, 0, 0, 0, 1, 1, 0, 0)

    -- renderOldUI()

    -- equipment view
    -- inventory tabs
    renderUITab(8, 0, 2, 2, 2, 1)
    renderUITab(10, 0, 2, 2, 7, 1)
    renderUITab(12, 0, 2, 2, 8, 1)

    -- panel
    renderUIPanel(7, 1.5 - 0.1, 9, 7, {0, 14, 10, 10})

    -- character view
    renderUIPanel(0.5, 0.5, 8, 8)
    -- drawGrid(tileSize * scale, {1, 0, 1, 1})

    -- render logbox
    renderUIPanel(1, 9, 15, 4)
    -- renderUIPanel(chatboxDims.x, chatboxDims.y, chatboxDims.width, chatboxDims.height)
    renderUIPanel(sizes.chatboxDims:unpack())
    love.graphics.setColor(0, 0, 0, 1)
    -- TODO: Fade out top of the chat window
    -- TODO: Smooth chat scrolling
    -- TODO: Implement maximum chat message length

    -- render chatbox
    drawMessageList(chatboxMessageHistory, sizes.chatMessagesBoundingBox)
    local chatboxTextFieldPos = {
        x = sizes.chatMessagesBoundingBox.x + 30 * sizes.resolutionConversionRatio,
        y = sizes.chatMessagesBoundingBox.y + 880 * sizes.resolutionConversionRatio
    }
    local hasCaret = false
    if activeUIElemStack:last() == "chatbox" then
        hasCaret = true
    end
    drawTextInputField(chatboxTextFieldPos.x, chatboxTextFieldPos.y, hasCaret, clientChatBoxMessageRef.val,
        450 * sizes.resolutionConversionRatio, 2)

    -- render send button
    love.graphics.draw(assets.get("resources/images/ui/smallIcons.png"), 1220 * sizes.resolutionConversionRatio,
        100 * sizes.resolutionConversionRatio, 0, 3, 3) -- icons preview
    tileAtlas.wrap("resources/images/ui/smallIcons.png", (sizes.UITileSize * (3 / 4)) * sizes.resolutionConversionRatio,
        2):drawTile(0, 8, sizes.chatboxSendBtnDims.x, sizes.chatboxSendBtnDims.y, sizes.chatboxSendBtnDims.width,
        sizes.chatboxSendBtnDims.height)
    drawOutline(sizes.chatMessagesBoundingBox.x + 480 * sizes.resolutionConversionRatio,
        sizes.chatMessagesBoundingBox.y + 870 * sizes.resolutionConversionRatio,
        (sizes.UITileSize * 4) * sizes.resolutionConversionRatio,
        (sizes.UITileSize * 4) * sizes.resolutionConversionRatio)
    tileAtlas.wrap("resources/images/ui/smallIcons.png", 12, 2):drawTile(2, 4, 1830 * sizes.resolutionConversionRatio,
        0, (sizes.UITileSize * 4) * sizes.resolutionConversionRatio, (sizes.UITileSize * 4) *
            sizes.resolutionConversionRatio)
    drawOutline(sizes.settingsBtnDimensions)
    love.graphics.setColor(1, 1, 1, 1)

    -- draw scene
    love.graphics.setCanvas(sceneviewCanvas)
    -- playerAreaCanvas:renderTo(function()
    love.graphics.clear(1.0, 1.0, 1.0)
    love.graphics.withShader(assets.get("testShaderA"), function()
        assets.get("testShaderA"):sendColor("color1", {0.9, 0.7, 0.9, 1.0})
        assets.get("testShaderA"):sendColor("color2", {0.7, 0.9, 0.9, 1.0})
        assets.get("testShaderA"):send("rectSize", {64, 64})
        love.graphics.rectangle("fill", 0, 0, 720, 720)
    end)

    local side = 720 * sizes.resolutionConversionRatio
    local playerAreaQuad = love.graphics.newQuad(0, 0, side, side, side, side)
    love.graphics.draw(assets.get("resources/images/background2.png"), playerAreaQuad)

    -- TODO: Make the item bob in the scene
    if sceneType == "playerCloseUpView" then
        -- for _, itemInScene in itemsInScene:iter() do
        --     if itemInScene.visible then
        --         itemsAtlas:drawTile(itemInScene)
        --         drawOutline(itemInScene)
        --     end
        -- end
        itemsAtlas:drawTile(testMugItemInfo.tileX, testMugItemInfo.tileY, sizes.testMugItemDims)
        -- local blurShader = assets.get("resources/shaders/blur.glsl")
        -- love.graphics.withShader(blurShader, function()
        --     blurShader:send("blurSize", 1 / (2560 / 16))
        --     blurShader:send("sigma", 5)
        --     local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)
        --     playerAnimation:draw(0, 0, 720, 720)
        -- end)
        playerAnimation:draw(0, 0, 720, 720)
    elseif sceneType == "battleMode" then
        error("Not yet implemented.")
    else
        error("Scene type " .. tostring(sceneType) .. " is not allowed")
    end
    -- end)
    love.graphics.setCanvas()
    local playfieldScenePlacementQuad = love.graphics.newQuad(0, 0, sizes.sceneviewDims.width,
        sizes.sceneviewDims.height, sizes.sceneviewDims.width, sizes.sceneviewDims.height)
    drawing.resolutionScaledDraw(sceneviewCanvas, playfieldScenePlacementQuad, sizes.sceneviewDims.x,
        sizes.sceneviewDims.y)

    -- render character silhouette

    local quad = love.graphics.newQuad(0, 0, 800, 800, 800, 800)
    drawing.resolutionScaledDraw(tempCanvas, quad, 1040, 80)

    -- equipment view
    local mainHandEquipment = equipmentSlotsEquipment["mainHand"]
    drawAtEquipmentSlot(3, 1, mainHandEquipment and mainHandEquipment.tileX,
        mainHandEquipment and mainHandEquipment.tileY, itemsAtlas, 9 - 0.2, 4, 2, 2)

    local offHandEquipment = equipmentSlotsEquipment["offHand"]
    drawAtEquipmentSlot(3, 1, offHandEquipment and offHandEquipment.x, offHandEquipment and offHandEquipment.y,
        itemsAtlas, 9 - 0.2, 6, 2, 2)

    local headGearEquipment = equipmentSlotsEquipment["headGear"]
    drawAtEquipmentSlot(1, 0, headGearEquipment and headGearEquipment.x, headGearEquipment and headGearEquipment.y,
        itemsAtlas, 13, 2, 2, 2)

    local bodyArmorEquipment = equipmentSlotsEquipment["bodyArmor"]
    drawAtEquipmentSlot(0, 0, bodyArmorEquipment and bodyArmorEquipment.x, bodyArmorEquipment and bodyArmorEquipment.y,
        itemsAtlas, 13.5, 4, 2, 2)

    local shoeGearEquipment = equipmentSlotsEquipment["shoeGear"]
    drawAtEquipmentSlot(7, 0, shoeGearEquipment and shoeGearEquipment.x, shoeGearEquipment and shoeGearEquipment.y,
        itemsAtlas, 13, 6, 2, 2)

    if draggedItem then
        -- TODO: Correct scaling
        -- itemsAtlas:drawTile(2, 14, love.mouse.getX(), love.mouse.getY(), draggedItem.x * sizes.UIScale, draggedItem.height * sizes.resolutionConversionRatio)
    end

    -- local x, y, width, height = 11.8, 6, 2, 2
    -- tiledUIPanel("uiImage", tileSize, scale, {10, 4, 2, 2}):draw(x, y, width, height)
    -- TODO: Don't flicker the login box if credentials are rejected. (fade-out ?)

    -- render loginbox
    local caret
    if delta % 1 < 0.5 then
        caret = "_"
    else
        caret = ""
    end
    if loginboxEnabled then
        local x, y = sizes.loginboxDims.x, sizes.loginboxDims.y
        if not devConsoleEnabled then
            tintScreen()
        end

        tiledUIPanel.wrap("uiImage", sizes.UITileSize, sizes.UIScale):draw(sizes.loginboxDims)
        tiledUIPanel.wrap("uiImage", sizes.UITileSize / 2, sizes.UIScale, {20, 20, 4, 4}):draw(x * 2 + 10 - 0.5,
            y * 2 + 4 - 0.1, 6, 2)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("login", (x + 5.8) * sizes.UITileSize * sizes.UIScale,
            (y + 2.1) * sizes.UITileSize * sizes.UIScale)
        love.graphics.print("username:", x * sizes.UITileSize * sizes.UIScale + 50 * sizes.resolutionConversionRatio,
            y * sizes.UITileSize * sizes.UIScale + 60 * sizes.resolutionConversionRatio)
        local usernameTextFieldSizes = sizes.loginboxTextFieldsSizes.username
        tintedTextField(usernameTextFieldSizes.x, usernameTextFieldSizes.y, usernameTextFieldSizes.width,
            usernameTextFieldSizes.margins)
        local usernameCaret = ""
        if activeLoginBoxField == "nickname" then
            usernameCaret = caret
        end
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(loginboxUsernameText .. usernameCaret,
            x * sizes.UITileSize * sizes.UIScale + 270 * sizes.resolutionConversionRatio,
            y * sizes.UITileSize * sizes.UIScale + 60 * sizes.resolutionConversionRatio)
        love.graphics.print("password:", x * sizes.UITileSize * sizes.UIScale + 50 * sizes.resolutionConversionRatio,
            y * sizes.UITileSize * sizes.UIScale + 110 * sizes.resolutionConversionRatio)

        love.graphics.setColor(0, 0, 0, 0.1)
        local passwordTextFieldSizes = sizes.loginboxTextFieldsSizes.password
        tintedTextField(passwordTextFieldSizes.x, passwordTextFieldSizes.y, passwordTextFieldSizes.width,
            passwordTextFieldSizes.margins)
        love.graphics.setColor(0, 0, 0, 1)
        local pwdCaret = ""
        if activeLoginBoxField == "password" then
            pwdCaret = caret
        end
        love.graphics.print(string.rep("*", #loginboxPasswordText) .. pwdCaret,
            x * sizes.UITileSize * sizes.UIScale + 270 * sizes.resolutionConversionRatio,
            y * sizes.UITileSize * sizes.UIScale + 110 * sizes.resolutionConversionRatio)
        love.graphics.setColor(0.8, 0.3, 0.3, 1)
        love.graphics.setFont(assets.get("resources/fonts/JPfallback.ttf", 24))
        love.graphics.printf(loginboxErrorText, x * sizes.UITileSize * sizes.UIScale + 32,
            y * sizes.UITileSize * sizes.UIScale + 170 * sizes.resolutionConversionRatio,
            300 * sizes.resolutionConversionRatio, "left")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(assets.get("font"))
    end

    if settingsEnabled then
        tintScreen()
        tiledUIPanel.wrap("uiImage", sizes.UITileSize, sizes.UIScale):draw(sizes.settingsBoxDimensionsInTiles)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("UI Style", (sizes.settingsBoxDimensionsInTiles.x + 0.5) * sizes.UITileSize * sizes.UIScale,
            (sizes.settingsBoxDimensionsInTiles.y + 0.5) * sizes.UITileSize * sizes.UIScale)
        love.graphics.print("Log Out", (sizes.settingsBoxDimensionsInTiles.x + 0.5) * sizes.UITileSize * sizes.UIScale,
            (sizes.settingsBoxDimensionsInTiles.y + 0.5) * sizes.UITileSize * sizes.UIScale + 50 *
                sizes.resolutionConversionRatio)
        love.graphics.print("Exit", (sizes.settingsBoxDimensionsInTiles.x + 0.5) * sizes.UITileSize * sizes.UIScale,
            (sizes.settingsBoxDimensionsInTiles.y + 0.5) * sizes.UITileSize * sizes.UIScale + 100 *
                sizes.resolutionConversionRatio)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- draw dev devConsole
    if devConsoleEnabled then
        tintScreen()
        local x, y = 30 * sizes.resolutionConversionRatio, 1000 * sizes.resolutionConversionRatio
        drawTextInputField(x, y, true, devConsoleMessageRef.val, 1600 * sizes.resolutionConversionRatio, 2,
            {0.8, 0.8, 0.8, 0.1})
        drawMessageList(devConsoleMessageHistory, {
            x = 10,
            y = 0,
            width = 1870,
            height = 1020
        }, true)
    end
    -- love.graphics.print("Nice text", 0, 10, 0, 8, 8)
end

function game.quit()
    print("Terminating the game")
    client.onDisconnect()
end

function game.keypressed(key)
    if key == "f5" then
        love.event.quit("restart")
    end
    if key == "escape" then
        handleSettingsClose()
    end
    if key == "`" then
        devConsoleTogglePrompt()
        return
    end
    -- NOTE: I don't like this.
    if not not UIElemHandlers[activeUIElemStack:last()] then
        UIElemHandlers[activeUIElemStack:last()].keypressed(key)
    end
end

function game.mousepressed(x, y, mb, isTouch, presses)
    if pointIntersectsQuad(x, y, sizes.settingsBtnDimensions) and shouldHandleSettingsBtnClick or
        (settingsEnabled and isPosOutOfSettingsPanel(x, y)) then
        toggleSettings()
        return
    end
    if loginboxEnabled and pointIntersectsQuad(x, y, sizes.loginboxBtnDims) and shouldHandleLoginClick then
        onLoginClicked()
    end

    if loginboxEnabled then
        return
    end

    if pointIntersectsQuad(x, y, sizes.chatboxSendBtnDims) and shouldHandleChatboxSendBtnClick then
        handleChatKp("return")
        return
    end

    handleLoginBoxFieldFocusOnMouseClick(x, y, mb, isTouch, presses)
    local size = dims.wrap {
        x = sizes.testMugItemDims.x * sizes.resolutionConversionRatio,
        y = sizes.testMugItemDims.y * sizes.resolutionConversionRatio,
        width = sizes.testMugItemDims.width * sizes.resolutionConversionRatio,
        height = sizes.testMugItemDims.height * sizes.resolutionConversionRatio
    }
    if pointIntersectsQuad(x, y, size) then
        draggedItem = testMugItemInfo
    end
    -- for _, item in itemsInScene:iter() do
    --     if pointIntersectsQuad(x, y, item) then
    --         draggedItem = map.shallowCopy(item)
    --         assert(draggedItem.tileX and draggedItem.tileY)
    --         draggedItem.offsets = {
    --             -- TODO:
    --             x = item.x,
    --             y = item.y
    --         }
    --         draggedItem.visible = false
    --         print("Picked up an item.")
    --     end
    -- end
    -- TODO: Pick up items in the inventory
end

function game.mousereleased(x, y)
    if draggedItem then
        local m = sizes.mainHandInventorySlotDims
        local mul = sizes.UIScale * sizes.UITileSize
        if pointIntersectsQuad(x, y, m.x * mul, m.y * mul, m.width * mul, m.height * mul) then
            print("Deposited item into mainHand slot")
            equipmentSlotsEquipment.mainHand = draggedItem
            -- TODO: Equip item
            -- TODO: Disable mouse trigger
        else
            draggedItem.visible = true
        end
        draggedItem = nil
        -- TOOD: Unequip item
    end
end

function game.textinput(key)
    if key == "`" then
        return
    end
    UIElemHandlers[activeUIElemStack:last()].textinput(key)
end

-- luacheck: push no unused args
function game.mousemoved(x, y, dx, dy, istouch)
    return true
    -- TODO: Hover animation for buttons
end
-- luacheck: pop

return game
