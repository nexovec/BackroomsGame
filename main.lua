require("loveOverrides")

-- requires
local profile = require("profile")


local std = require("std")

local game = require("game") -- needs to be the last require
local assets = require("assets")
local animation = require("animation")

-- variables
local sceneCanvas = love.graphics.newCanvas(2560, 1440)

local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0


-- callbacks
function love.load()
    profile.start()
    love.graphics.setDefaultFilter("nearest", "nearest")
    sceneCanvas:setFilter("nearest", "nearest")

    -- make fullscreen
    love.window.setVSync(0)
    love.window.requestAttention()
    game.init()

    if assets.settings.logging.shouldPerformanceLog then print(profile.report(10)) end
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
    animation.updateAnimations(dt)
    game.tick(dt)

    if assets.settings.logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        print(ticks .. "\t:\t" .. collectgarbage("count"))
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (assets.settings.logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged > assets.settings.logging.performanceLogPeriodInSeconds) then
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
