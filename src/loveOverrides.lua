function love.graphics.withShader(shader, func)
    assert(type(func) == "function", "Argument #2 must not be nil.", 2)
    local oldShader = love.graphics.getShader()
    love.graphics.setShader(shader)
    local res = func()
    love.graphics.setShader(oldShader)
    return res
end
function love.graphics.applyShader(canvas, textureShader, uniformsTable, options)
    -- TODO: test
    canvas:renderTo(function()
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
    end)
end
