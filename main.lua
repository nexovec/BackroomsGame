local oldreq = require
require = function(s) return oldreq('src.' .. s) end
require_lib = function(s) return oldreq('libs.' .. s) end

-- load libraries next to love api by convention
require_lib("autobatch")
love.profile = require_lib("profile")
love.flux = require_lib("flux")

local game = require('game')
settings = {
    targetFPS = 10,
    performanceLoggingPeriodInSeconds = 1
}
 
function love.load()
    love.flux.update(love.timer.getDelta())

    love.profile.start()
    game.init()
    print(love.profile.report(10))
    love.profile.reset()
end

local timeLastLogged = love.timer.getTime()
function love.update(dt)
    game.tick()
    if (love.timer.getTime() - timeLastLogged)>settings.performanceLoggingPeriodInSeconds then
        -- love.profile.stop()
        love.profile.report(10)
        love.profile.reset()
        -- love.profile.start()
        timeLastLogged = love.timer.getTime()
    end
end

function love.draw()
    game.draw()
end

function love.quit()
    print("quitw")
end
