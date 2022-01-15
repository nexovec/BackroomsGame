local uiBox = {}


local types = require("std.types")


local uiBtnRoundingMask = love.graphics.newShader("resources/shaders/masks/uiBtnRoundingMask.glsl")


function uiBox:clear()
    -- stencil buffer
    love.graphics.push("all")
    love.graphics.setCanvas({
        self.textureCvs,
        depthstencil = true
    })
    love.graphics.stencil(function()
        love.graphics.setShader(uiBtnRoundingMask)
        uiBtnRoundingMask:send("rounding", self.rounding)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.applyShader({
        self.textureCvs,
        depthstencil = true,
        getDimensions = function()
            return self.textureCvs:getDimensions()
        end
    }, self.shader, {
        top_left = {0.1, 0.1, 0.1, 1},
        top_right = {0.1, 0.1, 0.1, 1},
        bottom_right = {0.2, 0.2, 0.2, 1},
        bottom_left = {0.2, 0.2, 0.2, 1}
    })
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    love.graphics.pop()

    -- alternative with no stencil shader (if you need to resample the alpha texture to get jagged edges)
    -- love.graphics.push("all")
    -- local gradientShaderA = love.graphics.newShader("resources/shaders/gradient.glsl")
    -- local applyAlphaA = love.graphics.newShader("resources/shaders/applyAlpha.glsl")
    -- self.chatboxTexture = love.graphics.newCanvas(unpack(chatboxDims))
    -- local aspect = width / height
    -- self.textureCvs = love.graphics.newCanvas(width, height)
    -- local texture = love.graphics.newCanvas(width, height)
    -- local alphaTexture = love.graphics.newCanvas(aspect * 128, 128)
    -- alphaTexture:renderTo(function()
        --     love.graphics.withShader(uiBtnRoundingMask, function()
            --         uiBtnRoundingMask:send("rounding", 8)
    --         love.graphics.rectangle("fill", 0, 0, width, height)
    --     end)
    -- end)

    -- love.graphics.applyShader(texture, gradientShaderA, {
    --     top_left = {0.1, 0.1, 0.1, 1},
    --     top_right = {0.1, 0.1, 0.1, 1},
    --     bottom_right = {0.2, 0.2, 0.2, 1},
    --     bottom_left = {0.2, 0.2, 0.2, 1}
    -- })


    -- love.graphics.applyShader(self.textureCvs, applyAlphaA, {alphaMask = alphaTexture}, {draw = texture})
    -- texture:release()
    -- alphaTexture:release()

    return self
end

function uiBox.makeBox(width, height, shader, uniformsTable, rounding)
    -- TODO: use uniformsTable
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

return types.makeType(uiBox)