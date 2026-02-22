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
    maxEggs = 7,  -- Max eggs to hatch at once (configurable in UI)
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
-- Format numbers with commas (1234567890 -> 1,234,567,890)
local function formatNumber(num)
    if type(num) ~= "number" then return tostring(num) end
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function SendWebhook(url, msg)
    pcall(function()
        request({
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)
end

-- ✅ FIXED: Get stats from leaderstats and UI (leaderstats have emoji prefixes!)
local function updateStats()
    -- Get from leaderstats (names have emoji prefixes like "🥚 Hatches")
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        -- Try with and without emoji prefixes
        local bubblesValue = leaderstats:FindFirstChild("🟣 Bubbles") or leaderstats:FindFirstChild("Bubbles")
        local hatchesValue = leaderstats:FindFirstChild("🥚 Hatches") or leaderstats:FindFirstChild("Hatches")

        if bubblesValue then
            state.stats.bubbles = bubblesValue.Value
        end
        if hatchesValue then
            state.stats.hatches = hatchesValue.Value
        end
    end

    -- Get currency from UI (preserve formatted text like "23.5b")
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
                                    state.stats.coins = label.Text  -- Full text with formatting
                                end
                            end
                        end

                        -- Bubble Stock (remove rich text tags)
                        local bubbleFrame = currency:FindFirstChild("Bubble")
                        if bubbleFrame then
                            local frame = bubbleFrame:FindFirstChild("Frame")
                            if frame then
                                local label = frame:FindFirstChild("Label")
                                if label and label:IsA("TextLabel") then
                                    local rawText = label.Text
                                    -- Remove rich text: <stroke>value / ∞</stroke>
                                    local cleaned = rawText:gsub("<.->" , "")  -- Remove all tags
                                    cleaned = cleaned:match("([%d%.,]+[KMBT]?)")
                                    state.stats.bubbleStock = cleaned or rawText
                                end
                            end
                        end

                        -- Gems (capital G according to diagnostic report)
                        local gemsFrame = currency:FindFirstChild("Gems") or currency:FindFirstChild("gems")
                        if gemsFrame then
                            local frame = gemsFrame:FindFirstChild("Frame")
                            if frame then
                                local label = frame:FindFirstChild("Label")
                                if label and label:IsA("TextLabel") then
                                    state.stats.gems = label.Text  -- Full text with formatting
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ✅ FIXED: Real-time rift scanner with correct paths (Display.SurfaceGui)
local function scanRifts()
    local newRifts = {}
    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered and rendered:FindFirstChild("Rifts") then
            for _, rift in pairs(rendered.Rifts:GetChildren()) do
                if rift:IsA("Model") then
                    local display = rift:FindFirstChild("Display")
                    if display then
                        local surfaceGui = display:FindFirstChild("SurfaceGui")
                        if surfaceGui then
                            local timerLabel = surfaceGui:FindFirstChild("Timer")
                            local iconFrame = surfaceGui:FindFirstChild("Icon")
                            local luckLabel = iconFrame and iconFrame:FindFirstChild("Luck")

                            local timerText = "N/A"
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
        end
    end)

    state.currentRifts = newRifts
    return newRifts
end

-- ✅ FIXED: Real-time egg scanner (Chunker folders with proper filtering)
local function scanEggs()
    local newEggs = {}
    local seenEggs = {}  -- Prevent duplicates

    pcall(function()
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered then
            local foundEggs = 0
            for _, folder in pairs(rendered:GetChildren()) do
                -- Fixed: It's "Chunker" not "Chuncker"
                if folder.Name == "Chunker" then
                    for _, egg in pairs(folder:GetChildren()) do
                        if egg:IsA("Model") then
                            local eggName = egg.Name
                            -- Filter: Skip "Coming Soon", UUIDs, and duplicates
                            local isUUID = eggName:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-")
                            local isComingSoon = eggName == "Coming Soon"

                            if not isUUID and not isComingSoon and not seenEggs[eggName] then
                                seenEggs[eggName] = true
                                foundEggs = foundEggs + 1
                                table.insert(newEggs, {
                                    name = eggName,
                                    instance = egg
                                })
                            end
                        end
                    end
                end
            end

            if foundEggs > 0 then
                print("✅ Found " .. foundEggs .. " eggs in Chunker folders")
            end
        end
    end)

    state.currentEggs = newEggs
    return newEggs
end

-- ✅ FIXED: Proper teleport function (safe distance from eggs/rifts)
local function tpToModel(model)
    pcall(function()
        if not player.Character then return end
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Check if it's a rift (has EggPlatformSpawn)
        local platform = model:FindFirstChild("EggPlatformSpawn")

        if platform then
            -- Rift teleport - get center of platform (higher up)
            local cf = platform:GetPivot()
            hrp.CFrame = cf + Vector3.new(0, 10, 0)  -- 10 studs above platform
        else
            -- Regular egg teleport - in front and above the egg
            local cf = model:GetPivot()
            hrp.CFrame = cf + Vector3.new(0, 15, 8)  -- 15 studs up, 8 studs forward
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
            Content = "Will hatch " .. state.maxEggs .. "x " .. (state.eggPriority or "None"),
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

local MaxEggsSlider = EggsTab:CreateSlider({
   Name = "🥚 Max Eggs Per Hatch",
   Range = {1, 100},
   Increment = 1,
   CurrentValue = 7,
   Flag = "MaxEggs",
   Callback = function(Value)
      state.maxEggs = Value
      Rayfield:Notify({
         Title = "Max Eggs Updated",
         Content = "Will hatch " .. Value .. " eggs at once",
         Duration = 2,
      })
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
local RemoteSection = DataTab:CreateSection("✅ Remotes Found!")
DataTab:CreateLabel("Auto-Bubble & Auto-Hatch are READY")
DataTab:CreateLabel("Network: RS.Shared.Framework.Network.Remote")

DataTab:CreateButton({
   Name = "📡 Scan All Remotes",
   Callback = function()
      pcall(function()
         local RS = game:GetService("ReplicatedStorage")
         print("\n🔍 === ALL REMOTES IN GAME ===")
         local count = 0
         for _, obj in pairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
               count = count + 1
               print("   📡 [" .. count .. "] " .. obj:GetFullName())
            end
         end
         print("\nTotal found: " .. count)
         print("=== END SCAN ===\n")
      end)

      Rayfield:Notify({
         Title = "Scan Complete",
         Content = "Check console (F9)",
         Duration = 3
      })
   end
})

DataTab:CreateButton({
   Name = "🕵️ Test Auto-Blow Now",
   Callback = function()
      pcall(function()
         local RS = game:GetService("ReplicatedStorage")
         local networkRemote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
         networkRemote:FireServer("BlowBubble")
         print("✅ Sent BlowBubble command!")
      end)

      Rayfield:Notify({
         Title = "Bubble Blown!",
         Content = "Manual test successful",
         Duration = 2
      })
   end
})

DataTab:CreateButton({
   Name = "🥚 Test Hatch Now (Priority Egg)",
   Callback = function()
      if state.eggPriority then
         pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local networkRemote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
            networkRemote:FireServer("HatchEgg", state.eggPriority, state.maxEggs)
            print("✅ Sent HatchEgg command for: " .. state.eggPriority .. " x" .. state.maxEggs)
         end)

         Rayfield:Notify({
            Title = "Hatching Egg!",
            Content = state.eggPriority,
            Duration = 2
         })
      else
         Rayfield:Notify({
            Title = "No Egg Selected",
            Content = "Select an egg first",
            Duration = 3
         })
      end
   end
})

-- === MAIN LOOPS ===

-- ✅ AUTO-SCAN: Rifts and Eggs (every 2 seconds) - Only refresh if data changed
local lastRiftData = ""
local lastEggData = ""

task.spawn(function()
    while task.wait(2) do
        -- Scan rifts
        local rifts = scanRifts()
        local riftNames = {}
        for _, rift in pairs(rifts) do
            table.insert(riftNames, rift.displayText)
        end

        -- Only refresh if data changed (prevents list clearing during scroll)
        local newRiftData = table.concat(riftNames, "|")
        if newRiftData ~= lastRiftData then
            lastRiftData = newRiftData
            if #riftNames > 0 then
                pcall(function()
                    RiftDropdown:Refresh(riftNames, false)  -- false = don't clear selection
                end)
            end
        end

        -- Scan eggs
        local eggs = scanEggs()
        local eggNames = {}
        for _, egg in pairs(eggs) do
            table.insert(eggNames, egg.name)
        end

        -- Only refresh if data changed (prevents list clearing during scroll)
        local newEggData = table.concat(eggNames, "|")
        if newEggData ~= lastEggData then
            lastEggData = newEggData
            if #eggNames > 0 then
                pcall(function()
                    EggDropdown:Refresh(eggNames, false)  -- false = don't clear selection
                end)
            end
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
            state.labels.bubbles:Set("🧱 Bubbles: " .. formatNumber(state.stats.bubbles))
            state.labels.hatches:Set("🥚 Hatches: " .. formatNumber(state.stats.hatches))
            state.labels.coins:Set("💰 Coins: " .. tostring(state.stats.coins))
            state.labels.bubbleStock:Set("🫧 Bubble Stock: " .. tostring(state.stats.bubbleStock))
            state.labels.gems:Set("💎 Gems: " .. tostring(state.stats.gems))
        end)

        updateStats()
    end
end)

-- ✅ AUTO FEATURES: Fast loop (100ms)
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local networkRemote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(0.1) do
        -- ✅ Auto Blow Bubbles (IMPLEMENTED)
        if state.autoBlow then
            pcall(function()
                networkRemote:FireServer("BlowBubble")
            end)
        end

        -- ✅ Auto Hatch (IMPLEMENTED)
        if state.autoHatch and state.eggPriority then
            pcall(function()
                -- Find the egg instance
                for _, egg in pairs(state.currentEggs) do
                    if egg.name == state.eggPriority then
                        -- Teleport to egg
                        tpToModel(egg.instance)

                        -- Open egg (format: "HatchEgg", eggName, quantity)
                        task.wait(0.15)  -- Small delay after teleport
                        networkRemote:FireServer("HatchEgg", state.eggPriority, state.maxEggs)

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
