local oldreq = require
require = function(s) return oldreq("src." .. s) end
require_lib = function(s) return oldreq("libs." .. s) end

-- libraries
love.profile = require_lib("profile")
love.flux = require_lib("flux")
love.settings = {
    targetFPS = 60,
    performanceLoggingPeriodInSeconds = 5
}

-- modules
local game = require("game")

-- module scoped variables
local sceneCanvas = love.graphics.newCanvas(1280, 720)
local presentationCanvas = love.graphics.getCanvas()

function love.load()
    love.flux.update(love.timer.getDelta())
    
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
    game.tick()
    if (love.timer.getTime() - timeLastLogged) > love.settings.performanceLoggingPeriodInSeconds then
        print(love.profile.report(10))
        love.profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    love.profile.stop()
end

function love.draw()
    sceneCanvas:setFilter("nearest", "nearest", 16)
    sceneCanvas:renderTo(function() game.draw(sceneCanvas) end)
    local _,_,width,height = love.window.getSafeArea()
    local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
    love.graphics.draw(sceneCanvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
end

function love.quit()
    print("quitw")
end
