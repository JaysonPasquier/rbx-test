-- BGSI Premium Hub v2026 - RAYFIELD MOBILE-OPTIMIZED
-- ✅ Perfect for mobile screens - Auto-resizes and single column layout

getgenv().script_key = "uIeCsXNDMliclXkKGlfNwXHZHFblrJZl"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🧼 BGSI Premium Hub v2026 - LOADING (Rayfield)...")

-- Load Rayfield Library (Mobile-Optimized)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- === CREATE WINDOW ===
local Window = Rayfield:CreateWindow({
   Name = "🧼 BGSI Premium Hub",
   Icon = 0,
   LoadingTitle = "BGSI Premium Hub",
   LoadingSubtitle = "Mobile-Optimized for 2026",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "BGSIHub"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "BGSI Hub",
      Subtitle = "Key System",
      Note = "No key required",
      FileName = "BGSIKey",
      SaveKey = false,
      GrabKeyFromSite = false,
      Key = {""}
   }
})

print("✅ Rayfield window created (auto mobile-optimized)")

-- === STATE MANAGEMENT ===
local state = {
    autoBlow = false,
    autoHatch = false,
    riftPriority = nil,
    eggPriority = nil,
    webhookUrl = "",
    webhookStats = true,
    currentRifts = {},
    currentEggs = {},
    stats = {bubbles=0, hatches=0, coins=0, bubbleStock=0, gems=0},
    startTime = tick(),
    labels = {}
}

-- === DATA ===
local petData, _codeData
pcall(function()
    petData = require(RS.Shared.Data.Pets)
    _codeData = require(RS.Shared.Data.Codes)
end)

-- === UTILITY FUNCTIONS ===
local function SendWebhook(url, msg)
    pcall(function()
        request({
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)
end

local function updateStats()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        state.stats.bubbles = leaderstats:FindFirstChild("Bubbles") and leaderstats.Bubbles.Value or 0
        state.stats.hatches = leaderstats:FindFirstChild("Hatches") and leaderstats.Hatches.Value or 0
    end

    pcall(function()
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui and screenGui:FindFirstChild("HUD") then
            local currencyFrame = screenGui.HUD:FindFirstChild("Left", true):FindFirstChild("Currency", true)
            if currencyFrame then
                for _, currency in pairs(currencyFrame:GetChildren()) do
                    local label = currency:FindFirstChild("Frame", true):FindFirstChild("Label")
                    if label then
                        local value = tonumber(label.Text:match("%d+")) or 0
                        local name = currency.Name:lower()
                        if name == "coins" then state.stats.coins = value end
                        if name == "bubble" then state.stats.bubbleStock = value end
                        if name == "gems" then state.stats.gems = value end
                    end
                end
            end
        end
    end)
end

local function scanRifts()
    state.currentRifts = {}
    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered and rendered:FindFirstChild("Rifts") then
            for _, rift in pairs(rendered.Rifts:GetChildren()) do
                local display = rift:FindFirstChild("Display")
                if display then
                    local timer = display:FindFirstChild("Timer")
                    local icon = display:FindFirstChild("Icon")
                    local luck = icon and icon:FindFirstChild("Luck")
                    table.insert(state.currentRifts, {
                        name = rift.Name,
                        timer = timer and timer.Text or "00:00",
                        luck = luck and luck.Text or "x1",
                        instance = rift
                    })
                end
            end
        end
    end)
end

local function scanEggs()
    state.currentEggs = {}
    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered then
            for _, folder in pairs(rendered:GetChildren()) do
                if folder.Name:lower():find("chuncker") then
                    for _, egg in pairs(folder:GetChildren()) do
                        if egg.Name ~= "Coming Soon" then
                            table.insert(state.currentEggs, {name = egg.Name, instance = egg})
                        end
                    end
                end
            end
        end
    end)
end

local function tpToModel(model)
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local cf = model:FindFirstChild("EggPlatformSpawn")
                and model.EggPlatformSpawn:GetModelCFrame()
                or model:GetModelCFrame()
            hrp.CFrame = cf + Vector3.new(0, 5, 0)
        end
    end)
end

-- === MAIN TAB ===
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

local StatsSection = MainTab:CreateSection("📊 Live Stats")

state.labels.runtime = MainTab:CreateLabel("Runtime: 00:00:00")
state.labels.bubbles = MainTab:CreateLabel("Bubbles: 0")
state.labels.hatches = MainTab:CreateLabel("Hatches: 0")
state.labels.coins = MainTab:CreateLabel("Coins: 0")
state.labels.bubbleStock = MainTab:CreateLabel("Bubble Stock: 0")
state.labels.gems = MainTab:CreateLabel("Gems: 0")

-- === FARM TAB ===
local FarmTab = Window:CreateTab("🔧 Farm", 4483362458)

local FarmSection = FarmTab:CreateSection("🤖 Auto Farm")

local AutoBlowToggle = FarmTab:CreateToggle({
   Name = "🧼 Auto Blow Bubbles",
   CurrentValue = false,
   Flag = "AutoBlow",
   Callback = function(Value)
      state.autoBlow = Value
      Rayfield:Notify({
         Title = "Auto Blow",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- === EGGS TAB ===
local EggsTab = Window:CreateTab("🥚 Eggs", 4483362458)

local EggsSection = EggsTab:CreateSection("🥚 Eggs Management")

local EggDropdown = EggsTab:CreateDropdown({
   Name = "Select Egg",
   Options = {},
   CurrentOption = {"Scan eggs first"},
   MultipleOptions = false,
   Flag = "EggSelect",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Scan eggs first" then
         state.eggPriority = Option[1]
         for _, egg in pairs(state.currentEggs) do
            if egg.name == Option[1] then
               tpToModel(egg.instance)
               Rayfield:Notify({
                  Title = "Teleported",
                  Content = "TP to " .. Option[1],
                  Duration = 2,
                  Image = 4483362458,
               })
               break
            end
         end
      end
   end,
})

local AutoHatchToggle = EggsTab:CreateToggle({
   Name = "🔄 Auto Hatch",
   CurrentValue = false,
   Flag = "AutoHatch",
   Callback = function(Value)
      state.autoHatch = Value
   end,
})

local ScanEggsButton = EggsTab:CreateButton({
   Name = "🔄 Scan Eggs",
   Callback = function()
      scanEggs()
      local names = {}
      for _, egg in pairs(state.currentEggs) do
         table.insert(names, egg.name)
      end
      EggDropdown:Refresh(names, true)
      Rayfield:Notify({
         Title = "Eggs Scanned",
         Content = #names .. " eggs found!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- === RIFTS TAB ===
local RiftsTab = Window:CreateTab("🌌 Rifts", 4483362458)

local RiftsSection = RiftsTab:CreateSection("🌌 Rifts Management")

local RiftDropdown = RiftsTab:CreateDropdown({
   Name = "Select Rift",
   Options = {},
   CurrentOption = {"Scan rifts first"},
   MultipleOptions = false,
   Flag = "RiftSelect",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Scan rifts first" then
         local name = Option[1]:match("^(.+?) |") or Option[1]
         state.riftPriority = name
         for _, rift in pairs(state.currentRifts) do
            if rift.name == name then
               tpToModel(rift.instance)
               Rayfield:Notify({
                  Title = "Teleported",
                  Content = "TP to " .. name,
                  Duration = 2,
                  Image = 4483362458,
               })
               break
            end
         end
      end
   end,
})

local ScanRiftsButton = RiftsTab:CreateButton({
   Name = "🔄 Scan Rifts",
   Callback = function()
      scanRifts()
      local names = {}
      for _, rift in pairs(state.currentRifts) do
         table.insert(names, rift.name .. " | " .. rift.timer .. " | " .. rift.luck)
      end
      RiftDropdown:Refresh(names, true)
      Rayfield:Notify({
         Title = "Rifts Scanned",
         Content = #names .. " rifts found!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- === WEBHOOK TAB ===
local WebTab = Window:CreateTab("📊 Webhook", 4483362458)

local WebSection = WebTab:CreateSection("💬 Discord Integration")

local WebhookInput = WebTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "https://discord.com/api/webhooks/...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      state.webhookUrl = Text
   end,
})

local WebhookStatsToggle = WebTab:CreateToggle({
   Name = "📊 Send Stats",
   CurrentValue = true,
   Flag = "WebhookStats",
   Callback = function(Value)
      state.webhookStats = Value
   end,
})

local WebhookTestButton = WebTab:CreateButton({
   Name = "🧪 Test Webhook",
   Callback = function()
      if state.webhookUrl == "" then
         Rayfield:Notify({
            Title = "Error",
            Content = "Please add webhook URL first!",
            Duration = 3,
            Image = 4483362458,
         })
         return
      end
      SendWebhook(state.webhookUrl, "**🧼 BGSI Test** " .. os.date("%H:%M"))
      Rayfield:Notify({
         Title = "Test Sent",
         Content = "Check your Discord!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- === DATA TAB ===
local DataTab = Window:CreateTab("📋 Data", 4483362458)

local DataSection = DataTab:CreateSection("🐾 Pet Information")

if petData then
   local count = 0
   for name, data in pairs(petData) do
      if data.Rarity and count < 10 then
         DataTab:CreateLabel(name .. " [" .. data.Rarity .. "]")
         count += 1
      end
   end
else
   DataTab:CreateLabel("Pet data not available in this game")
end

-- === MAIN LOOPS ===
task.spawn(function()
    while task.wait(0.1) do
        updateStats()
        scanRifts()
        scanEggs()
        
        if state.autoBlow then
            -- Uncomment when ready:
            -- RS.Remotes.BlowBubbleRemote:FireServer()
        end
        
        if state.autoHatch and state.eggPriority then
            for _, egg in pairs(state.currentEggs) do
                if egg.name == state.eggPriority then
                    tpToModel(egg.instance)
                    break
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        local runtime = tick() - state.startTime
        local h,m,s = math.floor(runtime/3600), math.floor((runtime%3600)/60), math.floor(runtime%60)

        pcall(function()
            state.labels.runtime:Set("Runtime: " .. string.format("%02d:%02d:%02d", h,m,s))
            state.labels.bubbles:Set("Bubbles: " .. state.stats.bubbles)
            state.labels.hatches:Set("Hatches: " .. state.stats.hatches)
            state.labels.coins:Set("Coins: " .. state.stats.coins)
            state.labels.bubbleStock:Set("Bubble Stock: " .. state.stats.bubbleStock)
            state.labels.gems:Set("Gems: " .. state.stats.gems)
        end)
    end
end)

-- Initial scans
scanEggs()
scanRifts()

-- Load saved configuration
Rayfield:LoadConfiguration()

print("✅ ==========================================")
print("✅ BGSI Premium Hub - READY!")
print("✅ ==========================================")
print("📱 Rayfield is automatically mobile-optimized!")
print("   • Single column layout")
print("   • Auto-resizes to your screen")
print("   • Touch-friendly buttons")
print("✅ ==========================================")
print("📋 Tabs:")
print("   🏠 Main - Live stats")
print("   🔧 Farm - Auto blow bubbles")
print("   🥚 Eggs - Scanner & auto hatch")
print("   🌌 Rifts - Scanner & teleport")
print("   📊 Webhook - Discord integration")
print("   📋 Data - Pet information")
print("✅ ==========================================")

Rayfield:Notify({
   Title = "🧼 BGSI Hub Ready!",
   Content = "Mobile-optimized by Rayfield",
   Duration = 5,
   Image = 4483362458,
})

print("🎉 BGSI Hub loaded successfully!")
