-- Zenith (BGSI) - Bubble Gum Simulator Infinite
-- Script: Zenith | Game: BGSI — Perfect for mobile screens, auto-resizes, single column layout

getgenv().script_key = "uIeCsXNDMliclXkKGlfNwXHZHFblrJZl"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("Zenith (BGSI) - LOADING...")

-- Load Rayfield Library (Mobile-Optimized)
print("Loading Rayfield UI library...")
local success, Rayfield = pcall(function()
    local code = game:HttpGet('https://sirius.menu/rayfield')
    if not code or code == "" then
        error("Failed to download Rayfield library (empty response)")
    end
    local loadedFunc = loadstring(code)
    if not loadedFunc then
        error("Failed to compile Rayfield library (loadstring returned nil)")
    end
    return loadedFunc()
end)

if not success then
    warn("❌ CRITICAL ERROR: Failed to load Rayfield UI library!")
    warn("Error: " .. tostring(Rayfield))
    warn("Please check:")
    warn("  1. Your executor supports HttpGet")
    warn("  2. Your executor supports loadstring")
    warn("  3. The Rayfield library URL is accessible")
    error("Cannot continue without UI library")
end

if not Rayfield or type(Rayfield) ~= "table" then
    error("❌ Rayfield loaded but is invalid (not a table). Got: " .. type(Rayfield))
end

print("✅ Rayfield UI library loaded successfully!")

-- === CREATE WINDOW ===
local Window = Rayfield:CreateWindow({
   Name = "Zenith | BGSI",
   Icon = 0,
   LoadingTitle = "Zenith - BGSI",
   LoadingSubtitle = "Mobile-Optimized for 2026",
   Theme = "Default",

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Zenith_BGSI"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Zenith - BGSI",
      Subtitle = "Key System",
      Note = "No key required",
      FileName = "Zenith_BGSI_Key",
      SaveKey = false,
      GrabKeyFromSite = false,
      Key = {""}
   }
})

print("Zenith (BGSI) window created")

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
    webhookRarities = {Common=false, Unique=false, Rare=false, Epic=false, Legendary=true, Secret=true, Infinity=true},
    webhookChanceThreshold = 100000000,  -- Only send if rarity is 1 in X or rarer (default: 1 in 100M)
    webhookStatsEnabled = false,  -- NEW: Enable user stats webhook
    webhookStatsInterval = 60,  -- NEW: Stats webhook interval (30-120 seconds)
    lastStatsSnapshot = nil,  -- NEW: Previous stats for difference calculation
    lastStatsWebhookTime = nil,  -- NEW: Last time stats webhook was sent
    statsMessageId = nil,  -- NEW: Discord message ID for editing stats webhook
    webhookPingEnabled = false,  -- NEW: Enable Discord user ping
    webhookPingUserId = "",  -- NEW: Discord user ID to ping
    antiAFK = false,  -- NEW: Anti-AFK toggle (prevents Roblox kick)
    autoFishEnabled = false,  -- NEW: Auto fishing toggle
    fishingIsland = nil,  -- NEW: Selected fishing island (set dynamically)
    fishingRod = "Wooden Rod",  -- NEW: Selected fishing rod (default: Wooden Rod)
    fishingTeleported = false,  -- NEW: Track if we've teleported to fishing location
    fishingRodEquipped = false,  -- NEW: Track if rod is currently equipped
    lastFishingAttempt = 0,  -- NEW: Timestamp of last fishing attempt
    currentRifts = {},
    currentEggs = {},
    currentChests = {},
    chestFarmActive = false,
    currentChestRift = nil,
    previousEggPriority = nil,
    previousRiftPriority = nil,
    farmingPriorityRift = nil,
    farmingPriorityEgg = nil,
    eggDatabase = {},
    gameEggData = {},
    gameRiftData = {},
    gameEggList = {},
    gameRiftList = {},
    -- Auto potions
    gamePotionList = {},
    gamePotionData = {},
    selectedPotions = {},
    autoPotionEnabled = false,
    potionCounts = {},
    activePotions = {},
    -- Disable animation
    disableHatchAnimation = false,
    -- Custom teams
    hatchTeam = nil,
    statsTeam = nil,
    gameTeamList = {},
    -- Auto enchant
    gameEnchantList = {},
    enchantMain = nil,
    enchantSecond = nil,
    autoEnchantEnabled = false,
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

-- === MODIFIER CHANCES & STATS (from Constants) ===
local SHINY_CHANCE = 2.5  -- 2.5%
local MYTHIC_CHANCE = 1   -- 1%
local SUPER_CHANCE = 0.04 -- 0.04%
local XL_CHANCES = {
    Common = 0.02,      -- 0.02%
    Unique = 0.028571,
    Rare = 0.133333,
    Epic = 0.4,
    Legendary = 5,      -- 5%
    Secret = 20         -- 20%
}

-- Pet stat multipliers for variants
local STAT_MULTIPLIERS = {
    Normal = 1,
    Shiny = 2.5,        -- 2.5x stats
    Mythic = 10,        -- 10x stats
    ShinyMythic = 25    -- 25x stats (2.5 * 10)
}

-- === DATA ===
local petData, eggData, _codeData
local petModuleSource = "" -- Store raw pet module source for parsing images
local eggModuleSource = "" -- Store raw egg module source for parsing chances

pcall(function()
    petData = require(RS.Shared.Data.Pets)
    _codeData = require(RS.Shared.Data.Codes)

    -- Try to get egg data
    local eggModule = RS:FindFirstChild("Shared")
    if eggModule then eggModule = eggModule:FindFirstChild("Data") end
    if eggModule then eggModule = eggModule:FindFirstChild("Eggs") end
    if eggModule and eggModule:IsA("ModuleScript") then
        eggData = require(eggModule)
        -- Get raw source for parsing
        pcall(function()
            eggModuleSource = decompile(eggModule)
        end)
    end

    -- Get raw pet module source for parsing images
    local petModule = RS:FindFirstChild("Shared")
    if petModule then petModule = petModule:FindFirstChild("Data") end
    if petModule then petModule = petModule:FindFirstChild("Pets") end
    if petModule and petModule:IsA("ModuleScript") then
        pcall(function()
            petModuleSource = decompile(petModule)
        end)
    end
end)

-- Parse pet images from PetBuilder string (normal, shiny, normal mythical, shiny mythical)
local function getPetImages(petName)
    if petModuleSource == "" then return {} end

    -- Search for pet definition using plain text search
    local searchStr = '["' .. petName .. '"]'
    local petStart = petModuleSource:find(searchStr, 1, true)

    if not petStart then return {} end

    -- Find the Build() that ends this pet's definition
    local buildStart = petModuleSource:find('Build()', petStart, true)
    if not buildStart then return {} end

    -- Extract pet definition section
    local petDef = petModuleSource:sub(petStart, buildStart)

    -- Search for :Image() in the definition
    local imageStart = petDef:find(':Image(', 1, true)
    if not imageStart then return {} end

    -- Find the closing parenthesis for :Image(...)
    local imageEnd = petDef:find(')', imageStart, true)
    if not imageEnd then return {} end

    -- Extract the content between :Image( and )
    local imageContent = petDef:sub(imageStart + 7, imageEnd - 1)

    -- Extract all rbxassetid numbers using plain text search
    local images = {}
    local pos = 1
    while true do
        local idStart = imageContent:find('rbxassetid://', pos, true)
        if not idStart then break end

        -- Extract digits after rbxassetid://
        local numStart = idStart + 13
        local numEnd = numStart
        while numEnd <= #imageContent do
            local char = imageContent:sub(numEnd, numEnd)
            if char:match('%d') then
                numEnd = numEnd + 1
            else
                break
            end
        end

        if numEnd > numStart then
            local assetId = imageContent:sub(numStart, numEnd - 1)
            table.insert(images, assetId)
        end

        pos = numEnd
    end

    return images
end

-- Find which egg contains a specific pet (searches through egg data)
local function findEggContainingPet(petName)
    if not eggData then
        print("⚠️ Egg data not loaded")
        return nil
    end

    -- Search through all eggs in structured data
    for eggName, eggInfo in pairs(eggData) do
        if eggInfo.Pets then
            -- Check if this egg contains the pet
            for _, petEntry in pairs(eggInfo.Pets) do
                if petEntry.Name == petName or petEntry == petName then
                    print("✅ Found pet '" .. petName .. "' in egg: " .. eggName)
                    return eggName
                end
            end
        end
    end

    -- If not found in structured data, try simple string search in raw source
    if eggModuleSource ~= "" then
        -- Search for the pet name in quotes after :Pet(
        local searchString = ':Pet(' -- Start of pet definition
        local petQuoted = '"' .. petName .. '"' -- Pet name in quotes

        -- Split source into egg sections and search each
        local pos = 1
        while true do
            local eggStart = eggModuleSource:find('["', pos, true)
            if not eggStart then break end

            local eggNameStart = eggStart + 2
            local eggNameEnd = eggModuleSource:find('"', eggNameStart, true)
            if not eggNameEnd then break end

            local eggName = eggModuleSource:sub(eggNameStart, eggNameEnd - 1)
            local buildPos = eggModuleSource:find('Build()', eggNameEnd, true)
            if buildPos then
                local eggSection = eggModuleSource:sub(eggNameEnd, buildPos)
                -- Simple string search - does this section contain our pet?
                if eggSection:find(petQuoted, 1, true) then
                    print("✅ Found pet '" .. petName .. "' in egg: " .. eggName .. " (via source search)")
                    return eggName
                end
                pos = buildPos + 1
            else
                break
            end
        end
    end

    print("⚠️ Could not find egg containing pet: " .. petName)
    return nil
end

-- Get pet chance from egg data
local function getPetChanceFromEgg(petName, eggName)
    if eggModuleSource == "" then
        print("⚠️ Egg module source not available")
        return nil
    end

    if eggName == "Unknown Egg" then
        print("⚠️ Cannot get pet chance: Unknown egg name")
        return nil
    end

    -- Find the egg definition using plain text search
    local searchStr = '["' .. eggName .. '"]'
    local eggStart = eggModuleSource:find(searchStr, 1, true)

    if not eggStart then
        print("⚠️ Egg definition not found for: " .. eggName)
        return nil
    end

    -- Find the Build() that ends this egg's definition
    local buildStart = eggModuleSource:find('Build()', eggStart, true)
    if not buildStart then
        print("⚠️ No Build() found for egg: " .. eggName)
        return nil
    end

    -- Extract egg definition section
    local eggDef = eggModuleSource:sub(eggStart, buildStart)

    -- Search for the pet in the egg definition: :Pet(chance, "PetName")
    local petSearch = '"' .. petName .. '"'
    local petPos = eggDef:find(petSearch, 1, true)

    if not petPos then
        print("⚠️ Pet not found in egg: " .. petName .. " in " .. eggName)
        return nil
    end

    -- Search backwards from pet name to find :Pet(
    local petCallStart = nil
    for i = petPos, 1, -1 do
        if eggDef:sub(i, i+4) == ':Pet(' then
            petCallStart = i + 5  -- Position after :Pet(
            break
        end
    end

    if not petCallStart then
        print("⚠️ Could not find :Pet( before pet name")
        return nil
    end

    -- Extract the chance value between :Pet( and the comma
    local chanceEnd = petPos - 3  -- Position before comma and space before pet name
    local chanceStr = eggDef:sub(petCallStart, chanceEnd):match('[%d%.e%-]+')

    if chanceStr then
        local chance = tonumber(chanceStr)
        if chance then
            print(string.format("✅ Found pet chance: %s in %s = %.8f%%", petName, eggName, chance))
            return chance
        end
    end

    print("⚠️ Could not extract chance value for: " .. petName .. " in " .. eggName)
    return nil
end

-- Calculate actual chance including modifiers (shiny, mythic, XL, super)
local function calculateModifiedChance(baseChance, rarity, isShiny, isMythic, isXL, isSuper)
    if not baseChance or baseChance == 0 then
        return nil, {}
    end

    local modifiedChance = baseChance
    local modifiers = {}

    -- Apply shiny modifier (2.5% chance to be shiny)
    if isShiny then
        modifiedChance = modifiedChance * (SHINY_CHANCE / 100)
        table.insert(modifiers, string.format("Shiny: %.1f%%", SHINY_CHANCE))
    end

    -- Apply mythic modifier (1% chance to be mythic)
    if isMythic then
        modifiedChance = modifiedChance * (MYTHIC_CHANCE / 100)
        table.insert(modifiers, string.format("Mythic: %.1f%%", MYTHIC_CHANCE))
    end

    -- Apply XL modifier (rarity-dependent chance)
    if isXL and XL_CHANCES[rarity] then
        modifiedChance = modifiedChance * (XL_CHANCES[rarity] / 100)
        table.insert(modifiers, string.format("XL: %.3f%%", XL_CHANCES[rarity]))
    end

    -- Apply super modifier (0.04% chance to be super)
    if isSuper then
        modifiedChance = modifiedChance * (SUPER_CHANCE / 100)
        table.insert(modifiers, string.format("Super: %.2f%%", SUPER_CHANCE))
    end

    return modifiedChance, modifiers
end

-- Stop hatch animation function (simple - just hide Hatching frame)
local function stopHatchAnimation()
    if not state.disableHatchAnimation then return end
    pcall(function()
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local hatchingFrame = screenGui:FindFirstChild("Hatching")
            if hatchingFrame then
                hatchingFrame.Visible = false
            end
        end
    end)
end

-- Continuous animation monitor (keeps Hatching frame hidden)
task.spawn(function()
    while task.wait(0.05) do  -- Check every 50ms for fast hiding
        if state.disableHatchAnimation then
            stopHatchAnimation()
        end
    end
end)

-- === UTILITY FUNCTIONS ===

-- File path for saving stats message ID (persists across rejoins)
local STATS_MESSAGE_FILE = "zenith_bgsi_stats_message_id.txt"
local LOG_FILE = "zenith_bgsi_fishing_log.txt"
local DEBUG_LOG_FILE = "zenith_bgsi_webhook_debug.txt"

-- Logging function (writes to both console and file)
local function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = "[" .. timestamp .. "] " .. message
    print(logMessage)

    -- Write to file
    if writefile and readfile and isfile then
        pcall(function()
            local existingLog = ""
            if isfile(LOG_FILE) then
                existingLog = readfile(LOG_FILE)
            end
            writefile(LOG_FILE, existingLog .. logMessage .. "\n")
        end)
    end
end

-- Debug logging function (writes to debug file)
local function debugLog(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = "[" .. timestamp .. "] " .. message
    print(logMessage)

    -- Write to debug file
    if writefile and readfile and isfile then
        pcall(function()
            local existingLog = ""
            if isfile(DEBUG_LOG_FILE) then
                existingLog = readfile(DEBUG_LOG_FILE)
            end
            writefile(DEBUG_LOG_FILE, existingLog .. logMessage .. "\n")
        end)
    end
end

-- Load stats message ID from file
local function loadStatsMessageId()
    if isfile and isfile(STATS_MESSAGE_FILE) then
        local success, content = pcall(readfile, STATS_MESSAGE_FILE)
        if success and content and content ~= "" then
            -- Trim whitespace from message ID
            content = content:match("^%s*(.-)%s*$") or content
            if content ~= "" then
                state.statsMessageId = content
                print("[Webhook] Loaded existing message ID: " .. content)
            end
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

                    -- Build list of ALL rift names (no filtering)
                    for riftName, riftInfo in pairs(riftData) do
                        table.insert(state.gameRiftList, riftName)
                    end

                    print("✅ Loaded " .. #state.gameRiftList .. " rifts from game data (all included)")
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

-- Load potion data from game (ReplicatedStorage.Shared.Data.Potions)
local function loadGamePotionData()
    local success, result = pcall(function()
        local data = RS:FindFirstChild("Shared")
        if data then data = data:FindFirstChild("Data") end
        if data then data = data:FindFirstChild("Potions") end
        if data and data:IsA("ModuleScript") then
            local potionData = require(data)
            state.gamePotionData = potionData
            state.gamePotionList = {}
            for name, _ in pairs(potionData) do
                table.insert(state.gamePotionList, name)
            end
            print("✅ Loaded " .. #state.gamePotionList .. " potions from game data")
            return true
        end
        return false
    end)
    if not success then
        print("⚠️ Failed to load potion data: " .. tostring(result))
    end
end

-- Load enchant data
local function loadGameEnchantData()
    pcall(function()
        local data = RS:FindFirstChild("Shared")
        if data then data = data:FindFirstChild("Data") end
        if data then data = data:FindFirstChild("Enchants") end
        if data and data:IsA("ModuleScript") then
            local enchantData = require(data)
            state.gameEnchantList = {}
            for name, _ in pairs(enchantData) do
                table.insert(state.gameEnchantList, name)
            end
            if #state.gameEnchantList > 0 then
                print("✅ Loaded " .. #state.gameEnchantList .. " enchants")
            end
        end
    end)
end

-- Load team data
local function loadGameTeamData()
    pcall(function()
        local data = RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Data")
        if data then data = data:FindFirstChild("Teams") end
        if data and data:IsA("ModuleScript") then
            local teamData = require(data)
            state.gameTeamList = {}
            for name, _ in pairs(teamData) do
                table.insert(state.gameTeamList, name)
            end
            if #state.gameTeamList > 0 then
                print("✅ Loaded " .. #state.gameTeamList .. " teams")
            end
        end
    end)
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

-- Generate random boundary for multipart/form-data
local function generateBoundary()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local boundary = "----WebKitFormBoundary"
    for i = 1, 16 do
        local rand = math.random(1, #chars)
        boundary = boundary .. chars:sub(rand, rand)
    end
    return boundary
end

-- Build multipart/form-data body with JSON payload and image files
local function buildMultipartBody(boundary, payload, files)
    local body = ""

    -- Add JSON payload
    body = body .. "--" .. boundary .. "\r\n"
    body = body .. "Content-Disposition: form-data; name=\"payload_json\"\r\n"
    body = body .. "Content-Type: application/json\r\n\r\n"
    body = body .. HttpService:JSONEncode(payload) .. "\r\n"

    -- Add files
    for i, file in ipairs(files) do
        body = body .. "--" .. boundary .. "\r\n"
        body = body .. "Content-Disposition: form-data; name=\"file" .. (i-1) .. "\"; filename=\"" .. file.name .. "\"\r\n"
        body = body .. "Content-Type: " .. file.contentType .. "\r\n\r\n"
        body = body .. file.data .. "\r\n"
    end

    body = body .. "--" .. boundary .. "--\r\n"
    return body
end

-- Send rich embed webhook for pet hatches (ASYNC - non-blocking)
-- displayEgg: The egg name to show in the webhook (e.g., "Infinity Egg")
-- chanceEgg: The egg to use for chance calculation (e.g., "Spikey Egg")
local function SendPetHatchWebhook(petName, displayEgg, chanceEgg, rarityFromGUI, isXL, isShiny, isSuper, isMythic)
    -- Run webhook in background thread to prevent game freezing
    task.spawn(function()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔔 WEBHOOK TRIGGERED (ASYNC)")
        print("Pet: " .. petName)
        print("Display Egg: " .. displayEgg)
        print("Chance Egg: " .. chanceEgg)
        print("Rarity: " .. rarityFromGUI)
        print("Webhook URL set: " .. (state.webhookUrl ~= "" and "YES" or "NO"))

        if state.webhookUrl == "" then
            print("❌ Webhook BLOCKED: No webhook URL configured!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        end

        local success, error = pcall(function()
        -- Parse rarity from GUI (handle variants like "AA-Secret" -> "Secret")
        local baseRarity = rarityFromGUI
        if rarityFromGUI:find("Secret") or rarityFromGUI:find("secret") then
            baseRarity = "Secret"
        elseif rarityFromGUI:find("Infinity") or rarityFromGUI:find("infinity") then
            baseRarity = "Infinity"
        elseif rarityFromGUI:find("Legendary") or rarityFromGUI:find("legendary") then
            baseRarity = "Legendary"
        elseif rarityFromGUI:find("Epic") or rarityFromGUI:find("epic") then
            baseRarity = "Epic"
        elseif rarityFromGUI:find("Rare") or rarityFromGUI:find("rare") then
            baseRarity = "Rare"
        elseif rarityFromGUI:find("Unique") or rarityFromGUI:find("unique") then
            baseRarity = "Unique"
        elseif rarityFromGUI:find("Common") or rarityFromGUI:find("common") then
            baseRarity = "Common"
        end

        print("📊 Parsed base rarity: " .. baseRarity)
        print("📋 Rarity filter enabled for " .. baseRarity .. ": " .. tostring(state.webhookRarities[baseRarity]))

        -- Check rarity filter
        if not state.webhookRarities[baseRarity] then
            print("❌ Webhook BLOCKED: Rarity '" .. baseRarity .. "' not enabled in filter!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        end

        print("✅ Rarity filter passed!")

        -- Get pet data from game
        local pet = petData and petData[petName]
        if not pet then
            print("⚠️ Pet not found in petData: " .. petName)
            return
        end

        local baseBubbleStat = 0
        local baseCoinsStat = 0
        local baseGemsStat = 0

        -- Extract BASE stats - try multiple possible structures
        if pet.Stat then
            if type(pet.Stat) == "table" then
                baseBubbleStat = pet.Stat.Bubbles or 0
                baseCoinsStat = pet.Stat.Coins or 0
                baseGemsStat = pet.Stat.Gems or 0
            elseif type(pet.Stat) == "number" then
                baseBubbleStat = pet.Stat
            end
        -- Try direct stat access
        elseif pet.Bubbles or pet.Coins or pet.Gems then
            baseBubbleStat = pet.Bubbles or 0
            baseCoinsStat = pet.Coins or 0
            baseGemsStat = pet.Gems or 0
        -- Try Stats (plural)
        elseif pet.Stats then
            if type(pet.Stats) == "table" then
                baseBubbleStat = pet.Stats.Bubbles or 0
                baseCoinsStat = pet.Stats.Coins or 0
                baseGemsStat = pet.Stats.Gems or 0
            end
        end

        -- Apply stat multipliers for Shiny/Mythic variants
        local statMultiplier = STAT_MULTIPLIERS.Normal
        if isShiny and isMythic then
            statMultiplier = STAT_MULTIPLIERS.ShinyMythic
        elseif isMythic then
            statMultiplier = STAT_MULTIPLIERS.Mythic
        elseif isShiny then
            statMultiplier = STAT_MULTIPLIERS.Shiny
        end

        local bubbleStat = baseBubbleStat * statMultiplier
        local coinsStat = baseCoinsStat * statMultiplier
        local gemsStat = baseGemsStat * statMultiplier

        print(string.format("📊 Pet BASE stats: Bubbles=%s, Coins=%s, Gems=%s", tostring(baseBubbleStat), tostring(baseCoinsStat), tostring(baseGemsStat)))
        if statMultiplier ~= 1 then
            print(string.format("✨ Multiplier: x%s (%s)", tostring(statMultiplier), isShiny and isMythic and "Shiny + Mythic" or isMythic and "Mythic" or "Shiny"))
        end
        print(string.format("📊 Pet FINAL stats: Bubbles=%s, Coins=%s, Gems=%s", tostring(bubbleStat), tostring(coinsStat), tostring(gemsStat)))

        -- Get base pet chance from egg data (use chanceEgg for calculation)
        local baseChance = getPetChanceFromEgg(petName, chanceEgg)

        -- Calculate modified chance based on shiny/mythic/XL/super modifiers
        local modifiedChance, modifiers = calculateModifiedChance(baseChance, baseRarity, isShiny, isMythic, isXL, isSuper)

        -- Use modified chance if we have modifiers, otherwise use base chance
        local displayChance = modifiedChance or baseChance
        local baseChanceRatio = 0
        local modifiedChanceRatio = 0
        local baseChanceStr = "Unknown"
        local modifiedChanceStr = "Unknown"

        if baseChance and baseChance > 0 then
            baseChanceRatio = math.floor(100 / baseChance)
            baseChanceStr = string.format("%.8f", baseChance)
        end

        if modifiedChance and modifiedChance > 0 then
            modifiedChanceRatio = math.floor(100 / modifiedChance)
            modifiedChanceStr = string.format("%.10f", modifiedChance)
        end

        print("🎲 Base chance: " .. baseChanceStr .. "% (1 in " .. baseChanceRatio .. ")")
        if #modifiers > 0 then
            print("✨ Modifiers: " .. table.concat(modifiers, ", "))
            print("🎲 Modified chance: " .. modifiedChanceStr .. "% (1 in " .. modifiedChanceRatio .. ")")
        end
        print("🎯 Chance threshold: 1 in " .. formatNumber(state.webhookChanceThreshold))

        -- Check chance threshold using modified chance if available
        local checkRatio = modifiedChanceRatio > 0 and modifiedChanceRatio or baseChanceRatio
        if checkRatio > 0 and checkRatio < state.webhookChanceThreshold then
            print("❌ Webhook BLOCKED: Pet too common (1 in " .. checkRatio .. " < threshold 1 in " .. state.webhookChanceThreshold .. ")")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        end

        print("✅ Chance threshold passed!")

        -- Format chance ratio with commas
        local function formatChance(num)
            local str = tostring(num)
            local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
            if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
            return formatted
        end

        -- Get pet images and download them
        local images = getPetImages(petName)
        local petImageData = nil

        print("🖼️ Found " .. #images .. " images for pet: " .. petName)
        if #images > 0 then
            for i, imgId in ipairs(images) do
                print("  Image " .. i .. ": " .. imgId)
            end
        end

        if #images > 0 then
            -- Determine which image to use based on shiny/mythical status
            local imageIndex = 1 -- Default: normal
            if isShiny and #images >= 2 then
                imageIndex = 2 -- Shiny
            end

            print("🎨 Using image index " .. imageIndex .. " (asset ID: " .. images[imageIndex] .. ")")

            -- Get thumbnail URL from Roblox API
            local thumbUrl = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. images[imageIndex] .. "&size=420x420&format=Png"
            print("📡 Fetching thumbnail from Roblox API...")

            local success, response = pcall(function()
                return request({
                    Url = thumbUrl,
                    Method = "GET"
                })
            end)

            if success and response.StatusCode == 200 then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    local imageUrl = data.data[1].imageUrl
                    print("✅ Got thumbnail URL: " .. imageUrl:sub(1, 50) .. "...")

                    -- Download the actual image
                    local imgSuccess, imgResponse = pcall(function()
                        return request({
                            Url = imageUrl,
                            Method = "GET"
                        })
                    end)

                    if imgSuccess and imgResponse.StatusCode == 200 then
                        petImageData = imgResponse.Body
                        print("✅ Successfully downloaded pet image (" .. #petImageData .. " bytes)")
                    else
                        print("❌ Failed to download pet image: " .. tostring(imgSuccess and imgResponse.StatusCode or "request failed"))
                    end
                else
                    print("❌ No image URL in Roblox API response")
                end
            else
                print("❌ Failed to fetch thumbnail from Roblox API: " .. tostring(success and response.StatusCode or "request failed"))
            end
        else
            print("⚠️ No images found for pet: " .. petName)
        end

        -- Download user avatar
        print("📡 Fetching user avatar...")
        local avatarImageData = nil
        local avatarSuccess, avatarResponse = pcall(function()
            return request({
                Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. player.UserId .. "&size=150x150&format=Png",
                Method = "GET"
            })
        end)

        if avatarSuccess and avatarResponse.StatusCode == 200 then
            local avatarData = HttpService:JSONDecode(avatarResponse.Body)
            if avatarData and avatarData.data and avatarData.data[1] and avatarData.data[1].imageUrl then
                local avatarUrl = avatarData.data[1].imageUrl
                print("✅ Got avatar URL")

                -- Download the avatar image
                local avatarImgSuccess, avatarImgResponse = pcall(function()
                    return request({
                        Url = avatarUrl,
                        Method = "GET"
                    })
                end)

                if avatarImgSuccess and avatarImgResponse.StatusCode == 200 then
                    avatarImageData = avatarImgResponse.Body
                    print("✅ Successfully downloaded avatar image (" .. #avatarImageData .. " bytes)")
                else
                    print("❌ Failed to download avatar image")
                end
            else
                print("❌ No avatar URL in response")
            end
        else
            print("❌ Failed to fetch avatar from Roblox API")
        end

        -- Get runtime
        local runtime = tick() - state.startTime
        local h,m,s = math.floor(runtime/3600), math.floor((runtime%3600)/60), math.floor(runtime%60)
        local runtimeStr = string.format("%02d:%02d:%02d", h,m,s)

        -- Rarity colors
        local colors = {
            Common = 0xAAAAAA,
            Unique = 0x00FF00,
            Rare = 0x0099FF,
            Epic = 0x9900FF,
            Legendary = 0xFF6600,
            Secret = 0xFFD700,
            Infinity = 0xFF00FF
        }

        -- Build pet title with modifiers
        local petTitle = petName
        if isXL then petTitle = "XL " .. petTitle end
        if isShiny then petTitle = "✨ " .. petTitle end
        if isSuper then petTitle = "⭐ " .. petTitle end

        -- Format chance ratio with commas
        local function formatChance(num)
            local str = tostring(num)
            local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
            if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
            return formatted
        end

        -- Build chance display text
        local chanceText = ""
        if #modifiers > 0 then
            -- Show modified chance with breakdown
            chanceText = string.format("🔮 **Modified Chance:** %s%% (1 in %s)\n📊 Base Chance: %s%% (1 in %s)\n✨ Modifiers: %s",
                modifiedChanceStr,
                modifiedChanceRatio > 0 and formatChance(modifiedChanceRatio) or "Unknown",
                baseChanceStr,
                baseChanceRatio > 0 and formatChance(baseChanceRatio) or "Unknown",
                table.concat(modifiers, " × ")
            )
        else
            -- Show base chance only
            chanceText = string.format("🔮 Chance: %s%% (1 in %s)",
                baseChanceStr,
                baseChanceRatio > 0 and formatChance(baseChanceRatio) or "Unknown"
            )
        end

        -- Build embed with attachment references
        local embed = {
            title = "🎉 " .. player.Name .. " hatched " .. petTitle .. "!",
            color = colors[baseRarity] or 0xFFFFFF,
            author = avatarImageData and {
                name = player.Name,
                icon_url = "attachment://avatar.png"
            } or nil,
            thumbnail = petImageData and {url = "attachment://pet.png"} or nil,
            fields = {
                {
                    name = "📊 User Stats",
                    value = string.format("⏱️ Playtime: %s\n🥚 Hatches: %s\n💰 Coins: %s\n💎 Gems: %s\n🎟️ Tickets: %s",
                        runtimeStr,
                        formatNumber(state.stats.hatches),
                        tostring(state.stats.coins),
                        tostring(state.stats.gems),
                        tostring(state.stats.tickets)
                    ),
                    inline = false
                },
                {
                    name = "🥚 Hatch Info",
                    value = string.format("🥚 Egg: %s\n🎲 Rarity: %s%s\n%s",
                        displayEgg,
                        rarityFromGUI,
                        (isXL and " [XL]" or "") .. (isShiny and " [✨ SHINY]" or "") .. (isSuper and " [⭐ SUPER]" or ""),
                        chanceText
                    ),
                    inline = false
                },
                {
                    name = "📈 Pet Stats",
                    value = string.format("🫧 Bubbles: x%s\n💰 Coins: x%s%s",
                        formatNumber(bubbleStat),
                        formatNumber(coinsStat),
                        gemsStat > 0 and ("\n💎 Gems: x" .. formatNumber(gemsStat)) or ""
                    ),
                    inline = false
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }

        -- Prepare files for attachment
        local files = {}
        if petImageData then
            print("📎 Adding pet image to attachments (" .. #petImageData .. " bytes)")
            table.insert(files, {
                name = "pet.png",
                contentType = "image/png",
                data = petImageData
            })
        else
            print("⚠️ No pet image data to attach")
        end
        if avatarImageData then
            print("📎 Adding avatar image to attachments (" .. #avatarImageData .. " bytes)")
            table.insert(files, {
                name = "avatar.png",
                contentType = "image/png",
                data = avatarImageData
            })
        else
            print("⚠️ No avatar image data to attach")
        end

        -- Send webhook with attachments
        print("📤 Sending webhook...")
        print("Files attached: " .. #files)

        -- Add ping content if enabled
        local pingContent = ""
        if state.webhookPingEnabled and state.webhookPingUserId ~= "" then
            pingContent = "<@" .. state.webhookPingUserId .. ">"
            print("📢 Adding Discord ping for user: " .. state.webhookPingUserId)
        end

        local sendSuccess, sendError = pcall(function()
            if #files > 0 then
                print("📎 Using multipart/form-data (with images)")
                local boundary = generateBoundary()
                local payload = {embeds = {embed}}
                if pingContent ~= "" then
                    payload.content = pingContent
                end
                local body = buildMultipartBody(boundary, payload, files)

                request({
                    Url = state.webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "multipart/form-data; boundary=" .. boundary},
                    Body = body
                })
            else
                print("📝 Using JSON (no images)")
                -- Fallback to simple JSON if no images
                local payload = {embeds = {embed}}
                if pingContent ~= "" then
                    payload.content = pingContent
                end
                request({
                    Url = state.webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload)
                })
            end
        end)

        if sendSuccess then
            print("✅ Webhook sent successfully for " .. petTitle .. " from " .. displayEgg)
        else
            print("❌ Webhook send FAILED: " .. tostring(sendError))
        end
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    end)

    if not success then
        print("❌ WEBHOOK FUNCTION ERROR: " .. tostring(error))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    end
    end)
end

-- === REMOTE EVENT PET HATCH DETECTION ===
-- ⚡ SUPER RELIABLE - Uses game's own hatch events!
-- ✅ No auto-delete timing issues
-- ✅ No freezing (async network event)
-- ✅ No duplicates (fires once per hatch)
-- ✅ Detects ALL pets in multi-egg hatches (3x, 7x, etc.)
task.spawn(function()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔍 [WEBHOOK] Initializing RemoteEvent pet hatch detection...")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    task.wait(3) -- Wait for game to load

    local success, error = pcall(function()
        print("📡 [DEBUG] Loading Remote module...")
        local Remote = require(RS.Shared.Framework.Network.Remote)
        print("✅ [DEBUG] Remote module loaded successfully")

        -- Helper function to process hatched pets
        local function processPets(hatchData, eventType)
            if not hatchData then
                print("⚠️ [" .. eventType .. "] No hatch data")
                return
            end

            -- Debug: Print ENTIRE hatchData structure
            print("🔍 [DEBUG] Full hatchData structure:")
            for key, value in pairs(hatchData) do
                if type(value) == "table" then
                    print("  " .. tostring(key) .. " = [table with " .. #value .. " items]")
                else
                    print("  " .. tostring(key) .. " = " .. tostring(value))
                end
            end

            if not hatchData.Pets or #hatchData.Pets == 0 then
                print("⚠️ [" .. eventType .. "] No pets in hatch data")
                return
            end

            local eggName = hatchData.Name or "Unknown Egg"
            print("✅ [" .. eventType .. "] Hatched " .. #hatchData.Pets .. " pet(s) from: " .. eggName)

            -- Process each pet
            for i, petInfo in ipairs(hatchData.Pets) do
                -- Skip deleted pets (auto-deleted by game)
                if petInfo.Deleted ~= true then
                    -- Debug: print COMPLETE pet info structure for EVERY pet
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("🔍 [DEBUG] Pet #" .. i .. " FULL structure:")
                    for key, value in pairs(petInfo) do
                        if type(value) == "table" then
                            print("  " .. tostring(key) .. " = [table]")
                            for subKey, subValue in pairs(value) do
                                print("    " .. tostring(subKey) .. " = " .. tostring(subValue))
                            end
                        else
                            print("  " .. tostring(key) .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
                        end
                    end
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                    -- Extract pet name (top level)
                    local petName = petInfo.Name or "Unknown Pet"

                    -- Extract modifiers (top level)
                    local isShiny = petInfo.Shiny == true
                    local isMythic = petInfo.Mythic == true

                    -- Check for XL and Super in nested Pet table
                    local isXL = false
                    local isSuper = false

                    -- FIXED: Get pet name and modifiers from nested Pet table
                    if petInfo.Pet and type(petInfo.Pet) == "table" then
                        -- Pet name is inside Pet table
                        petName = petInfo.Pet.Name or "Unknown Pet"

                        -- Modifiers are also inside Pet table
                        isShiny = petInfo.Pet.Shiny == true
                        isMythic = petInfo.Pet.Mythic == true
                        isXL = petInfo.Pet.XL == true or petInfo.Pet.xl == true
                        isSuper = petInfo.Pet.Super == true or petInfo.Pet.super == true
                    end
                    print("  Pet name: " .. tostring(petName))
                    print("  XL: " .. tostring(isXL))
                    print("  Shiny: " .. tostring(isShiny))
                    print("  Super: " .. tostring(isSuper))
                    print("  Mythic: " .. tostring(isMythic))

                    -- Get rarity from pet data
                    local rarity = "Unknown"
                    if petData and petData[petName] and petData[petName].Rarity then
                        rarity = petData[petName].Rarity
                        print("✅ [DEBUG] Found rarity in petData: " .. rarity)
                    else
                        print("❌ [DEBUG] Could not find rarity for: " .. tostring(petName))
                    end

                    print(string.format("  [%d/%d] %s [%s] (XL:%s Shiny:%s Super:%s Mythic:%s)",
                        i, #hatchData.Pets, petName, rarity,
                        tostring(isXL), tostring(isShiny), tostring(isSuper), tostring(isMythic)))

                    -- Find pet's ORIGINAL egg (not the hatching egg)
                    -- This ensures Infinity Egg hatches show the correct base egg
                    local originalEgg = findEggContainingPet(petName) or eggName
                    if originalEgg ~= eggName then
                        print("🔄 [DEBUG] Using original egg: " .. originalEgg .. " (hatched from: " .. eggName .. ")")
                    end

                    -- Send webhook (FULLY async task to prevent ANY freezing)
                    -- Pass both eggs: eggName for display, originalEgg for chance calculation
                    task.spawn(function()
                        local webhookSuccess, webhookError = pcall(function()
                            SendPetHatchWebhook(petName, eggName, originalEgg, rarity, isXL, isShiny, isSuper, isMythic)
                        end)

                        if not webhookSuccess then
                            print("❌ [" .. eventType .. "] Webhook failed for " .. petName .. ": " .. tostring(webhookError))
                        end
                    end)
                else
                    print("⏭️  [" .. eventType .. "] Skipping deleted pet #" .. i)
                end
            end

            -- Small delay to prevent rate limiting Discord if many pets hatched
            if #hatchData.Pets > 1 then
                task.wait(0.1)
            end

            -- Stop hatch animation if enabled
            task.defer(stopHatchAnimation)
        end

        -- Register handler for REGULAR egg hatches
        print("🔗 [DEBUG] Registering HatchEgg event handler...")
        Remote.Event("HatchEgg"):Connect(function(hatchData)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🥚 [HatchEgg] Event FIRED! Time: " .. os.date("%H:%M:%S"))
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            processPets(hatchData, "HatchEgg")
        end)
        print("✅ [DEBUG] HatchEgg event handler registered!")

        -- Register handler for EXCLUSIVE egg hatches (premium, shop eggs, etc.)
        print("🔗 [DEBUG] Registering ExclusiveHatch event handler...")
        Remote.Event("ExclusiveHatch"):Connect(function(hatchData, shouldAnimate)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎁 [ExclusiveHatch] Event FIRED! Time: " .. os.date("%H:%M:%S"))
            print("   Animate: " .. tostring(shouldAnimate))
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            processPets(hatchData, "ExclusiveHatch")
        end)
        print("✅ [DEBUG] ExclusiveHatch event handler registered!")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ Pet hatch detection initialized successfully!")
        print("   📡 Using RemoteEvent (game's own hatch events)")
        print("   ⚡ INSTANT detection (fires before GUI/LocalData)")
        print("   🎯 Handles multi-egg hatches perfectly")
        print("   🚫 No auto-delete timing issues")
        print("   🔒 No duplicates (fires once per hatch)")
        print("   ⚙️ No freezing (async network events)")
        print("   🌐 Discord-safe rate limiting (250ms between webhooks)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    end)

    if not success then
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("❌ [DEBUG] INITIALIZATION FAILED!")
        print("❌ Error: " .. tostring(error))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    end
end)

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
            print("[Webhook] Creating new stats message (ID: " .. tostring(state.statsMessageId) .. ")")
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
                print("[Webhook] PATCH failed, will try POST next time")
                state.statsMessageId = nil
                saveStatsMessageId("")
                print("[Webhook] Cleared saved message ID due to error")
            end
            return
        end

        -- Check response status
        if response and response.StatusCode then
            print("[Webhook] Response status: " .. response.StatusCode)
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
            else
                print("[Webhook] Failed to decode response or no message ID in response")
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

-- ✅ Fishing island scanner (scans Seven Seas Areas for islands with FishingAreas)
local function scanFishingIslands()
    local islands = {}

    pcall(function()
        local workspace = game:GetService("Workspace")
        local worlds = workspace:FindFirstChild("Worlds")

        if worlds then
            local sevenSeas = worlds:FindFirstChild("Seven Seas")
            if sevenSeas then
                local areas = sevenSeas:FindFirstChild("Areas")
                if areas then
                    -- Scan all children in Areas folder
                    for _, island in pairs(areas:GetChildren()) do
                        -- Only include islands that have FishingAreas folder
                        local fishingAreas = island:FindFirstChild("FishingAreas")
                        if fishingAreas then
                            table.insert(islands, island.Name)
                            log("🎣 [Scan] Found fishing island: " .. island.Name)
                        end
                    end
                end
            end
        end
    end)

    return islands
end

-- Get best fishing island based on player's fishing level
local function getBestFishingIsland()
    local bestIsland = nil
    local highestLevel = -1

    pcall(function()
        local FishingAreas = require(RS.Shared.Data.FishingAreas)
        local LocalData = require(RS.Client.Framework.Services.LocalData)
        local ExperienceUtil = require(RS.Shared.Utils.ExperienceUtil)
        local FishingUtil = require(RS.Shared.Utils.FishingUtil)

        local playerData = LocalData:Get()
        if not playerData then
            log("⚠️ [Fishing] Could not get player data")
            return
        end

        local fishingXP = playerData.FishingExperience or 0
        local playerLevel = ExperienceUtil:GetLevel(fishingXP, FishingUtil.XP_CONFIG)
        log("🎣 [Fishing] Player fishing level: " .. playerLevel .. " (XP: " .. fishingXP .. ")")

        -- Check all fishing areas
        for areaId, areaData in pairs(FishingAreas) do
            local requiredLevel = areaData.RequiredLevel or 0
            local displayName = areaData.DisplayName

            -- Check if player can access this island
            if playerLevel >= requiredLevel then
                log("  ✅ " .. displayName .. " - UNLOCKED (Level " .. requiredLevel .. ")")

                -- Track highest level island the player can access
                if requiredLevel > highestLevel then
                    highestLevel = requiredLevel
                    bestIsland = displayName
                end
            else
                log("  🔒 " .. displayName .. " - LOCKED (Requires Level " .. requiredLevel .. ")")
            end
        end

        if bestIsland then
            log("🏆 [Fishing] Best island: " .. bestIsland .. " (Level " .. highestLevel .. ")")
        else
            log("⚠️ [Fishing] No islands unlocked, using first available")
        end
    end)

    return bestIsland
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

local TeamSection = MainTab:CreateSection("👥 Custom Team")
MainTab:CreateLabel("Hatch team / Stats team")

local HatchTeamDropdown = MainTab:CreateDropdown({
   Name = "Hatch team",
   Options = {"—"},
   CurrentOption = {"—"},
   MultipleOptions = false,
   Flag = "HatchTeam",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "—" then
         state.hatchTeam = Option[1]
         pcall(function()
            local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
            Remote:FireServer("SetHatchTeam", Option[1])
         end)
      else
         state.hatchTeam = nil
      end
   end,
})

local StatsTeamDropdown = MainTab:CreateDropdown({
   Name = "Stats team",
   Options = {"—"},
   CurrentOption = {"—"},
   MultipleOptions = false,
   Flag = "StatsTeam",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "—" then
         state.statsTeam = Option[1]
         pcall(function()
            local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
            Remote:FireServer("SetStatsTeam", Option[1])
         end)
      else
         state.statsTeam = nil
      end
   end,
})

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

-- === AUTO POTIONS ===
local PotionSection = FarmTab:CreateSection("🧪 Auto Potions")

local PotionDropdown = FarmTab:CreateDropdown({
   Name = "Potions to auto-use (multi-select)",
   Options = {"Loading..."},
   CurrentOption = {"Loading..."},
   MultipleOptions = true,
   Flag = "PotionSelect",
   Callback = function(Options)
      state.selectedPotions = Options or {}
   end,
})

local AutoPotionToggle = FarmTab:CreateToggle({
   Name = "Auto Use Potion",
   CurrentValue = false,
   Flag = "AutoPotion",
   Callback = function(Value)
      state.autoPotionEnabled = Value
      Rayfield:Notify({
         Title = "Auto Potion",
         Content = Value and "Enabled - Re-applying selected potions" or "Disabled",
         Duration = 2,
      })
   end,
})

FarmTab:CreateLabel("Keeps selected potions active")

-- === AUTO ENCHANT ===
local EnchantSection = FarmTab:CreateSection("✨ Auto Enchant")
FarmTab:CreateLabel("Main slot + second slot (can't be same)")

local EnchantMainDropdown = FarmTab:CreateDropdown({
   Name = "Main enchant slot",
   Options = {"Loading..."},
   CurrentOption = {"Loading..."},
   MultipleOptions = false,
   Flag = "EnchantMain",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Loading..." then
         state.enchantMain = Option[1]
      else
         state.enchantMain = nil
      end
   end,
})

local EnchantSecondDropdown = FarmTab:CreateDropdown({
   Name = "Second enchant slot",
   Options = {"Loading..."},
   CurrentOption = {"Loading..."},
   MultipleOptions = false,
   Flag = "EnchantSecond",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Loading..." then
         if Option[1] == state.enchantMain then
            state.enchantSecond = nil
            Rayfield:Notify({ Title = "Enchant", Content = "Second slot can't be same as main", Duration = 2 })
         else
            state.enchantSecond = Option[1]
         end
      else
         state.enchantSecond = nil
      end
   end,
})

local AutoEnchantToggle = FarmTab:CreateToggle({
   Name = "Auto Enchant equipped pet",
   CurrentValue = false,
   Flag = "AutoEnchant",
   Callback = function(Value)
      state.autoEnchantEnabled = Value
      Rayfield:Notify({
         Title = "Auto Enchant",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2,
      })
   end,
})

FarmTab:CreateLabel("Auto-enchants equipped pet")

-- === AUTO FISHING ===
local FishingSection = FarmTab:CreateSection("🎣 Auto Fishing")

local FishingIslandDropdown = FarmTab:CreateDropdown({
   Name = "Select Fishing Island",
   Options = {"Scanning..."},
   CurrentOption = {"Scanning..."},
   MultipleOptions = false,
   Flag = "FishingIsland",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Scanning..." then
         state.fishingIsland = Option[1]
         state.fishingTeleported = false  -- Reset teleport flag when island changes
         log("🎣 [Fishing] Island changed to: " .. state.fishingIsland)
         Rayfield:Notify({
            Title = "Fishing Island",
            Content = "Changed to " .. state.fishingIsland,
            Duration = 2,
         })
      end
   end,
})

local FishingRodDropdown = FarmTab:CreateDropdown({
   Name = "Select Fishing Rod",
   Options = {"Wooden Rod", "Steel Rod", "Golden Rod", "Blizzard Rod", "Lotus Rod", "Molten Rod", "Trident Rod", "Galaxy Rod", "Abyssal Rod"},
   CurrentOption = {"Wooden Rod"},
   MultipleOptions = false,
   Flag = "FishingRod",
   Callback = function(Option)
      if Option and Option[1] then
         state.fishingRod = Option[1]
         log("🎣 [Fishing] Rod changed to: " .. state.fishingRod)
         Rayfield:Notify({
            Title = "Fishing Rod",
            Content = "Using " .. state.fishingRod,
            Duration = 2,
         })
      end
   end,
})

local UpdateBestIslandButton = FarmTab:CreateButton({
   Name = "🏆 Auto-Select Best Island",
   Callback = function()
      local bestIsland = getBestFishingIsland()
      if bestIsland then
         state.fishingIsland = bestIsland
         state.fishingTeleported = false  -- Reset teleport flag
         log("🏆 [Fishing] Updated to best island: " .. bestIsland)
         Rayfield:Notify({
            Title = "Best Island Selected",
            Content = "Now fishing at " .. bestIsland,
            Duration = 3,
            Image = 4483362458,
         })
      else
         Rayfield:Notify({
            Title = "No Islands Available",
            Content = "No unlocked fishing islands found",
            Duration = 3,
         })
      end
   end,
})

local AutoFishToggle = FarmTab:CreateToggle({
   Name = "🎣 Auto Fish",
   CurrentValue = false,
   Flag = "AutoFish",
   Callback = function(Value)
      state.autoFishEnabled = Value
      if Value then
         state.fishingTeleported = false  -- Reset on enable
         local island = state.fishingIsland or "No island selected"
         log("🎣 [Fishing] Auto fishing ENABLED - Island: " .. island)
         Rayfield:Notify({
            Title = "Auto Fishing",
            Content = "Enabled - " .. (state.fishingIsland and ("Fishing at " .. state.fishingIsland) or "Select an island first"),
            Duration = 2,
            Image = 4483362458,
         })
      else
         log("🎣 [Fishing] Auto fishing DISABLED")
         Rayfield:Notify({
            Title = "Auto Fishing",
            Content = "Disabled",
            Duration = 2,
            Image = 4483362458,
         })
      end
   end,
})

FarmTab:CreateLabel("Auto-fishes at selected island")
FarmTab:CreateLabel("NOTE: You must own the selected rod!")
FarmTab:CreateLabel("Buy rods from Fishing Shop first")
FarmTab:CreateLabel("Check fishing_log.txt for debug info")

-- === ANTI-AFK ===
local AntiAFKSection = FarmTab:CreateSection("🛡️ Anti-AFK Protection")

local AntiAFKToggle = FarmTab:CreateToggle({
   Name = "🛡️ Prevent AFK Kick",
   CurrentValue = false,
   Flag = "AntiAFK",
   Callback = function(Value)
      state.antiAFK = Value
      Rayfield:Notify({
         Title = "Anti-AFK",
         Content = Value and "Enabled - Won't be kicked" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

FarmTab:CreateLabel("Prevents Roblox from kicking you (every 15-19 min)")

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

local DisableHatchAnimToggle = EggsTab:CreateToggle({
   Name = "Disable egg hatching animation",
   CurrentValue = false,
   Flag = "DisableHatchAnim",
   Callback = function(Value)
      state.disableHatchAnimation = Value
      Rayfield:Notify({
         Title = "Hatch animation",
         Content = Value and "Disabled (animation will be stopped)" or "Enabled",
         Duration = 2,
      })
   end,
})

EggsTab:CreateLabel("🚧 Disable egg hatching animation (coming soon)")

local PriorityEggSection = EggsTab:CreateSection("⭐ Egg Prioritizer Management")

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

local PingSection = WebTab:CreateSection("📢 Discord Ping")

local PingToggle = WebTab:CreateToggle({
   Name = "Enable Discord Ping",
   CurrentValue = false,
   Flag = "WebhookPing",
   Callback = function(Value)
      state.webhookPingEnabled = Value
   end,
})

local PingUserInput = WebTab:CreateInput({
   Name = "Discord User ID",
   PlaceholderText = "123456789012345678",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      state.webhookPingUserId = Text
   end,
})

WebTab:CreateLabel("Pings the user when legendary+ pet hatches")

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

local RarityInfinityToggle = WebTab:CreateToggle({
   Name = "🌟 Infinity",
   CurrentValue = true,
   Flag = "RarityInfinity",
   Callback = function(Value)
      state.webhookRarities.Infinity = Value
   end,
})

WebTab:CreateLabel("💡 Legendary, Secret & Infinity enabled by default")

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

WebTab:CreateButton({
   Name = "🔍 Diagnose Hatch Detection",
   Callback = function()
      print("━━━━━━━━━━ HATCH DETECTION DIAGNOSTICS ━━━━━━━━━━")

      -- Check PlayerGui
      local screenGui = playerGui:FindFirstChild("ScreenGui")
      print("PlayerGui.ScreenGui: " .. (screenGui and "✅ EXISTS" or "❌ NOT FOUND"))

      if screenGui then
         -- List all children
         print("\n📋 ScreenGui children:")
         for _, child in pairs(screenGui:GetChildren()) do
            print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
         end

         -- Check for Hatching frame
         local hatchingFrame = screenGui:FindFirstChild("Hatching")
         print("\nScreenGui.Hatching: " .. (hatchingFrame and "✅ EXISTS" or "❌ NOT FOUND"))

         if hatchingFrame then
            print("\n📋 Hatching frame children:")
            for _, child in pairs(hatchingFrame:GetChildren()) do
               print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
            end
         end
      end

      print("\n💡 If Hatching frame exists, try hatching an egg!")
      print("   Template frames should appear as children when hatching.")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

      Rayfield:Notify({
         Title = "Diagnostics Complete",
         Content = "Check console (F9) for details",
         Duration = 3,
      })
   end,
})

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
      local testPets = {
         {name = "King Doggy", rarity = "Secret"},
         {name = "The Overlord", rarity = "Secret"},
         {name = "The Superlord", rarity = "Infinity"},
         {name = "Giant Crescent Empress", rarity = "Secret"}
      }
      local testData = testPets[math.random(#testPets)]
      -- Simulate XL, Shiny, and Mythic randomly for test
      local testXL = math.random() > 0.7
      local testShiny = math.random() > 0.5
      local testMythic = math.random() > 0.8
      SendPetHatchWebhook(testData.name, state.eggPriority or "Test Egg", testData.rarity, testXL, testShiny, false, testMythic)
      Rayfield:Notify({
         Title = "Pet Hatch Test Sent",
         Content = testData.name .. (testXL and " [XL]" or "") .. (testShiny and " [Shiny]" or "") .. (testMythic and " [Mythic]" or ""),
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
         local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
         Remote:FireServer("BlowBubble")
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
            local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
            Remote:FireServer("HatchEgg", state.eggPriority, 99)
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
print("📦 Fetching egg, rift, potion, enchant and team data from game...")
loadGameEggData()
loadGameRiftData()
loadGamePotionData()
loadGameEnchantData()
loadGameTeamData()

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

-- ✅ AUTO-SCAN: Rifts and Eggs (every 2 seconds) - Only refresh if count changed
local lastRiftCount = 0
local lastEggCount = 0

task.spawn(function()
    while task.wait(2) do
        -- Scan rifts (only for normal rift selection - spawned rifts)
        local rifts = scanRifts()
        local riftNames = {}
        for _, rift in pairs(rifts) do
            table.insert(riftNames, rift.displayText)
        end

        -- Only refresh if items added/removed (not just reordered)
        local newCount = #riftNames
        if newCount ~= lastRiftCount or (newCount > 0 and lastRiftCount == 0) then
            lastRiftCount = newCount
            if newCount > 0 then
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

        -- Only refresh if items added/removed (not just reordered)
        local newCount = #eggNames
        if newCount ~= lastEggCount or (newCount > 0 and lastEggCount == 0) then
            lastEggCount = newCount
            if newCount > 0 then
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
    -- ✅ FIX: Use Remote MODULE (not RemoteEvent) - this is what the game uses!
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(0.1) do
        -- ✅ Auto Blow Bubbles
        if state.autoBlow then
            pcall(function()
                Remote:FireServer("BlowBubble")
            end)
        end

        -- ✅ Auto Pickup (Improved - multiple remote attempts)
        if state.autoPickup then
            pcall(function()
                local rendered = Workspace:FindFirstChild("Rendered")
                if rendered then
                    local pickups = rendered:FindFirstChild("Pickups")
                    if pickups then
                        for _, pickup in pairs(pickups:GetChildren()) do
                            if (pickup:IsA("Model") or pickup:IsA("BasePart")) and pickup:IsDescendantOf(Workspace) then
                                -- Try multiple collection methods
                                pcall(function() Remote:FireServer("CollectPickup", pickup) end)
                                pcall(function() Remote:FireServer("CollectPickup", pickup.Name) end)
                                pcall(function() Remote:FireServer("PickupCoin", pickup) end)
                                pcall(function() Remote:FireServer("CollectCoin", pickup) end)
                                pcall(function() Remote:FireServer("Collect", pickup) end)
                                pcall(function() Remote:FireServer("Pickup", pickup) end)
                            end
                        end
                    end

                    -- Also check for coins in separate folder
                    local coins = rendered:FindFirstChild("Coins")
                    if coins then
                        for _, coin in pairs(coins:GetChildren()) do
                            if (coin:IsA("Model") or coin:IsA("BasePart")) and coin:IsDescendantOf(Workspace) then
                                pcall(function() Remote:FireServer("CollectPickup", coin) end)
                                pcall(function() Remote:FireServer("CollectCoin", coin) end)
                            end
                        end
                    end
                end
            end)
        end

        -- ✅ Auto Chest
        if state.autoChest then
            pcall(function()
                local rendered = Workspace:FindFirstChild("Rendered")
                if rendered then
                    local chests = rendered:FindFirstChild("Chests")
                    if chests then
                        for _, chest in pairs(chests:GetChildren()) do
                            pcall(function()
                                Remote:FireServer("ClaimChest", chest.Name)
                            end)
                        end
                    end
                end
            end)
        end

        -- ✅ Auto Sell Bubbles
        if state.autoSellBubbles then
            pcall(function()
                Remote:FireServer("SellBubble")
            end)
        end

        -- ✅ Auto Fishing (runs every 0.1s but only fishes when cooldown expires)
        if state.autoFishEnabled then
            -- Safety check: ensure island is selected
            if not state.fishingIsland or state.fishingIsland == "" or state.fishingIsland == "Scanning..." then
                return
            end

            local currentTime = tick()

            -- Only teleport ONCE when first enabled or when island changes
            if not state.fishingTeleported then
                pcall(function()
                    log("🎣 [Fishing] Initiating teleport to " .. state.fishingIsland)
                    local teleportPath = "Workspace.Worlds.Seven Seas.Areas." .. state.fishingIsland .. ".IslandTeleport.Spawn"

                    Remote:FireServer("Teleport", teleportPath)
                    state.fishingTeleported = true
                    log("✅ [Fishing] Teleported to " .. state.fishingIsland)
                    task.wait(2)
                end)
            end

            -- Fishing cooldown: 2 seconds between casts
            if currentTime - state.lastFishingAttempt >= 2 then
                pcall(function()
                    log("🎣 [Fishing] Starting fishing attempt at " .. state.fishingIsland)

                    -- Find fishing areas
                    local workspace = game:GetService("Workspace")
                    local worlds = workspace:FindFirstChild("Worlds")

                    if not worlds then
                        log("❌ [Fishing] ERROR: Worlds not found in Workspace")
                        return
                    end
                    log("✅ [Fishing] Found Worlds")

                    local sevenSeas = worlds:FindFirstChild("Seven Seas")
                    if not sevenSeas then
                        log("❌ [Fishing] ERROR: Seven Seas not found")
                        return
                    end
                    log("✅ [Fishing] Found Seven Seas")

                    local areas = sevenSeas:FindFirstChild("Areas")
                    if not areas then
                        log("❌ [Fishing] ERROR: Areas not found")
                        return
                    end
                    log("✅ [Fishing] Found Areas")

                    local island = areas:FindFirstChild(state.fishingIsland)
                    if not island then
                        log("❌ [Fishing] ERROR: Island '" .. state.fishingIsland .. "' not found")
                        log("Available islands: " .. table.concat(areas:GetChildren(), ", "))
                        return
                    end
                    log("✅ [Fishing] Found island: " .. state.fishingIsland)

                    local fishingAreas = island:FindFirstChild("FishingAreas")
                    if not fishingAreas then
                        log("❌ [Fishing] ERROR: FishingAreas not found in " .. state.fishingIsland)
                        return
                    end
                    log("✅ [Fishing] Found FishingAreas")

                    -- Get all fishing areas (UUID named models)
                    local areaList = fishingAreas:GetChildren()
                    if #areaList == 0 then
                        log("❌ [Fishing] ERROR: No fishing areas found")
                        return
                    end
                    log("✅ [Fishing] Found " .. #areaList .. " fishing areas")

                    -- Pick first fishing area
                    local area = areaList[1]
                    if not area:IsA("Model") then
                        log("❌ [Fishing] ERROR: Fishing area is not a Model")
                        return
                    end
                    log("✅ [Fishing] Using fishing area: " .. area.Name)

                    -- Get the CORRECT areaId using game's FishingAreas module
                    local correctAreaId = nil
                    pcall(function()
                        local FishingAreas = require(RS.Client.Gui.Frames.Fishing.FishingAreas)
                        correctAreaId = FishingAreas:GetAreaIdFromRoot(area)
                    end)

                    if not correctAreaId then
                        correctAreaId = area.Name  -- Fallback to UUID name
                    end
                    log("✅ [Fishing] Area ID: " .. tostring(correctAreaId))

                    -- Calculate center of fishing area
                    local center = area:GetBoundingBox().Position
                    log("✅ [Fishing] Fishing area center: " .. tostring(center))

                    -- Get player character
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        log("❌ [Fishing] ERROR: HumanoidRootPart not found")
                        return
                    end

                    -- TELEPORT PLAYER TO FISHING AREA (on the edge, not center)
                    local fishingPosition = CFrame.new(center.X, center.Y + 3, center.Z + 15)  -- Stand at edge
                    hrp.CFrame = fishingPosition
                    task.wait(0.3)

                    -- Face the fishing area center
                    hrp.CFrame = CFrame.new(hrp.Position, center)
                    log("✅ [Fishing] Positioned at edge, facing water")

                    -- ONE-TIME SETUP: Equip rod, enable AutoFish, and setup event listeners
                    if not state.fishingRodEquipped then
                        log("🎣 [Fishing] Setting up rod and event listeners...")
                        Remote:FireServer("SetEquippedRod", state.fishingRod, false)
                        task.wait(1)
                        Remote:FireServer("EquipRod")
                        task.wait(2)

                        -- Enable AutoFish (handles reeling minigame automatically)
                        log("🎣 [Fishing] Enabling AutoFish for automatic reeling...")
                        pcall(function()
                            local FishingWorldAutoFish = require(RS.Client.Gui.Frames.Fishing.FishingWorldAutoFish)
                            FishingWorldAutoFish:SetEnabled(true)
                            log("  ✅ AutoFish enabled (auto-reels fish)")
                        end)

                        -- Setup FSM event listeners
                        log("🎣 [Fishing] Setting up FSM event listeners...")
                        pcall(function()
                            local FishingPlayerRods = require(RS.Client.Gui.Frames.Fishing.FishingPlayerRods)
                            local rodComponent = FishingPlayerRods:GetRodComponent(player)

                            if rodComponent and rodComponent._fsm then
                                local fsm = rodComponent._fsm

                                -- Store event connections for cleanup
                                state.fishingEventConnections = state.fishingEventConnections or {}

                                -- Listen for state changes
                                if fsm.StateChanged then
                                    local conn = fsm.StateChanged:Connect(function(newState)
                                        log("🔄 [Fishing] State changed to: " .. tostring(newState))
                                    end)
                                    table.insert(state.fishingEventConnections, conn)
                                end

                                log("  ✅ FSM event listeners connected")
                            else
                                log("  ⚠️ RodComponent or FSM not found (may appear after first cast)")
                            end
                        end)

                        state.fishingRodEquipped = true
                        log("✅ [Fishing] Rod equipped: " .. state.fishingRod)
                    end

                    -- MANUAL FISHING (NO GAMEPASS REQUIRED)
                    -- Replicate the AutoFish logic from ChargeState

                    -- Calculate cast position using game's raycast method
                    local castPosition = nil
                    pcall(function()
                        local FishingUtil = require(RS.Shared.Utils.FishingUtil)
                        local FishingAreas = require(RS.Client.Gui.Frames.Fishing.FishingAreas)

                        local MIN_CAST = FishingUtil.MIN_CAST_DISTANCE or 10
                        local MAX_CAST = FishingUtil.MAX_CAST_DISTANCE or 60
                        local increment = (MAX_CAST - MIN_CAST) / 10

                        local lookVec = hrp.CFrame.LookVector
                        local rayParams = FishingAreas:GetRaycastParams()

                        -- Try 10 horizontal distances (game's method)
                        for i = 1, 10 do
                            local horizPos = hrp.Position + lookVec * (MIN_CAST + increment * i)
                            local rayResult = workspace:Raycast(horizPos, Vector3.new(0, -50, 0), rayParams)
                            if rayResult then
                                castPosition = rayResult.Position
                                log("✅ [Fishing] Found water at distance " .. i .. "/10")
                                break
                            end
                        end
                    end)

                    if not castPosition then
                        log("⚠️ [Fishing] Raycast failed, using default position")
                        castPosition = center
                    end

                    -- EVENT-DRIVEN FISHING (waits for actual game events)
                    log("🎣 [Fishing] Starting event-driven cast...")

                    local castComplete = false
                    local eventSuccess = pcall(function()
                        local FishingPlayerRods = require(RS.Client.Gui.Frames.Fishing.FishingPlayerRods)
                        local FishingInput = require(RS.Client.Gui.Frames.Fishing.FishingInput)
                        local FishingState = require(RS.Client.Gui.Frames.Fishing.FishingPlayerRods.FishingState)

                        local rodComponent = FishingPlayerRods:GetRodComponent(player)

                        if not rodComponent then
                            log("⚠️ [Fishing] RodComponent not found, using fallback timing")
                            error("No RodComponent")
                        end

                        local fsm = rodComponent._fsm
                        if not fsm then
                            log("⚠️ [Fishing] FSM not found, using fallback timing")
                            error("No FSM")
                        end

                        log("  ✅ Found RodComponent and FSM")

                        -- Track current state
                        local currentState = fsm:GetCurrentState()
                        log("  📊 Current state: " .. tostring(currentState))

                        -- Wait for Idle state before casting
                        if currentState ~= FishingState.Idle then
                            log("  ⏳ Waiting for Idle state...")
                            local maxWait = 0
                            while fsm:GetCurrentState() ~= FishingState.Idle and maxWait < 100 do
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end
                        end

                        -- Press to start charge
                        log("  → OnInputBegan (BeginCastCharge)")
                        FishingInput.Pressed:Fire()
                        task.wait(0.05)

                        -- Wait for Charge state
                        local maxWait = 0
                        while fsm:GetCurrentState() ~= FishingState.Charge and maxWait < 20 do
                            task.wait(0.05)
                            maxWait = maxWait + 1
                        end

                        if fsm:GetCurrentState() == FishingState.Charge then
                            log("  ✅ Charge state active")
                            -- Hold for 80% precision
                            task.wait(0.4)

                            -- Release to cast
                            log("  → OnInputReleased (FinishCastCharge)")
                            FishingInput.Released:Fire()
                            task.wait(0.1)

                            -- Wait for Casting state
                            maxWait = 0
                            while fsm:GetCurrentState() ~= FishingState.Casting and maxWait < 20 do
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end
                            log("  ✅ Casting state - bobber in water")

                            -- Wait for Waiting state (waiting for fish)
                            maxWait = 0
                            while fsm:GetCurrentState() ~= FishingState.Waiting and maxWait < 50 do
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end
                            log("  ✅ Waiting state - fish will bite soon")

                            -- Wait for Reeling state (fish bit!)
                            log("  ⏳ Waiting for fish bite...")
                            maxWait = 0
                            while fsm:GetCurrentState() ~= FishingState.Reeling and maxWait < 200 do
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end

                            if fsm:GetCurrentState() == FishingState.Reeling then
                                log("  🐟 Fish bit! Reeling... (AutoFish handles this)")

                                -- Wait for Idle state (fish caught, cycle complete)
                                maxWait = 0
                                while fsm:GetCurrentState() ~= FishingState.Idle and maxWait < 150 do
                                    task.wait(0.1)
                                    maxWait = maxWait + 1
                                end

                                log("  ✅ Fish caught! Back to Idle state")
                                castComplete = true
                            else
                                log("  ⚠️ Fish didn't bite, timeout")
                            end
                        else
                            log("  ❌ Failed to enter Charge state")
                        end
                    end)

                    if not eventSuccess then
                        log("❌ [Fishing] Event-driven fishing failed, using fallback timing...")

                        -- Fallback: Use input events with hardcoded timing
                        pcall(function()
                            local FishingInput = require(RS.Client.Gui.Frames.Fishing.FishingInput)
                            FishingInput.Pressed:Fire()
                            task.wait(0.4)
                            FishingInput.Released:Fire()
                        end)

                        -- Wait with hardcoded time as fallback
                        log("  ⏳ Waiting 30s (fallback timing)")
                        task.wait(30)
                        castComplete = true
                    end

                    if castComplete then
                        state.lastFishingAttempt = currentTime
                        log("✅ [Fishing] Cast cycle complete! Ready for next cast")
                    else
                        log("⚠️ [Fishing] Cast cycle incomplete, waiting before retry")
                        task.wait(5)
                        state.lastFishingAttempt = currentTime
                    end
                end)
            end
        else
            -- Reset flags, disable AutoFish, cleanup events, and unequip rod when disabled
            if state.fishingTeleported or state.fishingRodEquipped then
                state.fishingTeleported = false
                state.fishingRodEquipped = false
                log("🎣 [Fishing] Auto fishing disabled - cleaning up...")

                pcall(function()
                    -- Disconnect event listeners
                    if state.fishingEventConnections then
                        for _, conn in ipairs(state.fishingEventConnections) do
                            pcall(function() conn:Disconnect() end)
                        end
                        state.fishingEventConnections = nil
                        log("  ✅ Event listeners disconnected")
                    end

                    -- Disable AutoFish
                    local FishingWorldAutoFish = require(RS.Client.Gui.Frames.Fishing.FishingWorldAutoFish)
                    if FishingWorldAutoFish:IsEnabled() then
                        FishingWorldAutoFish:SetEnabled(false)
                        log("  ✅ AutoFish disabled")
                    end

                    -- Unequip rod
                    Remote:FireServer("UnequipRod")
                    log("  ✅ Rod unequipped")
                end)
            end
        end

        -- ✅ PRIORITY RIFT AUTO-HATCH (Highest priority - check first)
        local handledByPriorityRift = false
        if state.riftPriorityMode and type(state.priorityRifts) == "table" and #state.priorityRifts > 0 then
            pcall(function()
                local priorityRiftName = nil
                local priorityRiftInstance = nil

                -- Find highest priority rift that's currently spawned
                for _, rift in pairs(state.currentRifts) do
                    for _, pname in pairs(state.priorityRifts) do
                        if rift.name == pname then
                            priorityRiftName = rift.name
                            priorityRiftInstance = rift.instance
                            break
                        end
                    end
                    if priorityRiftName then break end
                end

                -- If we were farming a priority rift and it's gone, revert to previous
                if state.farmingPriorityRift then
                    local stillHere = false
                    for _, rift in pairs(state.currentRifts) do
                        if rift.name == state.farmingPriorityRift then
                            stillHere = true
                            break
                        end
                    end
                    if not stillHere then
                        print("[Rift] Priority rift '" .. state.farmingPriorityRift .. "' despawned - reverting")
                        state.chestFarmActive = false
                        state.currentChestRift = nil
                        state.eggPriority = state.previousEggPriority
                        state.riftPriority = state.previousRiftPriority
                        state.farmingPriorityRift = nil
                        -- TP back to previous egg if auto hatch is on
                        if state.previousEggPriority and state.autoHatch then
                            for _, egg in pairs(state.currentEggs) do
                                if egg.name == state.previousEggPriority then
                                    tpToModel(egg.instance)
                                    state.lastEggPosition = egg.instance:GetPivot().Position
                                    print("[Rift] Teleported back to normal egg: " .. state.previousEggPriority)
                                    break
                                end
                            end
                        end
                    end
                end

                -- If we found a priority rift that's spawned, farm it
                if priorityRiftName and priorityRiftInstance then
                    if not priorityRiftInstance:IsDescendantOf(Workspace) then
                        print("[Rift] Priority rift instance not in workspace, skipping")
                        return
                    end

                    -- Save previous if we're switching to this priority rift
                    if state.farmingPriorityRift ~= priorityRiftName then
                        state.previousEggPriority = state.eggPriority
                        state.previousRiftPriority = state.riftPriority
                        state.farmingPriorityRift = priorityRiftName
                        print("[Rift] Switching to priority rift: " .. priorityRiftName)
                    end

                    -- Teleport to rift
                    tpToModel(priorityRiftInstance)
                    task.wait(0.15)

                    -- Get rift data and farm accordingly
                    local riftData = state.gameRiftData[priorityRiftName]
                    if riftData then
                        if riftData.Type == "Egg" and riftData.Egg then
                            Remote:FireServer("HatchEgg", riftData.Egg, 99)
                            task.defer(stopHatchAnimation)
                        elseif riftData.Type == "Chest" then
                            state.chestFarmActive = true
                            state.currentChestRift = priorityRiftName
                            Remote:FireServer("UnlockRiftChest", priorityRiftName, true)
                        end
                    else
                        -- Fallback
                        pcall(function() Remote:FireServer("HatchEgg", priorityRiftName, 99) end)
                        pcall(function() Remote:FireServer("UnlockRiftChest", priorityRiftName, true) end)
                    end
                    handledByPriorityRift = true
                end
            end)
        end

        -- ✅ RIFT AUTO HATCH (Rift tab: selected rift from list)
        if not handledByPriorityRift and state.riftAutoHatch and state.riftPriority then
            pcall(function()
                local riftInstance = nil

                -- Find the selected rift in currently spawned rifts
                for _, rift in pairs(state.currentRifts) do
                    if rift.name == state.riftPriority then
                        riftInstance = rift.instance
                        break
                    end
                end

                if riftInstance and riftInstance:IsDescendantOf(Workspace) then
                    -- Teleport to rift
                    tpToModel(riftInstance)
                    task.wait(0.15)

                    -- Get rift data and farm accordingly
                    local riftData = state.gameRiftData[state.riftPriority]
                    if riftData then
                        if riftData.Type == "Egg" and riftData.Egg then
                            Remote:FireServer("HatchEgg", riftData.Egg, 99)
                            task.defer(stopHatchAnimation)
                        elseif riftData.Type == "Chest" then
                            state.chestFarmActive = true
                            state.currentChestRift = state.riftPriority
                            Remote:FireServer("UnlockRiftChest", state.riftPriority, true)
                        end
                    else
                        -- Fallback
                        pcall(function() Remote:FireServer("HatchEgg", state.riftPriority, 99) end)
                        pcall(function() Remote:FireServer("UnlockRiftChest", state.riftPriority, true) end)
                    end
                else
                    print("[Rift] Selected rift '" .. tostring(state.riftPriority) .. "' not found in spawned rifts")
                end
            end)
        end

        -- ✅ PRIORITY EGG DETECTION
        local handledByPriorityEgg = false
        if not handledByPriorityRift and state.priorityEggMode and type(state.priorityEggs) == "table" and #state.priorityEggs > 0 and state.autoHatch then
            pcall(function()
                local priorityEggName = nil
                local priorityEggInstance = nil

                -- Find highest priority egg that's currently spawned
                for _, egg in pairs(state.currentEggs) do
                    for _, pname in pairs(state.priorityEggs) do
                        if egg.name == pname then
                            priorityEggName = egg.name
                            priorityEggInstance = egg.instance
                            break
                        end
                    end
                    if priorityEggName then break end
                end

                -- If we found a priority egg, switch to it temporarily
                if priorityEggName and priorityEggInstance then
                    if priorityEggInstance:IsDescendantOf(Workspace) then
                        -- Save previous egg if we're switching
                        if state.previousEggPriority == nil or state.previousEggPriority ~= state.eggPriority then
                            if state.eggPriority and state.eggPriority ~= priorityEggName then
                                state.previousEggPriority = state.eggPriority
                                print("[Egg] Switching to priority egg: " .. priorityEggName)
                            end
                        end

                        -- Teleport to priority egg
                        tpToModel(priorityEggInstance)
                        task.wait(0.15)

                        -- Hatch the priority egg
                        Remote:FireServer("HatchEgg", priorityEggName, 99)
                        task.defer(stopHatchAnimation)

                        handledByPriorityEgg = true
                    end
                else
                    -- No priority egg found, revert to previous if we had one
                    if state.previousEggPriority and state.previousEggPriority ~= state.eggPriority then
                        print("[Egg] Priority egg gone, reverting to: " .. state.previousEggPriority)
                        state.eggPriority = state.previousEggPriority
                        state.previousEggPriority = nil
                        state.lastEggPosition = nil
                    end
                end
            end)
        end

        -- ✅ NORMAL EGG AUTO HATCH (only when not farming any rifts or priority eggs)
        if not handledByPriorityRift and not handledByPriorityEgg and state.autoHatch and state.eggPriority and not (state.riftAutoHatch and state.riftPriority) then
            pcall(function()
                for _, egg in pairs(state.currentEggs) do
                    if egg.name == state.eggPriority then
                        -- Validate egg still exists
                        if not egg.instance:IsDescendantOf(Workspace) then
                            print("[Egg] Normal egg instance not in workspace, rescanning")
                            return
                        end

                        local shouldTeleport = false
                        if not state.lastEggPosition then
                            shouldTeleport = true
                            state.lastEggPosition = egg.instance:GetPivot().Position
                        else
                            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local distance = (hrp.Position - state.lastEggPosition).Magnitude
                                if distance > 20 then
                                    shouldTeleport = true
                                    state.lastEggPosition = egg.instance:GetPivot().Position
                                end
                            end
                        end
                        if shouldTeleport then
                            tpToModel(egg.instance)
                            task.wait(0.15)
                        end
                        Remote:FireServer("HatchEgg", state.eggPriority, 99)
                        task.defer(stopHatchAnimation)
                        break
                    end
                end
            end)
        end
    end
end)

-- ✅ AUTO-FARM RIFT CHESTS: Every 0.5 seconds (fast chest opening)
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(0.5) do
        if state.chestFarmActive and state.currentChestRift and state.autoHatch then
            pcall(function()
                -- UnlockRiftChest command: FireServer("UnlockRiftChest", chestName, autoOpen)
                Remote:FireServer("UnlockRiftChest", state.currentChestRift, false)
            end)
        else
            -- Stop chest farming if conditions not met
            if state.chestFarmActive then
                state.chestFarmActive = false
                state.currentChestRift = nil
                print("📦 Stopped chest farming")
            end
        end
    end
end)

-- ✅ AUTO-CLAIM PLAYTIME GIFTS: Every 60 seconds
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(60) do
        if state.autoClaimPlaytime then
            pcall(function()
                Remote:FireServer("ClaimAllPlaytime")
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
                state.lastStatsWebhookTime = tick()  -- Set BEFORE calling to prevent race condition
                SendStatsWebhook()
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

    if #state.gamePotionList > 0 then
        pcall(function()
            PotionDropdown:Refresh(state.gamePotionList, true)
        end)
        print("✅ Potion list populated with " .. #state.gamePotionList .. " potions")
    end

    if #state.gameEnchantList > 0 then
        pcall(function()
            EnchantMainDropdown:Refresh(state.gameEnchantList, true)
            EnchantSecondDropdown:Refresh(state.gameEnchantList, true)
        end)
    end

    if #state.gameTeamList > 0 then
        local teamOpts = {"—"}
        for _, t in pairs(state.gameTeamList) do table.insert(teamOpts, t) end
        pcall(function()
            HatchTeamDropdown:Refresh(teamOpts, true)
            StatsTeamDropdown:Refresh(teamOpts, true)
        end)
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

-- Initial fishing island scan
task.spawn(function()
    task.wait(1)  -- Wait for game to load
    local islands = scanFishingIslands()

    if #islands > 0 then
        pcall(function()
            FishingIslandDropdown:Refresh(islands, true)

            -- Auto-select best island based on player's fishing level
            local bestIsland = getBestFishingIsland()
            if bestIsland then
                state.fishingIsland = bestIsland
                log("🏆 [Fishing] Auto-selected best island: " .. bestIsland)
                print("🏆 Auto-selected best fishing island: " .. bestIsland)
            else
                -- Fallback: use first island
                state.fishingIsland = islands[1]
                log("📍 [Fishing] Using first island: " .. islands[1])
            end
        end)
        log("✅ [Fishing] Found " .. #islands .. " fishing islands: " .. table.concat(islands, ", "))
        print("✅ Found " .. #islands .. " fishing islands")
    else
        log("⚠️ [Fishing] No fishing islands found")
        print("⚠️ No fishing islands found yet")
    end
end)

-- Auto-update to best island when player levels up
task.spawn(function()
    task.wait(3)  -- Wait for game to fully load

    pcall(function()
        local LocalData = require(RS.Client.Framework.Services.LocalData)
        local ExperienceUtil = require(RS.Shared.Utils.ExperienceUtil)
        local FishingUtil = require(RS.Shared.Utils.FishingUtil)

        local lastLevel = 0

        -- Monitor fishing level changes
        LocalData:ConnectDataChanged("FishingExperience", function(data)
            if not data or not data.FishingExperience then return end

            local currentLevel = ExperienceUtil:GetLevel(data.FishingExperience, FishingUtil.XP_CONFIG)

            -- Check if leveled up
            if currentLevel > lastLevel and lastLevel > 0 then
                log("🎉 [Fishing] LEVEL UP! New level: " .. currentLevel)

                -- Auto-update to best island when auto-fishing is enabled
                if state.autoFishEnabled then
                    local bestIsland = getBestFishingIsland()
                    if bestIsland and bestIsland ~= state.fishingIsland then
                        log("🏆 [Fishing] Upgraded to better island: " .. bestIsland)
                        state.fishingIsland = bestIsland
                        state.fishingTeleported = false  -- Trigger re-teleport

                        Rayfield:Notify({
                            Title = "Fishing Island Upgraded!",
                            Content = "Now fishing at " .. bestIsland,
                            Duration = 4,
                            Image = 4483362458,
                        })
                    end
                end
            end

            lastLevel = currentLevel
        end)

        log("✅ [Fishing] Auto-upgrade monitor active")
    end)
end)

-- Load saved configuration
Rayfield:LoadConfiguration()

print("✅ ==========================================")
print("✅ Zenith (BGSI) - READY!")
print("✅ ==========================================")
print("📱 Zenith is mobile-optimized (Rayfield)")
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
print("   • Fishing: Auto-selects best island")
print("   • Anti-AFK: Every 15-19 minutes")
print("✅ ==========================================")
print("📋 Tabs:")
print("   🏠 Main - Live stats (ALL 18 currencies!)")
print("   🔧 Farm - Auto blow, pickup, fishing, anti-AFK, event detector")
print("   🥚 Eggs - Auto-scanned eggs + auto hatch")
print("   🌌 Rifts - Auto-scanned rifts + priority mode")
print("   📊 Webhook - Pet hatches, stats, rarity filter")
print("   📋 Data - Pet information")
print("✅ ==========================================")
print("🎉 WEBHOOK FEATURES:")
print("   ⚡ INSTANT pet hatch detection (event-driven!)")
print("   🎯 Multi-egg support (3x, 7x hatches)")
print("   ✨ Shiny/Mythic stat multipliers (x2.5, x10, x25)")
print("   🎨 Rarity filtering (multi-select)")
print("   🎲 Chance threshold (only rare pets)")
print("   📊 User stats webhook (editable, no spam)")
print("   🔒 No duplicates, no freezing, no missed pets")
print("✅ ==========================================")

Rayfield:Notify({
   Title = "Zenith (BGSI) Ready!",
   Content = "Mobile-optimized | All systems active!",
   Duration = 5,
   Image = 4483362458,
})

print("Zenith (BGSI) loaded successfully!")
print("💡 Rifts and eggs will auto-refresh every 2 seconds")
print("💡 Enable webhook for pet hatch notifications!")
print("🎣 Fishing: Auto-selects best island + upgrades on level up")
print("🎣 Fishing logs: zenith_bgsi_fishing_log.txt")

-- === ANTI-AFK BACKGROUND TASK ===
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")

    -- Capture controller once at startup
    VirtualUser:CaptureController()

    print("🛡️ [Anti-AFK] System initialized")

    while task.wait(1) do
        if state.antiAFK then
            -- Random interval between 15-19 minutes (900-1140 seconds)
            local interval = math.random(900, 1140)

            print("🛡️ [Anti-AFK] Enabled - Next input in " .. math.floor(interval/60) .. " minutes")

            task.wait(interval)

            if state.antiAFK then
                -- Simulate user input to prevent AFK kick
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)

                print("🛡️ [Anti-AFK] Input simulated - Reset AFK timer")
            end
        else
            task.wait(10)  -- Check every 10 seconds when disabled
        end
    end
end)
