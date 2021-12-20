-- libraries
love.profile = require("libs.profile")
local flux = require("libs.flux")
love.settings = {
    targetFPS = 60,
    performanceLoggingPeriodInSeconds = 5
}

-- modules
require("src.utils")
local game = require("src.game") -- needs to be the last require

-- module scoped variables
local sceneCanvas = love.graphics.newCanvas(3840, 2160)

function love.load()
    love.profile.start()
    love.graphics.setDefaultFilter("nearest", "nearest", 16)
    -- make fullscreen
    love.window.requestAttention()
    love.window.setFullscreen(true, "desktop")
    game.init()
    print(love.profile.report(10))
    love.profile.reset()
    love.profile.stop()
end

local timeLastLogged = love.timer.getTime()
local delta = 0
function love.update(dt)
    delta = delta + dt
    if delta < 1 / love.settings.targetFPS then
        return
    end
    delta = 0
    love.profile.start()
    flux.update(dt)
    game.tick(dt)
    if (love.timer.getTime() - timeLastLogged) > love.settings.performanceLoggingPeriodInSeconds then
        print(love.profile.report(10))
        love.profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    love.profile.stop()
end

function love.draw()
    love.profile.start()
    sceneCanvas:setFilter("nearest", "nearest", 16)
    sceneCanvas:renderTo(game.draw)
    local _,_,width,height = love.window.getSafeArea()
    local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
    love.graphics.draw(sceneCanvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
    love.profile.stop()
end

function love.quit()
    print("quitw")
end
