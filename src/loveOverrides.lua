function love.graphics.withShader(shader, func)
    love.graphics.setShader(shader)
    local res = func()
    love.graphics.setShader()
    return res
end