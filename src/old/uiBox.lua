-- luacheck: ignore
---@diagnostic disable: unused-function, undefined-global
local uiBox = {}

local types = require("std.types")
local assets = require("assets")
local assert = require("std.assert")

function love.graphics.applyShader(canvas, textureShader, uniformsTable, options)
    -- TODO: Test
    -- local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.withShader(textureShader, function()
        for i, v in pairs(uniformsTable) do
            textureShader:send(i, v)
        end
        if options then
            if options.draw then
                love.graphics.draw(options.draw, options.x, options.y)
            else
                love.graphics.rectangle("fill", options.x, options.y, canvas:getDimensions())
            end
        else
            love.graphics.rectangle("fill", 0, 0, canvas:getDimensions())
        end
    end)
    love.graphics.setCanvas()
    -- FIXME: This breaks the code
    -- love.graphics.setCanvas(oldCanvas)
end

function uiBox:clear()
    -- stencil buffer
    love.graphics.push("all")
    love.graphics.setCanvas({
        self.textureCvs,
        depthstencil = true
    })
    love.graphics.stencil(function()
        local sh = assets.get("resources/shaders/masks/uiBtnRoundingMask.glsl")
        love.graphics.setShader(sh)
        sh:send("rounding", self.rounding)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.applyShader({
        self.textureCvs,
        depthstencil = true,
        getDimensions = function()
            return self.textureCvs:getDimensions()
        end
    }, assets.get(self.shader), {
        top_left = {0.1, 0.1, 0.1, 1},
        top_right = {0.1, 0.1, 0.1, 1},
        bottom_right = {0.2, 0.2, 0.2, 1},
        bottom_left = {0.2, 0.2, 0.2, 1}
    })
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    love.graphics.pop()

    -- alternative with no stencil shader (if you need to resample the alpha texture to get jagged edges)
    -- love.graphics.push("all")
    -- self.chatboxTexture = love.graphics.newCanvas(unpack(chatboxDims))
    -- local aspect = width / height
    -- self.textureCvs = love.graphics.newCanvas(width, height)
    -- local texture = love.graphics.newCanvas(width, height)
    -- local alphaTexture = love.graphics.newCanvas(aspect * 128, 128)
    -- alphaTexture:renderTo(function()
    --     love.graphics.withShader(assets.uiBtnRoundingMask, function()
    --         assets.uiBtnRoundingMask:send("rounding", 8)
    --         love.graphics.rectangle("fill", 0, 0, width, height)
    --     end)
    -- end)

    -- love.graphics.applyShader(texture, assets.gradientShaderA, {
    --     top_left = {0.1, 0.1, 0.1, 1},
    --     top_right = {0.1, 0.1, 0.1, 1},
    --     bottom_right = {0.2, 0.2, 0.2, 1},
    --     bottom_left = {0.2, 0.2, 0.2, 1}
    -- })

    -- love.graphics.applyShader(self.textureCvs, assets.applyAlphaA, {alphaMask = alphaTexture}, {draw = texture})
    -- texture:release()
    -- alphaTexture:release()

    return self
end

function uiBox.makeBox(width, height, shader, uniformsTable, rounding)
    assert(type(shader) == "string", "Shader must be an asset name of a shader or a filepath to it", 2)
    -- TODO: Use uniformsTable
    local self = {}
    -- draw ui box
    self.rounding = rounding
    self.uniformsTable = uniformsTable
    self.shader = shader
    self.width = width
    self.height = height
    self.textureCvs = love.graphics.newCanvas(width, height)
    self.alphaCvs = love.graphics.newCanvas(width, height, {
        format = "stencil8"
    })

    setmetatable(self, uiBox)
    self:clear()
    return self
end
-- old UI code with shader generated textures
local function renderOldUI()
    local uiBox = require("old.uiBox")
    chatboxUIBox = chatboxUIBox or uiBox.makeBox(chatboxDims[1], chatboxDims[2], "gradientShaderA", {}, 20)
    nicknamePickerUIBox = nicknamePickerUIBox or
                              uiBox.makeBox(nicknamePickerBoxDims[1], nicknamePickerBoxDims[2], "gradientShaderA", {},
            20)
    logMessageBox = logMessageBox or
                        uiBox.makeBox(logMessageBoxDims[1], logMessageBoxDims[2], "gradientShaderA", {}, 20)
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

        love.graphics.print(clientChatBoxMessage, 30, 1210)
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

return types.makeType(uiBox, "uiBox")
