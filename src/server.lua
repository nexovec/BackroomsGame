local server = {}


local array = require("std.array")
local timing = require("timing")
local network = require("network")
local assert = require("std.assert")


local enethost
local connectedPeers = array.wrap()
local peerNicknames = array.wrap()
local enet = require("enet")

local function beginServer()
    print("Starting the Server...")

    -- establish host for receiving msg
    enethost = enet.host_create("192.168.0.234:6750")

end

local function setPeerUsername(peer, username)
    assert(peer and username, "You must pass peer, username to this.", 2)
    local peerIndex = connectedPeers:indexOf(peer)
    peerNicknames[peerIndex] = username
end
local function getPeerUsername(peer)
    assert(peer, "You must pass peer to this", 2)
    return peerNicknames[connectedPeers:indexOf(peer)]
end

local function receiveEnetHandle(hostevent)
    local data = hostevent.data
    local prefix, trimmedData = network.getNetworkMessagePrefix(data)
    if prefix == "message" then
        -- broadcast message to everybody
        local authorName = getPeerUsername(hostevent.peer)
        if not authorName then
            --TODO: Who are you again?
        end
        local msg = authorName .. ": " .. trimmedData
        print(msg)
        enethost:broadcast("message:" .. msg)
    elseif prefix == "status" then
        prefix, trimmedData = network.getNetworkMessagePrefix(trimmedData)
        if prefix == "logIn" then
            username, password  = network.getNetworkMessagePrefix(trimmedData)

            -- TODO: Allow only alphabet, _ and numerics in player names, implement max and min player name size
            -- FIXME: this is wrong, always sets to nil

            setPeerUsername(hostevent.peer, username)
            enethost:broadcast("message: User " .. getPeerUsername(hostevent.peer) .. " just logged in.")
            print(hostevent.peer, "Just registered as ", getPeerUsername(hostevent.peer), "!")
        elseif trimmedData == "ping!" then
            local tempHost = hostevent
            timing.delayCall(function()
                tempHost.peer:send("status:pong!")
            end, 2)
        else
            -- TODO:
        end
    else
        -- TODO: handle unwanted messages
    end
end

function handleEnetServer()
    if not enethost then
        error("Well this could be a problem")
        return
    end
    local hostevent = enethost:service()
    if hostevent then
        -- print("Server detected message type: " .. hostevent.type)
        if hostevent.type == "connect" then
            print(hostevent.peer, "connected.")
            connectedPeers:append(hostevent.peer)
        end
        if not connectedPeers:contains(hostevent.peer) then
            -- TODO: log unregistered clients trying to send messages
            print("ERRORRRROOROROOROROROR")
            return
        end
        if hostevent.type == "receive" then
            receiveEnetHandle(hostevent)
        end
        -- TODO: unlog timed-out clients
    end
    hostevent = nil
end

function server.load()
    -- TODO:
    beginServer()
end

function server.update(dt)
    -- TODO:
    handleEnetServer()
end

function server.draw()
    -- TODO:
end

return server