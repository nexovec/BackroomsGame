local server = {}


local array = require("std.array")
local timing = require("timing")
local network = require("network")


local enethost
local connectedPeers = array.wrap()
local peerNicknames = array.wrap()
local enet = require("enet")

local function beginServer()
    print("Starting the Server...")

    -- establish host for receiving msg
    enethost = enet.host_create("192.168.0.234:6750")

end

local function receiveMessageHandle(hostevent)
    -- TODO:
    local data = hostevent.data
    local prefix, trimmedMessage = network.getNetworkMessagePrefix(data)
    if prefix == "message" then
        -- TODO: send to everybody
        local authorName = peerNicknames[connectedPeers:indexOf(hostevent.peer)]

        local msg = authorName .. ": " .. data:sub((#"message:" + 1), #data)
        -- hostevent.peer:send("message:" .. msg)
        enethost:broadcast("message:" .. msg)
    elseif prefix == "status" then
        local shortened = data:sub(#"status:" + 1, #data)
        if shortened:sub(1, #"addPlayer:") == "addPlayer:" then
            local peerIndex = connectedPeers:indexOf(hostevent.peer)
            -- TODO: Allow only alphabet, _ and numerics in player names, implement max player name size
            -- FIXME: this is wrong, always sets to nil
            peerNicknames[peerIndex] = shortened:sub((#"addPlayer:") + 1, #shortened)
            enethost:broadcast("message: User " .. peerNicknames[peerIndex] .. " just logged in.")
            print(hostevent.peer, "Just registered as ", peerNicknames[peerIndex], "!")
        else
            local tempHost = hostevent
            timing.delayCall(function()
                tempHost.peer:send("status:pong!")
            end, 2)
        end
    else
        -- TODO: handle unwanted messages
    end
end

function handleEnetIfServer()
    if not enethost then
        error("Well this could be a problem")
        return
    end
    local hostevent = enethost:service()
    if hostevent then
        print("Server detected message type: " .. hostevent.type)
        if hostevent.type == "connect" then
            print(hostevent.peer, "connected.")
            connectedPeers[#connectedPeers + 1] = hostevent.peer
        end
        -- TODO: log unregistered clients trying to send messages
        if not connectedPeers:contains(hostevent.peer) then
            print("ERRORRRROOROROOROROROR")
            return
        end
        if hostevent.type == "receive" then
            receiveMessageHandle(hostevent)
        end
    end
    hostevent = nil
end

function server.load()
    -- TODO:
    beginServer()
end

function server.update(dt)
    -- TODO:
    handleEnetIfServer()
end

function server.draw()
    -- TODO:
end

return server