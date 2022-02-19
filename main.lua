-- requires
local profile = require("profile")

local std = require("std")
local json = require("std.json")
local assets = require("assets")
local types = require("std.types")
local map = require("std.map")
local game
local server

-- variables
local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}

local reportedFPS = 0

-- TODO: Move macro handling to a separate file
local currentFrame = 0
local currentMacro
local isRecordingMacro

local function addMacroEvent(type, contents)
    currentMacro.put(love.timer.getTime(), {
        frame = currentFrame,
        type = type,
        contents = contents
    })
end

function startRecordingPlayerInputs()
    currentMacro = currentMacro or map.wrap()
    isRecordingMacro = true
end

function stopRecordingPlayerInputs()
    local result = currentMacro
    print(json.encode(result))
    currentMacro = nil
    isRecordingMacro = false
    return result
end

function love.load(args)
    -- TODO: Untested platform warnings, compatibility checks
    options.isServer = args[1] == "--server"
    profile.start()

    if options.isServer then
        server = require("server")
        assets.initOnServer()
        if server == nil then
            print("You can't launch as a server because I yeeted the server files, precisely so you can't do this.")
        end
        server.load()
    else
        require("loveOverrides")
        game = require("game")
        assets.initOnClient()
        love.graphics.setDefaultFilter("nearest", "nearest")
        -- FIXME: Magic numbers

        -- make fullscreen
        love.window.setVSync(1)
        love.window.requestAttention()
        game.load(options)
    end

    if assets.get("settings").logging.shouldPerformanceLog then
        print(profile.report(10))
    end

    timeLastLoggedFPS = love.timer.getTime()
    profile.reset()
    profile.stop()
    collectgarbage("collect")
    collectgarbage("stop")
    timeLastLogged = love.timer.getTime()
end

deltaTime = 0

function love.update(dt)
    profile.start()
    currentFrame = currentFrame + 1
    ticks = ticks + 1

    if options.isServer then
        server.update(dt)
    else
        targetTPS = assets.get("settings").targetTPS
        if not targetTPS then
            game.tick(dt)
        else
            msPerTick = 1 / targetTPS
            deltaTime = deltaTime + dt
            if deltaTime >= msPerTick then
                -- shouldRender = true
                game.tick(deltaTime)
                deltaTime = 0
            end
        end
    end

    if assets.get("settings").logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        -- print(ticks .. "\t:\t" .. collectgarbage("count"))
        reportedFPS = ticks
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (assets.get("settings").logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged >
        assets.get("settings").logging.performanceLogPeriodInSeconds) then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    collectgarbage("step")
    profile.stop()
end

function love.draw()
    -- TODO: Render at display refresh rate
    profile.start()
    game.draw()
    profile.stop()
    if assets.get("settings").logging.shouldLogFPS then
        love.graphics.setFont(assets.get("font"))
        love.graphics.print(reportedFPS)
    end
end

function love.quit()
    if game then
        types.optionalCall(game.quit)
    else
        types.optionalCall(server.quit)
    end
end

function love.keypressed(...)
    if isRecordingMacro then
        addMacroEvent("keypressed", ...)
    end
    game.keypressed(...)
end

function love.textinput(...)
    if isRecordingMacro then
        addMacroEvent("textinput", ...)
    end
    game.textinput(...)
end

function love.mousepressed(...)
    if isRecordingMacro then
        addMacroEvent("mousepressed", ...)
    end
    game.mousepressed(...)
end
