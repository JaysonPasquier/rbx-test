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

-- ✅ IMPROVED: Get stats from leaderstats and UI
local function updateStats()
    -- Get from leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local bubblesValue = leaderstats:FindFirstChild("Bubbles")
        local hatchesValue = leaderstats:FindFirstChild("Hatches")

        if bubblesValue then
            state.stats.bubbles = bubblesValue.Value
        end
        if hatchesValue then
            state.stats.hatches = hatchesValue.Value
        end
    end

    -- Get currency from UI
    pcall(function()
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local hud = screenGui:FindFirstChild("HUD")
            if hud then
                local left = hud:FindFirstChild("Left")
                if left then
                    local currency = left:FindFirstChild("Currency")
                    if currency then
                        -- Coins
                        local coinsFrame = currency:FindFirstChild("Coins")
                        if coinsFrame then
                            local frame = coinsFrame:FindFirstChild("Frame")
                            if frame then
                                local label = frame:FindFirstChild("Label")
                                if label and label:IsA("TextLabel") then
                                    local value = tonumber(label.Text:match("%d+")) or 0
                                    state.stats.coins = value
                                end
                            end
                        end

                        -- Bubble Stock
                        local bubbleFrame = currency:FindFirstChild("Bubble")
                        if bubbleFrame then
                            local frame = bubbleFrame:FindFirstChild("Frame")
                            if frame then
                                local label = frame:FindFirstChild("Label")
                                if label and label:IsA("TextLabel") then
                                    local value = tonumber(label.Text:match("%d+")) or 0
                                    state.stats.bubbleStock = value
                                end
                            end
                        end

                        -- Gems
                        local gemsFrame = currency:FindFirstChild("gems")
                        if gemsFrame then
                            local frame = gemsFrame:FindFirstChild("Frame")
                            if frame then
                                local label = frame:FindFirstChild("Label")
                                if label and label:IsA("TextLabel") then
                                    local value = tonumber(label.Text:match("%d+")) or 0
                                    state.stats.gems = value
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ✅ IMPROVED: Real-time rift scanner with timer & luck
local function scanRifts()
    local newRifts = {}
    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered and rendered:FindFirstChild("Rifts") then
            for _, rift in pairs(rendered.Rifts:GetChildren()) do
                if rift:IsA("Model") then
                    local display = rift:FindFirstChild("Display")
                    if display then
                        local timerLabel = display:FindFirstChild("Timer")
                        local icon = display:FindFirstChild("Icon")
                        local luckLabel = icon and icon:FindFirstChild("Luck")

                        local timerText = "00:00"
                        local luckText = "x1"

                        if timerLabel and timerLabel:IsA("TextLabel") then
                            timerText = timerLabel.Text
                        end

                        if luckLabel and luckLabel:IsA("TextLabel") then
                            luckText = luckLabel.Text
                        end

                        table.insert(newRifts, {
                            name = rift.Name,
                            timer = timerText,
                            luck = luckText,
                            instance = rift,
                            displayText = rift.Name .. " | " .. timerText .. " | " .. luckText
                        })
                    end
                end
            end
        end
    end)

    state.currentRifts = newRifts
    return newRifts
end

-- ✅ IMPROVED: Real-time egg scanner (Chuncker folders)
local function scanEggs()
    local newEggs = {}
    local seenEggs = {}  -- Prevent duplicates

    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered then
            -- Search through ALL children for "Chuncker" folders (note the typo in game)
            for _, folder in pairs(rendered:GetChildren()) do
                if folder.Name:find("Chuncker") then
                    for _, egg in pairs(folder:GetChildren()) do
                        -- Skip "Coming Soon" and duplicates
                        if egg.Name ~= "Coming Soon" and not seenEggs[egg.Name] then
                            seenEggs[egg.Name] = true
                            table.insert(newEggs, {
                                name = egg.Name,
                                instance = egg
                            })
                        end
                    end
                end
            end
        end
    end)

    state.currentEggs = newEggs
    return newEggs
end

-- ✅ FIXED: Proper teleport function
local function tpToModel(model)
    pcall(function()
        if not player.Character then return end
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Check if it's a rift (has EggPlatformSpawn)
        local platform = model:FindFirstChild("EggPlatformSpawn")

        if platform then
            -- Rift teleport - get center of platform
            local cf = platform:GetPivot()
            hrp.CFrame = cf + Vector3.new(0, 5, 0)
        else
            -- Regular egg teleport - get model center
            local cf = model:GetPivot()
            hrp.CFrame = cf + Vector3.new(0, 3, 0)
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
   Options = {"Scanning..."},
   CurrentOption = {"Scanning..."},
   MultipleOptions = false,
   Flag = "EggSelect",
   Callback = function(Option)
      if Option and Option[1] then
         local selectedEgg = Option[1]

         -- Find and teleport to selected egg
         for _, egg in pairs(state.currentEggs) do
            if egg.name == selectedEgg then
               state.eggPriority = selectedEgg
               tpToModel(egg.instance)
               Rayfield:Notify({
                  Title = "Teleported",
                  Content = "Teleported to " .. selectedEgg,
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
   Name = "🔄 Auto Hatch (Priority Egg)",
   CurrentValue = false,
   Flag = "AutoHatch",
   Callback = function(Value)
      state.autoHatch = Value
      if Value then
         Rayfield:Notify({
            Title = "Auto Hatch",
            Content = "Will keep teleporting to: " .. (state.eggPriority or "None"),
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

EggsTab:CreateLabel("Auto-scans eggs every 2 seconds")

-- === RIFTS TAB ===
local RiftsTab = Window:CreateTab("🌌 Rifts", 4483362458)

local RiftsSection = RiftsTab:CreateSection("🌌 Rifts Management")

local RiftDropdown = RiftsTab:CreateDropdown({
   Name = "Select Rift (Priority)",
   Options = {"Scanning..."},
   CurrentOption = {"Scanning..."},
   MultipleOptions = false,
   Flag = "RiftSelect",
   Callback = function(Option)
      if Option and Option[1] then
         local selectedRift = Option[1]

         -- Extract rift name (before the " | ")
         local riftName = selectedRift:match("^(.+) |") or selectedRift

         -- Find and teleport to selected rift
         for _, rift in pairs(state.currentRifts) do
            if rift.name == riftName or rift.displayText == selectedRift then
               state.riftPriority = rift.name
               tpToModel(rift.instance)
               Rayfield:Notify({
                  Title = "Teleported",
                  Content = "Teleported to " .. rift.name,
                  Duration = 2,
                  Image = 4483362458,
               })
               break
            end
         end
      end
   end,
})

RiftsTab:CreateLabel("Auto-scans rifts every 2 seconds")
RiftsTab:CreateLabel("Shows: Name | Timer | Luck")

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

-- 🔍 Remote Discovery Section
local RemoteSection = DataTab:CreateSection("🔍 Remote Discovery (For Devs)")
DataTab:CreateLabel("Use this to find game remotes:")

DataTab:CreateButton({
   Name = "📡 Scan RS Remotes",
   Callback = function()
      local RS = game:GetService("ReplicatedStorage")
      print("\n🔍 === REPLICATEDSTORAGE REMOTES ===")
      for _, obj in pairs(RS:GetDescendants()) do
         if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
            print("   📡 " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
         end
      end
      print("=== END SCAN ===\n")
      Rayfield:Notify({
         Title = "Remote Scan Complete",
         Content = "Check console (F9) for results",
         Duration = 3
      })
   end
})

DataTab:CreateButton({
   Name = "🎯 Find Bubble Remotes",
   Callback = function()
      local RS = game:GetService("ReplicatedStorage")
      print("\n🧼 === SEARCHING FOR BUBBLE REMOTES ===")
      for _, obj in pairs(RS:GetDescendants()) do
         if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("bubble") or name:find("blow") or name:find("click") or name:find("tap") then
               print("   💡 POSSIBLE: " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
            end
         end
      end
      print("=== END SEARCH ===\n")
      Rayfield:Notify({
         Title = "Bubble Remote Search Complete",
         Content = "Check console (F9) for results",
         Duration = 3
      })
   end
})

DataTab:CreateButton({
   Name = "🥚 Find Egg/Hatch Remotes",
   Callback = function()
      local RS = game:GetService("ReplicatedStorage")
      print("\n🥚 === SEARCHING FOR EGG/HATCH REMOTES ===")
      for _, obj in pairs(RS:GetDescendants()) do
         if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("egg") or name:find("hatch") or name:find("open") or name:find("purchase") then
               print("   💡 POSSIBLE: " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
            end
         end
      end
      print("=== END SEARCH ===\n")
      Rayfield:Notify({
         Title = "Egg/Hatch Remote Search Complete",
         Content = "Check console (F9) for results",
         Duration = 3
      })
   end
})

-- === MAIN LOOPS ===

-- ✅ AUTO-SCAN: Rifts and Eggs (every 2 seconds)
task.spawn(function()
    while task.wait(2) do
        -- Scan rifts
        local rifts = scanRifts()
        local riftNames = {}
        for _, rift in pairs(rifts) do
            table.insert(riftNames, rift.displayText)
        end

        if #riftNames > 0 then
            pcall(function()
                RiftDropdown:Refresh(riftNames, true)
            end)
        end

        -- Scan eggs
        local eggs = scanEggs()
        local eggNames = {}
        for _, egg in pairs(eggs) do
            table.insert(eggNames, egg.name)
        end

        if #eggNames > 0 then
            pcall(function()
                EggDropdown:Refresh(eggNames, true)
            end)
        end
    end
end)

-- ✅ STATS UPDATE: Every second
task.spawn(function()
    while task.wait(1) do
        local runtime = tick() - state.startTime
        local h,m,s = math.floor(runtime/3600), math.floor((runtime%3600)/60), math.floor(runtime%60)

        pcall(function()
            state.labels.runtime:Set("⏱️ Runtime: " .. string.format("%02d:%02d:%02d", h,m,s))
            state.labels.bubbles:Set("🧼 Bubbles: " .. tostring(state.stats.bubbles))
            state.labels.hatches:Set("🥚 Hatches: " .. tostring(state.stats.hatches))
            state.labels.coins:Set("💰 Coins: " .. tostring(state.stats.coins))
            state.labels.bubbleStock:Set("🫧 Bubble Stock: " .. tostring(state.stats.bubbleStock))
            state.labels.gems:Set("💎 Gems: " .. tostring(state.stats.gems))
        end)

        updateStats()
    end
end)

-- ✅ AUTO FEATURES: Fast loop (100ms)
task.spawn(function()
    while task.wait(0.1) do
        -- Auto Blow Bubbles
        if state.autoBlow then
            pcall(function()
                -- 🔍 NEED TO FIND: The bubble blowing remote
                -- Possible locations: RS.Remotes, RS.Network, RS.Events
                -- Look for: BlowBubble, Bubble, Click, Tap events
                -- Try: game:GetService("ReplicatedStorage"):GetDescendants() to find remotes
                local RS = game:GetService("ReplicatedStorage")

                -- Common patterns:
                -- RS.Remotes.BlowBubble:FireServer()
                -- RS.Network.BlowBubble:InvokeServer()
                -- RS.Events.Bubble:Fire()

                -- Placeholder for now:
                warn("⚠️ Auto Blow: Remote not yet implemented!")
            end)
        end

        -- Auto Hatch (teleport to priority egg)
        if state.autoHatch and state.eggPriority then
            pcall(function()
                for _, egg in pairs(state.currentEggs) do
                    if egg.name == state.eggPriority then
                        tpToModel(egg.instance)

                        -- 🔍 NEED TO FIND: The egg opening/hatching remote
                        -- Possible approach:
                        -- 1. Find ProximityPrompt on egg model
                        -- 2. Trigger it: fireclickdetector or fireproximityprompt
                        -- 3. OR find RemoteEvent/RemoteFunction like:
                        --    RS.Remotes.OpenEgg:InvokeServer(eggName)
                        --    RS.Network.HatchEgg:FireServer(eggModel)

                        break
                    end
                end
            end)
        end
    end
end)

-- === INITIAL SETUP ===
print("✅ Performing initial scans...")

-- Initial egg scan
task.spawn(function()
    task.wait(1)  -- Wait for game to load
    local eggs = scanEggs()
    local eggNames = {}
    for _, egg in pairs(eggs) do
        table.insert(eggNames, egg.name)
    end

    if #eggNames > 0 then
        pcall(function()
            EggDropdown:Refresh(eggNames, true)
        end)
        print("✅ Found " .. #eggNames .. " eggs")
    else
        print("⚠️ No eggs found yet")
    end
end)

-- Initial rift scan
task.spawn(function()
    task.wait(1)  -- Wait for game to load
    local rifts = scanRifts()
    local riftNames = {}
    for _, rift in pairs(rifts) do
        table.insert(riftNames, rift.displayText)
    end

    if #riftNames > 0 then
        pcall(function()
            RiftDropdown:Refresh(riftNames, true)
        end)
        print("✅ Found " .. #riftNames .. " rifts")
    else
        print("⚠️ No rifts spawned yet")
    end
end)

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
print("🔄 AUTO-SCANNING:")
print("   • Rifts: Every 2 seconds")
print("   • Eggs: Every 2 seconds")
print("   • Stats: Every 1 second")
print("✅ ==========================================")
print("📋 Tabs:")
print("   🏠 Main - Live stats")
print("   🔧 Farm - Auto blow bubbles")
print("   🥚 Eggs - Auto-scanned eggs + auto hatch")
print("   🌌 Rifts - Auto-scanned rifts with timers")
print("   📊 Webhook - Discord integration")
print("   📋 Data - Pet information")
print("✅ ==========================================")

Rayfield:Notify({
   Title = "🧼 BGSI Hub Ready!",
   Content = "Mobile-optimized | Auto-scanning enabled",
   Duration = 5,
   Image = 4483362458,
})

print("🎉 BGSI Hub loaded successfully!")
print("💡 Rifts and eggs will auto-refresh every 2 seconds")
