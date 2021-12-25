function love.graphics.withShader(shader, func)
    love.graphics.setShader(shader)
    func()
    love.graphics.setShader()
end