--[[
    FISHING MONITOR - IN-GAME EXECUTION
    ===================================
    Run this in your Roblox executor WHILE IN THE GAME

    INSTRUCTIONS:
    1. Load this script in your executor
    2. Execute it
    3. Go to Fisher's Island manually
    4. MANUALLY fish ONE time (click the fishing rod, cast, wait for bite, reel in)
    5. Send me the file: fishing_monitor_output.txt

    This will capture exactly what remote events are fired during successful fishing!
]]

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- File logging setup
local logFileName = "fishing_monitor_output.txt"
local logBuffer = ""

-- Log function - writes to both console and file
local function log(message)
    print(message)
    logBuffer = logBuffer .. message .. "\n"
    writefile(logFileName, logBuffer)
end

-- Clear/create log file
writefile(logFileName, "")
logBuffer = ""

log("\n" .. string.rep("=", 80))
log("🎣 FISHING MONITOR - ACTIVE")
log(string.rep("=", 80))
log("Instructions:")
log("1. Go to Fisher's Island")
log("2. MANUALLY fish ONE time (full cycle: cast → wait → reel)")
log("3. Send the file: " .. logFileName)
log(string.rep("=", 80) .. "\n")

-- Find the Remote event
local Remote = RS:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")

log("✅ Found Remote event, hooking into FireServer...")
log("📡 Now monitoring ALL remote events...\n")

-- Store original FireServer
local originalFireServer = Remote.FireServer

-- Fishing-related events to monitor
local fishingEvents = {
    "SetEquippedRod",
    "EquipRod",
    "UnequipRod",
    "BeginCastCharge",
    "FinishCastCharge",
    "Reel",
    "CatchFish",
    "FishingBite",
    "FishCaught",
    "StartFishing",
    "StopFishing"
}

local eventCount = 0

-- Hook FireServer to log fishing events
Remote.FireServer = function(self, eventName, ...)
    -- Check if this is a fishing-related event
    local isFishingEvent = false
    for _, fishEvent in ipairs(fishingEvents) do
        if eventName == fishEvent then
            isFishingEvent = true
            break
        end
    end

    if isFishingEvent then
        eventCount = eventCount + 1
        log(string.rep("-", 80))
        log(string.format("🎣 EVENT #%d: %s", eventCount, tostring(eventName)))
        log(string.rep("-", 80))

        local args = {...}
        if #args > 0 then
            log("📋 Parameters:")
            for i, arg in ipairs(args) do
                local argType = type(arg)
                local argValue = tostring(arg)

                -- Special formatting for different types
                if argType == "Vector3" then
                    argValue = string.format("Vector3(%s, %s, %s)", arg.X, arg.Y, arg.Z)
                elseif argType == "CFrame" then
                    argValue = string.format("CFrame(Position: %s, %s, %s)", arg.Position.X, arg.Position.Y, arg.Position.Z)
                elseif argType == "table" then
                    argValue = game:GetService("HttpService"):JSONEncode(arg)
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
            log(string.format("📍 Player Position: %.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z))
        end

        log(string.format("⏰ Timestamp: %s", os.date("%H:%M:%S")))
        log(string.rep("-", 80) .. "\n")
    end

    -- Call original function
    return originalFireServer(self, eventName, ...)
end

log("✅ Hook installed successfully!")
log("🎣 Waiting for fishing events...")
log("👉 Go fish manually NOW!\n")

-- Also monitor player's equipped tool
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function(char)
    character = char
end)

-- Monitor tool equipped
local function monitorTools()
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.ToolEquipped:Connect(function(tool)
                log(string.rep("=", 80))
                log("🔧 TOOL EQUIPPED: " .. tool.Name)
                log(string.rep("=", 80) .. "\n")
            end)

            humanoid.ToolUnequipped:Connect(function(tool)
                log(string.rep("=", 80))
                log("🔧 TOOL UNEQUIPPED: " .. tool.Name)
                log(string.rep("=", 80) .. "\n")
            end)
        end
    end
end

monitorTools()

-- Monitor when fishing GUI appears (if it exists)
task.spawn(function()
    local PlayerGui = player:WaitForChild("PlayerGui")

    PlayerGui.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ScreenGui") or descendant:IsA("Frame") then
            if string.find(string.lower(descendant.Name), "fish") or string.find(string.lower(descendant.Name), "reel") then
                log(string.rep("=", 80))
                log("🎮 FISHING GUI DETECTED: " .. descendant:GetFullName())
                log(string.rep("=", 80) .. "\n")
            end
        end
    end)
end)

log("✅ Tool monitor installed!")
log("✅ GUI monitor installed!")
log("\n🎣 ALL SYSTEMS READY - Now manually fish and watch the console!\n")
log("📄 Output will be saved to: " .. logFileName)

