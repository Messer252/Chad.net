-- OUTLOOK CLIENT (ULTRA STABLE)

local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

--------------------------------------------------
-- SERVER DISCOVERY (NO HARDCODING)
--------------------------------------------------
rednet.broadcast({type="ping"})
local SERVER_ID = nil

local timer = os.startTimer(2)

while true do
    local event, a, b = os.pullEvent()

    if event == "rednet_message" then
        local sender, msg = a, b
        if type(msg) == "table" then
            SERVER_ID = sender
            break
        end
    elseif event == "timer" and a == timer then
        break
    end
end

if not SERVER_ID then
    error("No server found")
end

--------------------------------------------------
-- SAFE REQUEST SYSTEM
--------------------------------------------------
local function request(data)
    data._id = tostring(os.epoch("utc")) .. tostring(math.random(1000,9999))

    rednet.send(SERVER_ID, data)

    local timeout = os.startTimer(5)

    while true do
        local event, a, b = os.pullEvent()

        if event == "rednet_message" then
            local sender, msg = a, b

            if sender == SERVER_ID and type(msg) == "table" then
                if msg.request == data._id then
                    return msg
                end
            end

        elseif event == "timer" and a == timeout then
            return { ok=false, err="timeout" }
        end
    end
end

--------------------------------------------------
-- LOGIN
--------------------------------------------------
local token, user

local function login()
    term.clear()
    term.setCursorPos(1,1)

    print("=== LOGIN ===")

    print("Username:")
    local u = read()

    print("Password:")
    local p = read("*")

    local res = request({
        type="login",
        user=u,
        pass=p
    })

    if res.ok then
        token = res.token
        user = u
        return true
    end

    print(res.err or "failed")
    sleep(2)
    return false
end

--------------------------------------------------
-- INBOX
--------------------------------------------------
local function inbox()
    local res = request({
        type="inbox",
        token=token
    })

    term.clear()
    term.setCursorPos(1,1)

    if not res.ok then
        print("Failed to load inbox")
        sleep(2)
        return
    end

    local mail = res.data

    print("=== INBOX ===\n")

    if #mail == 0 then
        print("No mail")
        read()
        return
    end

    for i,v in ipairs(mail) do
        print(i .. ". " .. v.subject)
        print("From: " .. v.from)
        print("----------------")
    end

    read()
end

--------------------------------------------------
-- COMPOSE
--------------------------------------------------
local function compose()
    term.clear()
    term.setCursorPos(1,1)

    print("To:")
    local to = read()

    print("Subject:")
    local subject = read()

    print("Message:")
    local body = read()

    local res = request({
        type="send",
        token=token,
        to=to,
        subject=subject,
        body=body
    })

    print(res.ok and "Sent" or "Failed")
    sleep(1)
end

--------------------------------------------------
-- MAIN UI
--------------------------------------------------
while true do
    if login() then
        while true do
            term.clear()
            term.setCursorPos(1,1)

            print("=== OUTLOOK ===")
            print("User:", user)
            print("----------------")
            print("1. Inbox")
            print("2. Compose")
            print("3. Logout")

            local c = read()

            if c == "1" then inbox()
            elseif c == "2" then compose()
            elseif c == "3" then break end
        end
    end
end
