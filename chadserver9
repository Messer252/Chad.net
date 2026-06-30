local PROTOCOL = "chadnet"

local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

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
    if type(msg) ~= "table" then goto continue end

    -------------------------------------------------
    -- LOGIN (NO PASSWORD SYSTEM)
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
    if msg.type == "chat" then
        local u = clients[id]
        if u then
            broadcast({type="chat", text="["..u.name.."]: "..msg.text})
        end
    end

    -------------------------------------------------
    -- USER LIST
    -------------------------------------------------
    if msg.type == "user_list" then
        send(id, {type="user_list", users=getUsers()})
    end

    -------------------------------------------------
    -- TTT INVITE (FIXED)
    -------------------------------------------------
    if msg.type == "ttt_challenge" then
        local from = clients[id] and clients[id].name
        local target = msg.target

        local targetId
        for cid, v in pairs(clients) do
            if v.name == target then
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

    ::continue::
end
