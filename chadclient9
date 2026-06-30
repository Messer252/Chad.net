local PROTOCOL = "chadnet"

-------------------------------------------------
-- MODEM
-------------------------------------------------
local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

-------------------------------------------------
-- OPTIONAL MONITOR MIRROR
-------------------------------------------------
local mon = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if mon then
    mon.setTextScale(0.5)
end

local function out()
    return mon or term
end

local function ding()
    if speaker then speaker.playNote("bell", 1, 12) end
end

-------------------------------------------------
-- STATE
-------------------------------------------------
local user = ""
local chat = {}
local input = ""
local screen = "chat"
local online = {}
local popup = nil

-------------------------------------------------
local function notify(text)
    popup = {text=text, t=os.clock()+3}
end

-------------------------------------------------
local function draw()
    local t = out()
    t.clear()
    t.setCursorPos(1,1)

    local w,h = t.getSize()
    local right = math.floor(w*0.7)

    print("Chad.Net | "..user.." | ONLINE")
    print("--------------------------------")

    if screen == "chat" then
        for i = math.max(1,#chat-10), #chat do
            print(chat[i])
        end
    end

    print("--------------------------------")
    write("> "..input)

    -- USER LIST (RIGHT SIDE)
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
    t.write("READY")
end

-------------------------------------------------
-- RECEIVE
-------------------------------------------------
local function recv()
    while true do
        local _,msg = rednet.receive(PROTOCOL)

        if msg.type == "login_ok" then
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
            notify("TTT invite from "..msg.from)
            ding()
        end

        draw()
    end
end

-------------------------------------------------
-- INPUT
-------------------------------------------------
local function inputLoop()
    draw()

    while true do
        local e,a = os.pullEvent()

        if e == "char" then
            input = input .. a

        elseif e == "key" and a == keys.enter then
            local msg = input
            input = ""

            if msg == "/users" then
                rednet.broadcast({type="user_list"}, PROTOCOL)

            elseif msg:sub(1,5) == "/ttt " then
                rednet.broadcast({
                    type="ttt_challenge",
                    target=msg:sub(6)
                }, PROTOCOL)

            else
                rednet.broadcast({type="chat", text=msg}, PROTOCOL)
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

parallel.waitForAny(recv, inputLoop, ping)
