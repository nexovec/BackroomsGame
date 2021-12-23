require("src.std.luaOverrides")

-- requires
local profile = require("profile")
local flux = require("flux")

require("std.types")
require("std.tables")

local game = require("game") -- needs to be the last require
local loveOverrides = require("loveOverrides")
local animation = require("animation")
assert(animation)

-- variables
local sceneCanvas = love.graphics.newCanvas(2560, 1440)

local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0


-- callbacks
function love.load()
    profile.start()
    love.graphics.setDefaultFilter("nearest", "nearest", 16)
    sceneCanvas:setFilter("nearest", "nearest", 16)
    -- make fullscreen
    love.window.setVSync(0)
    love.window.requestAttention()
    love.window.setFullscreen(true, "desktop")
    loveOverrides.loadData()
    game.init()
    if media.settings.logging.shouldPerformanceLog then print(profile.report(10)) end
    timeLastLoggedFPS = love.timer.getTime()
    profile.reset()
    profile.stop()
    collectgarbage("collect")
    collectgarbage("stop")
    timeLastLogged = love.timer.getTime()
end


function love.update(dt)
    profile.start()
    ticks = ticks + 1
    flux.update(dt)
    animation.update()
    game.tick(dt)
    if media.settings.logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        print(ticks .. "\t:\t" .. collectgarbage("count"))
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (media.settings.logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged > media.settings.logging.performanceLogPeriodInSeconds) then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    collectgarbage("step")
    profile.stop()
end

function love.draw()
    profile.start()
    sceneCanvas:renderTo(game.draw)
    local _,_,width,height = love.window.getSafeArea()
    local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
    love.graphics.draw(sceneCanvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
    collectgarbage("step")
    profile.stop()
end

function love.quit()
    print("Exiting the game...")
end
