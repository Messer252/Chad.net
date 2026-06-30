local PROTOCOL = "chadnet"

-------------------------------------------------
-- MODEM SAFE OPEN
-------------------------------------------------
local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

-------------------------------------------------
-- OPTIONAL MONITOR
-------------------------------------------------
local mon = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if mon then
    mon.setTextScale(0.5)
end

local function out()
    return mon or term
end

-------------------------------------------------
-- STATE
-------------------------------------------------
local user = ""
local chat = {}
local input = ""
local online = {}
local popup = nil
local status = "BOOTING..."

-------------------------------------------------
local function ding()
    if speaker then speaker.playNote("bell", 1, 12) end
end

local function notify(text)
    popup = {text=text, t=os.clock()+3}
end

-------------------------------------------------
-- SAFE DRAW (NEVER BLOCKS NETWORK)
-------------------------------------------------
local function draw()
    local t = out()
    t.clear()
    t.setCursorPos(1,1)

    local w,h = t.getSize()
    local right = math.floor(w*0.7)

    print("Chad.Net V9 | " .. status)
    print("--------------------------------")

    for i = math.max(1,#chat-10), #chat do
        print(chat[i])
    end

    print("--------------------------------")
    write("> " .. input)

    -- USER LIST
    t.setCursorPos(right,2)
    print("ONLINE")
    for i,v in ipairs(online) do
        t.setCursorPos(right,2+i)
        print(v)
    end

    -- POPUP
    if popup and os.clock() < popup.t then
        t.setCursorPos(2,h-2)
        t.clearLine()
        t.write("[MSG] "..popup.text)
    end

    t.setCursorPos(1,h)
    t.clearLine()
    t.write(status)
end

-------------------------------------------------
-- NETWORK LOOP (ISOLATED)
-------------------------------------------------
local function network()
    while true do
        local id,msg = rednet.receive(PROTOCOL)

        if type(msg) == "table" then

            if msg.type == "login_ok" then
                status = "ONLINE"
                notify("Connected")
                ding()

            elseif msg.type == "chat" then
                table.insert(chat,msg.text)
                ding()

            elseif msg.type == "system" then
                notify(msg.text)
                ding()

            elseif msg.type == "user_list" then
                online = msg.users

            elseif msg.type == "ttt_invite" then
                notify("TTT from "..msg.from)
                ding()

            elseif msg.type == "pong" then
                status = "ONLINE"
            end

            draw()
        end
    end
end

-------------------------------------------------
-- INPUT LOOP (ALWAYS RESPONSIVE)
-------------------------------------------------
local function inputLoop()
    while true do
        local e,a = os.pullEvent()

        if e == "char" then
            input = input .. a

        elseif e == "key" and a == keys.enter then
            local msg = input
            input = ""

            if msg:sub(1,5) == "/ttt " then
                rednet.broadcast({
                    type="ttt_challenge",
                    target=msg:sub(6)
                }, PROTOCOL)

            elseif msg == "/users" then
                rednet.broadcast({type="user_list"}, PROTOCOL)

            elseif msg == "/login" then
                notify("No login needed in V9")

            else
                rednet.broadcast({
                    type="chat",
                    text=msg
                }, PROTOCOL)
            end

            draw()
        end
    end
end

-------------------------------------------------
-- HEARTBEAT
-------------------------------------------------
local function ping()
    while true do
        rednet.broadcast({type="ping"}, PROTOCOL)
        sleep(2)
    end
end

-------------------------------------------------
-- BOOT SEQUENCE (IMPORTANT FIX)
-------------------------------------------------
status = "CONNECTING..."
draw()

rednet.broadcast({type="ping"}, PROTOCOL)

parallel.waitForAny(network, inputLoop, ping)
