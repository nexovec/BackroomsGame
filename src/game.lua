local game = {}


-- requires
local animation = require("animation")
local talkies = require('talkies')
local enet = require("enet")


-- variables
local backgroundImage
local playerImage
local testTileSet
local basicShaderA
local invertShaderA
local testShaderA

local enethost
local enetclient
local clientpeer
local hostevent
-- test networking
local function beginServer()
    print("Starting the Server...")

    -- establish host for receiving msg
	enethost = enet.host_create("192.168.0.234:6750")

end
local function beginClient()
    print("Attempting to join the server...")

    -- establish a connection to host on same PC
    enetclient = enet.host_create()
    clientpeer = enetclient:connect("192.168.0.234:6750")
end
local connectedPeer
function ServerListen()
    if not enethost then return end
	hostevent = enethost:service(100)
	if hostevent then
		print("Server detected message type: " .. hostevent.type)
		if hostevent.type == "connect" then
			print(hostevent.peer, "connected.")
		end
		if hostevent.type == "receive" then
			print("Received message: ", hostevent.data, hostevent.peer)
            hostevent.peer:send("Hello from the server!")
		end
	end
end

function ClientSend()
    if not enetclient then return end
	hostevent = enetclient:service(100)
    if not hostevent then return end
	if hostevent.type == "connect" then
        print("sending hi to server!")
        clientpeer:send("Hi")
    end
    if hostevent.type == "receive" then
        print("Client received message: ", hostevent.data, hostevent.peer)
        clientpeer:send("communicating!")
    end
end
local function handleNetworking()
    talkies.say("Networking", "Who do you want to be?", {
        rounding = 5,
        font = love.graphics.newFont("resources/fonts/Pixel UniCode.ttf", 48),
        options = {{"Server", function()beginServer()end}, {"Client", function() beginClient() end}}})
end


-- API
function game.init()
    love.window.setTitle("Backrooms v0.0.1 pre-dev")
    -- load assets
    backgroundImage = love.graphics.newImage("resources/images/background1.png")
    playerImage = animation.new("character")
    tilesetImage = animation.new("tileset")


    -- init logic:
    local animation = playerImage.play(3, "idle", true, false)
    basicShaderA = love.graphics.newShader("resources/shaders/basic.glsl")
    invertShaderA = love.graphics.newShader("resources/shaders/invert.glsl")
    testShaderA = love.graphics.newShader("resources/shaders/test.glsl")


    handleNetworking()

    -- TODO: draw floor, ceiling
    -- TODO: draw a chair in the scene
    -- TODO: make the player move
    -- TODO: basic interaction with chair transitions into level 0
    -- TODO: in-game log
    -- TODO: narration dialogue boxes
    -- TODO: scripted entity encounter
    -- TODO: entity cards
    -- TODO: display entity on the field
    -- TODO: scripted wanderer encounter
    -- TODO: background shader
    -- TODO: craft UI layouts
    -- TODO: settings menu
    -- TODO: fade-in, fade-out on level transition
    -- TODO: post-FX
    -- TODO: particles
    -- TODO: UI animations
    -- TODO: phone
    -- TODO: BeautifulBread logo on startup
    -- TODO: narrate intro and level 0
    -- TODO: add outpost
    -- TODO: add inventory
    -- TODO: add drinkable almond water
end


function game.tick(deltaTime)
    talkies.update(deltaTime)
    ClientSend()
    ServerListen()
end

function game.draw()

    -- draw background
    -- FIXME: magic numbers
    local backgroundQuad = love.graphics.newQuad(0, 0, 2560, 1440, 2560, 1440)
    love.graphics.draw(backgroundImage, backgroundQuad, 0, 0, 0, 1, 1, 0, 0)

    -- draw player animation
    local playfieldCanvas = love.graphics.newCanvas(1600,720)
    local playfieldQuad = love.graphics.newQuad(0,0,1600,720,1600,720)
    local playerSpriteQuad = love.graphics.newQuad(0, 0, 720, 720, 720, 720)

    playfieldCanvas:renderTo(function()
        love.graphics.clear(1.0, 1.0, 1.0)
        love.graphics.withShader(testShaderA, function()
            testShaderA:sendColor("color1", {0.9, 0.7, 0.9, 1.0})
            testShaderA:sendColor("color2", {0.7, 0.9, 0.9, 1.0})
            testShaderA:send("rectSize",{64,64})
            love.graphics.rectangle("fill", 0, 0, 720, 720)
        end)
        love.graphics.withShader(basicShaderA, function()
            playerImage.draw(playerSpriteQuad, 0, 0, 0, 1,1, 0, 0)
        end)
        talkies.draw()
    end)
    love.graphics.draw(playfieldCanvas, playfieldQuad, 100, 100, 0, 1, 1, 0, 0, 0, 0)
end

function love.keypressed(key)
    if key == "space" then talkies.onAction()
    elseif key == "up" then talkies.prevOption()
    elseif key == "down" then talkies.nextOption()
    end
end

return game
