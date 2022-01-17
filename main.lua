-- requires
local profile = require("profile")

local std = require("std")
local json = require("std.json")
local settings = json.decode(love.filesystem.newFileData("data/settings.json"):getString())
local assets
local game
local server


-- variables
local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}


function love.load(args)
    -- TODO: untested platform warnings, compatibility checks
    options.isServer = args[1] == "--server"
    profile.start()

    if options.isServer then
        -- TODO: read the real value
        server = require("server")
        if server == nil then print("You can't launch as a server because I yeeted the server files, precisely so you can't do this.") end
        server.load()
    else
        require("loveOverrides")
        game = require("game")
        -- TODO: solve
        assets = require("assets")
        assets.init()
        love.graphics.setDefaultFilter("nearest", "nearest")
        -- FIXME: magic numbers

        -- make fullscreen
        love.window.setVSync(0)
        love.window.requestAttention()
        game.load(options)
    end

    if settings.logging.shouldPerformanceLog then
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
        game.tick(dt)
    end

    if settings.logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        print(ticks .. "\t:\t" .. collectgarbage("count"))
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (settings.logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged >
    settings.logging.performanceLogPeriodInSeconds) then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    collectgarbage("collect")
    profile.stop()
end

function love.draw()
    profile.start()
    -- if options.isServer then server.draw() else
    --     -- TODO: don't double buffer like this, render in the actual resolution instead
    --     sceneCanvas:renderTo(game.draw)
    --     local _, _, width, height = love.window.getSafeArea()
    --     local screenQuad = love.graphics.newQuad(0, 0, width, height, width, height)
    --     love.graphics.draw(sceneCanvas, screenQuad, 0, 0, 0, 1, 1, 0, 0, 0, 0)
    -- end
    -- collectgarbage("step")
    -- TODO:
    game.draw()
    profile.stop()
end

function love.quit()
    -- TODO: track unused requires(detect unused things in types.makeType)
    print("Exiting the game...")
end