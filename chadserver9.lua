local PROTOCOL = "chadnet"

local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

print("Chad.Net Server V9 Online")

-------------------------------------------------
-- STATE
-------------------------------------------------
local clients = {} -- id -> {name,lastSeen}

-------------------------------------------------
local function send(id, msg)
    rednet.send(id, msg, PROTOCOL)
end

local function broadcast(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
local function getUsers()
    local list = {}
    for _, v in pairs(clients) do
        table.insert(list, v.name)
    end
    return list
end

-------------------------------------------------
while true do
    local id, msg = rednet.receive(PROTOCOL)

    if type(msg) == "table" then

        -------------------------------------------------
        -- LOGIN (V9 SAFE)
        -------------------------------------------------
        if msg.type == "login" then
            clients[id] = {name = msg.user, lastSeen = os.clock()}

            send(id, {type="login_ok"})
            broadcast({type="system", text=msg.user.." joined"})
        end

        -------------------------------------------------
        -- PING
        -------------------------------------------------
        if msg.type == "ping" and clients[id] then
            clients[id].lastSeen = os.clock()
            send(id, {type="pong"})
        end

        -------------------------------------------------
        -- CHAT
        -------------------------------------------------
        if msg.type == "chat" and clients[id] then
            broadcast({
                type="chat",
                text="["..clients[id].name.."]: "..msg.text
            })
        end

        -------------------------------------------------
        -- USERS
        -------------------------------------------------
        if msg.type == "user_list" then
            send(id, {type="user_list", users=getUsers()})
        end

        -------------------------------------------------
        -- TTT INVITE FIXED
        -------------------------------------------------
        if msg.type == "ttt_challenge" then
            local from = clients[id] and clients[id].name
            if not from then goto continue end

            local targetId
            for cid, v in pairs(clients) do
                if v.name == msg.target then
                    targetId = cid
                    break
                end
            end

            if targetId then
                send(targetId, {
                    type="ttt_invite",
                    from=from
                })
            else
                send(id, {type="system", text="User not found"})
            end
        end

        -------------------------------------------------
        -- CLEANUP
        -------------------------------------------------
        for cid, v in pairs(clients) do
            if os.clock() - v.lastSeen > 12 then
                broadcast({type="system", text=v.name.." disconnected"})
                clients[cid] = nil
            end
        end
    end

    ::continue::
end
