local oldreq = require
require = function(s) return oldreq('src.' .. s) end
require_lib = function(s) return oldreq('libs.' .. s) end

-- load libraries next to love api by convention
love.profile = require_lib("profile")
love.flux = require_lib("flux")
love.settings = {
    targetFPS = 10,
    performanceLoggingPeriodInSeconds = 1
}

local game = require('game')

local canvas = love.graphics.newCanvas(1280, 720)
 
function love.load()
    love.flux.update(love.timer.getDelta())

    love.profile.start()
    love.graphics.setDefaultFilter("nearest", "nearest", 16)
    game.init()
    print(love.profile.report(10))
    love.profile.reset()
end

local timeLastLogged = love.timer.getTime()
function love.update(dt)
    game.tick()
    if (love.timer.getTime() - timeLastLogged) > love.settings.performanceLoggingPeriodInSeconds then
        -- love.profile.stop()
        love.profile.report(10)
        love.profile.reset()
        -- love.profile.start()
        timeLastLogged = love.timer.getTime()
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1.0, 0.0, 1.0, 1.0)
    canvas:setFilter("nearest", "nearest", 16)
    game.draw()
    
    -- draw buffer to screen
    love.graphics.setCanvas()
    local _,_,width,height = love.window.getSafeArea()
    -- RESEARCH: can we use Transform instead of quad?
    local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
    -- TODO: use nearest neighbour texture filtering to avoid blur
    love.graphics.draw(canvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
end

function love.quit()
    print("quitw")
end
