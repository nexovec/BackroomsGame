-- requires
local profile = require("profile")

local std = require("std")
local json = require("std.json")
local assets = require("assets")
local types = require("std.types")
local map = require("std.map")
local array = require("std.array")
local utf8 = require("utf8")
local game
local server

-- variables
local timeLastLogged = nil
local deltaTime = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}

local reportedFPS = 0

-- TODO: Move macro handling to a separate file
local macroStartFrame = nil
local playedMacroStartFrame = nil
local currentFrame = 0
local currentMacro
local isRecordingMacro
local currentlyPlayedMacro

local function addMacroEvent(type, contents)
    assert(currentMacro)
    currentMacro:append{
        frame = currentFrame - macroStartFrame,
        timestamp = tostring(love.timer.getTime()),
        mType = type,
        contents = contents
    }
end

function startRecordingPlayerInputs(macroName)
    if currentMacro then
        return false
    end
    macroStartFrame = currentFrame
    currentMacro = array.wrap()
    currentMacroName = macroName
    isRecordingMacro = true
    return true
end

function pauseRecordingPlayerInputs()
    if not currentMacro then
        return false
    end
    isRecordingMacro = not isRecordingMacro
    return true
end

function startPlayingMacro(macro)
    playedMacroStartFrame = currentFrame
    currentlyPlayedMacro = macro
end

function stopRecordingPlayerInputs()
    -- TODO: Redirect the save folder
    local success = false
    if isRecordingMacro then
        success = true
    end
    local tempMacro = currentMacro
    macroStartFrame = nil
    currentMacro = nil
    isRecordingMacro = false
    return tempMacro, success
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

function playedMacroDispatchEvents()
    if currentlyPlayedMacro:length() == 0 then
        playedMacroStartFrame = nil
        currentlyPlayedMacro = nil
        return
    end
    for k, v in currentlyPlayedMacro:iter() do
        if v.frame <= currentFrame - playedMacroStartFrame then
            -- FIXME: This is exploitable
            -- TODO: Dispatch multiple during the same tick.
            if type(v.contents) == "table" then
                love.event.push(v.mType, unpack(v.contents))
            else
                love.event.push(v.mType, v.contents)
            end
            table.remove(currentlyPlayedMacro, k)
            return playedMacroDispatchEvents()
        end
    end
end

function love.update(dt)
    profile.start()
    currentFrame = currentFrame + 1
    ticks = ticks + 1

    if options.isServer then
        server.update(dt)
    else
        targetTPS = assets.get("settings").targetTPS
        if not targetTPS then
            -- TODO: Use macros here
            game.tick(dt)
        else
            msPerTick = 1 / targetTPS
            deltaTime = deltaTime + dt
            while deltaTime >= msPerTick do
                if not not currentlyPlayedMacro then
                    playedMacroDispatchEvents()
                end
                -- shouldRender = true
                game.tick(deltaTime)
                deltaTime = deltaTime - msPerTick
            end
        end
    end

    if assets.get("settings").logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
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

function love.mousemoved(...)
    if isRecordingMacro then
        addMacroEvent("mousemoved", ...)
    end
    game.mousemoved(...)
end
