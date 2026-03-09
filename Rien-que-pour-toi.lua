-- Lorio (BGSI) - Spring Event Script
-- Simplified version with Main + Spring Event tabs only

getgenv().script_key = "uIeCsXNDMliclXkKGlfNwXHZHFblrJZl"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
   Name = "Lorio | Spring Event",
   Icon = 0,
   LoadingTitle = "Lorio - Spring Event",
   LoadingSubtitle = "Auto Event Farming",
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
    bubbles = 0,
    hatches = 0,
    petals = "0",
    startTime = tick(),

    -- Toggles
    antiAFK = false,
    autoCollectFlowers = false,
    autoFlowersEgg = false,
    autoWheelSpin = false,
    autoShopBuy = false,

    -- Settings
    flowersEggChoice = "Spring Egg",
    lastFlowerEggTeleport = 0,
    webhookUrl = "",

    -- Data
    currentEggs = {},
    labels = {}
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

-- Helper: Teleport to model
local function tpToModel(model)
    pcall(function()
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local plate = model:FindFirstChild("Plate")
        local platform = model:FindFirstChild("Platform")

        if plate and plate:IsA("BasePart") then
            hrp.CFrame = plate.CFrame + Vector3.new(0, 5, 0)
        elseif platform and platform:IsA("BasePart") then
            hrp.CFrame = platform.CFrame + Vector3.new(0, 5, 0)
        else
            local primary = model:GetPivot()
            if primary then
                hrp.CFrame = primary + Vector3.new(0, 5, 0)
            end
        end
    end)
end

-- Scan for spring eggs
local function scanSpringEggs()
    local eggs = {}
    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if not rendered then return end

        for _, folder in pairs(rendered:GetChildren()) do
            if folder:IsA("Folder") and folder.Name:find("Chunker") then
                for _, item in pairs(folder:GetDescendants()) do
                    if item:IsA("Model") then
                        -- Check for Spring Egg, Petal Egg, or Forest Egg
                        if item.Name == "Spring Egg" or item.Name == "Petal Egg" or item.Name == "Forest Egg" then
                            table.insert(eggs, {
                                name = item.Name,
                                instance = item
                            })
                        end
                    end
                end
            end
        end
    end)
    state.currentEggs = eggs
    return eggs
end

-- Send webhook for Petal Spirit pet
local function sendPetalSpiritWebhook()
    if state.webhookUrl == "" then return end

    task.defer(function()
        pcall(function()
            local embed = {
                title = "馃尭 Petal Spirit Hatched!",
                description = "**Player**: " .. player.DisplayName .. " (@" .. player.Name .. ")",
                color = 16761035, -- Pink color
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
                fields = {
                    {name = "Pet", value = "馃尭 Petal Spirit", inline = true},
                    {name = "Source", value = "Flower Collection", inline = true}
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

-- Update stats from game
local function updateStats()
    pcall(function()
        -- Get leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local bubblesValue = leaderstats:FindFirstChild("Bubbles")
            local hatchesValue = leaderstats:FindFirstChild("Hatches")
            if bubblesValue then
                state.bubbles = bubblesValue.Value
            end
            if hatchesValue then
                state.hatches = hatchesValue.Value
            end
        else
            print("[DEBUG] leaderstats not found in player")
        end

        -- Get currencies (petals)
        local main = playerGui:FindFirstChild("Main")
        if not main then
            return
        end

        local right = main:FindFirstChild("Right")
        if not right then
            return
        end

        local currencies = right:FindFirstChild("Currencies")
        if currencies then
            for _, item in pairs(currencies:GetChildren()) do
                if item:IsA("Frame") and item.Name == "Petals" then
                    local amount = item:FindFirstChild("Amount")
                    if amount and amount:IsA("TextLabel") then
                        state.petals = amount.Text
                    end
                end
            end
        end
    end)
end

-- Monitor for Petal Spirit hatch
-- HOW IT WORKS:
-- 1. When you collect flowers (PickPetal), the server randomly gives rewards
-- 2. If you get Petal Spirit, the server fires "HatchEgg" event to client
-- 3. The HatchEgg event contains: hatchData.Pets[n].Pet.Name
-- 4. We listen to ALL HatchEgg events and check if any pet is "Petal Spirit"
-- 5. Note: HatchEgg is used for BOTH egg hatching AND flower rewards!
local function monitorPetalSpirit()
    pcall(function()
        local Remote = require(RS.Shared.Framework.Network.Remote)

        print("[DEBUG] Petal Spirit monitor started")

        -- Listen to HatchEgg event for Petal Spirit
        Remote.Event("HatchEgg"):Connect(function(hatchData)
            if hatchData and hatchData.Pets then
                -- Check each pet in the hatch data
                for i, petEntry in pairs(hatchData.Pets) do
                    if petEntry and petEntry.Pet and not petEntry.Deleted then
                        local pet = petEntry.Pet

                        if pet.Name == "Petal Spirit" then
                            print("馃尭馃尭馃尭 [Petal Spirit] DETECTED! 馃尭馃尭馃尭")
                            sendPetalSpiritWebhook()
                        end
                    end
                end
            end
        end)
    end)
end

-- === MAIN TAB ===
local MainTab = Window:CreateTab("馃彔 Main", 4483362458)

local StatsSection = MainTab:CreateSection("馃搳 Live Stats")

state.labels.runtime = MainTab:CreateLabel("Runtime: 00:00:00")
state.labels.bubbles = MainTab:CreateLabel("Bubbles: 0")
state.labels.hatches = MainTab:CreateLabel("Hatches: 0")
state.labels.petals = MainTab:CreateLabel("馃尭 Petals: 0")

local WebhookSection = MainTab:CreateSection("馃搳 Webhook")

local WebhookInput = MainTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "https://discord.com/api/webhooks/...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      state.webhookUrl = Text
   end,
})

MainTab:CreateLabel("Petal Spirit notifications")

local AntiAFKSection = MainTab:CreateSection("馃洝锔� Anti-AFK")

local AntiAFKToggle = MainTab:CreateToggle({
   Name = "馃洝锔� Prevent AFK Kick",
   CurrentValue = false,
   Flag = "AntiAFK",
   Callback = function(Value)
      state.antiAFK = Value
   end,
})

-- === SPRING EVENT TAB ===
local EventTab = Window:CreateTab("馃尭 Spring Event", 4483362458)

local FlowerSection = EventTab:CreateSection("馃尭 Auto Collect Flowers")

local AutoFlowersToggle = EventTab:CreateToggle({
    Name = "馃尭 Auto Collect Flowers",
    CurrentValue = false,
    Flag = "AutoFlowers",
    Callback = function(Value)
        state.autoCollectFlowers = Value
    end,
})

local FlowerEggSection = EventTab:CreateSection("馃尭馃 Auto Flowers + Egg")

local FlowerEggDropdown = EventTab:CreateDropdown({
    Name = "Select Egg",
    Options = {"Spring Egg", "Petal Egg", "Forest Egg"},
    CurrentOption = {"Spring Egg"},
    MultipleOptions = false,
    Flag = "FlowerEgg",
    Callback = function(Option)
        if Option and Option[1] then
            state.flowersEggChoice = Option[1]
        end
    end,
})

local AutoFlowersEggToggle = EventTab:CreateToggle({
    Name = "馃尭馃 Auto Flowers + Egg",
    CurrentValue = false,
    Flag = "AutoFlowersEgg",
    Callback = function(Value)
        state.autoFlowersEgg = Value
        state.lastFlowerEggTeleport = 0
    end,
})

local ShopSection = EventTab:CreateSection("馃洅 Auto Shop")

local AutoShopToggle = EventTab:CreateToggle({
    Name = "馃洅 Auto Buy Pet (Item #6)",
    CurrentValue = false,
    Flag = "AutoShop",
    Callback = function(Value)
        state.autoShopBuy = Value
    end,
})

local WheelSection = EventTab:CreateSection("馃幇 Auto Wheel Spin")

local AutoWheelToggle = EventTab:CreateToggle({
    Name = "馃幇 Auto Wheel Spin",
    CurrentValue = false,
    Flag = "AutoWheel",
    Callback = function(Value)
        state.autoWheelSpin = Value
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
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
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
            state.labels.bubbles:Set("馃挩 Bubbles: " .. formatNumber(state.bubbles))
            state.labels.hatches:Set("馃 Hatches: " .. formatNumber(state.hatches))
            state.labels.petals:Set("馃尭 Petals: " .. state.petals)
        end)
    end
end)

-- === EGG SCANNER TASK ===
task.spawn(function()
    while task.wait(2) do
        scanSpringEggs()
    end
end)

-- === AUTO EGG HATCHING LOOP (DEDICATED - NOT BLOCKED BY ANYTHING) ===
task.spawn(function()
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(0.3) do
        -- Auto Flowers + Egg: EGG HATCHING ONLY (spam constantly)
        if state.autoFlowersEgg then
            pcall(function()
                local currentTime = tick()
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if not hrp then return end

                -- Find selected egg
                local egg = nil
                for _, eggModel in pairs(state.currentEggs) do
                    if eggModel.name == state.flowersEggChoice then
                        egg = eggModel.instance
                        break
                    end
                end

                if egg then
                    -- Teleport to egg every 10 seconds
                    if currentTime - state.lastFlowerEggTeleport >= 10 then
                        tpToModel(egg)
                        state.lastFlowerEggTeleport = currentTime
                        print("[DEBUG] Teleported to", state.flowersEggChoice)
                    end

                    -- SPAM EGG OPENING (99 eggs every 0.3 seconds)
                    Remote:FireServer("HatchEgg", state.flowersEggChoice, 99)
                end
            end)
        end
    end
end)

-- === AUTO FLOWER COLLECTION LOOP (SEPARATE FROM EGG HATCHING) ===
task.spawn(function()
    while task.wait(0.1) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1) continue end

        -- Auto Collect Flowers (Simple mode - just TP and collect)
        if state.autoCollectFlowers and not state.autoFlowersEgg then
            pcall(function()
                local spring = Workspace:FindFirstChild("Spring")
                if not spring then return end

                local pickPetals = spring:FindFirstChild("PickPetals")
                if not pickPetals then return end

                for _, flower in pairs(pickPetals:GetChildren()) do
                    if flower:IsA("Model") then
                        local root = flower:FindFirstChild("Root")
                        if root and root:IsA("BasePart") then
                            hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
                        end
                    end
                end
            end)
        end

        -- Auto Flowers + Egg: FLOWER COLLECTION ONLY
        if state.autoFlowersEgg then
            pcall(function()
                local spring = Workspace:FindFirstChild("Spring")
                if not spring then return end

                local pickPetals = spring:FindFirstChild("PickPetals")
                if not pickPetals then return end

                local flowerCount = 0
                for _, flower in pairs(pickPetals:GetChildren()) do
                    if flower:IsA("Model") then
                        local root = flower:FindFirstChild("Root")
                        if root and root:IsA("BasePart") then
                            flowerCount = flowerCount + 1
                            local originalCFrame = root.CFrame
                            root.CFrame = hrp.CFrame + Vector3.new(0, -1, 0)
                            task.wait(0.1)
                            root.CFrame = originalCFrame
                        end
                    end
                end
            end)
        end
    end
end)

-- === AUTO SHOP & WHEEL LOOP ===
task.spawn(function()
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(1) do
        -- Auto Shop Buy (Item #6 - Pet)
        if state.autoShopBuy then
            pcall(function()
                Remote:FireServer("BuyShopItem", "spring-shop", 6, false)
            end)
        end

        -- Auto Wheel Spin
        if state.autoWheelSpin then
            pcall(function()
                Remote:FireServer("SpinWheel", "spring-wheel")
            end)
        end
    end
end)

-- Start monitoring for Petal Spirit
monitorPetalSpirit()

print("=" .. string.rep("=", 60))
print("Lorio Spring Event Script Loaded!")
print("=" .. string.rep("=", 60))
print("[INFO] Separate loops: Egg hatching NEVER blocked by flowers!")
print("[DEBUG] Only important events logged:")
print("Petal Spirit detection")
print("Egg teleports (every 10 seconds)")
print("=" .. string.rep("=", 60))
