-- Lorio (ETFB) - Escape Tsunami for Brainrot Script
-- Full-featured automation with Tsunami ESP, Auto-Farm, and more

getgenv().script_key = "uIeCsXNDMliclXkKGlfNwXHZHFblrJZl"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Load Rayfield Library
local success, Rayfield = pcall(function()
    local code = game:HttpGet('https://sirius.menu/rayfield')
    if not code or code == "" then
        error("Failed to download Rayfield library")
    end
    local loadedFunc = loadstring(code)
    if not loadedFunc then
        error("Failed to compile Rayfield library")
    end
    return loadedFunc()
end)

if not success or not Rayfield or type(Rayfield) ~= "table" then
    error("Cannot continue without UI library")
end

-- Create Window
local Window = Rayfield:CreateWindow({
   Name = "Lorio | ETFB",
   Icon = 0,
   LoadingTitle = "Lorio - Escape Tsunami for Brainrot",
   LoadingSubtitle = "Tsunami ESP & Auto-Farm",
   Theme = "Default",
   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
   ConfigurationSaving = {Enabled = false},
   Discord = {Enabled = false},
   KeySystem = false
})

-- State Management
local state = {
    -- Stats
    brainrotsCollected = 0,
    bubblesSold = 0,
    tsunamisDodged = 0,
    currentSpeed = 0,
    startTime = tick(),

    -- Toggles
    antiAFK = false,
    autoBrainrot = false,
    autoSell = false,
    tsunamiESP = false,
    tsunamiDodge = false,
    speedBoost = false,
    autoLock = false,
    itemESP = false,

    -- Settings
    webhookUrl = "",
    speedMultiplier = 2,
    dodgeDistance = 100,
    minMutationToLock = {"Diamond", "Electric", "Infinity", "Admin"},
    sellMutations = {"Emerald", "Gold", "Blood"},

    -- ESP Objects
    espObjects = {},
    waveESP = {},

    -- Data
    labels = {},
    activeTsunamis = {}
}

-- Mutation Colors (from game dump)
local mutationColors = {
    ["Emerald"] = Color3.fromRGB(0, 255, 0),
    ["Gold"] = Color3.fromRGB(255, 255, 127),
    ["Blood"] = Color3.fromRGB(255, 0, 0),
    ["Diamond"] = Color3.fromRGB(0, 255, 255),
    ["Electric"] = Color3.fromRGB(0, 150, 255),
    ["Radioactive"] = Color3.fromRGB(0, 255, 0),
    ["Admin"] = Color3.fromRGB(255, 0, 255),
    ["UFO"] = Color3.fromRGB(0, 255, 0),
    ["Hacker"] = Color3.fromRGB(0, 255, 0),
    ["Lucky"] = Color3.fromRGB(0, 255, 106),
    ["Money"] = Color3.fromRGB(255, 255, 0),
    ["Gamer"] = Color3.fromRGB(185, 110, 225),
    ["Candy"] = Color3.fromRGB(247, 85, 234),
    ["Doom"] = Color3.fromRGB(255, 120, 0),
    ["Fire"] = Color3.fromRGB(255, 80, 0),
    ["Ice"] = Color3.fromRGB(100, 200, 255),
    ["Phantom"] = Color3.fromRGB(0, 177, 177)
}

-- Helper: Format time
local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Helper: Format numbers
local function formatNumber(num)
    if num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Helper: Create ESP
local function createESP(part, text, color)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "LorioESP"
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = part

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboardGui

    return billboardGui
end

-- Helper: Remove all ESP
local function clearESP()
    for _, esp in pairs(state.espObjects) do
        pcall(function() esp:Destroy() end)
    end
    state.espObjects = {}
end

-- Helper: Remove wave ESP
local function clearWaveESP()
    for _, esp in pairs(state.waveESP) do
        pcall(function() esp:Destroy() end)
    end
    state.waveESP = {}
end

-- Send webhook for rare items
local function sendRareItemWebhook(itemName, mutation, level)
    if state.webhookUrl == "" then return end

    task.defer(function()
        pcall(function()
            local color = mutationColors[mutation] or Color3.fromRGB(255, 255, 255)
            local embed = {
                title = "💎 Rare Brainrot Collected!",
                description = "**Player**: " .. player.DisplayName .. " (@" .. player.Name .. ")",
                color = math.floor(color.R * 255) * 65536 + math.floor(color.G * 255) * 256 + math.floor(color.B * 255),
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
                fields = {
                    {name = "Item", value = itemName, inline = true},
                    {name = "Mutation", value = mutation or "None", inline = true},
                    {name = "Level", value = tostring(level or 1), inline = true}
                }
            }

            local payload = {embeds = {embed}}

            request({
                Url = state.webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- Update character reference
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)

-- Update stats
local function updateStats()
    pcall(function()
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local bubblesValue = leaderstats:FindFirstChild("Bubbles")
            if bubblesValue then
                state.bubblesSold = bubblesValue.Value
            end
        end

        -- Get current speed
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            state.currentSpeed = math.floor(humanoid.WalkSpeed)
        end
    end)
end

-- Auto-collect brainrots
local function collectBrainrots()
    pcall(function()
        if not state.autoBrainrot then return end
        if not hrp then return end

        local bases = Workspace:FindFirstChild("Bases")
        if not bases then return end

        for _, base in pairs(bases:GetChildren()) do
            if base:IsA("Model") then
                for _, item in pairs(base:GetDescendants()) do
                    if item:IsA("Model") and item:FindFirstChild("Brainrot") then
                        -- Check if it's a brainrot
                        local brainrotAttr = item:GetAttribute("BrainrotName")
                        if brainrotAttr then
                            local mutation = item:GetAttribute("Mutation") or "None"
                            local level = item:GetAttribute("Level") or 1

                            -- Teleport to collect
                            if item.PrimaryPart then
                                hrp.CFrame = item.PrimaryPart.CFrame
                                task.wait(0.1)

                                state.brainrotsCollected = state.brainrotsCollected + 1

                                -- Check if rare
                                if mutation == "Infinity" or mutation == "Admin" or mutation == "Diamond" then
                                    sendRareItemWebhook(brainrotAttr, mutation, level)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto-sell brainrots
local function autoSell()
    pcall(function()
        if not state.autoSell then return end

        local Remote = require(RS.Shared.Framework.Network.Remote)
        local sellRemote = Remote.Function("SellAllBrainrots")

        if sellRemote then
            sellRemote:InvokeServer()
        end
    end)
end

-- Auto-lock valuable items
local function autoLockItems()
    pcall(function()
        if not state.autoLock then return end

        local backpack = player:FindFirstChild("Backpack")
        if not backpack then return end

        local Remote = require(RS.Shared.Framework.Network.Remote)
        local lockRemote = Remote.Event("LockItem")

        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local mutation = item:GetAttribute("Mutation") or item:GetAttribute("GearMutation")
                local brainrotName = item:GetAttribute("BrainrotName")

                -- Check if should be locked
                if mutation and table.find(state.minMutationToLock, mutation) then
                    if not item:GetAttribute("Locked") then
                        lockRemote:FireServer(item.Name, true)
                    end
                end

                -- Lock Infinity brainrots
                if brainrotName and item:GetAttribute("BrainrotClass") == "Infinity" then
                    if not item:GetAttribute("Locked") then
                        lockRemote:FireServer(item.Name, true)
                    end
                end
            end
        end
    end)
end

-- Track active tsunamis
local function trackTsunamis()
    pcall(function()
        state.activeTsunamis = {}

        local activeTsunamis = Workspace:FindFirstChild("ActiveTsunamis")
        if not activeTsunamis then return end

        for _, wave in pairs(activeTsunamis:GetChildren()) do
            if wave:IsA("Model") then
                local startTime = wave:GetAttribute("StartTime")
                local startX = wave:GetAttribute("StartX")
                local speed = wave:GetAttribute("Speed")
                local waveType = "Normal"

                if wave:GetAttribute("IsSnakeWave") then
                    waveType = "Snake"
                elseif wave:GetAttribute("IsWonkyWave") then
                    waveType = "Wonky"
                elseif wave:GetAttribute("IsJumpWave") then
                    waveType = "Jump"
                end

                table.insert(state.activeTsunamis, {
                    model = wave,
                    startTime = startTime,
                    startX = startX,
                    speed = speed,
                    waveType = waveType
                })
            end
        end
    end)
end

-- Tsunami ESP
local function updateTsunamiESP()
    pcall(function()
        if not state.tsunamiESP then
            clearWaveESP()
            return
        end

        clearWaveESP()

        for _, waveData in pairs(state.activeTsunamis) do
            local wave = waveData.model
            if wave and wave.PrimaryPart then
                local esp = createESP(
                    wave.PrimaryPart,
                    string.format("%s Wave\nSpeed: %.1f", waveData.waveType, waveData.speed or 0),
                    Color3.fromRGB(255, 100, 100)
                )
                table.insert(state.waveESP, esp)
            end
        end
    end)
end

-- Tsunami auto-dodge
local function tsunamiAutoDodge()
    pcall(function()
        if not state.tsunamiDodge then return end
        if not hrp then return end

        for _, waveData in pairs(state.activeTsunamis) do
            local wave = waveData.model
            if wave and wave.PrimaryPart then
                local wavePos = wave.PrimaryPart.Position
                local playerPos = hrp.Position
                local distance = (wavePos - playerPos).Magnitude

                -- If wave is too close, teleport forward
                if distance < state.dodgeDistance then
                    hrp.CFrame = hrp.CFrame + Vector3.new(-state.dodgeDistance * 2, 0, 0)
                    state.tsunamisDodged = state.tsunamisDodged + 1
                    task.wait(0.5)
                end
            end
        end
    end)
end

-- Item ESP
local function updateItemESP()
    pcall(function()
        if not state.itemESP then
            clearESP()
            return
        end

        clearESP()

        local bases = Workspace:FindFirstChild("Bases")
        if not bases then return end

        for _, base in pairs(bases:GetChildren()) do
            if base:IsA("Model") then
                for _, item in pairs(base:GetDescendants()) do
                    if item:IsA("Model") and item:FindFirstChild("Brainrot") then
                        local mutation = item:GetAttribute("Mutation") or "None"
                        local color = mutationColors[mutation] or Color3.fromRGB(255, 255, 255)
                        local level = item:GetAttribute("Level") or 1

                        if item.PrimaryPart then
                            local esp = createESP(
                                item.PrimaryPart,
                                string.format("%s\nLv.%d", mutation, level),
                                color
                            )
                            table.insert(state.espObjects, esp)
                        end
                    end
                end
            end
        end
    end)
end

-- Speed boost
local function applySpeedBoost()
    pcall(function()
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            if state.speedBoost then
                humanoid.WalkSpeed = 16 * state.speedMultiplier
            else
                humanoid.WalkSpeed = 16
            end
        end
    end)
end

-- === MAIN TAB ===
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

local StatsSection = MainTab:CreateSection("📊 Live Stats")

state.labels.runtime = MainTab:CreateLabel("Runtime: 00:00:00")
state.labels.brainrots = MainTab:CreateLabel("🧠 Brainrots: 0")
state.labels.bubbles = MainTab:CreateLabel("💨 Bubbles: 0")
state.labels.tsunamis = MainTab:CreateLabel("🌊 Tsunamis Dodged: 0")
state.labels.speed = MainTab:CreateLabel("⚡ Speed: 0")

local WebhookSection = MainTab:CreateSection("📊 Webhook")

local WebhookInput = MainTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "https://discord.com/api/webhooks/...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      state.webhookUrl = Text
   end,
})

MainTab:CreateLabel("Rare item notifications (Infinity, Admin, Diamond)")

local AntiAFKSection = MainTab:CreateSection("🛡️ Anti-AFK")

local AntiAFKToggle = MainTab:CreateToggle({
   Name = "🛡️ Prevent AFK Kick",
   CurrentValue = false,
   Flag = "AntiAFK",
   Callback = function(Value)
      state.antiAFK = Value
   end,
})

-- === TSUNAMI TAB ===
local TsunamiTab = Window:CreateTab("🌊 Tsunami", 4483362458)

local TsunamiESPSection = TsunamiTab:CreateSection("👁️ Tsunami ESP")

local TsunamiESPToggle = TsunamiTab:CreateToggle({
    Name = "👁️ Enable Tsunami ESP",
    CurrentValue = false,
    Flag = "TsunamiESP",
    Callback = function(Value)
        state.tsunamiESP = Value
        if not Value then
            clearWaveESP()
        end
    end,
})

local DodgeSection = TsunamiTab:CreateSection("🏃 Auto-Dodge")

local DodgeToggle = TsunamiTab:CreateToggle({
    Name = "🏃 Auto-Dodge Tsunamis",
    CurrentValue = false,
    Flag = "TsunamiDodge",
    Callback = function(Value)
        state.tsunamiDodge = Value
    end,
})

local DodgeSlider = TsunamiTab:CreateSlider({
    Name = "Dodge Distance",
    Range = {50, 300},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 100,
    Flag = "DodgeDistance",
    Callback = function(Value)
        state.dodgeDistance = Value
    end,
})

-- === BRAINROT TAB ===
local BrainrotTab = Window:CreateTab("🧠 Brainrot", 4483362458)

local AutoFarmSection = BrainrotTab:CreateSection("⚡ Auto-Farm")

local AutoBrainrotToggle = BrainrotTab:CreateToggle({
    Name = "⚡ Auto-Collect Brainrots",
    CurrentValue = false,
    Flag = "AutoBrainrot",
    Callback = function(Value)
        state.autoBrainrot = Value
    end,
})

local AutoSellSection = BrainrotTab:CreateSection("💰 Auto-Sell")

local AutoSellToggle = BrainrotTab:CreateToggle({
    Name = "💰 Auto-Sell All Brainrots",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(Value)
        state.autoSell = Value
    end,
})

local AutoLockSection = BrainrotTab:CreateSection("🔒 Auto-Lock")

local AutoLockToggle = BrainrotTab:CreateToggle({
    Name = "🔒 Auto-Lock Valuable Items",
    CurrentValue = false,
    Flag = "AutoLock",
    Callback = function(Value)
        state.autoLock = Value
    end,
})

BrainrotTab:CreateLabel("Locks: Diamond, Electric, Infinity, Admin")

local ItemESPSection = BrainrotTab:CreateSection("👁️ Item ESP")

local ItemESPToggle = BrainrotTab:CreateToggle({
    Name = "👁️ Enable Item ESP",
    CurrentValue = false,
    Flag = "ItemESP",
    Callback = function(Value)
        state.itemESP = Value
        if not Value then
            clearESP()
        end
    end,
})

-- === MISC TAB ===
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

local SpeedSection = MiscTab:CreateSection("⚡ Speed Boost")

local SpeedToggle = MiscTab:CreateToggle({
    Name = "⚡ Enable Speed Boost",
    CurrentValue = false,
    Flag = "SpeedBoost",
    Callback = function(Value)
        state.speedBoost = Value
        applySpeedBoost()
    end,
})

local SpeedSlider = MiscTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = 2,
    Flag = "SpeedMultiplier",
    Callback = function(Value)
        state.speedMultiplier = Value
        if state.speedBoost then
            applySpeedBoost()
        end
    end,
})

-- === ANTI-AFK TASK ===
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:CaptureController()

    while true do
        if state.antiAFK then
            local interval = math.random(60, 120)
            task.wait(interval)

            if state.antiAFK then
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                end)
            end
        else
            task.wait(10)
        end
    end
end)

-- === STATS UPDATE TASK ===
task.spawn(function()
    while task.wait(1) do
        local runtime = tick() - state.startTime

        updateStats()

        pcall(function()
            state.labels.runtime:Set("Runtime: " .. formatTime(runtime))
            state.labels.brainrots:Set("🧠 Brainrots: " .. formatNumber(state.brainrotsCollected))
            state.labels.bubbles:Set("💨 Bubbles: " .. formatNumber(state.bubblesSold))
            state.labels.tsunamis:Set("🌊 Tsunamis Dodged: " .. formatNumber(state.tsunamisDodged))
            state.labels.speed:Set("⚡ Speed: " .. tostring(state.currentSpeed))
        end)
    end
end)

-- === TSUNAMI TRACKING TASK ===
task.spawn(function()
    while task.wait(1) do
        trackTsunamis()
        updateTsunamiESP()
    end
end)

-- === AUTO-FARM TASK ===
task.spawn(function()
    while task.wait(2) do
        collectBrainrots()
        autoLockItems()
    end
end)

-- === AUTO-SELL TASK ===
task.spawn(function()
    while task.wait(30) do
        autoSell()
    end
end)

-- === TSUNAMI DODGE TASK ===
task.spawn(function()
    while task.wait(0.5) do
        tsunamiAutoDodge()
    end
end)

-- === ITEM ESP UPDATE TASK ===
task.spawn(function()
    while task.wait(3) do
        updateItemESP()
    end
end)

-- === SPEED BOOST MONITORING ===
task.spawn(function()
    while task.wait(1) do
        if state.speedBoost then
            applySpeedBoost()
        end
    end
end)

print("=" .. string.rep("=", 60))
print("✅ Lorio ETFB Script Loaded!")
print("=" .. string.rep("=", 60))
print("[INFO] Features:")
print("  • 🌊 Tsunami ESP & Auto-Dodge")
print("  • 🧠 Auto-Collect Brainrots")
print("  • 💰 Auto-Sell & Auto-Lock")
print("  • ⚡ Speed Boost")
print("  • 👁️ Item ESP with Mutations")
print("=" .. string.rep("=", 60))
