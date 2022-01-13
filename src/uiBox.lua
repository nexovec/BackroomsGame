local uiBox = {}
local uiBtnRoundingMask = love.graphics.newShader("resources/shaders/masks/uiBtnRoundingMask.glsl")
function uiBox.makeBox(width, height, shader, uniformsTable, rounding)
    -- TODO: use uniformsTable
    local self = {}
    -- PERFORMANCE: don't create a new canvas each tick
    -- draw chatbox
    -- self.chatboxTexture = love.graphics.newCanvas(unpack(chatboxDims))
    self.textureCvs = love.graphics.newCanvas(width, height)
    self.alphaCvs = love.graphics.newCanvas(width, height, {
        format = "stencil8"
    })
    -- stencil buffer
    love.graphics.push("all")
    love.graphics.setCanvas({
        self.textureCvs,
        depthstencil = true
    })
    love.graphics.stencil(function()
        love.graphics.setShader(uiBtnRoundingMask)
        uiBtnRoundingMask:send("rounding", rounding)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.applyShader({
        self.textureCvs,
        depthstencil = true,
        getDimensions = function()
            return self.textureCvs:getDimensions()
        end
    }, shader, {
        top_left = {0.1, 0.1, 0.1, 1},
        top_right = {0.1, 0.1, 0.1, 1},
        bottom_right = {0.2, 0.2, 0.2, 1},
        bottom_left = {0.2, 0.2, 0.2, 1}
    })
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.pop()
    setmetatable(self, uiBox)
    return self
end

return uiBox