--[[
    FISHING MONITOR - IN-GAME EXECUTION
    ===================================
    Run this in your Roblox executor WHILE IN THE GAME

    INSTRUCTIONS:
    1. Load this script in your executor
    2. Execute it
    3. Go to Fisher's Island manually
    4. MANUALLY fish ONE time (click the fishing rod, cast, wait for bite, reel in)
    5. Check console output
    6. Copy ALL console output and send to me

    This will capture exactly what remote events are fired during successful fishing!
]]

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("\n" .. string.rep("=", 80))
print("🎣 FISHING MONITOR - ACTIVE")
print(string.rep("=", 80))
print("Instructions:")
print("1. Go to Fisher's Island")
print("2. MANUALLY fish ONE time (full cycle: cast → wait → reel)")
print("3. Copy ALL console output after fishing")
print(string.rep("=", 80) .. "\n")

-- Find the Remote event
local Remote = RS:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")

print("✅ Found Remote event, hooking into FireServer...")
print("📡 Now monitoring ALL remote events...\n")

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
        print(string.rep("-", 80))
        print(string.format("🎣 EVENT #%d: %s", eventCount, tostring(eventName)))
        print(string.rep("-", 80))

        local args = {...}
        if #args > 0 then
            print("📋 Parameters:")
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

                print(string.format("   [%d] (%s) = %s", i, argType, argValue))
            end
        else
            print("📋 No parameters")
        end

        -- Show player position
        local player = Players.LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            print(string.format("📍 Player Position: %.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z))
        end

        print(string.format("⏰ Timestamp: %s", os.date("%H:%M:%S")))
        print(string.rep("-", 80) .. "\n")
    end

    -- Call original function
    return originalFireServer(self, eventName, ...)
end

print("✅ Hook installed successfully!")
print("🎣 Waiting for fishing events...")
print("👉 Go fish manually NOW!\n")

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
                print(string.rep("=", 80))
                print("🔧 TOOL EQUIPPED: " .. tool.Name)
                print(string.rep("=", 80) .. "\n")
            end)

            humanoid.ToolUnequipped:Connect(function(tool)
                print(string.rep("=", 80))
                print("🔧 TOOL UNEQUIPPED: " .. tool.Name)
                print(string.rep("=", 80) .. "\n")
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
                print(string.rep("=", 80))
                print("🎮 FISHING GUI DETECTED: " .. descendant:GetFullName())
                print(string.rep("=", 80) .. "\n")
            end
        end
    end)
end)

print("✅ Tool monitor installed!")
print("✅ GUI monitor installed!")
print("\n🎣 ALL SYSTEMS READY - Now manually fish and watch the console!\n")
