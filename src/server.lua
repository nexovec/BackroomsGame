local server = {}


local array = require("std.array")
local timing = require("timing")


local enethost
local connectedPeers = array.wrap()
local peerNicknames = array.wrap()
local enet = require("enet")

local function beginServer()
    print("Starting the Server...")

    -- establish host for receiving msg
    enethost = enet.host_create("192.168.0.234:6750")

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
            local data = hostevent.data
            if data:sub(1, #"message:") == "message:" then
                -- TODO: send to everybody
                local authorName = peerNicknames[connectedPeers:indexOf(hostevent.peer)]
                local msg = authorName .. ": " .. data:sub((#"message:" + 1), #data)
                -- hostevent.peer:send("message:" .. msg)
                enethost:broadcast("message:" .. msg)
            end
            if data:sub(1, #"status:") == "status:" then
                local shortened = data:sub(#"status:" + 1, #data)
                if shortened:sub(1, #"addPlayer:") == "addPlayer:" then
                    local peerIndex = connectedPeers:indexOf(hostevent.peer)
                    -- TODO: Allow only alphabet, _ and numerics in player names, implement max player name size
                    -- FIXME: this is wrong, always sets to nil
                    peerNicknames[peerIndex] = shortened:sub((#"addPlayer:") + 1, #shortened)
                    print(hostevent.peer, "Just registered as ", peerNicknames[peerIndex], "!")
                else
                    -- TODO: check for stray packets
                    local tempHost = hostevent
                    timing.delayCall(function()
                        tempHost.peer:send("status:pong!")
                    end, 2)
                end
            end

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