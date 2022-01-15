-- requires
local profile = require("profile")

local std = require("std")
local assets = require("assets")
local animation = require("animation")
local game
local server


-- variables
local sceneCanvas

local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}


function love.load(args)
    options.isServer = args[1] == "--server"
    profile.start()

    if options.isServer then
        server = require("server")
        if server == nil then print("You can't launch as a server because I yeeted the server files, precisely so you can't do this.") end
        server.load()
    else
        require("loveOverrides")
        game = require("game")
        love.graphics.setDefaultFilter("nearest", "nearest")
        -- FIXME: magic numbers
        sceneCanvas = love.graphics.newCanvas(2560, 1440)

        -- make fullscreen
        love.window.setVSync(0)
        love.window.requestAttention()
        game.load(options)
    end

    if assets.settings.logging.shouldPerformanceLog then
        print(profile.report(10))
    end

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

    if options.isServer then
        server.update(dt)
    else
        animation.updateAnimations(dt)
        game.tick(dt)
    end

    if assets.settings.logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        print(ticks .. "\t:\t" .. collectgarbage("count"))
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (assets.settings.logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged >
    assets.settings.logging.performanceLogPeriodInSeconds) then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    collectgarbage("collect")
    profile.stop()
end

function love.draw()
    profile.start()
    if options.isServer then server.draw() else
        -- TODO: don't double buffer like this, render in the actual resolution instead
        sceneCanvas:renderTo(game.draw)
        local _, _, width, height = love.window.getSafeArea()
        local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
        love.graphics.draw(sceneCanvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
    end
    -- collectgarbage("step")
    profile.stop()
end

function love.quit()
    print("Exiting the game...")
end