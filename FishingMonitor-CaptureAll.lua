--[[
    FISHING MONITOR - CAPTURE ALL EVENTS
    =====================================
    This will capture EVERY remote event that fires, not just fishing ones

    INSTRUCTIONS:
    1. Load this script in your executor
    2. Execute it
    3. Wait 2 seconds (let other events settle)
    4. Go to Fisher's Island
    5. MANUALLY fish ONE complete cycle (equip → cast → wait → reel)
    6. Send me: fishing_monitor_all_events.txt
]]

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- File logging setup
local logFileName = "fishing_monitor_all_events.txt"
local logBuffer = ""

-- Log function
local function log(message)
    print(message)
    logBuffer = logBuffer .. message .. "\n"
    writefile(logFileName, logBuffer)
end

-- Clear/create log file
writefile(logFileName, "")
logBuffer = ""

log("\n" .. string.rep("=", 80))
log("🎣 FISHING MONITOR - CAPTURE ALL MODE")
log(string.rep("=", 80))
log("⚠️  WARNING: This will log EVERY remote event!")
log("Instructions:")
log("1. Wait 2 seconds after running this")
log("2. Go to Fisher's Island (if not already there)")
log("3. MANUALLY fish ONE time (equip → cast → wait → reel)")
log("4. Send the file: " .. logFileName)
log(string.rep("=", 80) .. "\n")

-- Find the Remote event
local Remote = RS:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")

log("✅ Found Remote event, hooking into FireServer...")
log("📡 Now monitoring ALL remote events...\n")
log("⏰ Script started at: " .. os.date("%H:%M:%S"))
log("⏳ Waiting 2 seconds before active monitoring...\n")

task.wait(2)

log("🟢 ACTIVE MONITORING STARTED - Now fish manually!\n")

-- Store original FireServer
local originalFireServer = Remote.FireServer

local eventCount = 0
local startTime = tick()

-- Hook FireServer to log ALL events
Remote.FireServer = function(self, eventName, ...)
    eventCount = eventCount + 1
    local elapsedTime = tick() - startTime

    log(string.rep("-", 80))
    log(string.format("📡 EVENT #%d (T+%.2fs): %s", eventCount, elapsedTime, tostring(eventName)))
    log(string.rep("-", 80))

    local args = {...}
    if #args > 0 then
        log("📋 Parameters (" .. #args .. " total):")
        for i, arg in ipairs(args) do
            local argType = type(arg)
            local argValue = tostring(arg)

            -- Special formatting for different types
            if argType == "Vector3" then
                argValue = string.format("Vector3(%.2f, %.2f, %.2f)", arg.X, arg.Y, arg.Z)
            elseif argType == "CFrame" then
                argValue = string.format("CFrame(Pos: %.2f, %.2f, %.2f)", arg.Position.X, arg.Position.Y, arg.Position.Z)
            elseif argType == "table" then
                local success, encoded = pcall(function()
                    return game:GetService("HttpService"):JSONEncode(arg)
                end)
                if success then
                    argValue = encoded
                else
                    argValue = "{table - cannot encode}"
                end
            elseif argType == "boolean" then
                argValue = tostring(arg)
            elseif argType == "number" then
                argValue = tostring(arg)
            end

            log(string.format("   [%d] (%s) = %s", i, argType, argValue))
        end
    else
        log("📋 No parameters")
    end

    -- Show player position
    local player = Players.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        log(string.format("📍 Player Pos: %.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z))
    end

    log(string.format("⏰ Time: %s", os.date("%H:%M:%S")))
    log(string.rep("-", 80) .. "\n")

    -- Call original function
    return originalFireServer(self, eventName, ...)
end

log("✅ Hook installed successfully!")
log("🎣 ALL events will be logged - go fish!\n")

-- Monitor player's equipped tool
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function(char)
    character = char
end)

local function monitorTools()
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.ToolEquipped:Connect(function(tool)
                log(string.rep("=", 80))
                log("🔧 TOOL EQUIPPED: " .. tool.Name)
                log("⏰ Time: " .. os.date("%H:%M:%S"))
                log(string.rep("=", 80) .. "\n")
            end)

            humanoid.ToolUnequipped:Connect(function(tool)
                log(string.rep("=", 80))
                log("🔧 TOOL UNEQUIPPED: " .. tool.Name)
                log("⏰ Time: " .. os.date("%H:%M:%S"))
                log(string.rep("=", 80) .. "\n")
            end)
        end
    end
end

monitorTools()

-- Monitor fishing GUI
task.spawn(function()
    local PlayerGui = player:WaitForChild("PlayerGui")

    PlayerGui.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ScreenGui") or descendant:IsA("Frame") or descendant:IsA("ImageButton") then
            local name = string.lower(descendant.Name)
            if string.find(name, "fish") or string.find(name, "reel") or string.find(name, "rod") or string.find(name, "cast") then
                log(string.rep("=", 80))
                log("🎮 FISHING GUI ELEMENT: " .. descendant:GetFullName())
                log("   Type: " .. descendant.ClassName)
                log("⏰ Time: " .. os.date("%H:%M:%S"))
                log(string.rep("=", 80) .. "\n")
            end
        end
    end)
end)

log("✅ Tool monitor installed!")
log("✅ GUI monitor installed!")
log("\n🎣 READY - Fish manually and ALL events will be logged!\n")
log("📄 Output saving to: " .. logFileName .. "\n")
