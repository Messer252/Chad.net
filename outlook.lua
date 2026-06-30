-- OUTLOOK CLIENT (STABLE FULL BUILD)

local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

math.randomseed(os.epoch("utc"))

--------------------------------------------------
-- SERVER ID (NO DISCOVERY = NO CRASHES)
--------------------------------------------------
local SERVER_FILE = "server_id.txt"
local SERVER_ID = nil

-- Load saved server id
if fs.exists(SERVER_FILE) then
    local f = fs.open(SERVER_FILE, "r")
    SERVER_ID = tonumber(f.readAll())
    f.close()
end

-- If missing, ask once
if not SERVER_ID then
    term.clear()
    term.setCursorPos(1,1)

    print("=== FIRST TIME SETUP ===")
    print("Enter SERVER ID (shown on server computer):")

    SERVER_ID = tonumber(read())

    if not SERVER_ID then
        error("Invalid server ID")
    end

    local f = fs.open(SERVER_FILE, "w")
    f.write(tostring(SERVER_ID))
    f.close()
end

--------------------------------------------------
-- SAFE REQUEST SYSTEM (NO HANGS)
--------------------------------------------------
local function request(data)
    local reqId = tostring(os.epoch("utc")) .. tostring(math.random(1000,9999))
    data._id = reqId

    rednet.send(SERVER_ID, data)

    local timeout = os.startTimer(5)

    while true do
        local event, a, b = os.pullEvent()

        if event == "rednet_message" then
            local sender, msg = a, b

            if sender == SERVER_ID and type(msg) == "table" then
                if msg.request == reqId then
                    return msg
                end
            end

        elseif event == "timer" and a == timeout then
            return { ok = false, err = "timeout" }
        end
    end
end

--------------------------------------------------
-- LOGIN STATE
--------------------------------------------------
local token = nil
local user = nil

--------------------------------------------------
-- LOGIN
--------------------------------------------------
local function login()
    term.clear()
    term.setCursorPos(1,1)

    print("=== OUTLOOK LOGIN ===")

    print("Username:")
    local u = read()

    print("Password:")
    local p = read("*")

    local res = request({
        type = "login",
        user = u,
        pass = p
    })

    if res.ok then
        token = res.token
        user = u
        return true
    end

    print(res.err or "Login failed")
    sleep(2)
    return false
end

--------------------------------------------------
-- INBOX
--------------------------------------------------
local function inbox()
    local res = request({
        type = "inbox",
        token = token
    })

    term.clear()
    term.setCursorPos(1,1)

    if not res.ok then
        print("Failed to load inbox")
        sleep(2)
        return
    end

    local mail = res.data or {}

    print("=== INBOX ===\n")

    if #mail == 0 then
        print("No mail.")
        read()
        return
    end

    for i, m in ipairs(mail) do
        print(i .. ". " .. (m.subject or "No Subject"))
        print("From: " .. (m.from or "?"))
        print("------------------------")
    end

    print("Press Enter...")
    read()
end

--------------------------------------------------
-- COMPOSE EMAIL
--------------------------------------------------
local function compose()
    term.clear()
    term.setCursorPos(1,1)

    print("=== COMPOSE ===")

    print("To:")
    local to = read()

    print("Subject:")
    local subject = read()

    print("Message:")
    local body = read()

    local res = request({
        type = "send",
        token = token,
        to = to,
        subject = subject,
        body = body
    })

    if res.ok then
        print("Sent!")
    else
        print("Failed to send")
    end

    sleep(1)
end

--------------------------------------------------
-- MAIN UI LOOP
--------------------------------------------------
while true do
    if login() then
        while true do
            term.clear()
            term.setCursorPos(1,1)

            print("=== OUTLOOK MAIL ===")
            print("User:", user)
            print("----------------------")
            print("1. Inbox")
            print("2. Compose")
            print("3. Logout")

            local c = read()

            if c == "1" then
                inbox()
            elseif c == "2" then
                compose()
            elseif c == "3" then
                break
            end
        end
    end
end
