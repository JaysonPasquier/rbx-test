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

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,

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
    autoPickup = false,
    autoChest = false,
    autoSellBubbles = false,  -- NEW: Auto-sell bubbles for coins
    autoClaimEventPrizes = false,  -- NEW: Auto-claim event prizes
    riftPriorityMode = false,  -- NEW: Wait for specific priority rifts to spawn
    riftAutoHatch = false,  -- NEW: Auto-hatch at normal rift
    riftPriority = nil,
    priorityRifts = {},  -- NEW: List of priority rifts to watch for
    eggPriority = nil,
    priorityEggs = {"Super Egg"},  -- NEW: List of priority eggs to watch for
    priorityEggMode = false,  -- NEW: Enable priority egg detection
    maxEggs = 7,
    lastEggPosition = nil,
    adminEventActive = false,  -- NEW: Track Admin Abuse event
    autoClaimPlaytime = false,  -- NEW: Auto-claim playtime gifts
    webhookUrl = "",
    webhookStats = true,
    webhookRarities = {Common=false, Unique=false, Rare=false, Epic=false, Legendary=true, Secret=true},
    webhookChanceThreshold = 100000000,  -- Only send if rarity is 1 in X or rarer (default: 1 in 100M)
    webhookStatsEnabled = false,  -- NEW: Enable user stats webhook
    webhookStatsInterval = 60,  -- NEW: Stats webhook interval (30-120 seconds)
    lastStatsSnapshot = nil,  -- NEW: Previous stats for difference calculation
    lastStatsWebhookTime = nil,  -- NEW: Last time stats webhook was sent
    statsMessageId = nil,  -- NEW: Discord message ID for editing stats webhook
    currentRifts = {},
    currentEggs = {},
    currentChests = {},
    eggDatabase = {},  -- NEW: Database of all eggs {EggName = {world="WorldName", position=Vector3}}
    gameEggData = {},  -- NEW: Egg data from ReplicatedStorage (all eggs in game)
    gameRiftData = {},  -- NEW: Rift data from ReplicatedStorage (all rifts in game)
    gameEggList = {},  -- NEW: Simple list of all egg names from game data
    gameRiftList = {},  -- NEW: Simple list of valid rift names (filtered, no Ignore=true)
    stats = {
        -- Leaderstats
        bubbles=0, hatches=0,
        -- Main currencies (GUI)
        coins="0", gems="0", bubbleStock="0",
        -- All 18 currencies from GUI
        tokens="0", tickets="0", seashells="0", festivalCoins="0",
        pearls="0", leaves="0", candycorn="0", ogPoints="0",
        thanksgivingShards="0", winterShards="0", snowflakes="0",
        newYearsShard="0", horns="0", halos="0", moonShards="0"
    },
    startTime = tick(),
    labels = {},
    currencyLabels = {}  -- NEW: Labels for all currencies
}

-- === DATA ===
local petData, _codeData
pcall(function()
    petData = require(RS.Shared.Data.Pets)
    _codeData = require(RS.Shared.Data.Codes)
end)

-- === HOOK PET HATCH RESPONSES ===
-- Listen for hatch responses from server
task.spawn(function()
    pcall(function()
        local networkRemote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

        -- Hook the OnClientEvent to catch hatch responses
        networkRemote.OnClientEvent:Connect(function(eventName, ...)
            if eventName == "HatchEgg" or eventName == "HatchResponse" or eventName == "PetHatched" then
                local args = {...}
                -- Try to extract pet name from args
                -- The structure varies, but typically args[1] or args[2] contains pet info
                pcall(function()
                    for _, arg in pairs(args) do
                        if type(arg) == "table" then
                            -- Check if it's a pet table
                            for k, v in pairs(arg) do
                                if type(k) == "string" and petData and petData[k] then
                                    -- Found a pet!
                                    SendPetHatchWebhook(k, state.eggPriority or "Unknown Egg")
                                    print("🎉 Hatched: " .. k)
                                elseif type(v) == "string" and petData and petData[v] then
                                    -- Pet name is the value
                                    SendPetHatchWebhook(v, state.eggPriority or "Unknown Egg")
                                    print("🎉 Hatched: " .. v)
                                end
                            end
                        elseif type(arg) == "string" and petData and petData[arg] then
                            -- Direct pet name string
                            SendPetHatchWebhook(arg, state.eggPriority or "Unknown Egg")
                            print("🎉 Hatched: " .. arg)
                        end
                    end
                end)
            end
        end)

        print("✅ Pet hatch webhook listener initialized")
    end)
end)

-- === UTILITY FUNCTIONS ===

-- File path for saving stats message ID (persists across rejoins)
local STATS_MESSAGE_FILE = "bgsi_stats_message_id.txt"

-- Load stats message ID from file
local function loadStatsMessageId()
    if isfile and isfile(STATS_MESSAGE_FILE) then
        local success, content = pcall(readfile, STATS_MESSAGE_FILE)
        if success and content and content ~= "" then
            state.statsMessageId = content
            print("[Webhook] Loaded existing message ID: " .. content)
        end
    end
end

-- Save stats message ID to file
local function saveStatsMessageId(messageId)
    if writefile then
        pcall(writefile, STATS_MESSAGE_FILE, messageId)
        print("[Webhook] Saved message ID: " .. messageId)
    end
end

-- Fetch and parse egg data from game (auto-updates with new game versions)
local function loadGameEggData()
    local success, result = pcall(function()
        local eggsModule = RS:FindFirstChild("Shared")
        if eggsModule then
            eggsModule = eggsModule:FindFirstChild("Data")
            if eggsModule then
                eggsModule = eggsModule:FindFirstChild("Eggs")
                if eggsModule and eggsModule:IsA("ModuleScript") then
                    local eggData = require(eggsModule)
                    state.gameEggData = eggData

                    -- Build simple list of all egg names
                    for eggName, _ in pairs(eggData) do
                        table.insert(state.gameEggList, eggName)
                    end

                    print("✅ Loaded " .. #state.gameEggList .. " eggs from game data")
                    return true
                end
            end
        end
        return false
    end)

    if not success then
        print("⚠️ Failed to load egg data: " .. tostring(result))
    end
end

-- Fetch and parse rift data from game (auto-updates with new game versions)
local function loadGameRiftData()
    local success, result = pcall(function()
        local riftsModule = RS:FindFirstChild("Shared")
        if riftsModule then
            riftsModule = riftsModule:FindFirstChild("Data")
            if riftsModule then
                riftsModule = riftsModule:FindFirstChild("Rifts")
                if riftsModule and riftsModule:IsA("ModuleScript") then
                    local riftData = require(riftsModule)
                    state.gameRiftData = riftData

                    -- Build list of valid rift names (filter out Ignore=true)
                    for riftName, riftInfo in pairs(riftData) do
                        -- Skip rifts marked with Ignore=true (event rifts, dev rifts)
                        if not riftInfo.Ignore then
                            table.insert(state.gameRiftList, riftName)
                        end
                    end

                    print("✅ Loaded " .. #state.gameRiftList .. " rifts from game data (filtered)")
                    return true
                end
            end
        end
        return false
    end)

    if not success then
        print("⚠️ Failed to load rift data: " .. tostring(result))
    end
end

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

-- Send rich embed webhook for pet hatches
local function SendPetHatchWebhook(petName, eggName)
    if state.webhookUrl == "" then return end

    pcall(function()
        -- Get pet data
        local pet = petData and petData[petName]
        if not pet then return end

        local rarity = pet.Rarity or "Unknown"
        local bubbleStat = pet.Stat or 0

        -- Check rarity filter
        if not state.webhookRarities[rarity] then return end

        -- Calculate chance (estimate based on rarity)
        local chanceRatios = {
            Common = 10,
            Unique = 100,
            Rare = 1000,
            Epic = 10000,
            Legendary = 1000000,
            Secret = 100000000
        }
        local chanceRatio = chanceRatios[rarity] or 100

        -- Check chance threshold
        if chanceRatio < state.webhookChanceThreshold then return end

        local chancePercent = (1 / chanceRatio) * 100
        local chanceStr = string.format("%.6f", chancePercent)

        -- Format chance ratio with commas
        local function formatChance(num)
            local str = tostring(num)
            local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
            if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
            return formatted
        end

        -- Get runtime
        local runtime = tick() - state.startTime
        local h,m,s = math.floor(runtime/3600), math.floor((runtime%3600)/60), math.floor(runtime%60)
        local runtimeStr = string.format("%02d:%02d:%02d", h,m,s)

        -- Rarity colors
        local colors = {
            Common = 0xFFFFFF,
            Unique = 0x00FF00,
            Rare = 0x0099FF,
            Epic = 0x9900FF,
            Legendary = 0xFF6600,
            Secret = 0xFFFF00
        }

        -- Build embed
        local embed = {
            title = player.Name .. " Hatched a " .. petName,
            color = colors[rarity] or 0xFFFFFF,
            fields = {
                {
                    name = "User Info",
                    value = string.format("⏱️  Playtime: %s\\n🥚  Hatches: %s\\n💰  Coins: %s\\n💎  Gems: %s\\n🎟️  Tickets: %s",
                        runtimeStr,
                        formatNumber(state.stats.hatches),
                        tostring(state.stats.coins),
                        tostring(state.stats.gems),
                        tostring(state.stats.tickets)
                    ),
                    inline = false
                },
                {
                    name = "Hatch Info",
                    value = string.format("🥚  Egg: %s\\n🔮  Chance: %s%% (1 in %s)\\n🎲  Rarity: %s",
                        eggName,
                        chanceStr,
                        formatChance(chanceRatio),
                        rarity
                    ),
                    inline = false
                },
                {
                    name = "Pet Stats",
                    value = string.format("🫧  Bubbles: x%d",
                        bubbleStat
                    ),
                    inline = false
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }

        request({
            Url = state.webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = {embed}})
        })
    end)
end

-- Send user stats webhook
local function SendStatsWebhook()
    if state.webhookUrl == "" or not state.webhookStatsEnabled then return end

    pcall(function()
        -- Get runtime
        local runtime = tick() - state.startTime
        local h,m,s = math.floor(runtime/3600), math.floor((runtime%3600)/60), math.floor(runtime%60)
        local runtimeStr = string.format("%02d:%02d:%02d", h,m,s)

        -- Calculate differences if we have previous snapshot
        local diffs = {}
        local timeSinceLastCheck = state.webhookStatsInterval -- In seconds
        if state.lastStatsSnapshot then
            diffs.bubbles = state.stats.bubbles - state.lastStatsSnapshot.bubbles
            diffs.hatches = state.stats.hatches - state.lastStatsSnapshot.hatches
        end

        -- Calculate per-minute rates based on actual interval and differences
        -- If interval is 60s: difference = already per minute
        -- If interval is 120s: difference/2 = per minute
        local bubblesPerMin = 0
        local hatchesPerMin = 0

        if diffs.bubbles and timeSinceLastCheck > 0 then
            -- Convert to per-minute: (difference / secondsElapsed) * 60
            bubblesPerMin = math.floor((diffs.bubbles / timeSinceLastCheck) * 60)
        end

        if diffs.hatches and timeSinceLastCheck > 0 then
            hatchesPerMin = math.floor((diffs.hatches / timeSinceLastCheck) * 60)
        end

        -- Build fields for non-zero currencies
        local currencyText = ""
        local currencies = {
            {name="Coins", value=state.stats.coins},
            {name="Gems", value=state.stats.gems},
            {name="Bubble Stock", value=state.stats.bubbleStock},
            {name="Tokens", value=state.stats.tokens},
            {name="Tickets", value=state.stats.tickets},
            {name="Seashells", value=state.stats.seashells},
            {name="Festival Coins", value=state.stats.festivalCoins},
            {name="Pearls", value=state.stats.pearls},
            {name="Leaves", value=state.stats.leaves},
            {name="Candycorn", value=state.stats.candycorn},
            {name="OG Points", value=state.stats.ogPoints},
            {name="Thanksgiving Shards", value=state.stats.thanksgivingShards},
            {name="Winter Shards", value=state.stats.winterShards},
            {name="Snowflakes", value=state.stats.snowflakes},
            {name="New Years Shard", value=state.stats.newYearsShard},
            {name="Horns", value=state.stats.horns},
            {name="Halos", value=state.stats.halos},
            {name="Moon Shards", value=state.stats.moonShards}
        }

        for _, curr in pairs(currencies) do
            local val = tostring(curr.value)
            -- Skip if 0 or placeholder
            if val ~= "0" and val ~= "$1,000,000" then
                currencyText = currencyText .. curr.name .. ": " .. val .. "\n"
            end
        end

        -- Build difference text
        local diffText = ""
        if diffs.bubbles and diffs.bubbles ~= 0 then
            diffText = diffText .. string.format("Bubbles: %s%s\n", diffs.bubbles > 0 and "+" or "", formatNumber(diffs.bubbles))
        end
        if diffs.hatches and diffs.hatches ~= 0 then
            diffText = diffText .. string.format("Hatches: %s%s\n", diffs.hatches > 0 and "+" or "", formatNumber(diffs.hatches))
        end

        local embed = {
            title = "📊 " .. player.Name .. "'s Stats",
            color = 0x00AAFF,
            thumbnail = {
                url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            },
            fields = {
                {
                    name = "⏱️ Session Info",
                    value = string.format("Playtime: %s\n🥚 Hatches: %s\n🫧 Bubbles: %s",
                        runtimeStr,
                        formatNumber(state.stats.hatches),
                        formatNumber(state.stats.bubbles)
                    ),
                    inline = false
                },
                {
                    name = "💰 Currencies",
                    value = currencyText ~= "" and currencyText or "No currencies tracked",
                    inline = false
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }

        -- Add differences if any
        if diffText ~= "" then
            table.insert(embed.fields, {
                name = "📈 Changes (Since Last Check)",
                value = diffText,
                inline = false
            })
        end

        -- Add per-minute rates
        table.insert(embed.fields, {
            name = "⏱️ Rates Per Minute",
            value = string.format("🫧 Bubbles: %s/min\n🥚 Hatches: %s/min",
                formatNumber(bubblesPerMin),
                formatNumber(hatchesPerMin)
            ),
            inline = false
        })

        -- Calculate time since last update for footer
        local updateText = "Just now"
        if state.lastStatsWebhookTime then
            local secondsAgo = math.floor(tick() - state.lastStatsWebhookTime)
            if secondsAgo < 60 then
                updateText = string.format("Updated %d second%s ago", secondsAgo, secondsAgo == 1 and "" or "s")
            elseif secondsAgo < 3600 then
                local minutes = math.floor(secondsAgo / 60)
                updateText = string.format("Updated %d minute%s ago", minutes, minutes == 1 and "" or "s")
            else
                local hours = math.floor(secondsAgo / 3600)
                updateText = string.format("Updated %d hour%s ago", hours, hours == 1 and "" or "s")
            end
        end

        -- Add footer with update timestamp
        embed.footer = {
            text = updateText
        }

        -- Determine if we should POST (new message) or PATCH (edit existing)
        local method = "POST"
        local url = state.webhookUrl

        if state.statsMessageId and state.statsMessageId ~= "" then
            -- Edit existing message
            method = "PATCH"
            url = state.webhookUrl .. "/messages/" .. state.statsMessageId
            print("[Webhook] Editing existing stats message: " .. state.statsMessageId)
        else
            print("[Webhook] Creating new stats message")
        end

        local success, response = pcall(function()
            return request({
                Url = url,
                Method = method,
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({embeds = {embed}})
            })
        end)

        if not success then
            print("[Webhook] Request failed: " .. tostring(response))
            -- If editing failed, reset message ID and try creating new one next time
            if method == "PATCH" then
                state.statsMessageId = nil
                saveStatsMessageId("")
                print("[Webhook] Cleared saved message ID due to error")
            end
            return
        end

        -- If this was a new message (POST), save the message ID
        if method == "POST" and response and response.Body then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if decodeSuccess and data and data.id then
                state.statsMessageId = data.id
                saveStatsMessageId(data.id)
                print("[Webhook] Saved new message ID: " .. data.id)
            end
        end

        -- Save snapshot for next comparison
        state.lastStatsSnapshot = {
            bubbles = state.stats.bubbles,
            hatches = state.stats.hatches
        }
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

                        -- All 18 currencies (from diagnostic report)
                        local currencyMap = {
                            {key="tokens", name="Tokens"},
                            {key="tickets", name="Tickets"},
                            {key="seashells", name="Seashells"},
                            {key="festivalCoins", name="FestivalCoins"},
                            {key="pearls", name="Pearls"},
                            {key="leaves", name="Leaves"},
                            {key="candycorn", name="Candycorn"},
                            {key="ogPoints", name="OGPoints"},
                            {key="thanksgivingShards", name="ThanksgivingShards"},
                            {key="winterShards", name="WinterShards"},
                            {key="snowflakes", name="Snowflakes"},
                            {key="newYearsShard", name="NewYearsShard"},
                            {key="horns", name="Horns"},
                            {key="halos", name="Halos"},
                            {key="moonShards", name="MoonShards"}
                        }

                        for _, curr in pairs(currencyMap) do
                            local currFrame = currency:FindFirstChild(curr.name)
                            if currFrame then
                                local frame = currFrame:FindFirstChild("Frame")
                                if frame then
                                    local label = frame:FindFirstChild("Label")
                                    if label and label:IsA("TextLabel") then
                                        state.stats[curr.key] = label.Text
                                    end
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

-- ✅ FIXED: Teleport to Plate part for eggs, platform for rifts
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
            -- Regular egg teleport - use Plate part
            local plate = model:FindFirstChild("Plate")
            if plate then
                -- Teleport on top of the Plate
                hrp.CFrame = plate.CFrame + Vector3.new(0, 5, 0)  -- 5 studs above plate
            else
                -- Fallback if no Plate part found
                local cf = model:GetPivot()
                hrp.CFrame = cf + Vector3.new(0, 15, 8)  -- 15 studs up, 8 studs forward
            end
        end
    end)
end

-- === MAIN TAB ===
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

local StatsSection = MainTab:CreateSection("📊 Live Stats")

state.labels.runtime = MainTab:CreateLabel("Runtime: 00:00:00")
state.labels.bubbles = MainTab:CreateLabel("Bubbles: 0")
state.labels.hatches = MainTab:CreateLabel("Hatches: 0")

local CurrencySection = MainTab:CreateSection("💰 All Currencies")

-- Single dynamic label for all currencies (no empty space!)
state.labels.allCurrencies = MainTab:CreateLabel("Loading currencies...")

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

local AutoPickupToggle = FarmTab:CreateToggle({
   Name = "💰 Auto Collect Pickups",
   CurrentValue = false,
   Flag = "AutoPickup",
   Callback = function(Value)
      state.autoPickup = Value
      Rayfield:Notify({
         Title = "Auto Pickup",
         Content = Value and "Enabled - Collecting coins/gems" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

local AutoChestToggle = FarmTab:CreateToggle({
   Name = "📦 Auto Open Chests",
   CurrentValue = false,
   Flag = "AutoChest",
   Callback = function(Value)
      state.autoChest = Value
      Rayfield:Notify({
         Title = "Auto Chest",
         Content = Value and "Enabled - Opening all chests" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

local AutoSellBubblesToggle = FarmTab:CreateToggle({
   Name = "💸 Auto Sell Bubbles",
   CurrentValue = false,
   Flag = "AutoSellBubbles",
   Callback = function(Value)
      state.autoSellBubbles = Value
      Rayfield:Notify({
         Title = "Auto Sell",
         Content = Value and "Enabled - Selling bubbles for coins" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- DISABLED: Auto Claim Event Prizes (Not working correctly)
-- local AutoClaimEventToggle = FarmTab:CreateToggle({
--    Name = "🎁 Auto Claim Event Prizes",
--    CurrentValue = false,
--    Flag = "AutoClaimEvent",
--    Callback = function(Value)
--       state.autoClaimEventPrizes = Value
--       Rayfield:Notify({
--          Title = "Auto Claim Events",
--          Content = Value and "Enabled - Claiming event rewards" or "Disabled",
--          Duration = 2,
--          Image = 4483362458,
--       })
--    end,
-- })

local EventSection = FarmTab:CreateSection("👑 Event Detection")

state.labels.adminEvent = FarmTab:CreateLabel("👑 Admin Event: Not Active")

local AdminEventToggle = FarmTab:CreateToggle({
   Name = "👑 Auto Admin Abuse Event",
   CurrentValue = false,
   Flag = "AdminEvent",
   Callback = function(Value)
      state.adminEventActive = Value
      Rayfield:Notify({
         Title = "Admin Event Detector",
         Content = Value and "Monitoring for Admin/Super events" or "Disabled",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

FarmTab:CreateLabel("Detects: Super, Giftbox, Nostalgia, Music, Retro")
FarmTab:CreateLabel("Auto-teleports + sets as priority egg")

local ClaimSection = FarmTab:CreateSection("🎁 Auto Claim")

local AutoClaimToggle = FarmTab:CreateToggle({
   Name = "🎁 Auto Claim Playtime Gifts",
   CurrentValue = false,
   Flag = "AutoClaim",
   Callback = function(Value)
      state.autoClaimPlaytime = Value
      Rayfield:Notify({
         Title = "Auto Claim",
         Content = Value and "Enabled - Claiming gifts every minute" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

FarmTab:CreateLabel("Claims playtime rewards every 60 seconds")

-- === EGGS TAB ===
local EggsTab = Window:CreateTab("🥚 Eggs", 4483362458)

local EggsSection = EggsTab:CreateSection("🥚 Egg Management")

local EggDropdown = EggsTab:CreateDropdown({
   Name = "Egg List (choose your egg to auto hatch)",
   Options = {"Scanning..."},
   CurrentOption = {"Scanning..."},
   MultipleOptions = false,
   Flag = "EggSelect",
   Callback = function(Option)
      if Option and Option[1] then
         local selectedEgg = Option[1]

         -- Find and set as normal egg
         for _, egg in pairs(state.currentEggs) do
            if egg.name == selectedEgg then
               state.eggPriority = selectedEgg
               tpToModel(egg.instance)
               Rayfield:Notify({
                  Title = "Egg Selected",
                  Content = "Set normal egg: " .. selectedEgg,
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
   Name = "Enable Auto Hatch",
   CurrentValue = false,
   Flag = "AutoHatch",
   Callback = function(Value)
      state.autoHatch = Value
      if Value then
         state.lastEggPosition = nil
         Rayfield:Notify({
            Title = "Auto Hatch Enabled",
            Content = "Hatching eggs from: " .. (state.eggPriority or "Select an egg first!"),
            Duration = 3,
            Image = 4483362458,
         })
      else
         state.lastEggPosition = nil
         Rayfield:Notify({
            Title = "Auto Hatch Disabled",
            Content = "Stopped auto-hatching",
            Duration = 2,
         })
      end
   end,
})

EggsTab:CreateLabel("🚧 Disable egg hatching animation (coming soon)")

local PriorityEggSection = EggsTab:CreateSection("⭐ Egg Prioritizer Management")

EggsTab:CreateLabel("📋 Contains ALL eggs from game (auto-updates)")
EggsTab:CreateLabel("✨ Detects eggs even before they spawn")

local PriorityEggDropdown = EggsTab:CreateDropdown({
   Name = "Eggs to prioritize over normal egg",
   Options = {"Loading game data..."},
   CurrentOption = {"Loading game data..."},
   MultipleOptions = true,
   Flag = "PriorityEggs",
   Callback = function(Options)
      -- Store priority eggs list
      state.priorityEggs = Options
   end,
})

local PriorityEggToggle = EggsTab:CreateToggle({
   Name = "Enable/Disable Priority Egg Detection",
   CurrentValue = false,
   Flag = "PriorityEggMode",
   Callback = function(Value)
      state.priorityEggMode = Value
      Rayfield:Notify({
         Title = "Priority Egg Mode",
         Content = Value and "Will auto-switch to priority eggs" or "Priority detection disabled",
         Duration = 2,
      })
   end,
})

EggsTab:CreateLabel("Priority eggs auto-hatch when detected")

-- === RIFTS TAB ===
local RiftsTab = Window:CreateTab("🌌 Rifts", 4483362458)

local RiftsSection = RiftsTab:CreateSection("🌌 Rifts Management")

local RiftDropdown = RiftsTab:CreateDropdown({
   Name = "Rifts List (choose a rift in current active rift list)",
   Options = {"Scanning..."},
   CurrentOption = {"Scanning..."},
   MultipleOptions = false,
   Flag = "RiftSelect",
   Callback = function(Option)
      if Option and Option[1] then
         local selectedRift = Option[1]

         -- Extract rift name (before the " | ")
         local riftName = selectedRift:match("^(.+) |") or selectedRift

         -- Find and set as normal rift
         for _, rift in pairs(state.currentRifts) do
            if rift.name == riftName or rift.displayText == selectedRift then
               state.riftPriority = rift.name
               tpToModel(rift.instance)
               Rayfield:Notify({
                  Title = "Rift Selected",
                  Content = "Set rift: " .. rift.name,
                  Duration = 2,
                  Image = 4483362458,
               })
               break
            end
         end
      end
   end,
})

local RiftAutoHatchToggle = RiftsTab:CreateToggle({
   Name = "Enable Auto Hatch",
   CurrentValue = false,
   Flag = "RiftAutoHatch",
   Callback = function(Value)
      state.riftAutoHatch = Value
      Rayfield:Notify({
         Title = "Rift Auto Hatch",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2,
      })
   end,
})

RiftsTab:CreateLabel("🚧 Disable egg hatching animation (coming soon)")

local PriorityRiftSection = RiftsTab:CreateSection("⭐ Rift Prioritizer Management")

RiftsTab:CreateLabel("📋 Contains ALL rifts from game (auto-updates)")
RiftsTab:CreateLabel("✨ Detects rifts even before they spawn")
RiftsTab:CreateLabel("🚫 Event rifts filtered out automatically")

local PriorityRiftDropdown = RiftsTab:CreateDropdown({
   Name = "Rifts to prioritize over normal rift",
   Options = {"Loading game data..."},
   CurrentOption = {"Loading game data..."},
   MultipleOptions = true,
   Flag = "PriorityRifts",
   Callback = function(Options)
      -- Store priority rifts list
      state.priorityRifts = Options
   end,
})

local PriorityRiftToggle = RiftsTab:CreateToggle({
   Name = "Enable/Disable Priority Rift Detection",
   CurrentValue = false,
   Flag = "PriorityRiftMode",
   Callback = function(Value)
      state.riftPriorityMode = Value
      if Value then
         Rayfield:Notify({
            Title = "Priority Rift Enabled",
            Content = "Will auto-switch to priority rifts when they spawn",
            Duration = 3,
            Image = 4483362458,
         })
      else
         Rayfield:Notify({
            Title = "Priority Rift Disabled",
            Content = "Back to normal rift farming",
            Duration = 2,
         })
      end
   end,
})

RiftsTab:CreateLabel("Priority rifts auto-farm when detected")
RiftsTab:CreateLabel("Auto-scans rifts every 2 seconds")

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

local RaritySection = WebTab:CreateSection("🎨 Rarity Filter (Hatch Notifications)")

WebTab:CreateLabel("Only send webhook when you hatch:")

local RarityCommonToggle = WebTab:CreateToggle({
   Name = "⚪ Common",
   CurrentValue = false,
   Flag = "RarityCommon",
   Callback = function(Value)
      state.webhookRarities.Common = Value
   end,
})

local RarityUniqueToggle = WebTab:CreateToggle({
   Name = "🟢 Unique",
   CurrentValue = false,
   Flag = "RarityUnique",
   Callback = function(Value)
      state.webhookRarities.Unique = Value
   end,
})

local RarityRareToggle = WebTab:CreateToggle({
   Name = "🔵 Rare",
   CurrentValue = false,
   Flag = "RarityRare",
   Callback = function(Value)
      state.webhookRarities.Rare = Value
   end,
})

local RarityEpicToggle = WebTab:CreateToggle({
   Name = "🟣 Epic",
   CurrentValue = false,
   Flag = "RarityEpic",
   Callback = function(Value)
      state.webhookRarities.Epic = Value
   end,
})

local RarityLegendaryToggle = WebTab:CreateToggle({
   Name = "🟠 Legendary",
   CurrentValue = true,
   Flag = "RarityLegendary",
   Callback = function(Value)
      state.webhookRarities.Legendary = Value
   end,
})

local RaritySecretToggle = WebTab:CreateToggle({
   Name = "🟡 Secret",
   CurrentValue = true,
   Flag = "RaritySecret",
   Callback = function(Value)
      state.webhookRarities.Secret = Value
   end,
})

WebTab:CreateLabel("💡 Legendary & Secret enabled by default")

local ChanceSection = WebTab:CreateSection("🎲 Chance Filter")

local ChanceThresholdInput = WebTab:CreateInput({
   Name = "Minimum Rarity (1 in X)",
   PlaceholderText = "100000000",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local value = tonumber(Text)
      if value and value > 0 then
         state.webhookChanceThreshold = value
         local formatted = value >= 1000000 and string.format("%.1fM", value/1000000) or
                          value >= 1000 and string.format("%.1fK", value/1000) or tostring(value)
         Rayfield:Notify({
            Title = "Chance Filter Updated",
            Content = "Only sends pets rarer than 1/" .. formatted,
            Duration = 2,
         })
      else
         Rayfield:Notify({
            Title = "Invalid Value",
            Content = "Please enter a positive number",
            Duration = 2,
         })
      end
   end,
})

WebTab:CreateLabel("Only send pets with rarity ≥ threshold")
WebTab:CreateLabel("Example: 100000000 = only 1 in 100M+ pets")

local StatsSection = WebTab:CreateSection("📊 User Stats Webhook")

WebTab:CreateLabel("✨ Edits the same message (no spam!)")
WebTab:CreateLabel("Message ID saved locally, persists across rejoins")

local StatsWebhookToggle = WebTab:CreateToggle({
   Name = "📊 Enable Stats Webhook",
   CurrentValue = false,
   Flag = "StatsWebhook",
   Callback = function(Value)
      state.webhookStatsEnabled = Value
      if Value then
         -- Send first stats immediately
         SendStatsWebhook()
      end
      Rayfield:Notify({
         Title = "Stats Webhook",
         Content = Value and "Enabled - Sending stats periodically" or "Disabled",
         Duration = 2,
      })
   end,
})

local StatsIntervalSlider = WebTab:CreateSlider({
   Name = "Stats Interval (seconds)",
   Range = {30, 120},
   Increment = 5,
   CurrentValue = 60,
   Flag = "StatsInterval",
   Callback = function(Value)
      state.webhookStatsInterval = Value
      Rayfield:Notify({
         Title = "Interval Updated",
         Content = "Stats will send every " .. Value .. " seconds",
         Duration = 2,
      })
   end,
})

WebTab:CreateLabel("Shows: Username, stats, differences, rates/min")

local WebhookTestButton = WebTab:CreateButton({
   Name = "🧪 Test Webhook (Simple)",
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

WebTab:CreateButton({
   Name = "🎉 Test Pet Hatch Webhook",
   Callback = function()
      if state.webhookUrl == "" then
         Rayfield:Notify({
            Title = "Error",
            Content = "Add webhook URL first!",
            Duration = 3,
         })
         return
      end
      -- Send test with a random Secret pet
      local testPets = {"King Doggy", "The Overlord", "The Superlord", "Giant Crescent Empress"}
      local testPet = testPets[math.random(#testPets)]
      SendPetHatchWebhook(testPet, state.eggPriority or "Test Egg")
      Rayfield:Notify({
         Title = "Pet Hatch Test Sent",
         Content = testPet,
         Duration = 3,
      })
   end,
})

WebTab:CreateButton({
   Name = "📊 Test Stats Webhook",
   Callback = function()
      if state.webhookUrl == "" then
         Rayfield:Notify({
            Title = "Error",
            Content = "Add webhook URL first!",
            Duration = 3,
         })
         return
      end
      SendStatsWebhook()
      Rayfield:Notify({
         Title = "Stats Webhook Sent",
         Content = "Check your Discord!",
         Duration = 2,
      })
   end,
})

WebTab:CreateButton({
   Name = "🔄 Reset Stats Message (Force New)",
   Callback = function()
      state.statsMessageId = nil
      if delfile and isfile and isfile(STATS_MESSAGE_FILE) then
         pcall(delfile, STATS_MESSAGE_FILE)
      end
      Rayfield:Notify({
         Title = "Message Reset",
         Content = "Next stats webhook will create a new message",
         Duration = 3,
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
            networkRemote:FireServer("HatchEgg", state.eggPriority, 99)
            print("✅ Sent HatchEgg command for: " .. state.eggPriority .. " x99")
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

-- === STARTUP: LOAD ALL CHUNKS AND SCAN EGGS ===
print("🔍 Loading all game chunks and scanning for eggs...")

-- Load saved stats message ID (persists across rejoins)
loadStatsMessageId()

-- Load egg and rift data from game modules (auto-updates with game versions)
print("📦 Fetching egg and rift data from game...")
loadGameEggData()
loadGameRiftData()

task.spawn(function()
    pcall(function()
        -- Use RequestStreamAroundAsync to load all worlds
        local worlds = Workspace:FindFirstChild("Worlds")
        if worlds and player.RequestStreamAroundAsync then
            for _, world in pairs(worlds:GetChildren()) do
                if world:IsA("Model") then
                    local primary = world.PrimaryPart or world:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        print("  Loading chunks for:", world.Name)
                        player:RequestStreamAroundAsync(primary.Position)
                        task.wait(0.5)
                    end
                end
            end
            print("✅ All chunks loaded!")
        end

        -- Now scan all eggs and build database
        task.wait(1) -- Wait for everything to render

        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered then
            local eggCount = 0
            for _, folder in pairs(rendered:GetChildren()) do
                if folder.Name == "Chunker" then
                    for _, egg in pairs(folder:GetChildren()) do
                        if egg:IsA("Model") and egg:FindFirstChild("Plate") then
                            eggCount = eggCount + 1
                            local pos = egg:FindFirstChild("Prompt")
                            if pos and pos:IsA("BasePart") then
                                -- Determine which world this egg is in
                                local worldName = "Unknown"
                                local eggPos = pos.Position

                                -- Check which world boundary the egg is in
                                if worlds then
                                    for _, world in pairs(worlds:GetChildren()) do
                                        if world:IsA("Model") then
                                            local primary = world.PrimaryPart or world:FindFirstChildWhichIsA("BasePart")
                                            if primary then
                                                local dist = (primary.Position - eggPos).Magnitude
                                                if dist < 5000 then -- Within 5000 studs = same world
                                                    worldName = world.Name
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end

                                -- Store in database
                                state.eggDatabase[egg.Name] = {
                                    world = worldName,
                                    position = eggPos,
                                    model = egg
                                }
                            end
                        end
                    end
                end
            end
            print("✅ Egg database built: " .. eggCount .. " eggs cataloged")
        end
    end)
end)

-- === MAIN LOOPS ===

-- ✅ AUTO-SCAN: Rifts and Eggs (every 2 seconds) - Only refresh if data changed
local lastRiftData = ""
local lastEggData = ""

task.spawn(function()
    while task.wait(2) do
        -- Scan rifts (only for normal rift selection - spawned rifts)
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

        -- Scan eggs (only for normal egg selection - spawned eggs)
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

            -- Build dynamic currency text (only show non-zero and non-$1M values)
            local currencyLines = {}
            local currencies = {
                {emoji="💰", name="Coins", value=state.stats.coins},
                {emoji="💎", name="Gems", value=state.stats.gems},
                {emoji="🫧", name="Bubble Stock", value=state.stats.bubbleStock},
                {emoji="🎫", name="Tokens", value=state.stats.tokens},
                {emoji="🎟️", name="Tickets", value=state.stats.tickets},
                {emoji="🐚", name="Seashells", value=state.stats.seashells},
                {emoji="🎊", name="Festival Coins", value=state.stats.festivalCoins},
                {emoji="🦪", name="Pearls", value=state.stats.pearls},
                {emoji="🍂", name="Leaves", value=state.stats.leaves},
                {emoji="🍬", name="Candycorn", value=state.stats.candycorn},
                {emoji="⭐", name="OG Points", value=state.stats.ogPoints},
                {emoji="🦃", name="Thanksgiving Shards", value=state.stats.thanksgivingShards},
                {emoji="❄️", name="Winter Shards", value=state.stats.winterShards},
                {emoji="⛄", name="Snowflakes", value=state.stats.snowflakes},
                {emoji="🎆", name="New Years Shard", value=state.stats.newYearsShard},
                {emoji="👹", name="Horns", value=state.stats.horns},
                {emoji="😇", name="Halos", value=state.stats.halos},
                {emoji="🌙", name="Moon Shards", value=state.stats.moonShards}
            }

            for _, curr in pairs(currencies) do
                local val = tostring(curr.value)
                if val ~= "0" and val ~= "$1,000,000" then
                    table.insert(currencyLines, curr.emoji .. " " .. curr.name .. ": " .. val)
                end
            end

            -- Update single currency label with all active currencies
            if #currencyLines > 0 then
                state.labels.allCurrencies:Set(table.concat(currencyLines, "\n"))
            else
                state.labels.allCurrencies:Set("No active currencies")
            end
        end)

        updateStats()
    end
end)

-- ✅ ADMIN EVENT MONITOR: Watch for AdminIsland appearing
task.spawn(function()
    while task.wait(2) do
        if state.adminEventActive then
            pcall(function()
                -- Check if AdminIsland exists in Workspace
                local adminIsland = Workspace:FindFirstChild("AdminIsland")

                if adminIsland then
                    -- AdminIsland found! Look for the Super Egg
                    local rendered = Workspace:FindFirstChild("Rendered")
                    local superEgg = nil

                    if rendered then
                        for _, folder in pairs(rendered:GetChildren()) do
                            if folder.Name == "Chunker" then
                                superEgg = folder:FindFirstChild("Super Egg")
                                if superEgg and superEgg:FindFirstChild("Plate") then
                                    break
                                end
                            end
                        end
                    end

                    if superEgg then
                        pcall(function()
                            state.labels.adminEvent:Set("👑 Admin Event: Super Egg (ACTIVE!)")
                        end)

                        -- Teleport to the egg's Plate
                        local plate = superEgg:FindFirstChild("Plate")
                        if plate then
                            tpToModel(superEgg)
                            Rayfield:Notify({
                                Title = "🎉 Admin Event: Super Egg!",
                                Content = "Teleporting to Super Egg now!",
                                Duration = 4,
                                Image = 4483362458,
                            })

                            -- Set as priority egg
                            state.eggPriority = "Super Egg"
                            Rayfield:Notify({
                                Title = "🥚 Priority: Super Egg",
                                Content = "Now auto-hatching Super Egg!",
                                Duration = 3,
                            })
                        end
                    else
                        pcall(function()
                            state.labels.adminEvent:Set("👑 Admin Event: Island Active (No Egg Yet)")
                        end)
                    end
                else
                    -- No AdminIsland found
                    pcall(function()
                        state.labels.adminEvent:Set("👑 Admin Event: Not Active")
                    end)
                end
            end)
        end
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

        -- ✅ Auto Pickup (Collect all coins/gems)
        if state.autoPickup then
            pcall(function()
                local rendered = Workspace:FindFirstChild("Rendered")
                if rendered then
                    local pickups = rendered:FindFirstChild("Pickups")
                    if pickups then
                        for _, pickup in pairs(pickups:GetChildren()) do
                            if pickup:IsA("Model") or pickup:IsA("BasePart") then
                                pcall(function()
                                    networkRemote:FireServer("CollectPickup", pickup)
                                end)
                            end
                        end
                    end
                end
            end)
        end

        -- ✅ Auto Chest (NEW - Open all chests)
        if state.autoChest then
            pcall(function()
                local rendered = Workspace:FindFirstChild("Rendered")
                if rendered then
                    local chests = rendered:FindFirstChild("Chests")
                    if chests then
                        for _, chest in pairs(chests:GetChildren()) do
                            pcall(function()
                                networkRemote:FireServer("ClaimChest", chest.Name)
                            end)
                        end
                    end
                end
            end)
        end

        -- ✅ Auto Sell Bubbles (NEW - Convert bubbles to coins)
        if state.autoSellBubbles then
            pcall(function()
                networkRemote:FireServer("SellBubble")
            end)
        end

        -- DISABLED: Auto Claim Event Prizes (Not working correctly)
        -- if state.autoClaimEventPrizes then
        --     pcall(function()
        --         networkRemote:FireServer("ClaimEventPrize")
        --     end)
        -- end

        -- ✅ Auto Hatch (IMPLEMENTED - Smart teleport + max quantity)
        if state.autoHatch and state.eggPriority then
            pcall(function()
                -- ✅ RIFT PRIORITY: Check if priority rift is spawned
                if state.riftPriorityMode and state.riftPriority then
                    local priorityRiftSpawned = false
                    local priorityRiftInstance = nil

                    -- Check if priority rift is currently spawned
                    for _, rift in pairs(state.currentRifts) do
                        if rift.name == state.riftPriority then
                            priorityRiftSpawned = true
                            priorityRiftInstance = rift.instance
                            break
                        end
                    end

                    -- If priority rift is spawned, farm it instead of eggs
                    if priorityRiftSpawned and priorityRiftInstance then
                        -- Teleport to rift
                        tpToModel(priorityRiftInstance)
                        task.wait(0.15)

                        -- Hatch at rift location (rifts spawn eggs too!)
                        networkRemote:FireServer("HatchEgg", state.eggPriority, 99)
                        return  -- Skip normal egg hatching
                    end
                    -- If priority rift not spawned, skip auto-hatch (wait for rift)
                    return
                end

                -- Normal egg auto-hatch (no rift priority or rift priority disabled)
                -- Find the egg instance
                for _, egg in pairs(state.currentEggs) do
                    if egg.name == state.eggPriority then
                        local shouldTeleport = false

                        -- Check if player has moved away or is first time
                        if not state.lastEggPosition then
                            shouldTeleport = true
                            state.lastEggPosition = egg.instance:GetPivot().Position
                        else
                            -- Check if player is far from egg (more than 20 studs)
                            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local distance = (hrp.Position - state.lastEggPosition).Magnitude
                                if distance > 20 then
                                    shouldTeleport = true
                                    state.lastEggPosition = egg.instance:GetPivot().Position
                                end
                            end
                        end

                        -- Only teleport if needed
                        if shouldTeleport then
                            tpToModel(egg.instance)
                            task.wait(0.15)  -- Small delay after teleport
                        end

                        -- Always use 99 (game will cap to player's max)
                        networkRemote:FireServer("HatchEgg", state.eggPriority, 99)

                        break
                    end
                end
            end)
        end
    end
end)

-- ✅ AUTO-CLAIM PLAYTIME GIFTS: Every 60 seconds
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local networkRemote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(60) do
        if state.autoClaimPlaytime then
            pcall(function()
                networkRemote:FireServer("ClaimAllPlaytime")
                print("✅ Claimed playtime gifts")
            end)
        end
    end
end)

-- ✅ STATS WEBHOOK: Periodic updates
task.spawn(function()
    while task.wait(1) do
        if state.webhookStatsEnabled and state.webhookUrl ~= "" then
            -- Check if enough time has passed
            if not state.lastStatsWebhookTime or (tick() - state.lastStatsWebhookTime) >= state.webhookStatsInterval then
                SendStatsWebhook()
                state.lastStatsWebhookTime = tick()
            end
        end
    end
end)

-- === INITIAL SETUP ===
print("✅ Performing initial scans...")

-- Populate priority dropdowns with game data (all eggs/rifts, not just spawned ones)
task.spawn(function()
    task.wait(0.5)  -- Wait for game data to load

    if #state.gameEggList > 0 then
        pcall(function()
            PriorityEggDropdown:Refresh(state.gameEggList, true)
        end)
        print("✅ Priority egg list populated with " .. #state.gameEggList .. " eggs from game data")
    end

    if #state.gameRiftList > 0 then
        pcall(function()
            PriorityRiftDropdown:Refresh(state.gameRiftList, true)
        end)
        print("✅ Priority rift list populated with " .. #state.gameRiftList .. " rifts from game data")
    end
end)

-- Initial egg scan (for normal egg selection - only spawned eggs)
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
        print("✅ Found " .. #eggNames .. " spawned eggs")
    else
        print("⚠️ No eggs found yet")
    end
end)

-- Initial rift scan (for normal rift selection - only spawned rifts)
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
        print("✅ Found " .. #riftNames .. " spawned rifts")
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
print("   • Admin Events: Every 3 seconds")
print("   • Playtime Gifts: Every 60 seconds")
print("✅ ==========================================")
print("📋 Tabs:")
print("   🏠 Main - Live stats (ALL 18 currencies!)")
print("   🔧 Farm - Auto blow, pickup, event detector, playtime claim")
print("   🥚 Eggs - Auto-scanned eggs + auto hatch")
print("   🌌 Rifts - Auto-scanned rifts + priority mode")
print("   📊 Webhook - Pet hatches, stats, rarity filter")
print("   📋 Data - Pet information")
print("✅ ==========================================")
print("🎉 NEW WEBHOOK FEATURES:")
print("   • Rich pet hatch notifications (with stats)")
print("   • User stats webhook (with differences)")
print("   • Rarity filtering (multi-select)")
print("   • Chance threshold (only rare pets)")
print("   • Configurable stats interval (30-120s)")
print("✅ ==========================================")

Rayfield:Notify({
   Title = "🧼 BGSI Hub Ready!",
   Content = "Mobile-optimized | All systems active!",
   Duration = 5,
   Image = 4483362458,
})

print("🎉 BGSI Hub loaded successfully!")
print("💡 Rifts and eggs will auto-refresh every 2 seconds")
print("💡 Enable webhook for pet hatch notifications!")
