require("src.luaOverrides")

-- requires
local profile = require("profile")
local flux = require("flux")
require("std.types")
require("std.tables")

local game = require("game") -- needs to be the last require


-- variables
local sceneCanvas = love.graphics.newCanvas(3840, 2160)


-- callbacks
function love.load()
    profile.start()
    love.graphics.setDefaultFilter("nearest", "nearest", 16)
    -- make fullscreen
    love.window.requestAttention()
    love.window.setFullscreen(true, "desktop")
    game.init()
    print(profile.report(10))
    profile.reset()
    profile.stop()
end

local timeLastLogged = love.timer.getTime()
local delta = 0
function love.update(dt)
    delta = delta + dt
    if delta < 1 / love.settings.targetFPS then
        return
    end
    delta = 0
    profile.start()
    flux.update(dt)
    game.tick(dt)
    if (love.timer.getTime() - timeLastLogged) > love.settings.performanceLoggingPeriodInSeconds then
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
