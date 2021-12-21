require("src.std.luaOverrides")

-- requires
local profile = require("profile")
local flux = require("flux")

require("std.types")
require("std.tables")

local game = require("game") -- needs to be the last require


-- variables
local sceneCanvas = love.graphics.newCanvas(3840, 2160)

local timeLastLogged = love.timer.getTime()
local delta = 0

-- callbacks
function love.load()
    profile.start()
    love.graphics.setDefaultFilter("nearest", "nearest", 16)
    -- make fullscreen
    love.window.requestAttention()
    love.window.setFullscreen(true, "desktop")
    local loveOverrides = require("loveOverrides")
    assert(loveOverrides)
    loveOverrides.init()
    game.init()
    print(profile.report(10))
    profile.reset()
    profile.stop()
end


function love.update(dt)
    delta = delta + dt
    if delta < 1 / love.ddd.constants.targetFPS then
        return
    end
    delta = 0
    profile.start()
    flux.update(dt)
    game.tick(dt)
    if (love.ddd.settings.logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged) > love.ddd.settings.logging.performanceLogPeriodInSeconds then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    profile.stop()
end

function love.draw()
    profile.start()
    sceneCanvas:setFilter("nearest", "nearest", 16)
    sceneCanvas:renderTo(game.draw)
    local _,_,width,height = love.window.getSafeArea()
    local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
    love.graphics.draw(sceneCanvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
    profile.stop()
end

function love.quit()
    print("Exiting the game...")
end
