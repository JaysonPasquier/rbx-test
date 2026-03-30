-- Lorio (BGSI) - Bubble Gum Simulator Infinite
-- Script: Lorio | Game: BGSI — Perfect for mobile screens, auto-resizes, single column layout

getgenv().script_key = "uIeCsXNDMliclXkKGlfNwXHZHFblrJZl"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cross-executor HTTP request compatibility (used by webhooks)
local request = request
    or http_request
    or (syn and syn.request)
    or (fluxus and fluxus.request)
    or (http and http.request)
    or (getgenv and getgenv().request)

-- Load Rayfield Library (Mobile-Optimized)
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
-- warn("❌ CRITICAL ERROR: Failed to load Rayfield UI library!")
-- warn("Error: " .. tostring(Rayfield))
-- warn("Please check:")
-- warn("  1. Your executor supports HttpGet")
-- warn("  2. Your executor supports loadstring")
-- warn("  3. The Rayfield library URL is accessible")
    error("Cannot continue without UI library")
end

if not Rayfield or type(Rayfield) ~= "table" then
    error("❌ Rayfield loaded but is invalid (not a table). Got: " .. type(Rayfield))
end

-- === CREATE WINDOW ===
local Window = Rayfield:CreateWindow({
   Name = "Lorio | BGSI",
   Icon = 0,
   LoadingTitle = "Lorio - BGSI",
   LoadingSubtitle = "Mobile-Optimized for 2026",
   Theme = "Default",

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,

   ConfigurationSaving = {
      Enabled = false,  -- Disabled: Using custom JSON config system instead
      FolderName = nil,
      FileName = "Lorio_BGSI"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Lorio - BGSI",
      Subtitle = "Key System",
      Note = "No key required",
      FileName = "Lorio_BGSI_Key",
      SaveKey = false,
      GrabKeyFromSite = false,
      Key = {""}
   }
})

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
    webhookRarities = {Common=false, Unique=false, Rare=false, Epic=false, Legendary=true, Secret=true, Infinity=true, Celestial=true},
    webhookChanceThreshold = 100000000,  -- Only send if rarity is 1 in X or rarer (default: 1 in 100M)
    webhookStatsEnabled = false,  -- NEW: Enable user stats webhook
    webhookStatsInterval = 60,  -- NEW: Stats webhook interval (30-120 seconds)
    lastStatsSnapshot = nil,  -- NEW: Previous stats for difference calculation
    lastStatsWebhookTime = nil,  -- NEW: Last time stats webhook was sent
    statsMessageId = nil,  -- NEW: Discord message ID for editing stats webhook
    webhookPingEnabled = false,  -- NEW: Enable Discord user ping
    webhookPingUserId = "",  -- NEW: Discord user ID to ping
    webhookDebugEnabled = false,  -- Keep verbose webhook debug off by default (performance)
    antiAFK = false,  -- NEW: Anti-AFK toggle (prevents Roblox kick)
    autoFishEnabled = false,  -- NEW: Auto fishing toggle
    autoCollectFlowers = false,  -- NEW: Auto collect event flowers
    autoWheelSpin = false,  -- Legacy field (unused for Easter event)
    autoFlowersEgg = false,  -- NEW: Auto collect flowers + egg hatching combo
    flowersEggChoice = "Spring Egg",  -- NEW: Which egg to use (Spring Egg or Petal Egg)
    lastFlowerEggTeleport = 0,  -- NEW: Timestamp for 10-second re-teleport to egg
    springEventActive = false,  -- NEW: Track if Spring event is active
    easterAutoPickup = false,
    easterAutoShop = false,
    easterShopTier = 1,
    easterSecretShop = false,
    easterAutoEgg = false,
    easterAutoChest = false,
    easterAutoHunt = false,
    easterAutoJester = false,
    easterAutoClaimRewards = false,
    easterAutoMastery = false,
    easterAdvancedShop = false,
    easterPickupZone = "Spawn Island",
    easterSelectedEgg = nil,
    easterPriorityEggMode = false,
    easterPriorityEggs = {"4x Luck Easter Bunny Egg"},
    easterShopId = "easter-shop",
    easterHatchAmount = 3,
    easterLowLagHatch = false,
    easterLastEggPosition = nil,
    easterReturnOrigCf = nil,
    easterReturnSunk = false,
    easterHideEggAnim = false,
    lastEasterShopBuy = 0,
    lastEasterSecretShopBuy = 0,
    lastEasterEggHatch = 0,
    lastEasterChestClaim = 0,
    lastEasterHuntAction = 0,
    lastEasterJesterAttempt = 0,
    lastEasterRewardClaim = 0,
    lastEasterMasteryUpgrade = 0,
    lastEasterAdvancedShopBuy = 0,
    lastEasterWorldTeleport = 0,
    easterPickupWarmupUntil = 0,
    easterLastEggTarget = nil,
    lastEasterEggScan = 0,
    easterHuntStatusText = "Hunt: waiting for data",
    easterMilestoneStatusText = "Milestones: waiting for data",
    currentEventEggs = {},
    performanceMode = false,
    performanceLightingBackup = nil,
    performancePostEffects = {},
    performanceFxObjects = {},
    fishingIsland = nil,  -- NEW: Selected fishing island (set dynamically)
    fishingRod = "Wooden Rod",  -- NEW: Selected fishing rod (default: Wooden Rod)
    fishingTeleported = false,  -- NEW: Track if we've teleported to fishing location
    fishingRodEquipped = false,  -- NEW: Track if rod is currently equipped
    lastFishingAttempt = 0,  -- NEW: Timestamp of last fishing attempt
    fishingAreaIndex = 1,  -- NEW: Current fishing area index (cycles through spots if stuck)
    lastSuccessfulCast = 0,  -- NEW: Timestamp of last successful cast (to detect stuck spots)
    fishingStuckCheckTime = 0,  -- NEW: Time when we started checking if stuck
    autoObbyFarm = false,  -- NEW: Auto-farm selected obbies
    autoObbyChestClaim = false,  -- NEW: Auto-claim obby chest reward
    selectedObbies = {"Easy"},  -- NEW: Selected obby difficulties
    obbyNextIndex = 1,  -- NEW: Next obby index in ordered selection
    obbyInProgress = false,  -- NEW: Guard against overlapping obby runs
    lastObbyRun = 0,  -- NEW: Timestamp for obby run cooldown
    autoDiscoverIslands = false,  -- Auto-visit island unlock hitboxes
    discoverTargetWorld = "Both Worlds",  -- Discovery target: Both/Overworld/Minigame
    discoveredIslands = {},  -- Cache visited island unlock hitboxes
    lastDiscoverStep = 0,
    lastDiscoverDoneLog = 0,
    autoUnlockWorlds = false,  -- Auto-unlock selected worlds
    selectedUnlockWorlds = {"Minigame Paradise"},
    lastWorldUnlockAttempt = 0,
    autoSeasonQuest = false,  -- Auto-complete active season quest
    autoSeasonClaimRewards = false,  -- Auto-claim season rewards
    autoSeasonInfinite = false,  -- Auto-start infinite season track
    seasonFallbackEgg = "Infinity Egg",  -- Fallback egg for generic season hatch quests
    lastSeasonQuestAction = 0,
    lastSeasonRewardClaim = 0,
    lastSeasonInfiniteAttempt = 0,
    pickupAttemptTimes = {},
    chestAttemptTimes = {},
    seasonActiveQuestId = nil,
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
    potionDebugEnabled = false,
    potionCycleIndex = 1,
    lastPotionCheck = 0,
    potionCounts = {},
    activePotions = {},
    -- Disable animation
    disableHatchAnimation = false,
    -- Custom teams
    hatchTeam = nil,
    statsTeam = nil,
    hatchTeamIndex = nil,
    statsTeamIndex = nil,
    gameTeamList = {},
    -- Auto enchant
    gameEnchantList = {},
    enchantMain = nil,
    enchantMainTier = 1,  -- 1-5 for I-V
    enchantMainEnabled = true,  -- Enable slot 1 checking
    enchantSecond = nil,
    enchantSecondTier = 1,  -- 1-5 for I-V
    enchantSecondEnabled = true,  -- Enable slot 2 checking
    autoEnchantEnabled = false,
    currentEnchantPetIndex = 1,  -- Track which pet in team we're currently enchanting
    -- Competitive
    compAutoEnabled = false,  -- Auto blow + auto reroll for competitive
    compWebhookUrl = "",  -- Separate webhook for competitive stats
    compWebhookInterval = 300,  -- Send stats every 5 minutes (300 seconds)
    compLastWebhook = 0,  -- Timestamp of last webhook send
    compRerollNonBubble = true,  -- Auto-reroll non-bubble quests (slots 3-4)
    compLastRerollCheck = 0,  -- Timestamp of last reroll check
    compPreviousScores = {},  -- Track previous scores for rate calculation
    compPreviousTime = 0,  -- Timestamp of previous webhook for rate calculation
    -- Competitive Quest Selection
    compDoHatchQuests = false,  -- Enable hatch quests (disabled by default)
    compDoBubbleQuests = true,  -- Enable bubble quests
    compDoPlaytimeQuests = true,  -- Enable playtime quests
    compCurrentHatchEgg = nil,  -- Current egg we're hatching for quest
    compHatchActive = false,  -- Whether we're actively hatching for quest
    compLastHatchTime = 0,  -- Timestamp of last hatch command
    -- Powerups
    gamePowerupList = {},
    selectedPowerups = {},
    autoPowerupEnabled = false,
    -- Config system
    currentConfigName = "",
    savedConfigs = {},
    stats = {
        -- Leaderstats
        bubbles=0, hatches=0,
        -- Main currencies (GUI)
        coins="0", gems="0", bubbleStock="0",
        -- All currencies including event currencies
        tokens="0", tickets="0", seashells="0", festivalCoins="0",
        pearls="0", leaves="0", candycorn="0", ogPoints="0",
        thanksgivingShards="0", winterShards="0", snowflakes="0",
        newYearsShard="0", horns="0", halos="0", moonShards="0",
        petals="0"  -- NEW: Spring event currency
    },
    startTime = tick(),
    labels = {},
    currencyLabels = {},  -- NEW: Labels for all currencies
    uiElements = {}  -- NEW: Store UI element references for updating when loading configs
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
    Secret = 20,        -- 20%
    Infinity = 20,
    Celestial = 20
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

-- Enchant tier order for auto-enchant
local ENCHANT_TIERS = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}
local ENCHANT_TIER_VALUES = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythical=6}

-- === CACHES (Performance optimization) ===
local petImageCache = {} -- Cache pet images to avoid re-searching decompiled source
local petEggCache = {} -- Cache which egg contains which pet
local petChanceCache = {} -- Cache pet chances (format: "petName|eggName" -> chance)
local playerAvatarCache = nil -- Cache player avatar URL (fetch once, reuse forever)

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
    -- Check cache first (MASSIVE performance boost!)
    if petImageCache[petName] then
        return petImageCache[petName]
    end

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

    -- Cache the result before returning
    petImageCache[petName] = images
    return images
end

-- Find which egg contains a specific pet (searches through egg data)
local function findEggContainingPet(petName)
    -- Check cache first (MASSIVE performance boost!)
    if petEggCache[petName] then
        return petEggCache[petName]
    end

    if not eggData then
        return nil
    end

    -- Search through all eggs in structured data
    for eggName, eggInfo in pairs(eggData) do
        if eggInfo.Pets then
            -- Check if this egg contains the pet
            for _, petEntry in pairs(eggInfo.Pets) do
                if petEntry.Name == petName or petEntry == petName then
                    -- Cache the result before returning
                    petEggCache[petName] = eggName
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
                    -- Cache the result before returning
                    petEggCache[petName] = eggName
                    return eggName
                end
                pos = buildPos + 1
            else
                break
            end
        end
    end

    return nil
end

-- Get pet chance from egg data
local function getPetChanceFromEgg(petName, eggName)
    -- Check cache first (MASSIVE performance boost!)
    local cacheKey = petName .. "|" .. eggName
    if petChanceCache[cacheKey] then
        return petChanceCache[cacheKey]
    end

    if eggModuleSource == "" then
        return nil
    end

    if eggName == "Unknown Egg" then
        return nil
    end

    -- Find the egg definition using plain text search
    local searchStr = '["' .. eggName .. '"]'
    local eggStart = eggModuleSource:find(searchStr, 1, true)

    if not eggStart then
        return nil
    end

    -- Find the Build() that ends this egg's definition
    local buildStart = eggModuleSource:find('Build()', eggStart, true)
    if not buildStart then
        return nil
    end

    -- Extract egg definition section
    local eggDef = eggModuleSource:sub(eggStart, buildStart)

    -- Search for the pet in the egg definition: :Pet(chance, "PetName")
    local petSearch = '"' .. petName .. '"'
    local petPos = eggDef:find(petSearch, 1, true)

    if not petPos then
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
        return nil
    end

    -- Extract the chance value between :Pet( and the comma
    local chanceEnd = petPos - 3  -- Position before comma and space before pet name
    local chanceStr = eggDef:sub(petCallStart, chanceEnd):match('[%d%.e%-]+')

    if chanceStr then
        local chance = tonumber(chanceStr)
        if chance then
            -- Cache the result before returning
            petChanceCache[cacheKey] = chance
            return chance
        end
    end

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

-- Pre-cache all pet data at startup (eliminates ALL webhook lag!)
local function preCacheAllPetData()
    local startTime = tick()
    local cachedPets = 0
    local cachedEggs = 0
    local cachedChances = 0

    -- 1. Pre-cache all pet images
    if petData and petModuleSource ~= "" then
        for petName, _ in pairs(petData) do
            if not petImageCache[petName] then
                local images = getPetImages(petName)
                -- getPetImages already caches, but we call it to populate
                cachedPets = cachedPets + 1
            end
        end
    end

    -- 2. Pre-cache all pet-to-egg mappings
    if eggData then
        for eggName, eggInfo in pairs(eggData) do
            if eggInfo.Pets then
                for _, petEntry in pairs(eggInfo.Pets) do
                    local petName = type(petEntry) == "table" and petEntry.Name or petEntry
                    if petName and not petEggCache[petName] then
                        petEggCache[petName] = eggName
                        cachedEggs = cachedEggs + 1
                    end
                end
            end
        end
    end

    -- 3. Pre-cache all pet chances (pet + egg combinations)
    if eggData and eggModuleSource ~= "" then
        for eggName, eggInfo in pairs(eggData) do
            if eggInfo.Pets then
                for _, petEntry in pairs(eggInfo.Pets) do
                    local petName = type(petEntry) == "table" and petEntry.Name or petEntry
                    if petName then
                        local cacheKey = petName .. "|" .. eggName
                        if not petChanceCache[cacheKey] then
                            local chance = getPetChanceFromEgg(petName, eggName)
                            -- getPetChanceFromEgg already caches, but we call it to populate
                            if chance then
                                cachedChances = cachedChances + 1
                            end
                        end
                    end
                end
            end
        end
    end

    local elapsed = tick() - startTime
    -- Only log if running in development mode (commented out for production)
    -- --  print(string.format("✅ Pre-cached: %d pets, %d eggs, %d chances in %.2fs", cachedPets, cachedEggs, cachedChances, elapsed))
end

-- === ADVANCED EGG ANIMATION DISABLER ===
-- Hooks into the game's HatchEgg module to completely disable animations

local hatchEggModule = nil
local originalPlayFunction = nil
local originalDisplayPetOnce = nil

-- Get HatchEgg module from ReplicatedStorage
pcall(function()
    hatchEggModule = RS:FindFirstChild("Client", true)
    if hatchEggModule then
        hatchEggModule = hatchEggModule:FindFirstChild("Effects", true)
        if hatchEggModule then
            hatchEggModule = hatchEggModule:FindFirstChild("HatchEgg", true)
            if hatchEggModule then
                -- Successfully found the module
                -- --  print("✅ Found HatchEgg module at: " .. hatchEggModule:GetFullName())
            end
        end
    end
end)

-- Hook the HatchEgg module's Play function
local function hookHatchEggModule()
    if not hatchEggModule then return end

    pcall(function()
        local module = require(hatchEggModule)

        -- Save original functions
        if not originalPlayFunction then
            originalPlayFunction = module.Play
            originalDisplayPetOnce = module.DisplayPetOnce
        end

        -- Replace Play function with dummy that does nothing
        module.Play = function(self, data)
            -- Do nothing - this skips the entire animation
            -- But we need to mark hatching as complete
            if module._hatching ~= nil then
                module._hatching = false
            end
            return
        end

        -- Replace DisplayPetOnce to skip secret reveals
        module.DisplayPetOnce = function(self, pet, egg)
            -- Do nothing - skip secret pet reveals too
            if module._hatching ~= nil then
                module._hatching = false
            end
            return
        end

        -- --  print("✅ Hooked HatchEgg.Play and DisplayPetOnce functions")
    end)
end

-- Restore original functions
local function unhookHatchEggModule()
    if not hatchEggModule or not originalPlayFunction then return end

    pcall(function()
        local module = require(hatchEggModule)
        module.Play = originalPlayFunction
        module.DisplayPetOnce = originalDisplayPetOnce
        -- --  print("✅ Restored original HatchEgg functions")
    end)
end

-- Hide all hatching UI elements
local function hideHatchingUI()
    pcall(function()
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if not screenGui then return end

        -- Hide main hatching frame
        local hatching = screenGui:FindFirstChild("Hatching")
        if hatching then
            hatching.Visible = false
        end

        -- Hide AFKReveal frame (for AFK eggs)
        local afkReveal = screenGui:FindFirstChild("AFKReveal")
        if afkReveal then
            afkReveal.Visible = false
        end

        -- Hide overlay
        local overlay = screenGui:FindFirstChild("_overlay")
        if overlay then
            overlay.BackgroundTransparency = 1
        end
    end)
end

-- Continuous monitor to keep animations disabled
task.spawn(function()
    while task.wait(0.1) do
        if state.disableHatchAnimation then
            -- Hook the module functions
            hookHatchEggModule()

            -- Hide all UI
            hideHatchingUI()

            -- Force HUD to be visible
            pcall(function()
                local screenGui = playerGui:FindFirstChild("ScreenGui")
                if screenGui then
                    local hud = screenGui:FindFirstChild("HUD")
                    if hud then
                        hud.Visible = true
                    end
                end
            end)
        else
            -- Restore original functions when disabled
            if originalPlayFunction then
                unhookHatchEggModule()
            end
        end
    end
end)

-- Legacy function for compatibility
local function stopHatchAnimation()
    if state.disableHatchAnimation then
        hideHatchingUI()
    end
end

-- === UTILITY FUNCTIONS ===

-- File path for saving stats message ID (persists across rejoins)
local STATS_MESSAGE_FILE = "lorio_bgsi_stats_message_id.txt"
local LOG_FILE = "lorio_bgsi_fishing_log.txt"
local DEBUG_LOG_FILE = "lorio_bgsi_webhook_debug.txt"

-- Logging function (writes to both console and file)
local function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = "[" .. timestamp .. "] " .. message

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

-- Potion debug logger (console + both txt logs)
local function potionDebug(message)
    if not state.potionDebugEnabled then
        return
    end
    local text = "🧪 [PotionDebug] " .. tostring(message)
    --  print(text)
    pcall(function() log(text) end)
    pcall(function() debugLog(text) end)
end

-- Webhook debug logger (console + both txt logs)
local function webhookDebug(message)
    if not state.webhookDebugEnabled then
        return
    end
    local text = "📡 [WebhookDebug] " .. tostring(message)
    --  print(text)
    pcall(function() log(text) end)
    pcall(function() debugLog(text) end)
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
            end
        end
    end
end

-- Save stats message ID to file
local function saveStatsMessageId(messageId)
    if writefile then
        pcall(writefile, STATS_MESSAGE_FILE, messageId)
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

                    return true
                end
            end
        end
        return false
    end)
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

                    return true
                end
            end
        end
        return false
    end)
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
            -- Always include Flowers even if not in standard potions
            if not potionData["Flowers"] then
                table.insert(state.gamePotionList, "Flowers")
            end
            return true
        end
        return false
    end)
end

-- Load powerup data from game (ReplicatedStorage.Shared.Data.Powerups)
local function loadGamePowerupData()
    local success, result = pcall(function()
        local data = RS:FindFirstChild("Shared")
        if data then data = data:FindFirstChild("Data") end
        if data then data = data:FindFirstChild("Powerups") end
        if data and data:IsA("ModuleScript") then
            local powerupData = require(data)
            state.gamePowerupList = {}
            for name, itemData in pairs(powerupData) do
                -- Filter out special powerups and keep useful ones
                if type(itemData) == "table" and not name:find("Egg") and not name:find("Chest") then
                    table.insert(state.gamePowerupList, name)
                end
            end
            return true
        end
        return false
    end)
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
            local addedEnchants = {}  -- Track unique base names

            for name, _ in pairs(enchantData) do
                -- Remove tier suffix (I, II, III, IV, V) to get base name
                local baseName = name:gsub("%s+[IVX]+$", "")  -- Remove Roman numerals at end

                -- Only add if we haven't seen this base name before
                if not addedEnchants[baseName] then
                    table.insert(state.gameEnchantList, baseName)
                    addedEnchants[baseName] = true
                end
            end

            -- Sort alphabetically
            table.sort(state.gameEnchantList)
        end
    end)
end

-- Load team data (now uses smart detection from player data)
local function loadGameTeamData()
    -- Team data will be loaded when updateTeamDropdowns() is called later
    -- This function exists for compatibility with the initialization sequence
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

local recentHatchWebhookSignatures = {}

local function makePetWebhookSignature(petName, isShiny, isMythic, isSuper, isXL)
    return string.format(
        "%s|sh=%s|my=%s|su=%s|xl=%s",
        tostring(petName),
        tostring(isShiny == true),
        tostring(isMythic == true),
        tostring(isSuper == true),
        tostring(isXL == true)
    )
end

local function rememberHatchWebhookSignature(signature)
    recentHatchWebhookSignatures[signature] = tick()
end

local function wasRecentlySentFromHatch(signature, windowSeconds)
    local now = tick()
    local window = windowSeconds or 3
    local seenAt = recentHatchWebhookSignatures[signature]

    if seenAt and (now - seenAt) <= window then
        return true
    end

    -- Cleanup old entries to keep map small
    for sig, ts in pairs(recentHatchWebhookSignatures) do
        if (now - ts) > 12 then
            recentHatchWebhookSignatures[sig] = nil
        end
    end

    return false
end

local function SendWebhook(url, msg)
    if not request then
        warn("[Webhook] No HTTP request function available in this executor")
        return
    end
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
    -- Run webhook in DEFERRED thread (lowest priority - zero game blocking)
    task.defer(function()
        webhookDebug(string.format("Queue send | pet=%s | displayEgg=%s | chanceEgg=%s | rarity=%s | xl=%s shiny=%s super=%s mythic=%s",
            tostring(petName), tostring(displayEgg), tostring(chanceEgg), tostring(rarityFromGUI),
            tostring(isXL), tostring(isShiny), tostring(isSuper), tostring(isMythic)
        ))

        if not request then
            webhookDebug("SKIP: request API missing in executor")
            return
        end
        if state.webhookUrl == "" then
            webhookDebug("SKIP: webhookUrl is empty")
            return
        end

        local success, error = pcall(function()
        -- Parse rarity from GUI (handle variants like "AA-Secret" -> "Secret")
        local baseRarity = rarityFromGUI
        local petMeta = petData and petData[petName]
        local isCelestialPet = petMeta and petMeta.Celestial ~= nil

        if isCelestialPet then
            baseRarity = "Celestial"
        elseif rarityFromGUI:find("Celestial") or rarityFromGUI:find("celestial") then
            baseRarity = "Celestial"
        elseif rarityFromGUI:find("Secret") or rarityFromGUI:find("secret") then
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

        -- Egg Comet / special-case fallback detection when rarity text is ambiguous
        if (baseRarity == "Unknown" or baseRarity == nil) and tostring(petName):find("Stardust Racer") then
            baseRarity = "Celestial"
        end

        -- Check rarity filter
        if not state.webhookRarities[baseRarity] then
            webhookDebug("SKIP: rarity filtered out -> " .. tostring(baseRarity))
            return
        end

        -- Get pet data from game
        local pet = petData and petData[petName]
        if not pet then
            webhookDebug("SKIP: pet not found in petData -> " .. tostring(petName))
            return
        end

        -- Extract BASE stats dynamically so event pets with custom currencies are supported
        local basePetStats = {}
        local function collectStats(statsTable)
            if type(statsTable) ~= "table" then return end
            for statName, statValue in pairs(statsTable) do
                if type(statName) == "string" and type(statValue) == "number" then
                    basePetStats[statName] = statValue
                end
            end
        end

        if pet.Stat then
            if type(pet.Stat) == "table" then
                collectStats(pet.Stat)
            elseif type(pet.Stat) == "number" then
                basePetStats.Bubbles = pet.Stat
            end
        end

        if pet.Stats then
            collectStats(pet.Stats)
        end

        -- Fallback for pets that expose direct fields instead of a Stat table
        if next(basePetStats) == nil then
            local directStats = {"Bubbles", "Coins", "Gems", "Clovers", "Leaves", "Petals", "Tickets", "Pearls", "Candycorn"}
            for _, key in ipairs(directStats) do
                local value = pet[key]
                if type(value) == "number" then
                    basePetStats[key] = value
                end
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

        local scaledPetStats = {}
        for statName, baseValue in pairs(basePetStats) do
            scaledPetStats[statName] = baseValue * statMultiplier
        end

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

        -- Check chance threshold using modified chance if available
        local checkRatio = modifiedChanceRatio > 0 and modifiedChanceRatio or baseChanceRatio
        if checkRatio > 0 and checkRatio < state.webhookChanceThreshold then
            webhookDebug(string.format("SKIP: chance threshold blocked | ratio=1/%s | threshold=1/%s",
                tostring(checkRatio), tostring(state.webhookChanceThreshold)))
            return
        end

        -- Format chance ratio with commas
        local function formatChance(num)
            local str = tostring(num)
            local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
            if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
            return formatted
        end

        -- Get pet image URL (using Big Games API proxy - no HTTP request!)
        local petImageUrl = nil
        local images = getPetImages(petName)  -- Already cached, instant lookup
        webhookDebug("Image candidates for " .. tostring(petName) .. ": " .. tostring(#images))

        if #images > 0 then
            -- Build candidate order: shiny prefers slot 2 then fallback to all others.
            local candidateIndexes = {}
            local seenIndex = {}

            local function addIndex(i)
                if i and i >= 1 and i <= #images and not seenIndex[i] then
                    seenIndex[i] = true
                    table.insert(candidateIndexes, i)
                end
            end

            if isShiny then
                addIndex(2)
                addIndex(1)
            else
                addIndex(1)
                addIndex(2)
            end

            for i = 1, #images do
                addIndex(i)
            end

            for _, imageIndex in ipairs(candidateIndexes) do
                local assetId = tostring(images[imageIndex] or "")
                if assetId ~= "" then
                    local thumbKey = "thumb:" .. assetId
                    local cachedThumb = petImageCache[thumbKey]
                    if cachedThumb ~= nil then
                        if cachedThumb ~= false then
                            petImageUrl = cachedThumb
                            break
                        end
                        continue
                    end

                    local thumbApi = "https://thumbnails.roblox.com/v1/assets?assetIds="
                        .. assetId
                        .. "&size=420x420&format=Png&isCircular=false"

                    local thumbOk, thumbResp = pcall(function()
                        return request({
                            Url = thumbApi,
                            Method = "GET"
                        })
                    end)

                    if thumbOk and thumbResp and thumbResp.StatusCode == 200 and thumbResp.Body then
                        local parseOk, parsed = pcall(function()
                            return HttpService:JSONDecode(thumbResp.Body)
                        end)

                        local item = parseOk and parsed and parsed.data and parsed.data[1] or nil
                        local imageUrl = item and item.imageUrl or nil
                        local stateVal = item and item.state or nil

                        if imageUrl and imageUrl ~= "" and (not stateVal or stateVal == "Completed") then
                            petImageUrl = imageUrl
                            petImageCache[thumbKey] = imageUrl
                            webhookDebug("Using Roblox thumbnail URL (slot " .. tostring(imageIndex) .. "): " .. tostring(petImageUrl))
                            break
                        else
                            petImageCache[thumbKey] = false
                            webhookDebug("Thumbnail fallback: bad/empty result for slot " .. tostring(imageIndex) .. " assetId=" .. assetId .. " state=" .. tostring(stateVal))
                        end
                    else
                        local status = thumbResp and thumbResp.StatusCode or "nil"
                        petImageCache[thumbKey] = false
                        webhookDebug("Thumbnail fallback: request failed for slot " .. tostring(imageIndex) .. " assetId=" .. assetId .. " status=" .. tostring(status))
                    end
                end
            end

            if not petImageUrl then
                webhookDebug("NO IMAGE: all candidate slots failed for " .. tostring(petName))
            end
        else
            webhookDebug("NO IMAGE: getPetImages returned empty list for " .. tostring(petName))
        end

        -- Get user avatar URL (fetch once, cache forever)
        local avatarUrl = playerAvatarCache

        if avatarUrl ~= false and not avatarUrl then
            -- First time only: fetch avatar from Roblox API
            local avatarSuccess, avatarResponse = pcall(function()
                return request({
                    Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. player.UserId .. "&size=150x150&format=Png",
                    Method = "GET"
                })
            end)

            if avatarSuccess and avatarResponse.StatusCode == 200 then
                local avatarData = HttpService:JSONDecode(avatarResponse.Body)
                if avatarData and avatarData.data and avatarData.data[1] and avatarData.data[1].imageUrl then
                    avatarUrl = avatarData.data[1].imageUrl
                    playerAvatarCache = avatarUrl  -- Cache for all future webhooks!
                else
                    playerAvatarCache = false
                end
            else
                playerAvatarCache = false
            end
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
            Infinity = 0xFF00FF,
            Celestial = 0x66CCFF
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

        -- Build Pet Stats text dynamically
        local statIcons = {
            Bubbles = "🫧",
            Coins = "💰",
            Gems = "💎",
            Tickets = "🎟️",
            Clovers = "🍀",
            Leaves = "🍃",
            Petals = "🌸",
            Pearls = "🦪",
            Candycorn = "🍬",
        }

        local statLines = {}
        local usedStats = {}
        local priorityStats = {"Bubbles", "Coins", "Gems", "Clovers", "Leaves", "Petals", "Tickets"}

        for _, statName in ipairs(priorityStats) do
            if scaledPetStats[statName] ~= nil then
                local icon = statIcons[statName] or "📌"
                table.insert(statLines, string.format("%s %s: x%s", icon, statName, formatNumber(scaledPetStats[statName])))
                usedStats[statName] = true
            end
        end

        local otherStats = {}
        for statName, _ in pairs(scaledPetStats) do
            if not usedStats[statName] then
                table.insert(otherStats, statName)
            end
        end
        table.sort(otherStats)

        for _, statName in ipairs(otherStats) do
            local icon = statIcons[statName] or "📌"
            table.insert(statLines, string.format("%s %s: x%s", icon, statName, formatNumber(scaledPetStats[statName])))
        end

        if #statLines == 0 then
            table.insert(statLines, "No stat data found")
        end

        webhookDebug("Pet stats fields for " .. tostring(petName) .. ": " .. table.concat(statLines, " | "))

        -- Build embed with image URLs (no attachments)
        local embed = {
            title = "🎉 " .. player.Name .. " hatched " .. petTitle .. "!",
            color = colors[baseRarity] or 0xFFFFFF,
            author = avatarUrl and {
                name = player.Name,
                icon_url = avatarUrl
            } or {name = player.Name},
            thumbnail = petImageUrl and {url = petImageUrl} or nil,
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
                    value = table.concat(statLines, "\n"),
                    inline = false
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }

        -- Send webhook with simple JSON (no file attachments)
        local pingContent = ""
        if state.webhookPingEnabled and state.webhookPingUserId ~= "" then
            pingContent = "<@" .. state.webhookPingUserId .. ">"
        end

        local payload = {embeds = {embed}}
        if pingContent ~= "" then
            payload.content = pingContent
        end

        -- Send webhook immediately (only 1 HTTP request, non-blocking via task.defer)
        pcall(function()
            local response = request({
                Url = state.webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })

            local code = response and response.StatusCode or "nil"
            webhookDebug("POST sent | status=" .. tostring(code) .. " | pet=" .. tostring(petTitle))
            if response and response.Body and tostring(response.Body) ~= "" then
                local bodySnippet = tostring(response.Body):sub(1, 220)
                webhookDebug("Response body snippet: " .. bodySnippet)
            end
        end)

        if not success then
            webhookDebug("ERROR in SendPetHatchWebhook: " .. tostring(error))
        end
    end)
    end)
end

-- === REMOTE EVENT PET HATCH DETECTION ===
-- ⚡ SUPER RELIABLE - Uses game's own hatch events!
-- ✅ No auto-delete timing issues
-- ✅ No freezing (async network event)
-- ✅ No duplicates (fires once per hatch)
-- ✅ Detects ALL pets in multi-egg hatches (3x, 7x, etc.)
task.spawn(function()
    task.wait(3) -- Wait for game to load

    pcall(function()
        local Remote = require(RS.Shared.Framework.Network.Remote)
        webhookDebug("Hatch event listeners initializing")

        -- Helper function to process hatched pets
        local function processPets(hatchData, eventType)
            if not hatchData then
                webhookDebug("SKIP processPets: hatchData nil for event " .. tostring(eventType))
                return
            end

            if not hatchData.Pets or #hatchData.Pets == 0 then
                webhookDebug("SKIP processPets: no pets in hatchData for event " .. tostring(eventType))
                return
            end

            local eggName = hatchData.Name or "Unknown Egg"
            webhookDebug(string.format("Event=%s | egg=%s | petCount=%d", tostring(eventType), tostring(eggName), #hatchData.Pets))

            -- Process each pet
            for i, petInfo in ipairs(hatchData.Pets) do
                -- Skip deleted pets (auto-deleted by game)
                if petInfo.Deleted ~= true then
                    -- Debug: print COMPLETE pet info structure for EVERY pet
-- --  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
-- --  print("🔍 [DEBUG] Pet #" .. i .. " FULL structure:")
                    for key, value in pairs(petInfo) do
                        if type(value) == "table" then
-- --  print("  " .. tostring(key) .. " = [table]")
                            for subKey, subValue in pairs(value) do
-- --  print("    " .. tostring(subKey) .. " = " .. tostring(subValue))
                            end
                        else
-- --  print("  " .. tostring(key) .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
                        end
                    end
-- --  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

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

                    -- Get rarity from pet data
                    local rarity = "Unknown"
                    if petData and petData[petName] and petData[petName].Rarity then
                        rarity = petData[petName].Rarity
                    end

                    -- Prefer the actual hatched egg for chance accuracy.
                    -- Fallback only when the current egg has no explicit entry for this pet.
                    local originalEgg = eggName
                    local chanceOnCurrentEgg = getPetChanceFromEgg(petName, eggName)
                    if not chanceOnCurrentEgg then
                        originalEgg = findEggContainingPet(petName) or eggName
                    end
                    webhookDebug(string.format("Pet parsed | name=%s | rarity=%s | displayEgg=%s | originalEgg=%s | deleted=%s",
                        tostring(petName), tostring(rarity), tostring(eggName), tostring(originalEgg), tostring(petInfo.Deleted)))

                    local webhookSignature = makePetWebhookSignature(petName, isShiny, isMythic, isSuper, isXL)
                    rememberHatchWebhookSignature(webhookSignature)

                    -- Send webhook (DEFERRED - zero game blocking)
                    -- Pass both eggs: eggName for display, originalEgg for chance calculation
                    task.defer(function()
                        pcall(function()
                            SendPetHatchWebhook(petName, eggName, originalEgg, rarity, isXL, isShiny, isSuper, isMythic)
                        end)
                    end)
                else
                    webhookDebug("Pet skipped: Deleted=true")
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
        Remote.Event("HatchEgg"):Connect(function(hatchData)
            processPets(hatchData, "HatchEgg")
        end)
        webhookDebug("Connected listener: Remote.Event(HatchEgg)")

        -- Register handler for EXCLUSIVE egg hatches (premium, shop eggs, etc.)
        Remote.Event("ExclusiveHatch"):Connect(function(hatchData, shouldAnimate)
            processPets(hatchData, "ExclusiveHatch")
        end)
        webhookDebug("Connected listener: Remote.Event(ExclusiveHatch)")
    end)
end)

-- === INVENTORY GAIN PET DETECTION (PICKUPS / NON-HATCH SOURCES) ===
-- Detects pets added directly to inventory (e.g., Egg Comet pickup rewards)
task.spawn(function()
    task.wait(6)

    local LocalData = nil
    pcall(function()
        LocalData = require(RS.Client.Framework.Services.LocalData)
    end)

    if not LocalData then
        pcall(function()
            local localDataModule = RS:FindFirstChild("Client", true)
            if localDataModule then
                localDataModule = localDataModule:FindFirstChild("Framework", true)
                if localDataModule then
                    localDataModule = localDataModule:FindFirstChild("Services", true)
                    if localDataModule then
                        localDataModule = localDataModule:FindFirstChild("LocalData", true)
                    end
                end
            end
            if localDataModule then
                LocalData = require(localDataModule)
            end
        end)
    end

    if not LocalData then
        webhookDebug("Inventory watcher disabled: LocalData module not found")
        return
    end

    local knownPetIds = {}
    local primed = false

    while task.wait(1) do
        local playerData = nil
        pcall(function()
            playerData = LocalData:Get()
        end)

        if not playerData or type(playerData.Pets) ~= "table" then
            continue
        end

        local pets = playerData.Pets
        local currentIds = {}

        for petId, petEntry in pairs(pets) do
            currentIds[petId] = true

            if not knownPetIds[petId] then
                knownPetIds[petId] = true

                -- First full snapshot should not notify old inventory
                if primed and state.webhookUrl ~= "" then
                    local petName = nil
                    local isShiny = false
                    local isMythic = false
                    local isSuper = false
                    local isXL = false

                    if type(petEntry) == "table" then
                        petName = petEntry.Name

                        if petEntry.Pet and type(petEntry.Pet) == "table" then
                            petName = petEntry.Pet.Name or petName
                            isShiny = petEntry.Pet.Shiny == true
                            isMythic = petEntry.Pet.Mythic == true
                            isSuper = petEntry.Pet.Super == true or petEntry.Pet.super == true
                            isXL = petEntry.Pet.XL == true or petEntry.Pet.xl == true
                        else
                            isShiny = petEntry.Shiny == true
                            isMythic = petEntry.Mythic == true
                            isSuper = petEntry.Super == true or petEntry.super == true
                            isXL = petEntry.XL == true or petEntry.xl == true
                        end
                    end

                    if petName and petName ~= "" then
                        local signature = makePetWebhookSignature(petName, isShiny, isMythic, isSuper, isXL)

                        -- Avoid duplicate webhook when hatch event already fired for same pet moments ago.
                        if not wasRecentlySentFromHatch(signature, 3) then
                            local rarity = "Unknown"
                            if petData and petData[petName] then
                                if petData[petName].Celestial ~= nil then
                                    rarity = "Celestial"
                                elseif petData[petName].Rarity then
                                    rarity = petData[petName].Rarity
                                end
                            end

                            webhookDebug(string.format("Inventory gain detected | id=%s | name=%s | rarity=%s", tostring(petId), tostring(petName), tostring(rarity)))

                            task.defer(function()
                                pcall(function()
                                    SendPetHatchWebhook(petName, "Pickup Reward", "Pickup Reward", rarity, isXL, isShiny, isSuper, isMythic)
                                end)
                            end)
                        else
                            webhookDebug("Inventory gain skipped (duplicate of recent hatch): " .. tostring(petName))
                        end
                    end
                end
            end
        end

        -- Cleanup IDs removed from inventory
        for trackedId, _ in pairs(knownPetIds) do
            if not currentIds[trackedId] then
                knownPetIds[trackedId] = nil
            end
        end

        if not primed then
            primed = true
            webhookDebug("Inventory watcher primed with existing pets")
        end
    end
end)

-- Send user stats webhook
local function SendStatsWebhook()
    if state.webhookUrl == "" or not state.webhookStatsEnabled then return end
    if not request then return end

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
            {name="Moon Shards", value=state.stats.moonShards},
            {name="Petals", value=state.stats.petals}  -- Spring event currency
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
            -- If editing failed, reset message ID and try creating new one next time
            if method == "PATCH" then
                state.statsMessageId = nil
                saveStatsMessageId("")
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

                        -- All currencies including event currencies
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
                            {key="moonShards", name="MoonShards"},
                            {key="petals", name="Petals"}  -- Spring event
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

-- Send competitive webhook with stats, quest progress, and team data
local function sendCompetitiveWebhook(testMode)
    if state.compWebhookUrl == "" then return end

    task.spawn(function()
        pcall(function()
            -- Get LocalData
            local localDataModule = RS:FindFirstChild("Client", true)
            if localDataModule then
                localDataModule = localDataModule:FindFirstChild("Framework", true)
                if localDataModule then
                    localDataModule = localDataModule:FindFirstChild("Services", true)
                    if localDataModule then
                        localDataModule = localDataModule:FindFirstChild("LocalData", true)
                    end
                end
            end

            if not localDataModule then return end

            local LocalData = require(localDataModule)
            local playerData = LocalData:Get()

            if not playerData then return end

            local compData = playerData.Competitive
            if not compData then
                -- No competitive data - send message
                local embed = {
                    title = testMode and "🧪 Test - Competitive Stats" or "🏆 Competitive Stats",
                    description = "❌ **No competitive data found**\nStart competitive mode in-game first!",
                    color = 15158332,  -- Red
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                }
                local payload = {embeds = {embed}}
                pcall(function()
                    request({
                        Url = state.compWebhookUrl,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
                return
            end

            local currentTime = tick()
            local timeSinceLastCheck = state.compPreviousTime > 0 and (currentTime - state.compPreviousTime) or 0
            local minutesSinceLastCheck = timeSinceLastCheck / 60

            -- Build team data
            local teamText = ""
            local clanData = compData.Clan
            local teamRank = "N/A"
            local starsPerMin = 0
            local starsTo250 = "N/A"

            -- Get leaderboard from workspace GUI frames
            local leaderboardList = nil
            pcall(function()
                local worlds = Workspace:FindFirstChild("Worlds")
                if worlds then
                    local overworld = worlds:FindFirstChild("The Overworld")
                    if overworld then
                        local leaderboards = overworld:FindFirstChild("Leaderboards")
                        if leaderboards then
                            local compLeaderboard = leaderboards:FindFirstChild("Competitive")
                            if compLeaderboard then
                                local display = compLeaderboard:FindFirstChild("Display")
                                if display then
                                    local leaderboard = display:FindFirstChild("Leaderboard")
                                    if leaderboard then
                                        leaderboardList = leaderboard:FindFirstChild("List")
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            if clanData and clanData.Id then
                local teamName = clanData.Id
                local memberCount = clanData.Members and #clanData.Members or 0

                -- Calculate total team score
                local totalScore = 0
                local memberScores = {}

                if clanData.Members then
                    for _, member in pairs(clanData.Members) do
                        local memberScore = member.Score or 0
                        local memberName = member.Username or "Unknown"

                        -- Use current player's actual score
                        if member.UserId == player.UserId then
                            memberScore = compData.Score
                        end

                        totalScore = totalScore + memberScore
                        table.insert(memberScores, {
                            name = memberName,
                            userId = member.UserId,
                            score = memberScore
                        })
                    end

                    -- Sort members by score (highest first)
                    table.sort(memberScores, function(a, b) return a.score > b.score end)
                end

                -- Find team rank in leaderboard by checking GUI frames
                if leaderboardList then
                    -- Get rank from player's Competitive UI
                    local rankText = "N/A"
                    pcall(function()
                        local competitiveGui = player.PlayerGui:FindFirstChild("ScreenGui")
                        if competitiveGui then
                            local compFrame = competitiveGui:FindFirstChild("Competitive")
                            if compFrame then
                                local frame = compFrame:FindFirstChild("Frame")
                                if frame then
                                    local content = frame:FindFirstChild("Content")
                                    if content then
                                        local team = content:FindFirstChild("Team")
                                        if team then
                                            local teamContent = team:FindFirstChild("Content")
                                            if teamContent then
                                                local rankLabel = teamContent:FindFirstChild("Rank")
                                                if rankLabel and rankLabel:IsA("TextLabel") then
                                                    rankText = rankLabel.Text
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)

                    teamRank = rankText

                    -- Parse rank number from text (e.g., "250th" -> 250, "347th" -> 347)
                    local rankNumber = tonumber(rankText:match("%d+"))

                    -- Determine which entry to compare against
                    local targetEntry = nil
                    local targetRankText = ""

                    if rankNumber and rankNumber > 0 then
                        if rankNumber <= 250 then
                            -- In top 250: look at team ahead (rank - 1)
                            if rankNumber > 1 then
                                local teamAheadRank = rankNumber - 1
                                targetEntry = leaderboardList:FindFirstChild("Entry" .. teamAheadRank)
                                targetRankText = string.format("rank %d", teamAheadRank)
                            else
                                -- Already rank 1!
                                starsTo250 = "Rank #1! 🏆"
                            end
                        else
                            -- Outside top 250: aim for 250th place
                            targetEntry = leaderboardList:FindFirstChild("Entry250")
                            targetRankText = "rank 250"
                        end
                    else
                        -- Couldn't parse rank, default to 250th place
                        targetEntry = leaderboardList:FindFirstChild("Entry250")
                        targetRankText = "rank 250"
                    end

                    -- Get target team's score
                    if targetEntry and starsTo250 ~= "Rank #1! 🏆" then
                        local numberLabel = targetEntry:FindFirstChild("Number")
                        if numberLabel and numberLabel:IsA("TextLabel") then
                            -- Parse the score (might have commas or formatting)
                            local scoreText = numberLabel.Text
                            local targetScore = tonumber((scoreText:gsub(",", ""))) or 0

                            if totalScore < targetScore then
                                local starsNeeded = targetScore - totalScore + 1  -- +1 to beat them
                                starsTo250 = string.format("%s to beat %s", formatNumber(starsNeeded), targetRankText)
                            else
                                if rankNumber and rankNumber <= 250 then
                                    starsTo250 = string.format("Beating %s! ✅", targetRankText)
                                else
                                    starsTo250 = "Ready for top 250! ✅"
                                end
                            end
                        end
                    end
                end

                -- Calculate stars/min based on total team score change
                local previousTotal = 0
                for userId, prevScore in pairs(state.compPreviousScores) do
                    previousTotal = previousTotal + prevScore
                end

                if previousTotal > 0 and minutesSinceLastCheck > 0 then
                    local scoreDiff = totalScore - previousTotal
                    starsPerMin = scoreDiff / minutesSinceLastCheck
                end

                -- Build team info text
                teamText = string.format("**Team Name**: %s\n", teamName)
                teamText = teamText .. string.format("**Members**: %d\n", memberCount)
                teamText = teamText .. string.format("**Total Team Score**: %s\n\n", formatNumber(totalScore))

                -- Add individual member scores with differences
                teamText = teamText .. "**Member Scores**:\n"
                for i, member in ipairs(memberScores) do
                    local prevScore = state.compPreviousScores[member.userId] or 0
                    local scoreDiff = member.score - prevScore
                    local diffText = ""

                    if prevScore > 0 and scoreDiff ~= 0 then
                        diffText = string.format(" (%s%s)",
                            scoreDiff > 0 and "+" or "",
                            formatNumber(scoreDiff)
                        )
                    end

                    teamText = teamText .. string.format("%d. %s: %s%s\n",
                        i,
                        member.name,
                        formatNumber(member.score),
                        diffText
                    )
                end

                -- Update previous scores
                state.compPreviousScores = {}
                for _, member in ipairs(memberScores) do
                    state.compPreviousScores[member.userId] = member.score
                end
            else
                teamText = "**Status**: Not in a team"
            end

            -- Update previous time
            state.compPreviousTime = currentTime

            -- Build embed
            local fields = {
                {
                    name = "📊 Competitive Score",
                    value = string.format("**Current Score**: %s", formatNumber(compData.Score or 0)),
                    inline = false
                }
            }

            -- Add team rank if in team
            if clanData and clanData.Id then
                table.insert(fields, {
                    name = "🏅 Team Leaderboard Position",
                    value = string.format("**Team Rank**: #%s", teamRank),
                    inline = false
                })
            end

            -- Add team data
            if clanData and clanData.Id then
                table.insert(fields, {
                    name = "👥 Team Data",
                    value = teamText,
                    inline = false
                })
            end

            -- Add performance stats
            if clanData and clanData.Id then
                local perfText = ""

                if starsPerMin > 0 then
                    perfText = string.format("**Stars/min**: %.1f ⭐\n", starsPerMin)
                else
                    perfText = "**Stars/min**: Calculating... (need 2 checks)\n"
                end

                perfText = perfText .. string.format("**Goal**: %s", starsTo250)

                table.insert(fields, {
                    name = "📈 Performance",
                    value = perfText,
                    inline = false
                })
            end

            local embed = {
                title = testMode and "🧪 Test - Competitive Stats" or "🏆 Competitive Stats",
                description = string.format("**Player**: %s (@%s)", player.DisplayName, player.Name),
                color = 3447003,  -- Blue
                fields = fields,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
            }

            local payload = {embeds = {embed}}

            pcall(function()
                request({
                    Url = state.compWebhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload)
                })
            end)

            if testMode then
                Rayfield:Notify({
                    Title = "Webhook Sent",
                    Content = "Competitive test webhook sent!",
                    Duration = 3,
                })
            end
        end)
    end)
end

-- === QUEST HELPER FUNCTIONS ===

-- Parse quest to determine type and requirements
local function parseQuest(quest)
    if not quest or not quest.Tasks or not quest.Tasks[1] then
        return nil
    end

    local task = quest.Tasks[1]
    local taskType = task.Type
    local progressValue = 0
    if type(quest.Progress) == "table" and type(quest.Progress[1]) == "number" then
        progressValue = quest.Progress[1]
    elseif type(task.Progress) == "number" then
        progressValue = task.Progress
    end

    local questInfo = {
        id = quest.Id,
        taskType = taskType,
        type = "unknown",
        specificEgg = nil,
        rarity = nil,
        amount = task.Amount or 0,
        progress = progressValue
    }

    -- Check task type
    if taskType then
        local lowerType = taskType:lower()

        -- Bubble quest
        if lowerType:find("bubble") or lowerType:find("blow") then
            questInfo.type = "bubble"
        -- Hatch quest
        elseif lowerType:find("hatch") or lowerType:find("egg") or lowerType:find("open") then
            questInfo.type = "hatch"

            -- Check for specific egg in task data
            if task.Data then
                if task.Data.Egg then
                    questInfo.specificEgg = task.Data.Egg
                elseif task.Data.Rarity then
                    questInfo.rarity = task.Data.Rarity
                end
            end

            -- Many quest tasks store these fields directly (not in task.Data)
            if not questInfo.specificEgg and task.Egg then
                questInfo.specificEgg = task.Egg
            end
            if not questInfo.specificEgg and type(task.Eggs) == "table" and type(task.Eggs[1]) == "string" then
                questInfo.specificEgg = task.Eggs[1]
            end
            if not questInfo.rarity and task.Rarity then
                questInfo.rarity = task.Rarity
            end

            -- Also check in task name/type for egg names
            if not questInfo.specificEgg then
                for _, eggName in pairs({"Common Egg", "Hell Egg", "Volcano Egg", "Ice Egg", "Sakura Egg", "Super Egg", "Heaven Egg", "Infinity Egg", "Painted Egg", "Basket Egg", "Easter Bunny Egg", "4x Luck Easter Bunny Egg"}) do
                    if taskType:find(eggName) then
                        questInfo.specificEgg = eggName
                        break
                    end
                end
            end

            -- Check for rarity in type
            if not questInfo.rarity then
                for _, rarity in pairs({"Common", "Unique", "Rare", "Epic", "Legendary", "Secret", "Infinity", "Celestial"}) do
                    if taskType:find(rarity) then
                        questInfo.rarity = rarity
                        break
                    end
                end
            end
        -- Playtime quest
        elseif lowerType:find("playtime") or lowerType:find("play") or lowerType:find("time") then
            questInfo.type = "playtime"
        end
    end

    return questInfo
end

-- Get all competitive hatch quests (slots 1-4)
local function getCompetitiveHatchQuests(playerData)
    local hatchQuests = {}

    if not playerData or not playerData.Quests then
        return hatchQuests
    end

    for slotNum = 1, 4 do
        local questId = "competitive-" .. slotNum

        for _, quest in pairs(playerData.Quests) do
            if type(quest) == "table" and quest.Id == questId then
                local questInfo = parseQuest(quest)
                if questInfo and questInfo.type == "hatch" then
                    questInfo.slot = slotNum
                    table.insert(hatchQuests, questInfo)
                end
                break
            end
        end
    end

    return hatchQuests
end

-- Get all season pass hatch quests
local function getSeasonHatchQuests(playerData)
    local hatchQuests = {}

    if not playerData or not playerData.Quests then
        return hatchQuests
    end

    for _, quest in pairs(playerData.Quests) do
        if type(quest) == "table" then
            -- Season quests typically have IDs like "season-1", "season-2", etc.
            if quest.Id and quest.Id:find("season") then
                local questInfo = parseQuest(quest)
                if questInfo and questInfo.type == "hatch" then
                    table.insert(hatchQuests, questInfo)
                end
            end
        end
    end

    return hatchQuests
end

-- Find best egg to hatch based on comp and season quests
local function findBestHatchEgg(compQuest, seasonQuests)
    -- Priority 1: Match specific egg from comp quest with season quest
    if compQuest.specificEgg then
        for _, seasonQuest in ipairs(seasonQuests) do
            if seasonQuest.specificEgg == compQuest.specificEgg then
                return compQuest.specificEgg, true  -- egg name, matches season
            end
        end
        return compQuest.specificEgg, false  -- use comp egg, no season match
    end

    -- Priority 2: Match rarity from comp quest with specific egg from season quest
    if compQuest.rarity then
        for _, seasonQuest in ipairs(seasonQuests) do
            if seasonQuest.specificEgg then
                -- Check if this egg has the rarity we need
                -- We'll use this egg and check if it gives the right rarity
                return seasonQuest.specificEgg, true
            end
        end
    end

    -- Priority 3: Use specific egg from any season quest
    for _, seasonQuest in ipairs(seasonQuests) do
        if seasonQuest.specificEgg then
            return seasonQuest.specificEgg, true
        end
    end

    -- Priority 4: Use specific egg from comp quest if available
    if compQuest.specificEgg then
        return compQuest.specificEgg, false
    end

    -- Priority 5: Fallback to Infinity Egg
    return "Infinity Egg", false
end

-- Check if a quest should be skipped based on user settings
local function shouldSkipQuest(questInfo)
    if not questInfo then return true end

    if questInfo.type == "hatch" and not state.compDoHatchQuests then
        return true
    end

    if questInfo.type == "bubble" and not state.compDoBubbleQuests then
        return true
    end

    if questInfo.type == "playtime" and not state.compDoPlaytimeQuests then
        return true
    end

    return false
end

local localDataService = nil
local function getPlayerData()
    if not localDataService then
        pcall(function()
            localDataService = require(RS.Client.Framework.Services.LocalData)
        end)

        if not localDataService then
            pcall(function()
                local localDataModule = RS:FindFirstChild("Client", true)
                if localDataModule then
                    localDataModule = localDataModule:FindFirstChild("Framework", true)
                    if localDataModule then
                        localDataModule = localDataModule:FindFirstChild("Services", true)
                        if localDataModule then
                            localDataModule = localDataModule:FindFirstChild("LocalData", true)
                        end
                    end
                end

                if localDataModule then
                    localDataService = require(localDataModule)
                end
            end)
        end
    end

    if not localDataService then
        return nil
    end

    local ok, data = pcall(function()
        return localDataService:Get()
    end)

    return ok and data or nil
end

local ROMAN_POTION_LEVELS = {
    I = 1, II = 2, III = 3, IV = 4, V = 5,
    VI = 6, VII = 7, VIII = 8, IX = 9, X = 10,
}

local function getServerUnixTime()
    local ok, value = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if ok and type(value) == "number" then
        return value
    end
    return os.time()
end

local function normalizePotionSelection(selection)
    if type(selection) ~= "string" then
        return nil, nil
    end

    local cleaned = selection:match("^%s*(.-)%s*$")
    if not cleaned or cleaned == "" then
        return nil, nil
    end

    local baseRoman, roman = cleaned:match("^(.-)%s+([IVX]+)$")
    if baseRoman and ROMAN_POTION_LEVELS[roman] then
        return baseRoman, ROMAN_POTION_LEVELS[roman]
    end

    local baseNumber, numeric = cleaned:match("^(.-)%s+(%d+)$")
    if baseNumber and numeric then
        return baseNumber, tonumber(numeric)
    end

    return cleaned, nil
end

local function getBestOwnedPotionLevel(playerData, potionName, requestedLevel)
    if not playerData or type(playerData.Potions) ~= "table" then
        return requestedLevel
    end

    local bestLevel = nil
    local requestedFound = false

    for _, potion in ipairs(playerData.Potions) do
        if type(potion) == "table" and potion.Name == potionName then
            local amount = tonumber(potion.Amount) or 0
            local level = tonumber(potion.Level)
            if amount > 0 and level then
                if requestedLevel and level == requestedLevel then
                    requestedFound = true
                end
                if not bestLevel or level > bestLevel then
                    bestLevel = level
                end
            end
        end
    end

    if requestedLevel then
        return requestedFound and requestedLevel or nil
    end

    return bestLevel
end

local function getActivePotionRemaining(playerData, potionName)
    if not playerData or type(playerData.ActivePotions) ~= "table" then
        return 0, nil
    end

    local potionEntry = playerData.ActivePotions[potionName]
    if type(potionEntry) ~= "table" then
        return 0, nil
    end

    -- If the game already queued one or more uses, do not spam UsePotion again.
    -- Queue entries are generally relative durations/uses, so treat as pending.
    if type(potionEntry.Queue) == "table" and #potionEntry.Queue > 0 then
        return 1, nil
    end

    local active = potionEntry.Active
    if type(active) ~= "table" then
        return 0, nil
    end

    local expiry = active.Expiry
    local expiryType = nil
    local expiryDuration = nil

    if type(expiry) == "table" then
        expiryType = expiry.Type
        expiryDuration = tonumber(expiry.Duration)
    elseif type(expiry) == "number" then
        expiryType = "Timer"
        expiryDuration = expiry
    end

    if not expiryDuration then
        return 0, active.Level
    end

    -- Some potions are usage-based (Expiry.Type = "Uses") and must not be
    -- interpreted as unix timestamps.
    if expiryType == "Uses" then
        return math.max(expiryDuration, 0), active.Level
    end

    -- Timer expiry in BGSI is usually unix time. Some contexts may provide
    -- relative seconds; treat small values as already-remaining duration.
    local now = getServerUnixTime()
    local remaining = nil
    if expiryDuration > 1000000000 then
        remaining = expiryDuration - now
    else
        remaining = expiryDuration
    end

    return math.max(remaining or 0, 0), active.Level
end

local function getSelectedPotionNames(selectionValue)
    local names = {}
    local seen = {}

    if type(selectionValue) ~= "table" then
        return names
    end

    for key, value in pairs(selectionValue) do
        local name = nil

        -- Format A: {"Lucky", "Speed"}
        if type(key) == "number" and type(value) == "string" then
            name = value
        end

        -- Format B: {Lucky = true, Speed = true}
        if not name and type(key) == "string" then
            if value == true or value == 1 or value == "true" then
                name = key
            end
        end

        if name then
            local trimmed = tostring(name):match("^%s*(.-)%s*$") or tostring(name)
            local lower = trimmed:lower()

            -- Drop UI placeholders/noise from multi-select controls.
            if trimmed == "" or lower == "loading..." or lower == "loading" or lower == "select" then
                name = nil
            else
                name = trimmed
            end
        end

        if name and not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    return names
end

local function getDiscoverWorldList()
    if state.discoverTargetWorld == "The Overworld" then
        return {"The Overworld"}
    end
    if state.discoverTargetWorld == "Minigame Paradise" then
        return {"Minigame Paradise"}
    end
    return {"The Overworld", "Minigame Paradise"}
end

local function getWorldAreaTargets(worldName)
    local targets = {}
    local worlds = Workspace:FindFirstChild("Worlds")
    if not worlds then
        return targets
    end

    local world = worlds:FindFirstChild(worldName)
    if not world then
        return targets
    end

    local function addTarget(areaName, keyName, part)
        if not areaName or not keyName or not part or not part:IsA("BasePart") then
            return
        end

        local key = worldName .. "::" .. keyName
        for _, existing in ipairs(targets) do
            if existing.key == key then
                return
            end
        end

        table.insert(targets, {
            key = key,
            worldName = worldName,
            areaName = areaName,
            part = part
        })
    end

    local areas = world:FindFirstChild("Areas")
    if areas then
        for _, area in ipairs(areas:GetChildren()) do
            local island = area:FindFirstChild("Island")
            local unlockHitbox = island and island:FindFirstChild("UnlockHitbox")
            local islandTeleport = area:FindFirstChild("IslandTeleport")
            local spawn = islandTeleport and islandTeleport:FindFirstChild("Spawn")

            if unlockHitbox and unlockHitbox:IsA("BasePart") then
                addTarget(area.Name, area.Name, unlockHitbox)
            elseif spawn and spawn:IsA("BasePart") then
                addTarget(area.Name, area.Name, spawn)
            end
        end
    end

    local islands = world:FindFirstChild("Islands")
    if islands then
        for _, islandFolder in ipairs(islands:GetChildren()) do
            local islandModel = islandFolder:FindFirstChild("Island")
            local unlockHitbox = islandModel and islandModel:FindFirstChild("UnlockHitbox")
            local portal = islandModel and islandModel:FindFirstChild("Portal")
            local prompt = portal and portal:FindFirstChild("Prompt")
            local display = portal and portal:FindFirstChild("Display")

            if unlockHitbox and unlockHitbox:IsA("BasePart") then
                addTarget(islandFolder.Name, islandFolder.Name, unlockHitbox)
            elseif prompt and prompt:IsA("BasePart") then
                addTarget(islandFolder.Name, islandFolder.Name, prompt)
            elseif display and display:IsA("BasePart") then
                addTarget(islandFolder.Name, islandFolder.Name, display)
            end
        end
    end

    table.sort(targets, function(a, b)
        return a.areaName < b.areaName
    end)

    return targets
end

local function doIslandDiscoverStep()
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false, "no-character"
    end

    local playerData = getPlayerData()
    local areasUnlocked = playerData and playerData.AreasUnlocked or nil

    local worlds = getDiscoverWorldList()
    local totalTargets = 0
    local remainingTargets = 0

    for _, worldName in ipairs(worlds) do
        local targets = getWorldAreaTargets(worldName)
        for _, target in ipairs(targets) do
            totalTargets = totalTargets + 1
            local alreadyUnlocked = type(areasUnlocked) == "table" and areasUnlocked[target.areaName] ~= nil

            if not state.discoveredIslands[target.key] and not alreadyUnlocked then
                remainingTargets = remainingTargets + 1
                if player.RequestStreamAroundAsync then
                    pcall(function()
                        player:RequestStreamAroundAsync(target.part.Position)
                    end)
                end

                hrp.CFrame = target.part.CFrame + Vector3.new(0, 4, 0)

                if firetouchinterest then
                    pcall(function()
                        firetouchinterest(hrp, target.part, 0)
                        firetouchinterest(hrp, target.part, 1)
                    end)
                end

                state.discoveredIslands[target.key] = true
                log("🗺️ [Discover] Visited " .. target.areaName .. " (" .. target.worldName .. ")")
                return true, "visited"
            end
        end
    end

    if totalTargets == 0 then
        return false, "no-targets"
    end
    if remainingTargets == 0 then
        return false, "all-unlocked"
    end
    return false, "idle"
end

local function isWorldUnlocked(playerData, worldName)
    if not playerData then
        return false
    end

    local unlocked = playerData.WorldsUnlocked
    if type(unlocked) ~= "table" then
        return false
    end

    if unlocked[worldName] then
        return true
    end

    for _, value in pairs(unlocked) do
        if value == worldName then
            return true
        end
    end

    return false
end

local function getActiveSeasonQuest(playerData)
    if not playerData or not playerData.Quests then
        return nil
    end

    local bestQuest = nil
    local bestPriority = 999

    for _, quest in pairs(playerData.Quests) do
        if type(quest) == "table" and type(quest.Id) == "string" then
            local idLower = quest.Id:lower()
            local isSeasonChallenge = idLower:find("daily%-challenge") or idLower:find("hourly%-challenge") or idLower:find("season")
            if isSeasonChallenge then
                local info = parseQuest(quest)
                if info and info.amount > 0 and info.progress < info.amount then
                    local lowerTaskType = type(info.taskType) == "string" and info.taskType:lower() or ""
                    local priority = 5

                    if info.type == "hatch" and info.specificEgg then
                        priority = 1
                    elseif info.type == "hatch" then
                        priority = 2
                    elseif info.type == "bubble" then
                        priority = 3
                    elseif lowerTaskType:find("collect") or lowerTaskType:find("pickup") or lowerTaskType:find("coin") then
                        priority = 4
                    elseif info.type == "playtime" then
                        priority = 10
                    end

                    if priority < bestPriority then
                        bestPriority = priority
                        bestQuest = info
                    end
                end
            end
        end
    end

    return bestQuest
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

-- === CONFIG SYSTEM ===
local setPerformanceMode

local function saveConfig(configName)
    if not configName or configName == "" then
        return false, "Config name cannot be empty"
    end

    -- Debug: Print current state values before saving
    --  print("📝 Preparing to save config: " .. configName)
    --  print("🔍 Current state.webhookUrl: " .. tostring(state.webhookUrl))
    --  print("🔍 Current state.webhookPingUserId: " .. tostring(state.webhookPingUserId))
    --  print("🔍 Current state.fishingIsland: " .. tostring(state.fishingIsland))

    local config = {
        -- Farm settings
        autoBlow = state.autoBlow,
        autoHatch = state.autoHatch,
        autoPickup = state.autoPickup,
        autoChest = state.autoChest,
        autoSellBubbles = state.autoSellBubbles,
        autoClaimPlaytime = state.autoClaimPlaytime,
        autoFishEnabled = state.autoFishEnabled,

        -- Egg/Rift settings
        eggPriority = state.eggPriority,
        riftPriority = state.riftPriority,
        maxEggs = state.maxEggs,
        priorityEggMode = state.priorityEggMode,
        priorityEggs = state.priorityEggs,
        riftPriorityMode = state.riftPriorityMode,
        priorityRifts = state.priorityRifts,
        riftAutoHatch = state.riftAutoHatch,

        -- Easter event settings
        easterAutoPickup = state.easterAutoPickup,
        easterAutoShop = state.easterAutoShop,
        easterShopTier = state.easterShopTier,
        easterSecretShop = state.easterSecretShop,
        easterAutoEgg = state.easterAutoEgg,
        easterSelectedEgg = state.easterSelectedEgg,
        easterPriorityEggMode = state.easterPriorityEggMode,
        easterPriorityEggs = state.easterPriorityEggs,
        easterHideEggAnim = state.easterHideEggAnim,
        easterAutoChest = state.easterAutoChest,
        easterAutoHunt = state.easterAutoHunt,
        easterAutoJester = state.easterAutoJester,
        easterAutoClaimRewards = state.easterAutoClaimRewards,
        easterAutoMastery = state.easterAutoMastery,
        easterAdvancedShop = state.easterAdvancedShop,
        easterShopId = state.easterShopId,
        easterPickupZone = state.easterPickupZone,
        easterHatchAmount = state.easterHatchAmount,
        easterLowLagHatch = state.easterLowLagHatch,

        -- Team settings
        hatchTeam = state.hatchTeam,
        statsTeam = state.statsTeam,
        hatchTeamIndex = state.hatchTeamIndex,
        statsTeamIndex = state.statsTeamIndex,

        -- Potion settings
        selectedPotions = state.selectedPotions,
        autoPotionEnabled = state.autoPotionEnabled,

        -- Powerup settings
        selectedPowerups = state.selectedPowerups,
        autoPowerupEnabled = state.autoPowerupEnabled,

        -- Enchant settings
        enchantMain = state.enchantMain,
      enchantMainTier = state.enchantMainTier,
      enchantMainEnabled = state.enchantMainEnabled,
      enchantSecond = state.enchantSecond,
      enchantSecondTier = state.enchantSecondTier,
      enchantSecondEnabled = state.enchantSecondEnabled,
      autoEnchantEnabled = state.autoEnchantEnabled,
        -- Webhook settings
        webhookUrl = state.webhookUrl,
        webhookRarities = state.webhookRarities,
        webhookChanceThreshold = state.webhookChanceThreshold,
        webhookStatsEnabled = state.webhookStatsEnabled,
        webhookStatsInterval = state.webhookStatsInterval,
        webhookPingEnabled = state.webhookPingEnabled,
        webhookPingUserId = state.webhookPingUserId,

        -- Competitive settings
        compAutoEnabled = state.compAutoEnabled,
        compWebhookUrl = state.compWebhookUrl,
        compWebhookInterval = state.compWebhookInterval,
        compRerollNonBubble = state.compRerollNonBubble,
        compDoHatchQuests = state.compDoHatchQuests,
        compDoBubbleQuests = state.compDoBubbleQuests,
        compDoPlaytimeQuests = state.compDoPlaytimeQuests,

        -- Other settings
        disableHatchAnimation = state.disableHatchAnimation,
        performanceMode = state.performanceMode,
        antiAFK = state.antiAFK,
        fishingIsland = state.fishingIsland,
        fishingRod = state.fishingRod,
        autoObbyFarm = state.autoObbyFarm,
        autoObbyChestClaim = state.autoObbyChestClaim,
        selectedObbies = state.selectedObbies,
        autoDiscoverIslands = state.autoDiscoverIslands,
        discoverTargetWorld = state.discoverTargetWorld,
        autoUnlockWorlds = state.autoUnlockWorlds,
        selectedUnlockWorlds = state.selectedUnlockWorlds,
        autoSeasonQuest = state.autoSeasonQuest,
        autoSeasonClaimRewards = state.autoSeasonClaimRewards,
        autoSeasonInfinite = state.autoSeasonInfinite,
        seasonFallbackEgg = state.seasonFallbackEgg
    }

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(config)
    end)

    if success then
        local fileName = "LorioBGSI_Config_" .. configName .. ".json"
        writefile(fileName, encoded)
        state.savedConfigs[configName] = config
        --  print("💾 Config saved to: " .. fileName)
        --  print("📊 Config size: " .. #encoded .. " bytes")
        --  print("🔍 Webhook URL saved: " .. tostring(config.webhookUrl ~= "" and "Yes (" .. #config.webhookUrl .. " chars)" or "Empty"))
        --  print("🔍 Webhook Ping User ID saved: " .. tostring(config.webhookPingUserId ~= "" and "Yes (" .. config.webhookPingUserId .. ")" or "Empty"))
        --  print("🔍 Fishing Island saved: " .. tostring(config.fishingIsland or "nil"))
        return true, "Config saved successfully"
    else
        return false, "Failed to encode config: " .. tostring(encoded)
    end
end

local function loadConfig(configName)
    if not configName or configName == "" then
        return false, "Config name cannot be empty"
    end

    local fileName = "LorioBGSI_Config_" .. configName .. ".json"

    if not isfile(fileName) then
        return false, "Config file not found"
    end

    local success, content = pcall(function()
        return readfile(fileName)
    end)

    if not success then
        return false, "Failed to read config file"
    end

    local decodeSuccess, config = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not decodeSuccess then
        return false, "Failed to decode config"
    end

    -- Apply config to state
    state.autoBlow = config.autoBlow or false
    state.autoHatch = config.autoHatch or false
    state.autoPickup = config.autoPickup or false
    state.autoChest = config.autoChest or false
    state.autoSellBubbles = config.autoSellBubbles or false
    state.autoClaimPlaytime = config.autoClaimPlaytime or false
    state.autoFishEnabled = config.autoFishEnabled or false

    state.eggPriority = config.eggPriority
    state.riftPriority = config.riftPriority
    state.maxEggs = config.maxEggs or 7
    state.priorityEggMode = config.priorityEggMode or false
    state.priorityEggs = config.priorityEggs or state.priorityEggs
    state.riftPriorityMode = config.riftPriorityMode or false
    state.priorityRifts = config.priorityRifts or state.priorityRifts
    state.riftAutoHatch = config.riftAutoHatch or false

    -- Easter event settings (with backward compatibility for old StPat keys)
    state.autoWheelSpin = false
    state.easterAutoPickup = (config.easterAutoPickup ~= nil) and config.easterAutoPickup or (config.stpatAutoPickup or false)
    state.easterAutoShop = (config.easterAutoShop ~= nil) and config.easterAutoShop or (config.stpatAutoShop or false)
    state.easterShopTier = (config.easterShopTier ~= nil) and config.easterShopTier or (config.stpatShopTier or 1)
    state.easterSecretShop = (config.easterSecretShop ~= nil) and config.easterSecretShop or (config.stpatSecretShop or false)
    state.easterAutoEgg = (config.easterAutoEgg ~= nil) and config.easterAutoEgg or (config.stpatAutoEgg or false)
    state.easterSelectedEgg = config.easterSelectedEgg or config.stpatSelectedEgg

    local function normalizeLegacyEggName(name)
        if type(name) ~= "string" then
            return name
        end
        if name == "4X Luck Fortune Egg" or name == "4X Gaelic Egg" or name == "4X Luck Gaelic Egg" then
            return "4x Luck Easter Bunny Egg"
        elseif name == "Gaelic Egg" or name == "Fortune Egg" then
            return "Easter Bunny Egg"
        elseif name == "Lucky Egg" then
            return "Basket Egg"
        end
        return name
    end

    state.easterSelectedEgg = normalizeLegacyEggName(state.easterSelectedEgg)
    state.easterPriorityEggMode = (config.easterPriorityEggMode ~= nil) and config.easterPriorityEggMode or (config.stpatPriorityEggMode or false)
    state.easterPriorityEggs = config.easterPriorityEggs or config.stpatPriorityEggs or state.easterPriorityEggs
    if type(state.easterPriorityEggs) == "table" then
        for i, name in ipairs(state.easterPriorityEggs) do
            state.easterPriorityEggs[i] = normalizeLegacyEggName(name)
        end
    end
    state.easterHideEggAnim = (config.easterHideEggAnim ~= nil) and config.easterHideEggAnim or (config.stpatHideEggAnim or false)
    state.easterAutoChest = (config.easterAutoChest ~= nil) and config.easterAutoChest or (config.stpatAutoChest or false)
    state.easterAutoHunt = config.easterAutoHunt or false
    state.easterAutoJester = config.easterAutoJester or false
    state.easterAutoClaimRewards = config.easterAutoClaimRewards or false
    state.easterAutoMastery = config.easterAutoMastery or false
    state.easterAdvancedShop = config.easterAdvancedShop or false
    state.easterShopId = config.easterShopId or "easter-shop"
    state.easterPickupZone = config.easterPickupZone or "Spawn Island"
    if state.easterPickupZone == "Second Island" or state.easterPickupZone == "Second Island (Easter Island)" then
        state.easterPickupZone = "Easter Island"
    end
    state.easterHatchAmount = math.clamp(tonumber(config.easterHatchAmount) or 3, 1, 99)
    state.easterLowLagHatch = config.easterLowLagHatch or false

    state.hatchTeam = config.hatchTeam
    state.statsTeam = config.statsTeam
    state.hatchTeamIndex = config.hatchTeamIndex
    state.statsTeamIndex = config.statsTeamIndex

    state.selectedPotions = config.selectedPotions or {}
    state.autoPotionEnabled = config.autoPotionEnabled or false

    state.selectedPowerups = config.selectedPowerups or {}
    state.autoPowerupEnabled = config.autoPowerupEnabled or false

    state.enchantMain = config.enchantMain
    state.enchantMainTier = config.enchantMainTier or 1
    state.enchantMainEnabled = config.enchantMainEnabled ~= false  -- Default true
    state.enchantSecond = config.enchantSecond
    state.enchantSecondTier = config.enchantSecondTier or 1
    state.enchantSecondEnabled = config.enchantSecondEnabled ~= false  -- Default true
    state.autoEnchantEnabled = config.autoEnchantEnabled or false

    state.webhookUrl = config.webhookUrl or ""
    state.webhookRarities = config.webhookRarities or state.webhookRarities
    state.webhookChanceThreshold = config.webhookChanceThreshold or state.webhookChanceThreshold
    state.webhookStatsEnabled = config.webhookStatsEnabled or false
    state.webhookStatsInterval = config.webhookStatsInterval or state.webhookStatsInterval
    state.webhookPingEnabled = config.webhookPingEnabled or false
    state.webhookPingUserId = config.webhookPingUserId or ""

    state.compAutoEnabled = config.compAutoEnabled or false
    state.compWebhookUrl = config.compWebhookUrl or ""
    state.compWebhookInterval = config.compWebhookInterval or 300
    state.compRerollNonBubble = config.compRerollNonBubble ~= false  -- Default true
    state.compDoHatchQuests = config.compDoHatchQuests == true  -- Default false
    state.compDoBubbleQuests = config.compDoBubbleQuests ~= false  -- Default true
    state.compDoPlaytimeQuests = config.compDoPlaytimeQuests ~= false  -- Default true

    state.disableHatchAnimation = config.disableHatchAnimation or false
    setPerformanceMode(config.performanceMode or false)
    state.antiAFK = config.antiAFK or false
    state.fishingIsland = config.fishingIsland
    state.fishingRod = config.fishingRod or "Wooden Rod"
    state.autoObbyFarm = config.autoObbyFarm or false
    state.autoObbyChestClaim = config.autoObbyChestClaim or false
    state.selectedObbies = config.selectedObbies or {"Easy"}
    state.obbyNextIndex = 1
    state.autoDiscoverIslands = config.autoDiscoverIslands or false
    state.discoverTargetWorld = config.discoverTargetWorld or "Both Worlds"
    state.discoveredIslands = {}
    state.lastDiscoverStep = 0
    state.lastDiscoverDoneLog = 0
    state.autoUnlockWorlds = config.autoUnlockWorlds or false
    state.selectedUnlockWorlds = config.selectedUnlockWorlds or {"Minigame Paradise"}
    state.lastWorldUnlockAttempt = 0
    state.autoSeasonQuest = config.autoSeasonQuest or false
    state.autoSeasonClaimRewards = config.autoSeasonClaimRewards or false
    state.autoSeasonInfinite = config.autoSeasonInfinite or false
    state.seasonFallbackEgg = config.seasonFallbackEgg or "Infinity Egg"
    state.lastSeasonQuestAction = 0
    state.lastSeasonRewardClaim = 0
    state.lastSeasonInfiniteAttempt = 0
    state.seasonActiveQuestId = nil

    state.savedConfigs[configName] = config

    --  print("✅ Config loaded from: " .. fileName)
    --  print("🔍 Webhook URL loaded: " .. (state.webhookUrl ~= "" and "Yes (" .. #state.webhookUrl .. " chars)" or "Empty"))
    --  print("🔍 Webhook Ping User ID loaded: " .. (state.webhookPingUserId ~= "" and "Yes (" .. state.webhookPingUserId .. ")" or "Empty"))
    --  print("🔍 Fishing Island loaded: " .. tostring(state.fishingIsland or "nil"))

    -- Update UI elements to match loaded config values
    --  print("🔄 Updating UI elements...")
    local ui = state.uiElements

    -- Update toggles (if they exist)
    if ui.DisableAnimToggle then pcall(function() ui.DisableAnimToggle:Set(state.disableHatchAnimation) end) end
    if ui.AutoBlowToggle then pcall(function() ui.AutoBlowToggle:Set(state.autoBlow) end) end
    if ui.AutoPickupToggle then pcall(function() ui.AutoPickupToggle:Set(state.autoPickup) end) end
    if ui.AutoHatchToggle then pcall(function() ui.AutoHatchToggle:Set(state.autoHatch) end) end
    if ui.AutoChestToggle then pcall(function() ui.AutoChestToggle:Set(state.autoChest) end) end
    if ui.AutoSellBubblesToggle then pcall(function() ui.AutoSellBubblesToggle:Set(state.autoSellBubbles) end) end
    if ui.AutoClaimEventPrizesToggle then pcall(function() ui.AutoClaimEventPrizesToggle:Set(state.autoClaimEventPrizes) end) end
    if ui.AutoClaimPlaytimeToggle then pcall(function() ui.AutoClaimPlaytimeToggle:Set(state.autoClaimPlaytime) end) end
    if ui.AntiAFKToggle then pcall(function() ui.AntiAFKToggle:Set(state.antiAFK) end) end
    if ui.PerformanceModeToggle then pcall(function() ui.PerformanceModeToggle:Set(state.performanceMode) end) end
    if ui.AutoFishToggle then pcall(function() ui.AutoFishToggle:Set(state.autoFishEnabled) end) end
    if ui.EasterAutoPickupToggle then pcall(function() ui.EasterAutoPickupToggle:Set(state.easterAutoPickup) end) end
    if ui.EasterAutoShopToggle then pcall(function() ui.EasterAutoShopToggle:Set(state.easterAutoShop) end) end
    if ui.EasterSecretShopToggle then pcall(function() ui.EasterSecretShopToggle:Set(state.easterSecretShop) end) end
    if ui.EasterHideEggAnimToggle then pcall(function() ui.EasterHideEggAnimToggle:Set(state.easterHideEggAnim) end) end
    if ui.EasterAutoEggToggle then pcall(function() ui.EasterAutoEggToggle:Set(state.easterAutoEgg) end) end
    if ui.EasterPriorityEggModeToggle then pcall(function() ui.EasterPriorityEggModeToggle:Set(state.easterPriorityEggMode) end) end
    if ui.EasterAutoChestToggle then pcall(function() ui.EasterAutoChestToggle:Set(state.easterAutoChest) end) end
    if ui.EasterAutoHuntToggle then pcall(function() ui.EasterAutoHuntToggle:Set(state.easterAutoHunt) end) end
    if ui.EasterAutoJesterToggle then pcall(function() ui.EasterAutoJesterToggle:Set(state.easterAutoJester) end) end
    if ui.EasterAutoClaimRewardsToggle then pcall(function() ui.EasterAutoClaimRewardsToggle:Set(state.easterAutoClaimRewards) end) end
    if ui.EasterAutoMasteryToggle then pcall(function() ui.EasterAutoMasteryToggle:Set(state.easterAutoMastery) end) end
    if ui.EasterAdvancedShopToggle then pcall(function() ui.EasterAdvancedShopToggle:Set(state.easterAdvancedShop) end) end
    if ui.EasterLowLagHatchToggle then pcall(function() ui.EasterLowLagHatchToggle:Set(state.easterLowLagHatch) end) end
    if ui.AutoObbyFarmToggle then pcall(function() ui.AutoObbyFarmToggle:Set(state.autoObbyFarm) end) end
    if ui.AutoObbyChestToggle then pcall(function() ui.AutoObbyChestToggle:Set(state.autoObbyChestClaim) end) end
    if ui.AutoDiscoverIslandsToggle then pcall(function() ui.AutoDiscoverIslandsToggle:Set(state.autoDiscoverIslands) end) end
    if ui.AutoUnlockWorldsToggle then pcall(function() ui.AutoUnlockWorldsToggle:Set(state.autoUnlockWorlds) end) end
    if ui.AutoSeasonQuestToggle then pcall(function() ui.AutoSeasonQuestToggle:Set(state.autoSeasonQuest) end) end
    if ui.AutoSeasonClaimToggle then pcall(function() ui.AutoSeasonClaimToggle:Set(state.autoSeasonClaimRewards) end) end
    if ui.AutoSeasonInfiniteToggle then pcall(function() ui.AutoSeasonInfiniteToggle:Set(state.autoSeasonInfinite) end) end
    if ui.AutoPotionToggle then pcall(function() ui.AutoPotionToggle:Set(state.autoPotionEnabled) end) end
    if ui.AutoPowerupToggle then pcall(function() ui.AutoPowerupToggle:Set(state.autoPowerupEnabled) end) end
    if ui.AutoEnchantToggle then pcall(function() ui.AutoEnchantToggle:Set(state.autoEnchantEnabled) end) end
    if ui.EnchantMainToggle then pcall(function() ui.EnchantMainToggle:Set(state.enchantMainEnabled) end) end
    if ui.EnchantSecondToggle then pcall(function() ui.EnchantSecondToggle:Set(state.enchantSecondEnabled) end) end
    if ui.PriorityEggModeToggle then pcall(function() ui.PriorityEggModeToggle:Set(state.priorityEggMode) end) end
    if ui.RiftPriorityModeToggle then pcall(function() ui.RiftPriorityModeToggle:Set(state.riftPriorityMode) end) end
    if ui.RiftAutoHatchToggle then pcall(function() ui.RiftAutoHatchToggle:Set(state.riftAutoHatch) end) end
    if ui.WebhookStatsToggle then pcall(function() ui.WebhookStatsToggle:Set(state.webhookStatsEnabled) end) end
    if ui.WebhookPingToggle then pcall(function() ui.WebhookPingToggle:Set(state.webhookPingEnabled) end) end
    if ui.CompAutoToggle then pcall(function() ui.CompAutoToggle:Set(state.compAutoEnabled) end) end
    if ui.CompRerollToggle then pcall(function() ui.CompRerollToggle:Set(state.compRerollNonBubble) end) end
    if ui.CompHatchToggle then pcall(function() ui.CompHatchToggle:Set(state.compDoHatchQuests) end) end
    if ui.CompBubbleToggle then pcall(function() ui.CompBubbleToggle:Set(state.compDoBubbleQuests) end) end
    if ui.CompPlaytimeToggle then pcall(function() ui.CompPlaytimeToggle:Set(state.compDoPlaytimeQuests) end) end

    -- Update inputs (if they exist)
    if ui.WebhookInput then pcall(function() ui.WebhookInput:Set(state.webhookUrl) end) end
    if ui.PingUserInput then pcall(function() ui.PingUserInput:Set(state.webhookPingUserId) end) end
    if ui.ChanceThresholdInput then pcall(function() ui.ChanceThresholdInput:Set(tostring(state.webhookChanceThreshold)) end) end
    if ui.WebhookStatsIntervalInput then pcall(function() ui.WebhookStatsIntervalInput:Set(tostring(state.webhookStatsInterval)) end) end
    if ui.CompWebhookInput then pcall(function() ui.CompWebhookInput:Set(state.compWebhookUrl) end) end
    if ui.CompWebhookIntervalInput then pcall(function() ui.CompWebhookIntervalInput:Set(tostring(state.compWebhookInterval)) end) end

    -- Update dropdowns (if they exist)
    if ui.FishingIslandDropdown and state.fishingIsland then pcall(function() ui.FishingIslandDropdown:Set(state.fishingIsland) end) end
    if ui.FishingRodDropdown then pcall(function() ui.FishingRodDropdown:Set(state.fishingRod) end) end
    if ui.ObbySelectionDropdown and state.selectedObbies and #state.selectedObbies > 0 then pcall(function() ui.ObbySelectionDropdown:Set(state.selectedObbies) end) end
    if ui.DiscoverWorldDropdown then pcall(function() ui.DiscoverWorldDropdown:Set(state.discoverTargetWorld) end) end
    if ui.UnlockWorldDropdown and state.selectedUnlockWorlds and #state.selectedUnlockWorlds > 0 then pcall(function() ui.UnlockWorldDropdown:Set(state.selectedUnlockWorlds) end) end
    if ui.SeasonFallbackEggDropdown then pcall(function() ui.SeasonFallbackEggDropdown:Set(state.seasonFallbackEgg) end) end
    if ui.HatchTeamDropdown and state.hatchTeam then pcall(function() ui.HatchTeamDropdown:Set(state.hatchTeam) end) end
    if ui.StatsTeamDropdown and state.statsTeam then pcall(function() ui.StatsTeamDropdown:Set(state.statsTeam) end) end
    if ui.EnchantMainDropdown and state.enchantMain then pcall(function() ui.EnchantMainDropdown:Set(state.enchantMain) end) end
    if ui.EnchantSecondDropdown and state.enchantSecond then pcall(function() ui.EnchantSecondDropdown:Set(state.enchantSecond) end) end
    if ui.EasterShopTierDropdown then
        local slot = math.clamp(tonumber(state.easterShopTier) or 1, 1, 6)
        local shopOptions = {
            ["easter-shop"] = {
                "1 - Cracked Egg x3",
                "2 - Shadow Crystal x5",
                "3 - Easter Elixir IV",
                "4 - Ultra Infinity Elixir",
                "5 - Infinity Elixir",
                "6 - Molten Split",
            },
            ["carrot-shop"] = {
                "1 - Carrot Shop Slot 1",
                "2 - Carrot Shop Slot 2",
            },
            ["secretegg-shop"] = {
                "1 - Molten Split (Mythic)",
            },
        }
        local selectedOptions = shopOptions[state.easterShopId] or shopOptions["easter-shop"]
        slot = math.clamp(slot, 1, #selectedOptions)
        pcall(function()
            ui.EasterShopTierDropdown:Refresh(selectedOptions, true)
            ui.EasterShopTierDropdown:Set(selectedOptions[slot])
        end)
    end
    if ui.EasterEggSelectDropdown and state.easterSelectedEgg then pcall(function() ui.EasterEggSelectDropdown:Set(state.easterSelectedEgg) end) end
    if ui.EasterPriorityEggsDropdown and state.easterPriorityEggs and #state.easterPriorityEggs > 0 then pcall(function() ui.EasterPriorityEggsDropdown:Set(state.easterPriorityEggs) end) end
    if ui.EasterShopSelectDropdown and state.easterShopId then
        local map = {
            ["easter-shop"] = "Easter Shop",
            ["carrot-shop"] = "Carrot Shop",
            ["secretegg-shop"] = "Secret Egg Shop",
        }
        pcall(function() ui.EasterShopSelectDropdown:Set(map[state.easterShopId] or "Easter Shop") end)
    end
    if ui.EasterPickupZoneDropdown then pcall(function() ui.EasterPickupZoneDropdown:Set(state.easterPickupZone) end) end
    if ui.EasterHatchAmountDropdown then
        local value = math.clamp(tonumber(state.easterHatchAmount) or 3, 1, 99)
        local label = "3"
        if value <= 1 then
            label = "1"
        elseif value <= 3 then
            label = "3"
        elseif value <= 10 then
            label = "10"
        else
            label = "99"
        end
        pcall(function() ui.EasterHatchAmountDropdown:Set(label) end)
    end

    -- Update rarity dropdown with selected rarities
    if ui.RarityDropdown and state.webhookRarities then
        pcall(function()
            if state.webhookRarities.Celestial == nil then
                state.webhookRarities.Celestial = true
            end
            local selectedRarities = {}
            for rarity, enabled in pairs(state.webhookRarities) do
                if enabled then
                    table.insert(selectedRarities, rarity)
                end
            end
            if #selectedRarities > 0 then
                ui.RarityDropdown:Set(selectedRarities)
            end
        end)
    end

    -- Update sliders (if they exist)
    if ui.EnchantMainSlider then pcall(function() ui.EnchantMainSlider:Set(state.enchantMainTier) end) end
    if ui.EnchantSecondSlider then pcall(function() ui.EnchantSecondSlider:Set(state.enchantSecondTier) end) end
    if ui.MaxEggsSlider then pcall(function() ui.MaxEggsSlider:Set(state.maxEggs) end) end

    --  print("✅ UI elements updated successfully")

    return true, "Config loaded successfully"
end

local function listConfigs()
    local configs = {}
    local success, err = pcall(function()
        -- Delta executor requires folder path for listfiles()
        local allFiles = listfiles(".") or listfiles() or {}
        for i, file in pairs(allFiles) do
            -- Print full path for debugging (first 10 files)
            if i <= 10 or file:lower():find("loriobgsi") then
                --  print("  📄 File " .. i .. ": " .. file)

                -- Extract filename from path (handle both / and \ separators)
                local fileName = file:match("([^/\\]+)$") or file
                --  print("    → Extracted: '" .. fileName .. "'")

                -- Test pattern match
                local matches = fileName:match("^LorioBGSI_Config_(.+)%.json$")
                --  print("    → Pattern match result: " .. tostring(matches))

                -- Check if it matches our config pattern
                if fileName:match("^LorioBGSI_Config_(.+)%.json$") then
                    local configName = fileName:match("^LorioBGSI_Config_(.+)%.json$")
                    table.insert(configs, configName)
                    --  print("    ✅ FOUND CONFIG: " .. configName)
                end
            end
        end

        -- Also try case-insensitive search
        --  print("\n🔍 Trying case-insensitive search for 'lorio'...")
        for _, file in pairs(allFiles) do
            if file:lower():find("lorio") then
                --  print("  🔎 Found file with 'lorio': " .. file)
            end
        end
    end)

    if not success then
        --  print("❌ Error listing config files: " .. tostring(err))
    end

    --  print("\n📋 Total configs found: " .. #configs)
    return configs
end

-- === SMART TEAM DETECTION ===
local function analyzeTeams()
    local teams = {}
    local hatchBestTeam = nil
    local statsBestTeam = nil
    local hatchBestIndex = nil
    local statsBestIndex = nil
    local hatchBestScore = 0
    local statsBestScore = 0

    local success, error = pcall(function()
        local LocalData = require(RS.Client.Framework.Services.LocalData)
        local playerData = LocalData:Get()

        --  print("🔍 [Team Detection] playerData exists:", playerData ~= nil)
        if not playerData then
            --  print("❌ [Team Detection] No playerData")
            return
        end

        --  print("🔍 [Team Detection] playerData.Teams exists:", playerData.Teams ~= nil)
        if not playerData.Teams then
            --  print("❌ [Team Detection] No Teams in playerData")
            return
        end

        --  print("📊 [Team Detection] Teams count:", #playerData.Teams)
        --  print("📊 [Team Detection] Teams type:", type(playerData.Teams))

        -- Iterate through teams array (indexed [1], [2], [3], etc.)
        for teamIndex = 1, #playerData.Teams do
            local teamData = playerData.Teams[teamIndex]
            --  print("🔍 [Team Detection] Team #" .. teamIndex .. " exists:", teamData ~= nil)

            if teamData then
                -- Team name: custom name or default "Team 1", "Team 2", etc.
                local teamName = teamData.Name or ("Team " .. teamIndex)
                --  print("✅ [Team Detection] Found team: " .. teamName)

                local hatchScore = 0
                local statsScore = 0
                local petCount = 0
                local totalCoins = 0
                local totalGems = 0
                local totalBubbles = 0

                -- Check Pets field
                --  print("  - Pets exists:", teamData.Pets ~= nil)
                --  print("  - Pets type:", type(teamData.Pets))

                -- Analyze pets in this team (teamData.Pets is an array of pet IDs)
                if teamData.Pets and type(teamData.Pets) == "table" then
                    --  print("  - Pets count:", #teamData.Pets)

                    for petIdx, petId in ipairs(teamData.Pets) do
                        --  print("    - Pet #" .. petIdx .. " ID:", petId)

                        -- Find the pet in player's pet collection
                        if playerData.Pets then
                            for _, pet in pairs(playerData.Pets) do
                                if pet.Id == petId then
                                    petCount = petCount + 1
                                    --  print("      ✅ Found matching pet in collection")

                                    -- Add base stats to team total
                                    if pet.Stat then
                                        totalCoins = totalCoins + (pet.Stat.Coins or 0)
                                        totalGems = totalGems + (pet.Stat.Gems or 0)
                                        totalBubbles = totalBubbles + (pet.Stat.Bubbles or 0)
                                    end

                                    -- Check enchants (enchants is an array with .Id and .Level)
                                    if pet.Enchants and type(pet.Enchants) == "table" then
                                        --  print("      - Enchants count:", #pet.Enchants)
                                        for _, enchant in ipairs(pet.Enchants) do
                                            if enchant and enchant.Id then
                                                local enchantId = tostring(enchant.Id):lower()
                                                local enchantLevel = enchant.Level or 1
                                                --  print("        - Enchant:", enchantId, "Level:", enchantLevel)

                                                -- HATCH-FOCUSED ENCHANTS (Luck/Egg enchants)
                                                if enchantId:find("high%-roller") then
                                                    hatchScore = hatchScore + 100  -- High Roller: +10% luck
                                                elseif enchantId:find("ultra%-roller") then
                                                    hatchScore = hatchScore + 200  -- Ultra Roller: +20% luck (Special)
                                                elseif enchantId:find("shiny%-seeker") then
                                                    hatchScore = hatchScore + 150  -- Shiny Seeker: +1% shiny (Special)
                                                elseif enchantId:find("secret%-hunter") then
                                                    hatchScore = hatchScore + 200  -- Secret Hunter: +5% secret (Special)
                                                elseif enchantId:find("super%-luck") then
                                                    hatchScore = hatchScore + 250  -- Super Luck: +100% luck
                                                elseif enchantId:find("super%-burst") then
                                                    hatchScore = hatchScore + 150  -- Super Burst: 10x luck every 100 eggs
                                                elseif enchantId:find("super%-speed") then
                                                    hatchScore = hatchScore + 100  -- Super Speed: +75% hatch speed
                                                elseif enchantId:find("super%-infinity") then
                                                    hatchScore = hatchScore + 300  -- Super Infinity: +2.5% infinity chance
                                                elseif enchantId:find("super%-duplication") then
                                                    hatchScore = hatchScore + 400  -- Super Duplication: duplicate secret pets
                                                elseif enchantId:find("infinity") and not enchantId:find("super") then
                                                    hatchScore = hatchScore + 50   -- Infinity: reduces infinity egg cost
                                                end

                                                -- STATS-FOCUSED ENCHANTS (Coin/Gem/Bubble generation)
                                                if enchantId:find("looter") then
                                                    -- Looter: +5-50% coin multiplier (levels 1-5)
                                                    local bonus = ({5, 10, 25, 35, 50})[enchantLevel] or 50
                                                    statsScore = statsScore + (bonus * 2)  -- x2 weight
                                                elseif enchantId:find("bubbler") then
                                                    -- Bubbler: +5-50% bubble (levels 1-5)
                                                    local bonus = ({5, 10, 25, 35, 50})[enchantLevel] or 50
                                                    statsScore = statsScore + (bonus * 2)  -- x2 weight
                                                elseif enchantId:find("gleaming") then
                                                    -- Gleaming: 5-35% chance to drop gems (levels 1-3)
                                                    local bonus = ({5, 15, 35})[enchantLevel] or 35
                                                    statsScore = statsScore + (bonus * 3)  -- x3 weight (gems valuable)
                                                elseif enchantId:find("team%-up") then
                                                    -- Team Up: +5-25% stats (levels 1-5)
                                                    local bonus = ({5, 10, 15, 20, 25})[enchantLevel] or 25
                                                    statsScore = statsScore + (bonus * 2)
                                                elseif enchantId:find("determination") then
                                                    statsScore = statsScore + 150  -- Determination: +50% stats (Special)
                                                elseif enchantId:find("super%-bubble") then
                                                    statsScore = statsScore + 300  -- Super Bubble: +150% bubble stats
                                                end
                                            end
                                        end
                                    end

                                    break
                                end
                            end
                        end
                    end
                end

                -- Add base stats to score (scaled down to not overwhelm enchant scores)
                statsScore = statsScore + (totalCoins / 10000) + (totalGems / 1000) + (totalBubbles / 10000)

                --  print("  📊 Team stats - Pets:", petCount, "Hatch Score:", hatchScore, "Stats Score:", statsScore)
                --  print("  💰 Base Stats - Coins:", totalCoins, "Gems:", totalGems, "Bubbles:", totalBubbles)

                -- Only add team if it has pets
                if petCount > 0 then
                    teams[teamName] = {
                        index = teamIndex,
                        hatchScore = hatchScore,
                        statsScore = statsScore,
                        pets = petCount,
                        coins = totalCoins,
                        gems = totalGems,
                        bubbles = totalBubbles
                    }

                    -- Track best teams
                    if hatchScore > hatchBestScore then
                        hatchBestScore = hatchScore
                        hatchBestTeam = teamName
                        hatchBestIndex = teamIndex
                    end

                    if statsScore > statsBestScore then
                        statsBestScore = statsScore
                        statsBestTeam = teamName
                        statsBestIndex = teamIndex
                    end
                end
            end
        end
    end)

    if not success then
        --  print("❌ [Team Detection] Error:", error)
    end

    -- Count teams properly (it's a dictionary, not an array)
    local teamCount = 0
    for _ in pairs(teams) do
        teamCount = teamCount + 1
    end

    --  print("✅ [Team Detection] Final teams count:", teamCount)
    --  print("🏆 [Team Detection] Best Hatch Team:", hatchBestTeam or "None", "(Index:", hatchBestIndex or "?", ") Score:", hatchBestScore)
    --  print("💰 [Team Detection] Best Stats Team:", statsBestTeam or "None", "(Index:", statsBestIndex or "?", ") Score:", statsBestScore)

    return teams, hatchBestTeam, statsBestTeam, hatchBestIndex, statsBestIndex
end

local function updateTeamDropdowns()
    local teams, bestHatch, bestStats, bestHatchIndex, bestStatsIndex = analyzeTeams()
    local teamNames = {"—"}

    for name, _ in pairs(teams) do
        table.insert(teamNames, name)
    end

    -- Update state
    state.gameTeamList = teamNames

    -- Auto-select best teams if none selected
    if bestHatch and not state.hatchTeam then
        state.hatchTeam = bestHatch
        state.hatchTeamIndex = bestHatchIndex
    end

    if bestStats and not state.statsTeam then
        state.statsTeam = bestStats
        state.statsTeamIndex = bestStatsIndex
    end

    return teamNames, bestHatch, bestStats
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
-- --  print("✅ Found " .. foundEggs .. " eggs in Chunker folders")
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

local function tpToPosition(position)
    pcall(function()
        if not player.Character then return end
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 8, 0))
    end)
end

local function findEggModelByName(eggName)
    if type(eggName) ~= "string" or eggName == "" then
        return nil
    end

    -- Fast path: currently scanned eggs
    for _, egg in pairs(state.currentEggs or {}) do
        if egg and egg.name == eggName and egg.instance and egg.instance:IsDescendantOf(Workspace) then
            return egg.instance
        end
    end

    -- Fallback: cached egg database model
    local eggInfo = state.eggDatabase and state.eggDatabase[eggName]
    if eggInfo and eggInfo.model and eggInfo.model:IsDescendantOf(Workspace) then
        return eggInfo.model
    end

    -- If we know historical position, request stream nearby and retry scan
    if eggInfo and eggInfo.position and player.RequestStreamAroundAsync then
        pcall(function()
            player:RequestStreamAroundAsync(eggInfo.position)
        end)
        task.wait(0.15)
    end

    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered then
        for _, folder in pairs(rendered:GetChildren()) do
            if folder.Name == "Chunker" then
                for _, model in pairs(folder:GetChildren()) do
                    if model:IsA("Model") and model.Name == eggName and model:FindFirstChild("Plate") then
                        return model
                    end
                end
            end
        end
    end

    -- Last-resort scan through world descendants for matching egg model
    local worlds = Workspace:FindFirstChild("Worlds")
    if worlds then
        for _, descendant in pairs(worlds:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == eggName and descendant:FindFirstChild("Plate") then
                return descendant
            end
        end
    end

    return nil
end

local function isUuidName(value)
    return type(value) == "string"
        and value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

local function getRenderedChunkerPickupTargets()
    local targets = {}
    local rendered = Workspace:FindFirstChild("Rendered")
    if not rendered then
        return targets
    end

    local seenIds = {}

    -- Primary source used by game client pickup renderer.
    local renderedPickups = rendered:FindFirstChild("Pickups")
    if renderedPickups then
        for _, child in pairs(renderedPickups:GetChildren()) do
            if child:IsA("Model") and child:IsDescendantOf(Workspace) then
                local id = tostring(child.Name or "")
                if id ~= "" and not seenIds[id] then
                    seenIds[id] = true
                    table.insert(targets, {
                        id = id,
                        model = child,
                    })
                end
            end
        end
    end

    -- There can be multiple folders named Chunker under Rendered.
    for _, folder in pairs(rendered:GetChildren()) do
        if folder.Name == "Chunker" then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") and child:IsDescendantOf(Workspace) and isUuidName(child.Name) then
                    if not seenIds[child.Name] then
                        seenIds[child.Name] = true
                        table.insert(targets, {
                            id = child.Name,
                            model = child,
                        })
                    end
                end
            end
        end
    end

    return targets
end

local function getAnyObjectPosition(obj)
    if not obj or not obj:IsDescendantOf(Workspace) then
        return nil
    end

    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.Position
        end
        local ok, pivot = pcall(function()
            return obj:GetPivot()
        end)
        if ok and pivot then
            return pivot.Position
        end
    end

    return nil
end

local function getSafeGroundedPosition(basePos)
    if not basePos then
        return nil
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = false
    local ignore = {}
    if player and player.Character then
        table.insert(ignore, player.Character)
    end
    rayParams.FilterDescendantsInstances = ignore

    local origin = basePos + Vector3.new(0, 140, 0)
    local result = Workspace:Raycast(origin, Vector3.new(0, -500, 0), rayParams)
    if result then
        return result.Position + Vector3.new(0, 5, 0)
    end

    return basePos + Vector3.new(0, 8, 0)
end

local function findPreferredIslandAnchor(container)
    if not container or not container:IsDescendantOf(Workspace) then
        return nil
    end

    local centerPos = getAnyObjectPosition(container)
    local bestPart, bestScore
    bestScore = -math.huge
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            local score = 0
            if name:find("fountain", 1, true) then score = score + 900 end
            if name:find("center", 1, true) or name:find("middle", 1, true) then score = score + 700 end
            if name:find("spawn", 1, true) or name:find("hub", 1, true) then score = score + 550 end
            if name:find("decor", 1, true) or name:find("decoration", 1, true) or name:find("statue", 1, true) then score = score + 450 end

            if obj.Anchored then score = score + 80 end
            if obj.CanCollide then score = score + 80 end
            if obj.Transparency < 0.95 then score = score + 60 end
            score = score + math.clamp(obj.Size.X + obj.Size.Y + obj.Size.Z, 0, 70)

            if centerPos then
                local dist = (obj.Position - centerPos).Magnitude
                score = score - math.clamp(dist * 0.35, 0, 220)
            end

            if score > bestScore then
                bestScore = score
                bestPart = obj
            end
        end
    end

    return bestPart
end

local function getEasterPickupZonePosition(zoneName)
    local worlds = Workspace:FindFirstChild("Worlds")
    local easterWorld = worlds and worlds:FindFirstChild("Easter Paradise")
    local spawnObj = easterWorld and easterWorld:FindFirstChild("Spawn", true)
    local defaultPos = getAnyObjectPosition(spawnObj)
    local defaultZoneModel = (spawnObj and spawnObj:IsA("Model")) and spawnObj or nil
    if zoneName == "Spawn Island" or not zoneName then
        return defaultPos, defaultZoneModel
    end

    local islands = easterWorld and easterWorld:FindFirstChild("Islands")
    if not islands then
        return defaultPos, defaultZoneModel
    end

    local islandContainer = islands:FindFirstChild(zoneName)
    if not islandContainer and type(zoneName) == "string" and zoneName ~= "" then
        local function normalizeName(name)
            local s = string.lower(tostring(name or ""))
            s = s:gsub("[%s%p]", "")
            s = s:gsub("island", "")
            return s
        end

        local wanted = normalizeName(zoneName)
        for _, child in ipairs(islands:GetChildren()) do
            local childNorm = normalizeName(child.Name)
            if childNorm == wanted or childNorm:find(wanted, 1, true) or wanted:find(childNorm, 1, true) then
                islandContainer = child
                break
            end
        end
    end

    if not islandContainer then
        return defaultPos, defaultZoneModel
    end

    local islandModel = islandContainer:FindFirstChild("Island") or islandContainer
    local anchorPart = findPreferredIslandAnchor(islandContainer) or findPreferredIslandAnchor(islandModel)
    local pos = anchorPart and anchorPart.Position or getAnyObjectPosition(islandModel)
    local safePos = getSafeGroundedPosition(pos or defaultPos)
    return safePos or defaultPos, islandModel
end

local function getEasterPickupTeleportPath(zoneName)
    local selected = zoneName
    if selected == "Second Island (Easter Island)" or selected == "Second Island" then
        selected = "Easter Island"
    end

    local paths = {
        ["Spawn Island"] = "Workspace.Worlds.Easter Paradise.Spawn",
        ["Carrot Island"] = "Workspace.Worlds.Easter Paradise.Islands.Carrot Island.Island.Portal.Spawn",
        ["Easter Island"] = "Workspace.Worlds.Easter Paradise.Islands.Easter Island.Island.Portal.Spawn",
        ["Dark Egg Island"] = "Workspace.Worlds.Easter Paradise.Islands.Dark Egg Island.Island.Portal.Spawn",
    }

    return paths[selected] or paths["Spawn Island"]
end

local function getRenderedChunkerPickupTargetsInZone(zonePosition, radius, zoneModel)
    local allTargets = getRenderedChunkerPickupTargets()
    if not zonePosition then
        return allTargets
    end

    local filtered = {}
    local hasBounds = false
    local boundsCf, boundsSize
    if zoneModel and zoneModel:IsDescendantOf(Workspace) then
        local ok, cf, size = pcall(function()
            return zoneModel:GetBoundingBox()
        end)
        if ok and cf and size then
            hasBounds = true
            boundsCf = cf
            boundsSize = size
        end
    end

    local maxDistance = tonumber(radius) or 700
    for _, target in ipairs(allTargets) do
        local pos = target.model and getAnyObjectPosition(target.model)
        if pos then
            local inZone = false
            local inRadius = (pos - zonePosition).Magnitude <= maxDistance
            if hasBounds then
                local localPos = boundsCf:PointToObjectSpace(pos)
                local halfX = (boundsSize.X * 0.5) + 50
                local halfY = (boundsSize.Y * 0.5) + 40
                local halfZ = (boundsSize.Z * 0.5) + 50
                inZone = math.abs(localPos.X) <= halfX
                    and math.abs(localPos.Y) <= halfY
                    and math.abs(localPos.Z) <= halfZ
                if not inZone and inRadius then
                    inZone = true
                end
            else
                inZone = inRadius
            end

            if inZone then
                table.insert(filtered, target)
            end
        end
    end
    return filtered
end

local function getModelPosition(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then
        return nil
    end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position
    end

    local ok, pivot = pcall(function()
        return model:GetPivot()
    end)
    if ok and pivot then
        return pivot.Position
    end

    return nil
end

local function movePlayerNearPickup(pickupModel, hrp)
    if not pickupModel or not hrp then
        return
    end

    local pickupPos = getModelPosition(pickupModel)
    if not pickupPos then
        return
    end

    local character = hrp.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local toPickup = pickupPos - hrp.Position
    local horizontal = Vector3.new(toPickup.X, 0, toPickup.Z)
    local direction = horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.new(0, 0, 1)
    local nearPos = pickupPos - (direction * 3.2)

    -- Land beside the pickup, then move into it immediately for reliable collection.
    pcall(function()
        hrp.CFrame = CFrame.new(nearPos + Vector3.new(0, 3, 0), pickupPos + Vector3.new(0, 3, 0))
    end)

    if humanoid then
        pcall(function()
            humanoid:MoveTo(pickupPos + Vector3.new(0, 0.5, 0))
        end)
    end

    task.wait(0.015)
end

local function shouldAttemptPickupId(id, cooldown)
    if type(id) ~= "string" or id == "" then
        return false
    end

    local now = tick()
    local last = state.pickupAttemptTimes[id]
    if last and (now - last) < cooldown then
        return false
    end

    state.pickupAttemptTimes[id] = now
    return true
end

local function shouldAttemptPickupTarget(target, cooldown)
    if not target or type(target.id) ~= "string" or target.id == "" then
        return false
    end

    local key = target.id
    if target.model then
        local ok, debugId = pcall(function()
            return target.model:GetDebugId(0)
        end)
        if ok and type(debugId) == "string" and debugId ~= "" then
            key = target.id .. "|" .. debugId
        end
    end

    local now = tick()
    local last = state.pickupAttemptTimes[key]
    if last and (now - last) < cooldown then
        return false
    end

    state.pickupAttemptTimes[key] = now

    -- Keep pickup cooldown table small in long sessions.
    if math.random(1, 40) == 1 then
        for k, t in pairs(state.pickupAttemptTimes) do
            if (now - (t or 0)) > 12 then
                state.pickupAttemptTimes[k] = nil
            end
        end
    end

    return true
end

setPerformanceMode = function(enabled)
    state.performanceMode = enabled

    if enabled then
        pcall(function()
            state.performanceLightingBackup = {
                GlobalShadows = Lighting.GlobalShadows,
                Brightness = Lighting.Brightness,
                EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
                EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
            }
            Lighting.GlobalShadows = false
            Lighting.Brightness = 1
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
        end)

        -- Disable post-processing effects
        state.performancePostEffects = {}
        pcall(function()
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("PostEffect") and obj.Enabled then
                    table.insert(state.performancePostEffects, obj)
                    obj.Enabled = false
                end
            end
        end)

        -- Disable expensive VFX emitters across workspace
        state.performanceFxObjects = {}
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")) and obj.Enabled then
                    table.insert(state.performanceFxObjects, obj)
                    obj.Enabled = false
                end
            end
        end)

        if setfpscap then
            pcall(function() setfpscap(5) end)
        end
    else
        -- Restore lighting
        if state.performanceLightingBackup then
            pcall(function()
                Lighting.GlobalShadows = state.performanceLightingBackup.GlobalShadows
                Lighting.Brightness = state.performanceLightingBackup.Brightness
                Lighting.EnvironmentDiffuseScale = state.performanceLightingBackup.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = state.performanceLightingBackup.EnvironmentSpecularScale
            end)
        end

        -- Restore post effects that were enabled before
        pcall(function()
            for _, obj in ipairs(state.performancePostEffects or {}) do
                if obj and obj.Parent then obj.Enabled = true end
            end
        end)

        -- Restore VFX that were enabled before
        pcall(function()
            for _, obj in ipairs(state.performanceFxObjects or {}) do
                if obj and obj.Parent then obj.Enabled = true end
            end
        end)

        state.performancePostEffects = {}
        state.performanceFxObjects = {}

        if setfpscap then
            pcall(function() setfpscap(30) end)
        end
    end
end

-- === EASTER EVENT HELPERS ===
local EasterEggDropdown

local function scanEasterEventEggs()
    local eggs = {}
    local allowedNames = {
        ["Painted Egg"] = true,
        ["Basket Egg"] = true,
        ["Easter Bunny Egg"] = true,
        ["4x Luck Easter Bunny Egg"] = true,
    }

    local function isTargetEgg(name)
        if type(name) ~= "string" then
            return false
        end
        if allowedNames[name] then
            return true
        end
        local lower = string.lower(name)
        return lower:find("easter", 1, true) ~= nil and lower:find("egg", 1, true) ~= nil
    end

    local rendered = Workspace:FindFirstChild("Rendered")
    if not rendered then
        state.currentEventEggs = eggs
        return eggs
    end

    for _, folder in pairs(rendered:GetChildren()) do
        if folder.Name == "Chunker" then
            for _, model in pairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    local name = model.Name
                    if isTargetEgg(name) then
                        table.insert(eggs, { name = name, instance = model })
                    end
                end
            end
        end
    end

    local generic = rendered:FindFirstChild("Generic")
    if generic then
        for _, model in pairs(generic:GetChildren()) do
            if model:IsA("Model") then
                local name = model.Name
                if isTargetEgg(name) then
                    local alreadyFound = false
                    for _, e in pairs(eggs) do
                        if e.name == name then
                            alreadyFound = true
                            break
                        end
                    end
                    if not alreadyFound then
                        table.insert(eggs, { name = name, instance = model })
                    end
                end
            end
        end
    end

    state.currentEventEggs = eggs

    if EasterEggDropdown then
        local names = {}
        local seen = {}
        for _, e in pairs(eggs) do
            if not seen[e.name] then
                seen[e.name] = true
                table.insert(names, e.name)
            end
        end
        if #names == 0 then names = {"None found"} end
        pcall(function()
            EasterEggDropdown:Refresh(names, false)
        end)
    end

    return eggs
end

local function sinkEasterReturnTeleporter()
    if state.easterReturnSunk then return end
    pcall(function()
        local world = Workspace:FindFirstChild("Worlds") and Workspace.Worlds:FindFirstChild("Easter Paradise")
        local returnModel = world and world:FindFirstChild("Return", true)
        if not returnModel then return end
        state.easterReturnOrigCf = returnModel:GetPivot()
        returnModel:PivotTo(state.easterReturnOrigCf - Vector3.new(0, 500, 0))
        state.easterReturnSunk = true
    end)
end

local function restoreEasterReturnTeleporter()
    if not state.easterReturnSunk then return end
    pcall(function()
        local world = Workspace:FindFirstChild("Worlds") and Workspace.Worlds:FindFirstChild("Easter Paradise")
        local returnModel = world and world:FindFirstChild("Return", true)
        if returnModel and state.easterReturnOrigCf then
            returnModel:PivotTo(state.easterReturnOrigCf)
        end
        state.easterReturnSunk = false
    end)
end

local function getEasterSpawnObject()
    local worlds = Workspace:FindFirstChild("Worlds")
    local easterWorld = worlds and worlds:FindFirstChild("Easter Paradise")
    if not easterWorld then
        return nil
    end
    return easterWorld:FindFirstChild("Spawn", true)
end

local function getEasterSpawnPosition()
    local spawnObj = getEasterSpawnObject()
    if not spawnObj then
        return nil
    end

    if spawnObj:IsA("BasePart") then
        return spawnObj.Position
    end

    if spawnObj:IsA("Model") then
        return getModelPosition(spawnObj)
    end

    return nil
end

local function isInEasterEventArea(hrp)
    if not hrp then
        return false
    end

    local worlds = Workspace:FindFirstChild("Worlds")
    local easterWorld = worlds and worlds:FindFirstChild("Easter Paradise")
    if easterWorld and easterWorld:IsDescendantOf(Workspace) then
        local ok, cf, size = pcall(function()
            return easterWorld:GetBoundingBox()
        end)
        if ok and cf and size then
            local p = cf:PointToObjectSpace(hrp.Position)
            local halfX = (size.X * 0.5) + 120
            local halfY = (size.Y * 0.5) + 120
            local halfZ = (size.Z * 0.5) + 120
            return math.abs(p.X) <= halfX and math.abs(p.Y) <= halfY and math.abs(p.Z) <= halfZ
        end
    end

    local spawnPos = getEasterSpawnPosition()
    if not spawnPos then
        return false
    end

    return (hrp.Position - spawnPos).Magnitude <= 2500
end

local function isInSelectedEasterPickupZone(hrp)
    if not hrp then
        return false
    end

    local zonePos, zoneModel = getEasterPickupZonePosition(state.easterPickupZone)
    if not zonePos then
        return false
    end

    if zoneModel and zoneModel:IsDescendantOf(Workspace) then
        local ok, cf, size = pcall(function()
            return zoneModel:GetBoundingBox()
        end)
        if ok and cf and size then
            local p = cf:PointToObjectSpace(hrp.Position)
            local halfX = (size.X * 0.5) + 30
            local halfY = (size.Y * 0.5) + 40
            local halfZ = (size.Z * 0.5) + 30
            if math.abs(p.X) <= halfX and math.abs(p.Y) <= halfY and math.abs(p.Z) <= halfZ then
                return true
            end
        end
    end

    return (hrp.Position - zonePos).Magnitude <= 1200
end

local function teleportToEasterEvent(remote, usePickupWarmup)
    local now = tick()
    if now - (state.lastEasterWorldTeleport or 0) < 5 then
        return false
    end

    local spawnObj = getEasterSpawnObject()
    local teleportPath = spawnObj and spawnObj:GetFullName() or "Workspace.Worlds.Easter Paradise.Spawn"

    pcall(function()
        remote:FireServer("WorldTeleport", "Easter Paradise")
    end)

    pcall(function()
        remote:FireServer("Teleport", teleportPath)
    end)

    state.lastEasterWorldTeleport = now
    state.easterLastEggPosition = nil
    state.easterLastEggTarget = nil

    if usePickupWarmup then
        state.easterPickupWarmupUntil = now + 2
    end

    return true
end

local EASTER_HUNT_EGGS = {
    "Pixel Egg",
    "Lights Out Egg",
    "Unreleased Egg",
    "Bunny Egg",
    "Cloudy Egg",
    "Jester Egg",
    "Mystery Egg",
    "FRIEND Egg",
    "Nerd Egg",
}

local EASTER_HUNT_REMOTE_BY_EGG = {
    ["Pixel Egg"] = "EasterPixelEgg",
    ["Lights Out Egg"] = "EasterLightsOutEgg",
    ["Unreleased Egg"] = "EasterUnreleasedEgg",
    ["Bunny Egg"] = "EasterBunnyEgg",
    ["Cloudy Egg"] = "EasterCloudyEgg",
    ["Mystery Egg"] = "EasterMysteryEgg",
    -- Jester/Nerd/FRIEND require puzzle or social inputs and are handled separately.
}

local function getEasterHuntProgress(playerData)
    local found = (((playerData or {}).Easter2026 or {}).Found) or {}
    local missing = {}
    for _, eggName in ipairs(EASTER_HUNT_EGGS) do
        if found[eggName] == nil then
            table.insert(missing, eggName)
        end
    end

    local claimed = (((playerData or {}).Easter2026 or {}).Claimed) == true
    return missing, claimed
end

local function updateEasterProgressText(playerData)
    local missing, claimed = getEasterHuntProgress(playerData)
    local foundCount = #EASTER_HUNT_EGGS - #missing
    local nextEgg = missing[1] or "None"
    state.easterHuntStatusText = string.format("Hunt: %d/9 found | Next: %s%s", foundCount, tostring(nextEgg), claimed and " | Rewards claimed" or "")

    local quests = (playerData and playerData.Quests) or {}
    local milestoneText = "Milestones: no easter quest detected"
    for _, quest in pairs(quests) do
        local idText = tostring(quest and (quest.Id or quest.Name or quest.Type) or "")
        local idLower = string.lower(idText)
        if idLower:find("easter", 1, true) then
            local progress = tonumber(quest.Progress) or 0
            local amount = tonumber(quest.Amount) or 0
            milestoneText = string.format("Milestones: %s (%s/%s)", idText ~= "" and idText or "Easter", tostring(progress), tostring(amount))
            break
        end
    end
    state.easterMilestoneStatusText = milestoneText
end

local function tryEasterHuntAction(remote, playerData)
    if not state.easterAutoHunt then
        return
    end

    local now = tick()
    if now - (state.lastEasterHuntAction or 0) < 2 then
        return
    end

    local missing, claimed = getEasterHuntProgress(playerData)
    if #missing == 0 then
        if state.easterAutoClaimRewards and not claimed then
            pcall(function()
                remote:FireServer("EasterClaimRewards")
            end)
        end
        state.lastEasterHuntAction = now
        return
    end

    for _, eggName in ipairs(missing) do
        local command = EASTER_HUNT_REMOTE_BY_EGG[eggName]
        if command then
            pcall(function()
                remote:FireServer(command)
            end)
            state.lastEasterHuntAction = now
            return
        end
    end

    state.lastEasterHuntAction = now
end

local function tryEasterJesterAction(remote, playerData)
    if not state.easterAutoJester then
        return
    end

    local now = tick()
    if now - (state.lastEasterJesterAttempt or 0) < 10 then
        return
    end

    local found = (((playerData or {}).Easter2026 or {}).Found) or {}
    if found["Jester Egg"] == nil then
        pcall(function()
            remote:FireServer("Teleport", "Workspace.Worlds.Easter Paradise.Card Castle.Decoration.JesterEnterSpawn")
        end)
        pcall(function()
            remote:FireServer("EasterJesterEgg")
        end)
    end

    state.lastEasterJesterAttempt = now
end

local function tryEasterRewardsAndMastery(remote)
    local now = tick()

    if state.easterAutoClaimRewards and now - (state.lastEasterRewardClaim or 0) >= 6 then
        pcall(function()
            remote:FireServer("EasterClaimRewards")
        end)
        pcall(function()
            remote:FireServer("ClaimWorldReward", "Easter Paradise")
        end)
        state.lastEasterRewardClaim = now
    end

    if state.easterAutoMastery and now - (state.lastEasterMasteryUpgrade or 0) >= 1.5 then
        for _, masteryName in ipairs({"Easter Paradise", "Carrot Island", "Easter Island", "Dark Egg Island"}) do
            pcall(function()
                remote:FireServer("UpgradeMastery", masteryName)
            end)
        end
        state.lastEasterMasteryUpgrade = now
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║                  TAB DECLARATIONS                          ║
-- ╚══════════════════════════════════════════════════════════════╝
local MainTab     = Window:CreateTab("🏠 Main",        4483362458)  -- 1
local FarmTab     = Window:CreateTab("🔧 Farm",        4483362458)  -- 2
local EventTab    = Window:CreateTab("🐰 Event",       4483362458)  -- 3
local EggsTab     = Window:CreateTab("🥚 Eggs",        4483362458)  -- 4
local EnchantTab  = Window:CreateTab("✨ Enchant",     4483362458)  -- 5
local FishingTab  = Window:CreateTab("🎣 Fishing",     4483362458)  -- 6
local ObbysTab    = Window:CreateTab("🏁 Obbys",       4483362458)  -- 7
local RiftsTab    = Window:CreateTab("🌌 Rifts",        4483362458)  -- 8
local WorldTab    = Window:CreateTab("🌍 World",        4483362458)  -- 9
local SeasonTab   = Window:CreateTab("📅 Season",      4483362458)  -- 10
local PowerupsTab = Window:CreateTab("⚡ Powerups",    4483362458)  -- 11
local CompTab     = Window:CreateTab("🏆 Competitive", 4483362458)  -- 12
local ConfigTab   = Window:CreateTab("⚙️ Config",      4483362458)  -- 13
local WebTab      = Window:CreateTab("📊 Webhook",     4483362458)  -- 14
local DataTab     = Window:CreateTab("📋 Data",        4483362458)  -- 15

-- === MAIN TAB ===

MainTab:CreateSection("📊 Live Stats")

state.labels.runtime = MainTab:CreateLabel("Runtime: 00:00:00")
state.labels.bubbles = MainTab:CreateLabel("Bubbles: 0")
state.labels.hatches = MainTab:CreateLabel("Hatches: 0")

-- === FARM TAB ===

FarmTab:CreateSection("🤖 Auto Farm")

local AutoBlowToggle = FarmTab:CreateToggle({
   Name = "🧼 Auto Blow Bubbles",
   CurrentValue = false,
   Flag = "AutoBlow",
   Callback = function(Value)
      state.autoBlow = Value

      -- Auto-equip stats team when enabled
      if Value and state.statsTeamIndex then
         pcall(function()
            local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
            Remote:FireServer("EquipTeam", state.statsTeamIndex)
         end)
      end

      -- Rayfield:Notify({
      -- Title = "Auto Blow",
      -- Content = Value and "Enabled" or "Disabled",
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
   end,
})
state.uiElements.AutoBlowToggle = AutoBlowToggle

local AutoPickupToggle = FarmTab:CreateToggle({
   Name = "💰 Auto Collect Pickups",
   CurrentValue = false,
   Flag = "AutoPickup",
   Callback = function(Value)
      state.autoPickup = Value
      -- Rayfield:Notify({
      -- Title = "Auto Pickup",
      -- Content = Value and "Enabled - Collecting coins/gems" or "Disabled",
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
   end,
})
state.uiElements.AutoPickupToggle = AutoPickupToggle

local AutoChestToggle = FarmTab:CreateToggle({
   Name = "📦 Auto Open Chests",
   CurrentValue = false,
   Flag = "AutoChest",
   Callback = function(Value)
      state.autoChest = Value
      -- Rayfield:Notify({
      -- Title = "Auto Chest",
      -- Content = Value and "Enabled - Opening all chests" or "Disabled",
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
   end,
})
state.uiElements.AutoChestToggle = AutoChestToggle

local AutoSellBubblesToggle = FarmTab:CreateToggle({
   Name = "💸 Auto Sell Bubbles",
   CurrentValue = false,
   Flag = "AutoSellBubbles",
   Callback = function(Value)
      state.autoSellBubbles = Value
      -- Rayfield:Notify({
      -- Title = "Auto Sell",
      -- Content = Value and "Enabled - Selling bubbles for coins" or "Disabled",
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
   end,
})
state.uiElements.AutoSellBubblesToggle = AutoSellBubblesToggle

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

FarmTab:CreateSection("🎁 Auto Claim")

local AutoClaimToggle = FarmTab:CreateToggle({
   Name = "🎁 Auto Claim Playtime Gifts",
   CurrentValue = false,
   Flag = "AutoClaim",
   Callback = function(Value)
      state.autoClaimPlaytime = Value
      -- Rayfield:Notify({
      -- Title = "Auto Claim",
      -- Content = Value and "Enabled - Claiming gifts every minute" or "Disabled",
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
   end,
})
state.uiElements.AutoClaimPlaytimeToggle = AutoClaimToggle

FarmTab:CreateSection("🛡️ Anti-AFK")

local AntiAFKToggle = FarmTab:CreateToggle({
    Name = "🛡️ Prevent AFK Kick",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        state.antiAFK = Value
    end,
})
state.uiElements.AntiAFKToggle = AntiAFKToggle

MainTab:CreateSection("🚀 Performance")

state.uiElements.PerformanceModeToggle = MainTab:CreateToggle({
    Name = "🚀 Ultra Performance Mode (5 FPS cap)",
    CurrentValue = false,
    Flag = "PerformanceMode",
    Callback = function(Value)
        setPerformanceMode(Value)
    end,
})

-- === EVENT TAB ===
EventTab:CreateSection("🐰 Easter Event")

state.uiElements.EasterAutoPickupToggle = EventTab:CreateToggle({
    Name = "🐰 Auto Collect Event Pickups",
    CurrentValue = false,
    Flag = "EasterAutoPickup",
    Callback = function(Value)
        state.easterAutoPickup = Value
        if Value then
            sinkEasterReturnTeleporter()
            state.lastEasterWorldTeleport = 0
            state.easterPickupWarmupUntil = tick() + 2
        else
            restoreEasterReturnTeleporter()
            state.easterPickupWarmupUntil = 0
        end
    end,
})

state.uiElements.EasterPickupZoneDropdown = EventTab:CreateDropdown({
    Name = "Pickup Zone",
    Options = {"Spawn Island", "Second Island (Easter Island)", "Easter Island", "Dark Egg Island"},
    CurrentOption = {"Spawn Island"},
    MultipleOptions = false,
    Flag = "EasterPickupZone",
    Callback = function(Option)
        local selected = Option and Option[1]
        if selected and selected ~= "" then
            if selected == "Second Island (Easter Island)" or selected == "Second Island" then
                selected = "Easter Island"
            end
            state.easterPickupZone = selected
            state.lastEasterWorldTeleport = 0
        end
    end,
})

EventTab:CreateSection("🛒 Event Shop")

local EASTER_SHOP_SLOT_OPTIONS = {
    ["easter-shop"] = {
        "1 - Cracked Egg x3",
        "2 - Shadow Crystal x5",
        "3 - Easter Elixir IV",
        "4 - Ultra Infinity Elixir",
        "5 - Infinity Elixir",
        "6 - Molten Split",
    },
    ["carrot-shop"] = {
        "1 - Carrot Shop Slot 1",
        "2 - Carrot Shop Slot 2",
    },
    ["secretegg-shop"] = {
        "1 - Molten Split (Mythic)",
    },
}

local function getShopSlotOptions(shopId)
    return EASTER_SHOP_SLOT_OPTIONS[shopId] or EASTER_SHOP_SLOT_OPTIONS["easter-shop"]
end

local function setEasterShopDefaults(shopId)
    local options = getShopSlotOptions(shopId)
    state.easterShopTier = 1
    if state.uiElements.EasterShopTierDropdown then
        pcall(function()
            state.uiElements.EasterShopTierDropdown:Refresh(options, true)
            state.uiElements.EasterShopTierDropdown:Set(options[1])
        end)
    end
end

state.uiElements.EasterShopTierDropdown = EventTab:CreateDropdown({
    Name = "Item To Buy",
    Options = {
        "1 - Cracked Egg x3",
        "2 - Shadow Crystal x5",
        "3 - Easter Elixir IV",
        "4 - Ultra Infinity Elixir",
        "5 - Infinity Elixir",
        "6 - Molten Split",
    },
    CurrentOption = {"1 - Cracked Egg x3"},
    MultipleOptions = false,
    Flag = "EasterShopTier",
    Callback = function(Option)
        if Option and Option[1] then
            local slot = tonumber(Option[1]:match("^(%d+)"))
            if slot then state.easterShopTier = slot end
        end
    end,
})

state.uiElements.EasterAutoShopToggle = EventTab:CreateToggle({
    Name = "🛒 Auto Buy Selected Shop Slot",
    CurrentValue = false,
    Flag = "EasterAutoShop",
    Callback = function(Value)
        state.easterAutoShop = Value
        state.lastEasterShopBuy = 0
    end,
})

state.uiElements.EasterSecretShopToggle = EventTab:CreateToggle({
    Name = "🔮 Auto Buy Secret Shop Item",
    CurrentValue = false,
    Flag = "EasterSecretShop",
    Callback = function(Value)
        state.easterSecretShop = Value
        state.lastEasterSecretShopBuy = 0
    end,
})

state.uiElements.EasterShopSelectDropdown = EventTab:CreateDropdown({
    Name = "Shop Pool",
    Options = {"Easter Shop", "Carrot Shop", "Secret Egg Shop"},
    CurrentOption = {"Easter Shop"},
    MultipleOptions = false,
    Flag = "EasterShopSelect",
    Callback = function(Option)
        local selected = Option and Option[1] or "Easter Shop"
        if selected == "Carrot Shop" then
            state.easterShopId = "carrot-shop"
        elseif selected == "Secret Egg Shop" then
            state.easterShopId = "secretegg-shop"
        else
            state.easterShopId = "easter-shop"
        end
        setEasterShopDefaults(state.easterShopId)
    end,
})

state.uiElements.EasterAdvancedShopToggle = EventTab:CreateToggle({
    Name = "🛍️ Advanced Shop Mode (uses selected pool)",
    CurrentValue = false,
    Flag = "EasterAdvancedShop",
    Callback = function(Value)
        state.easterAdvancedShop = Value
        state.lastEasterAdvancedShopBuy = 0
    end,
})

EventTab:CreateSection("🥚 Event Eggs")

EasterEggDropdown = EventTab:CreateDropdown({
    Name = "🥚 Select Egg to Auto Hatch",
    Options = {"Scanning..."},
    CurrentOption = {"Scanning..."},
    MultipleOptions = false,
    Flag = "EasterEggSelect",
    Callback = function(Option)
        if Option and Option[1] and Option[1] ~= "Scanning..." and Option[1] ~= "None found" then
            state.easterSelectedEgg = Option[1]
            state.easterLastEggPosition = nil
            state.easterLastEggTarget = nil
        end
    end,
})
state.uiElements.EasterEggSelectDropdown = EasterEggDropdown

state.uiElements.EasterHideEggAnimToggle = EventTab:CreateToggle({
    Name = "⚡ Disable egg hatching animation",
    CurrentValue = false,
    Flag = "EasterHideEggAnim",
    Callback = function(Value)
        state.easterHideEggAnim = Value
        state.disableHatchAnimation = Value
    end,
})

state.uiElements.EasterAutoEggToggle = EventTab:CreateToggle({
    Name = "🥚 Auto Hatch Selected Egg",
    CurrentValue = false,
    Flag = "EasterAutoEgg",
    Callback = function(Value)
        state.easterAutoEgg = Value
        state.lastEasterEggHatch = 0
        state.easterLastEggPosition = nil
        state.easterLastEggTarget = nil
    end,
})

state.uiElements.EasterHatchAmountDropdown = EventTab:CreateDropdown({
    Name = "Hatch Amount",
    Options = {"1", "3", "10", "99"},
    CurrentOption = {"3"},
    MultipleOptions = false,
    Flag = "EasterHatchAmount",
    Callback = function(Option)
        local value = tonumber(Option and Option[1])
        if value then
            state.easterHatchAmount = math.clamp(value, 1, 99)
        end
    end,
})

state.uiElements.EasterLowLagHatchToggle = EventTab:CreateToggle({
    Name = "🧊 Low Lag Hatch Mode",
    CurrentValue = false,
    Flag = "EasterLowLagHatch",
    Callback = function(Value)
        state.easterLowLagHatch = Value
    end,
})

EventTab:CreateSection("⭐ Priority Event Eggs")

state.uiElements.EasterPriorityEggsDropdown = EventTab:CreateDropdown({
    Name = "Priority eggs (override normal egg when spawned)",
    Options = {"Painted Egg", "Basket Egg", "Easter Bunny Egg", "4x Luck Easter Bunny Egg"},
    CurrentOption = state.easterPriorityEggs,
    MultipleOptions = true,
    Flag = "EasterPriorityEggs",
    Callback = function(Options)
        state.easterPriorityEggs = Options or {}
        state.easterLastEggTarget = nil
        state.easterLastEggPosition = nil
    end,
})

state.uiElements.EasterPriorityEggModeToggle = EventTab:CreateToggle({
    Name = "⭐ Enable Priority Event Egg Detection",
    CurrentValue = false,
    Flag = "EasterPriorityEggMode",
    Callback = function(Value)
        state.easterPriorityEggMode = Value
        state.easterLastEggTarget = nil
        state.easterLastEggPosition = nil
    end,
})

EventTab:CreateSection("🐰 Easter Chest")

state.uiElements.EasterAutoChestToggle = EventTab:CreateToggle({
    Name = "🐰 Auto Claim Easter Chest",
    CurrentValue = false,
    Flag = "EasterAutoChest",
    Callback = function(Value)
        state.easterAutoChest = Value
        state.lastEasterChestClaim = 0
    end,
})

EventTab:CreateSection("🧩 Egg Hunt")

state.uiElements.EasterAutoHuntToggle = EventTab:CreateToggle({
    Name = "🧩 Auto Egg Hunt Actions",
    CurrentValue = false,
    Flag = "EasterAutoHunt",
    Callback = function(Value)
        state.easterAutoHunt = Value
        state.lastEasterHuntAction = 0
    end,
})

state.uiElements.EasterAutoJesterToggle = EventTab:CreateToggle({
    Name = "🃏 Auto Jester Attempt (best effort)",
    CurrentValue = false,
    Flag = "EasterAutoJester",
    Callback = function(Value)
        state.easterAutoJester = Value
        state.lastEasterJesterAttempt = 0
    end,
})

state.uiElements.EasterAutoClaimRewardsToggle = EventTab:CreateToggle({
    Name = "🎁 Auto Claim Easter Rewards",
    CurrentValue = false,
    Flag = "EasterAutoClaimRewards",
    Callback = function(Value)
        state.easterAutoClaimRewards = Value
        state.lastEasterRewardClaim = 0
    end,
})

state.uiElements.EasterAutoMasteryToggle = EventTab:CreateToggle({
    Name = "📈 Auto Upgrade Easter Mastery",
    CurrentValue = false,
    Flag = "EasterAutoMastery",
    Callback = function(Value)
        state.easterAutoMastery = Value
        state.lastEasterMasteryUpgrade = 0
    end,
})

EventTab:CreateSection("📊 Easter Progress")
state.labels.easterHunt = EventTab:CreateLabel("Hunt: waiting for data")
state.labels.easterMilestone = EventTab:CreateLabel("Milestones: waiting for data")

-- === AUTO POTIONS ===
FarmTab:CreateSection("🧪 Auto Potions")

local PotionDropdown = FarmTab:CreateDropdown({
   Name = "Potions to auto-use (multi-select)",
   Options = {"Loading..."},
   CurrentOption = {"Loading..."},
   MultipleOptions = true,
   Flag = "PotionSelect",
   Callback = function(Options)
      local cleaned = getSelectedPotionNames(Options or {})
      state.selectedPotions = cleaned
      if #cleaned > 0 then
          potionDebug("Potion dropdown updated: " .. table.concat(cleaned, ", "))
      else
          potionDebug("Potion dropdown updated: no valid potion selected.")
      end
   end,
})

local AutoPotionToggle = FarmTab:CreateToggle({
   Name = "Auto Use Potion",
   CurrentValue = false,
   Flag = "AutoPotion",
   Callback = function(Value)
      state.autoPotionEnabled = Value
      -- Rayfield:Notify({
      -- Title = "Auto Potion",
      -- Content = Value and "Enabled - Re-applying selected potions" or "Disabled",
      -- Duration = 2,
      -- })
   end,
})
state.uiElements.AutoPotionToggle = AutoPotionToggle

-- === ENCHANT TAB ===

EnchantTab:CreateSection("✨ Auto Enchant")

local EnchantMainDropdown = EnchantTab:CreateDropdown({
   Name = "Enchant #1 (target)",
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
state.uiElements.EnchantMainDropdown = EnchantMainDropdown

local EnchantMainTierSlider = EnchantTab:CreateSlider({
   Name = "Enchant #1 Tier (I-V)",
   Range = {1, 5},
   Increment = 1,
   CurrentValue = 1,
   Flag = "EnchantMainTier",
   Callback = function(Value)
      state.enchantMainTier = Value
   end,
})
state.uiElements.EnchantMainTierSlider = EnchantMainTierSlider
state.uiElements.EnchantMainSlider = EnchantMainTierSlider  -- Alias for loadConfig

local EnchantMainCheckToggle = EnchantTab:CreateToggle({
   Name = "✅ Check Slot #1",
   CurrentValue = true,
   Flag = "EnchantMainEnabled",
   Callback = function(Value)
      state.enchantMainEnabled = Value
   end,
})
state.uiElements.EnchantMainToggle = EnchantMainCheckToggle

local EnchantSecondDropdown = EnchantTab:CreateDropdown({
   Name = "Enchant #2 (optional)",
   Options = {"Loading..."},
   CurrentOption = {"Loading..."},
   MultipleOptions = false,
   Flag = "EnchantSecond",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Loading..." then
         if Option[1] == state.enchantMain then
            state.enchantSecond = nil
      -- Rayfield:Notify({ Title = "Enchant", Content = "Second slot can't be same as main", Duration = 2 })
         else
            state.enchantSecond = Option[1]
         end
      else
         state.enchantSecond = nil
      end
   end,
})
state.uiElements.EnchantSecondDropdown = EnchantSecondDropdown

local EnchantSecondTierSlider = EnchantTab:CreateSlider({
   Name = "Enchant #2 Tier (I-V)",
   Range = {1, 5},
   Increment = 1,
   CurrentValue = 1,
   Flag = "EnchantSecondTier",
   Callback = function(Value)
      state.enchantSecondTier = Value
   end,
})
state.uiElements.EnchantSecondTierSlider = EnchantSecondTierSlider
state.uiElements.EnchantSecondSlider = EnchantSecondTierSlider  -- Alias for loadConfig

local EnchantSecondCheckToggle = EnchantTab:CreateToggle({
   Name = "✅ Check Slot #2",
   CurrentValue = true,
   Flag = "EnchantSecondEnabled",
   Callback = function(Value)
      state.enchantSecondEnabled = Value
   end,
})
state.uiElements.EnchantSecondToggle = EnchantSecondCheckToggle

local AutoEnchantToggle = EnchantTab:CreateToggle({
   Name = "🔮 Enable Auto Enchant",
   CurrentValue = false,
   Flag = "AutoEnchant",
   Callback = function(Value)
      state.autoEnchantEnabled = Value
      -- Rayfield:Notify({
      -- Title = "Auto Enchant",
      -- Content = Value and "Enabled" or "Disabled",
      -- Duration = 2,
      -- })
   end,
})
state.uiElements.AutoEnchantToggle = AutoEnchantToggle

-- === FISHING TAB ===

FishingTab:CreateSection("🎣 Auto Fishing")

local FishingIslandDropdown = FishingTab:CreateDropdown({
   Name = "Select Fishing Island",
   Options = {"Scanning..."},
   CurrentOption = {"Scanning..."},
   MultipleOptions = false,
   Flag = "FishingIsland",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "Scanning..." then
         state.fishingIsland = Option[1]
         state.fishingTeleported = false  -- Reset teleport flag when island changes
         state.fishingAreaIndex = 1  -- Reset to first fishing spot
         state.lastSuccessfulCast = 0
         state.fishingStuckCheckTime = 0
         log("🎣 [Fishing] Island changed to: " .. state.fishingIsland)
      -- Rayfield:Notify({
      -- Title = "Fishing Island",
      -- Content = "Changed to " .. state.fishingIsland,
      -- Duration = 2,
      -- })
      end
   end,
})
state.uiElements.FishingIslandDropdown = FishingIslandDropdown

local FishingRodDropdown = FishingTab:CreateDropdown({
   Name = "Select Fishing Rod",
   Options = {"Wooden Rod", "Steel Rod", "Golden Rod", "Blizzard Rod", "Lotus Rod", "Molten Rod", "Trident Rod", "Galaxy Rod", "Abyssal Rod"},
   CurrentOption = {"Wooden Rod"},
   MultipleOptions = false,
   Flag = "FishingRod",
   Callback = function(Option)
      if Option and Option[1] then
         state.fishingRod = Option[1]
         log("🎣 [Fishing] Rod changed to: " .. state.fishingRod)
      -- Rayfield:Notify({
      -- Title = "Fishing Rod",
      -- Content = "Using " .. state.fishingRod,
      -- Duration = 2,
      -- })
      end
   end,
})
state.uiElements.FishingRodDropdown = FishingRodDropdown

local UpdateBestIslandButton = FishingTab:CreateButton({
   Name = "🏆 Auto-Select Best Island",
   Callback = function()
      local bestIsland = getBestFishingIsland()
      if bestIsland then
         state.fishingIsland = bestIsland
         state.fishingTeleported = false  -- Reset teleport flag
         state.fishingAreaIndex = 1  -- Reset to first fishing spot
         state.lastSuccessfulCast = 0
         state.fishingStuckCheckTime = 0
         log("🏆 [Fishing] Updated to best island: " .. bestIsland)
      -- Rayfield:Notify({
      -- Title = "Best Island Selected",
      -- Content = "Now fishing at " .. bestIsland,
      -- Duration = 3,
      -- Image = 4483362458,
      -- })
      else
      -- Rayfield:Notify({
      -- Title = "No Islands Available",
      -- Content = "No unlocked fishing islands found",
      -- Duration = 3,
      -- })
      end
   end,
})

local AutoFishToggle = FishingTab:CreateToggle({
   Name = "🎣 Auto Fish",
   CurrentValue = false,
   Flag = "AutoFish",
   Callback = function(Value)
      state.autoFishEnabled = Value
      if Value then
         -- Reset all fishing state variables for fresh start
         state.fishingTeleported = false
         state.fishingRodEquipped = false
         state.fishingAreaIndex = 1
         state.lastSuccessfulCast = 0
         state.fishingStuckCheckTime = 0
         local island = state.fishingIsland or "No island selected"
         log("🎣 [Fishing] Auto fishing ENABLED - Island: " .. island)
      -- Rayfield:Notify({
      -- Title = "Auto Fishing",
      -- Content = "Enabled - " .. (state.fishingIsland and ("Fishing at " .. state.fishingIsland) or "Select an island first"),
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
      else
         log("🎣 [Fishing] Auto fishing DISABLED")
      -- Rayfield:Notify({
      -- Title = "Auto Fishing",
      -- Content = "Disabled",
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
      end
   end,
})
state.uiElements.AutoFishToggle = AutoFishToggle


-- === WORLD TAB ===

WorldTab:CreateSection("🗺️ World Automation")

local DiscoverWorldDropdown = WorldTab:CreateDropdown({
    Name = "Discover Islands In",
    Options = {"Both Worlds", "The Overworld", "Minigame Paradise"},
    CurrentOption = {state.discoverTargetWorld},
    MultipleOptions = false,
    Flag = "DiscoverWorld",
    Callback = function(Option)
        if Option and Option[1] then
            state.discoverTargetWorld = Option[1]
            state.discoveredIslands = {}
        end
    end,
})
state.uiElements.DiscoverWorldDropdown = DiscoverWorldDropdown

local AutoDiscoverIslandsToggle = WorldTab:CreateToggle({
    Name = "🗺️ Auto Discover Islands",
    CurrentValue = false,
    Flag = "AutoDiscoverIslands",
    Callback = function(Value)
        state.autoDiscoverIslands = Value
        if Value then
            state.discoveredIslands = {}
            log("🗺️ [Discover] Auto discover ENABLED")
        else
            log("🗺️ [Discover] Auto discover DISABLED")
        end
    end,
})
state.uiElements.AutoDiscoverIslandsToggle = AutoDiscoverIslandsToggle

WorldTab:CreateButton({
    Name = "🔄 Reset Discovered Islands Cache",
    Callback = function()
        state.discoveredIslands = {}
        log("🗺️ [Discover] Cleared discovered island cache")
    end,
})

local UnlockWorldDropdown = WorldTab:CreateDropdown({
    Name = "Auto Unlock World Targets",
    Options = {"Minigame Paradise", "Seven Seas"},
    CurrentOption = state.selectedUnlockWorlds,
    MultipleOptions = true,
    Flag = "UnlockWorldTargets",
    Callback = function(Options)
        state.selectedUnlockWorlds = Options or {"Minigame Paradise"}
    end,
})
state.uiElements.UnlockWorldDropdown = UnlockWorldDropdown

local AutoUnlockWorldsToggle = WorldTab:CreateToggle({
    Name = "🔓 Auto Unlock Selected Worlds",
    CurrentValue = false,
    Flag = "AutoUnlockWorlds",
    Callback = function(Value)
        state.autoUnlockWorlds = Value
        state.lastWorldUnlockAttempt = 0
        if Value then
            log("🔓 [World Unlock] Auto unlock ENABLED")
        else
            log("🔓 [World Unlock] Auto unlock DISABLED")
        end
    end,
})
state.uiElements.AutoUnlockWorldsToggle = AutoUnlockWorldsToggle

-- === SEASON TAB ===

SeasonTab:CreateSection("📅 Season Automation")

local SeasonFallbackEggDropdown = SeasonTab:CreateDropdown({
    Name = "Fallback Egg For Season Hatch",
    Options = {"Infinity Egg", "Super Egg", "Heaven Egg", "Sakura Egg"},
    CurrentOption = {state.seasonFallbackEgg},
    MultipleOptions = false,
    Flag = "SeasonFallbackEgg",
    Callback = function(Option)
        if Option and Option[1] then
            state.seasonFallbackEgg = Option[1]
        end
    end,
})
state.uiElements.SeasonFallbackEggDropdown = SeasonFallbackEggDropdown

local AutoSeasonQuestToggle = SeasonTab:CreateToggle({
    Name = "✅ Auto Complete Season Quest",
    CurrentValue = false,
    Flag = "AutoSeasonQuest",
    Callback = function(Value)
        state.autoSeasonQuest = Value
        state.lastSeasonQuestAction = 0
        if Value then
            log("📅 [Season] Auto season quest ENABLED")
        else
            log("📅 [Season] Auto season quest DISABLED")
        end
    end,
})
state.uiElements.AutoSeasonQuestToggle = AutoSeasonQuestToggle

local AutoSeasonClaimToggle = SeasonTab:CreateToggle({
    Name = "🎁 Auto Collect Season Rewards",
    CurrentValue = false,
    Flag = "AutoSeasonClaim",
    Callback = function(Value)
        state.autoSeasonClaimRewards = Value
        state.lastSeasonRewardClaim = 0
        if Value then
            log("📅 [Season] Auto reward claim ENABLED")
        else
            log("📅 [Season] Auto reward claim DISABLED")
        end
    end,
})
state.uiElements.AutoSeasonClaimToggle = AutoSeasonClaimToggle

local AutoSeasonInfiniteToggle = SeasonTab:CreateToggle({
    Name = "♾️ Auto Start Infinite Track",
    CurrentValue = false,
    Flag = "AutoSeasonInfinite",
    Callback = function(Value)
        state.autoSeasonInfinite = Value
        state.lastSeasonInfiniteAttempt = 0
    end,
})
state.uiElements.AutoSeasonInfiniteToggle = AutoSeasonInfiniteToggle

-- === OBBYS TAB ===

ObbysTab:CreateSection("🏁 Obby Farming")

local ObbySelectionDropdown = ObbysTab:CreateDropdown({
    Name = "Select Obby Difficulties",
    Options = {"Easy", "Medium", "Hard"},
    CurrentOption = state.selectedObbies,
    MultipleOptions = true,
    Flag = "ObbySelection",
    Callback = function(Options)
        state.selectedObbies = Options or {"Easy"}
        state.obbyNextIndex = 1
    end,
})
state.uiElements.ObbySelectionDropdown = ObbySelectionDropdown

local AutoObbyFarmToggle = ObbysTab:CreateToggle({
    Name = "🏁 Auto Farm Selected Obbys",
    CurrentValue = false,
    Flag = "AutoObbyFarm",
    Callback = function(Value)
        state.autoObbyFarm = Value
        state.obbyNextIndex = 1
        state.obbyInProgress = false
        if Value then
            log("🏁 [Obby] Auto obby farming ENABLED")
        else
            log("🏁 [Obby] Auto obby farming DISABLED")
        end
    end,
})
state.uiElements.AutoObbyFarmToggle = AutoObbyFarmToggle

local AutoObbyChestToggle = ObbysTab:CreateToggle({
    Name = "🎁 Auto Claim Obby Chest",
    CurrentValue = false,
    Flag = "AutoObbyChest",
    Callback = function(Value)
        state.autoObbyChestClaim = Value
    end,
})
state.uiElements.AutoObbyChestToggle = AutoObbyChestToggle

-- === EGGS TAB ===

EggsTab:CreateSection("🥚 Egg Management")

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
      -- Rayfield:Notify({
      -- Title = "Egg Selected",
      -- Content = "Set normal egg: " .. selectedEgg,
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
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

         -- Auto-equip hatch team when enabled
         if state.hatchTeamIndex then
            pcall(function()
               local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
               Remote:FireServer("EquipTeam", state.hatchTeamIndex)
            end)
         end

      -- Rayfield:Notify({
      -- Title = "Auto Hatch Enabled",
      -- Content = "Hatching eggs from: " .. (state.eggPriority or "Select an egg first!"),
      -- Duration = 3,
      -- Image = 4483362458,
      -- })
      else
         state.lastEggPosition = nil
      -- Rayfield:Notify({
      -- Title = "Auto Hatch Disabled",
      -- Content = "Stopped auto-hatching",
      -- Duration = 2,
      -- })
      end
   end,
})
state.uiElements.AutoHatchToggle = AutoHatchToggle

local DisableHatchAnimToggle = EggsTab:CreateToggle({
   Name = "Disable egg hatching animation",
   CurrentValue = false,
   Flag = "DisableHatchAnim",
   Callback = function(Value)
      state.disableHatchAnimation = Value
      -- Rayfield:Notify({
      -- Title = "Hatch animation",
      -- Content = Value and "Disabled (animation will be stopped)" or "Enabled",
      -- Duration = 2,
      -- })
   end,
})

EggsTab:CreateSection("⭐ Egg Prioritizer Management")

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
      -- Rayfield:Notify({
      -- Title = "Priority Egg Mode",
      -- Content = Value and "Will auto-switch to priority eggs" or "Priority detection disabled",
      -- Duration = 2,
      -- })
   end,
})
state.uiElements.PriorityEggModeToggle = PriorityEggToggle

-- === RIFTS TAB ===

RiftsTab:CreateSection("🌌 Rifts Management")

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
      -- Rayfield:Notify({
      -- Title = "Rift Selected",
      -- Content = "Set rift: " .. rift.name,
      -- Duration = 2,
      -- Image = 4483362458,
      -- })
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
      -- Rayfield:Notify({
      -- Title = "Rift Auto Hatch",
      -- Content = Value and "Enabled" or "Disabled",
      -- Duration = 2,
      -- })
   end,
})
state.uiElements.RiftAutoHatchToggle = RiftAutoHatchToggle

RiftsTab:CreateSection("⭐ Rift Prioritizer Management")

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
      -- Rayfield:Notify({
      -- Title = "Priority Rift Enabled",
      -- Content = "Will auto-switch to priority rifts when they spawn",
      -- Duration = 3,
      -- Image = 4483362458,
      -- })
      else
      -- Rayfield:Notify({
      -- Title = "Priority Rift Disabled",
      -- Content = "Back to normal rift farming",
      -- Duration = 2,
      -- })
      end
   end,
})
state.uiElements.RiftPriorityModeToggle = PriorityRiftToggle

-- === WEBHOOK TAB ===

WebTab:CreateSection("💬 Hatch Notifications")

local WebhookInput = WebTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "https://discord.com/api/webhooks/...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
        state.webhookUrl = (Text and Text:match("^%s*(.-)%s*$")) or ""
   end,
})
state.uiElements.WebhookInput = WebhookInput

local PingUserInput = WebTab:CreateInput({
   Name = "Discord User ID (to ping)",
   PlaceholderText = "123456789012345678",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      state.webhookPingUserId = Text
   end,
})
state.uiElements.PingUserInput = PingUserInput

local PingToggle = WebTab:CreateToggle({
   Name = "📢 Enable Discord Ping",
   CurrentValue = false,
   Flag = "WebhookPing",
   Callback = function(Value)
      state.webhookPingEnabled = Value
   end,
})
state.uiElements.WebhookPingToggle = PingToggle

local ChanceThresholdInput = WebTab:CreateInput({
   Name = "Minimum Rarity (1 in X)",
   PlaceholderText = "100000000",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local value = tonumber(Text)
      if value and value > 0 then
         state.webhookChanceThreshold = value
      end
   end,
})
state.uiElements.ChanceThresholdInput = ChanceThresholdInput


local RarityDropdown = WebTab:CreateDropdown({
   Name = "Select Rarities to Notify",
    Options = {"Common", "Unique", "Rare", "Epic", "Legendary", "Secret", "Infinity", "Celestial"},
    CurrentOption = {"Legendary", "Secret", "Infinity", "Celestial"},
   MultipleOptions = true,
   Flag = "WebhookRarities",
   Callback = function(Options)
      -- Reset all to false
        state.webhookRarities = {Common=false, Unique=false, Rare=false, Epic=false, Legendary=false, Secret=false, Infinity=false, Celestial=false}
      -- Enable selected ones
      for _, rarity in ipairs(Options) do
         state.webhookRarities[rarity] = true
      end
   end,
})
state.uiElements.RarityDropdown = RarityDropdown

WebTab:CreateButton({
    Name = "📡 Test Hatch Webhook",
    Callback = function()
        if state.webhookUrl == "" then
            Rayfield:Notify({
                Title = "Webhook Test",
                Content = "Please enter webhook URL first",
                Duration = 3,
            })
            return
        end

        if not request then
            Rayfield:Notify({
                Title = "Webhook Error",
                Content = "Executor request() not available",
                Duration = 4,
            })
            return
        end

        SendWebhook(state.webhookUrl, "✅ Hatch webhook test from Lorio BGSI")
        Rayfield:Notify({
            Title = "Webhook Test",
            Content = "Sent test message",
            Duration = 3,
        })
    end,
})

WebTab:CreateSection("📈 Stats Webhook")

state.uiElements.WebhookStatsToggle = WebTab:CreateToggle({
    Name = "📈 Enable Stats Webhook",
    CurrentValue = false,
    Flag = "WebhookStatsEnabled",
    Callback = function(Value)
        state.webhookStatsEnabled = Value
        if Value then
            state.lastStatsWebhookTime = nil
        end
    end,
})

state.uiElements.WebhookStatsIntervalInput = WebTab:CreateInput({
    Name = "Stats Interval (seconds)",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local value = tonumber(Text)
        if value and value >= 30 then
            state.webhookStatsInterval = value
        end
    end,
})

WebTab:CreateButton({
    Name = "🔁 Reset Stats Message ID",
    Callback = function()
        state.statsMessageId = nil
        pcall(function() saveStatsMessageId("") end)
        Rayfield:Notify({
            Title = "Stats Webhook",
            Content = "Message ID reset",
            Duration = 2,
        })
    end,
})


-- === POWERUPS TAB ===

PowerupsTab:CreateSection("⚡ Auto Use Powerups")

local PowerupDropdown = PowerupsTab:CreateDropdown({
   Name = "Powerups to auto-use",
   Options = {"Loading..."},
   CurrentOption = {"Loading..."},
   MultipleOptions = true,
   Flag = "PowerupSelect",
   Callback = function(Options)
      local cleaned = getSelectedPotionNames(Options or {})
      state.selectedPowerups = cleaned
      if #cleaned > 0 then
         potionDebug("Powerup dropdown updated: " .. table.concat(cleaned, ", "))
      end
   end,
})

local PowerupToggle = PowerupsTab:CreateToggle({
   Name = "✨ Enable Auto Powerups",
   CurrentValue = false,
   Flag = "AutoPowerups",
   Callback = function(Value)
      state.autoPowerupEnabled = Value
      -- Rayfield:Notify({
      -- Title = "Auto Powerups",
      -- Content = Value and "Enabled" or "Disabled",
      -- Duration = 2,
      -- })
   end,
})
state.uiElements.AutoPowerupToggle = PowerupToggle


-- === COMPETITIVE TAB ===

CompTab:CreateSection("🤖 Auto Competitive")

local CompAutoToggle = CompTab:CreateToggle({
   Name = "✨ Enable Auto Competitive",
   CurrentValue = false,
   Flag = "CompAuto",
   Callback = function(Value)
      state.compAutoEnabled = Value
      if Value then
         -- Auto-enable auto blow when competitive mode starts
         state.autoBlow = true
         if state.uiElements.AutoBlowToggle then
            pcall(function() state.uiElements.AutoBlowToggle:Set(true) end)
         end
      end
   end,
})
state.uiElements.CompAutoToggle = CompAutoToggle

local CompRerollToggle = CompTab:CreateToggle({
   Name = "🔄 Auto-Reroll Non-Bubble Quests",
   CurrentValue = true,
   Flag = "CompReroll",
   Callback = function(Value)
      state.compRerollNonBubble = Value
   end,
})
state.uiElements.CompRerollToggle = CompRerollToggle


CompTab:CreateSection("🎯 Quest Type Selection")


local CompHatchToggle = CompTab:CreateToggle({
   Name = "🥚 Do Hatch Quests",
   CurrentValue = false,
   Flag = "CompHatch",
   Callback = function(Value)
      state.compDoHatchQuests = Value
      if not Value then
         state.compHatchActive = false
         state.compCurrentHatchEgg = nil
      end
   end,
})
state.uiElements.CompHatchToggle = CompHatchToggle

local CompBubbleToggle = CompTab:CreateToggle({
   Name = "💨 Do Bubble Quests",
   CurrentValue = true,
   Flag = "CompBubble",
   Callback = function(Value)
      state.compDoBubbleQuests = Value
   end,
})
state.uiElements.CompBubbleToggle = CompBubbleToggle

local CompPlaytimeToggle = CompTab:CreateToggle({
   Name = "⏰ Do Playtime Quests",
   CurrentValue = true,
   Flag = "CompPlaytime",
   Callback = function(Value)
      state.compDoPlaytimeQuests = Value
   end,
})
state.uiElements.CompPlaytimeToggle = CompPlaytimeToggle


CompTab:CreateSection("📊 Competitive Webhook")

local CompWebhookInput = CompTab:CreateInput({
   Name = "Competitive Webhook URL",
   PlaceholderText = "https://discord.com/api/webhooks/...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      state.compWebhookUrl = Text
   end,
})
state.uiElements.CompWebhookInput = CompWebhookInput

local CompWebhookIntervalInput = CompTab:CreateInput({
   Name = "Webhook Interval (seconds)",
   PlaceholderText = "300 (5 minutes)",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local interval = tonumber(Text)
      if interval and interval >= 60 then
         state.compWebhookInterval = interval
      end
   end,
})
state.uiElements.CompWebhookIntervalInput = CompWebhookIntervalInput


CompTab:CreateButton({
   Name = "📡 Test Competitive Webhook",
   Callback = function()
      if state.compWebhookUrl == "" then
         Rayfield:Notify({
            Title = "Webhook Test",
            Content = "Please enter a webhook URL first",
            Duration = 3,
         })
         return
      end
      task.spawn(sendCompetitiveWebhook, true)  -- true = test mode
   end,
})

-- === CONFIG TAB ===

ConfigTab:CreateSection("💾 Save/Load Configuration")

local selectedConfig = nil

-- Dropdown for config selection
local ConfigDropdown = ConfigTab:CreateDropdown({
   Name = "Select Config",
   Options = {"No configs found"},
   CurrentOption = {"No configs found"},
   MultipleOptions = false,
   Flag = "SelectedConfig",
   Callback = function(Option)
      if Option and Option[1] and Option[1] ~= "No configs found" then
         selectedConfig = Option[1]
         state.currentConfigName = Option[1]
      else
         selectedConfig = nil
      end
   end,
})

-- Refresh button to update dropdown list
ConfigTab:CreateButton({
   Name = "🔄 Refresh Config List",
   Callback = function()
      local configs = listConfigs()
      --  print("📋 Found " .. #configs .. " config(s)")

      if #configs > 0 then
         table.insert(configs, "— Create New —")
         pcall(function()
            ConfigDropdown:Refresh(configs, true)  -- true = keep current selection if possible
            --  print("✅ Dropdown refreshed with " .. (#configs - 1) .. " config(s)")
            -- Set first config as selected if nothing is selected
            if not selectedConfig or selectedConfig == "No configs found" then
               selectedConfig = configs[1]
            end
         end)
      else
         pcall(function()
            ConfigDropdown:Refresh({"No configs found"}, true)
            selectedConfig = nil
            --  print("📋 No configs found")
         end)
      end
   end,
})

-- Input for new config name (when creating new)
state.pendingConfigName = state.pendingConfigName or ""
ConfigTab:CreateInput({
   Name = "New Config Name (for Create New)",
   PlaceholderText = "MyNewConfig",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
        state.pendingConfigName = Text
   end,
})

-- Save button (overwrites selected OR creates new)
ConfigTab:CreateButton({
   Name = "💾 Save Config",
   Callback = function()
      local nameToSave = selectedConfig

      -- If "Create New" is selected, use the input field
      if selectedConfig == "— Create New —" or not selectedConfig or selectedConfig == "No configs found" then
            if state.pendingConfigName == "" then
            --  print("❌ Enter a name in 'New Config Name' field!")
            return
         end
            nameToSave = state.pendingConfigName
      end

      local success, message = saveConfig(nameToSave)
      if success then
         --  print("✅ Config saved: " .. nameToSave)
         -- Auto-refresh dropdown
         task.wait(0.1)  -- Small delay to ensure file is written
         local configs = listConfigs()
         if #configs > 0 then
            table.insert(configs, "— Create New —")
            ConfigDropdown:Refresh(configs, true)
            selectedConfig = nameToSave
            --  print("🔄 Dropdown refreshed, showing " .. (#configs - 1) .. " config(s)")
         end
      else
         --  print("❌ Save failed: " .. message)
      end
   end,
})

-- Load button
ConfigTab:CreateButton({
   Name = "📂 Load Config",
   Callback = function()
      if not selectedConfig or selectedConfig == "No configs found" or selectedConfig == "— Create New —" then
         --  print("❌ Select a config from the dropdown first!")
         return
      end

      local success, message = loadConfig(selectedConfig)
      if success then
         --  print("✅ Config loaded: " .. selectedConfig)
      else
         --  print("❌ Load failed: " .. message)
      end
   end,
})

ConfigTab:CreateSection("📋 Auto-Refresh")


ConfigTab:CreateSection("🚀 Auto-Load")

ConfigTab:CreateButton({
   Name = "🚀 Set Selected as Auto-Load",
   Callback = function()
      if selectedConfig and selectedConfig ~= "No configs found" and selectedConfig ~= "— Create New —" then
         writefile("LorioBGSI_AutoLoad.txt", selectedConfig)
         --  print("✅ Auto-load set to: " .. selectedConfig)
      else
         --  print("❌ Select a config first!")
      end
   end,
})

ConfigTab:CreateButton({
   Name = "❌ Disable Auto-Load",
   Callback = function()
      if isfile("LorioBGSI_AutoLoad.txt") then
         pcall(function() delfile("LorioBGSI_AutoLoad.txt") end)
         --  print("✅ Auto-load disabled")
      end
   end,
})


-- === DATA TAB ===

DataTab:CreateSection("🐾 Pet Information")

if petData then
    pcall(function()
        local shown = 0
        for name, data in pairs(petData) do
            if data.Rarity and shown < 10 then
                DataTab:CreateLabel(name .. " [" .. data.Rarity .. "]")
                shown += 1
            end
        end
    end)
end

-- 🔍 Remote Discovery Section
DataTab:CreateSection("✅ Remotes Found!")

DataTab:CreateButton({
   Name = "📡 Scan All Remotes",
   Callback = function()
      pcall(function()
         local RS = game:GetService("ReplicatedStorage")
-- --  print("\n🔍 === ALL REMOTES IN GAME ===")
         local count = 0
         for _, obj in pairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
               count = count + 1
-- --  print("   📡 [" .. count .. "] " .. obj:GetFullName())
            end
         end
-- --  print("\nTotal found: " .. count)
-- --  print("=== END SCAN ===\n")
      end)

      -- Rayfield:Notify({
      -- Title = "Scan Complete",
      -- Content = "Check console (F9)",
      -- Duration = 3
      -- })
   end
})

DataTab:CreateButton({
   Name = "🕵️ Test Auto-Blow Now",
   Callback = function()
      pcall(function()
         local RS = game:GetService("ReplicatedStorage")
         local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
         Remote:FireServer("BlowBubble")
-- --  print("✅ Sent BlowBubble command!")
      end)

      -- Rayfield:Notify({
      -- Title = "Bubble Blown!",
      -- Content = "Manual test successful",
      -- Duration = 2
      -- })
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
-- --  print("✅ Sent HatchEgg command for: " .. state.eggPriority .. " x99")
         end)

      -- Rayfield:Notify({
      -- Title = "Hatching Egg!",
      -- Content = state.eggPriority,
      -- Duration = 2
      -- })
      else
      -- Rayfield:Notify({
      -- Title = "No Egg Selected",
      -- Content = "Select an egg first",
      -- Duration = 3
      -- })
      end
   end
})

-- === STARTUP: LOAD ALL CHUNKS AND SCAN EGGS ===
-- --  print("🔍 Loading all game chunks and scanning for eggs...")

-- Load saved stats message ID (persists across rejoins)
loadStatsMessageId()

-- Auto-refresh config dropdown on startup
task.spawn(function()
    task.wait(0.5)  -- Wait for UI to fully load
    pcall(function()
        local configs = listConfigs()
        if #configs > 0 then
            table.insert(configs, "— Create New —")
            ConfigDropdown:Refresh(configs, true)
            selectedConfig = configs[1]
            --  print("✅ Config list loaded: " .. (#configs - 1) .. " config(s) found")
        else
            ConfigDropdown:Refresh({"No configs found"}, true)
            --  print("📋 No saved configs found")
        end
    end)
end)

-- Try to auto-load config if set
task.spawn(function()
    task.wait(2)  -- Wait for UI to fully load
    pcall(function()
        if isfile("LorioBGSI_AutoLoad.txt") then
            local configName = readfile("LorioBGSI_AutoLoad.txt")
            if configName and configName ~= "" then
                local success, message = loadConfig(configName)
                if success then
                    --  print("✅ Auto-loaded config: " .. configName)
                    selectedConfig = configName
      -- Rayfield:Notify({
      -- Title = "Config Auto-Loaded",
      -- Content = configName,
      -- Duration = 3,
      -- })
                end
            end
        end
    end)
end)

-- Load egg and rift data from game modules (auto-updates with game versions)
-- --  print("📦 Fetching egg, rift, potion, powerup, enchant and team data from game...")
loadGameEggData()
loadGameRiftData()
loadGamePotionData()
loadGamePowerupData()
loadGameEnchantData()
loadGameTeamData()

-- Pre-cache all pet data for zero-lag webhooks!
task.spawn(function()
    task.wait(1) -- Wait a moment for all data to fully load
    preCacheAllPetData()
end)

task.spawn(function()
    pcall(function()
        -- Use RequestStreamAroundAsync to load all worlds
        local worlds = Workspace:FindFirstChild("Worlds")
        if worlds and player.RequestStreamAroundAsync then
            for _, world in pairs(worlds:GetChildren()) do
                if world:IsA("Model") then
                    local primary = world.PrimaryPart or world:FindFirstChildWhichIsA("BasePart")
                    if primary then
-- --  print("  Loading chunks for:", world.Name)
                        player:RequestStreamAroundAsync(primary.Position)
                        task.wait(0.5)
                    end
                end
            end
-- --  print("✅ All chunks loaded!")
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
-- --  print("✅ Egg database built: " .. eggCount .. " eggs cataloged")
        end
    end)
end)

-- === MAIN LOOPS ===

-- ✅ AUTO-SCAN: Rifts and Eggs (every 2 seconds) - Only refresh if count changed
state.lastRiftCount = state.lastRiftCount or 0
state.lastEggCount = state.lastEggCount or 0

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
        if newCount ~= state.lastRiftCount or (newCount > 0 and state.lastRiftCount == 0) then
            state.lastRiftCount = newCount
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
        if newCount ~= state.lastEggCount or (newCount > 0 and state.lastEggCount == 0) then
            state.lastEggCount = newCount
            if newCount > 0 then
                pcall(function()
                    EggDropdown:Refresh(eggNames, false)  -- false = don't clear selection
                end)
            end
        end

        -- Keep Event tab egg dropdown updated from loaded Easter eggs
        pcall(function()
            scanEasterEventEggs()
        end)
    end
end)

-- ✅ STATS UPDATE: Every second
task.spawn(function()
    while task.wait(1) do
        local runtime = tick() - state.startTime
        local h,m,s = math.floor(runtime/3600), math.floor((runtime%3600)/60), math.floor(runtime%60)

        pcall(function()
            local pd = getPlayerData()
            if pd then
                updateEasterProgressText(pd)
            end
        end)

        pcall(function()
            state.labels.runtime:Set("⏱️ Runtime: " .. string.format("%02d:%02d:%02d", h,m,s))
            state.labels.bubbles:Set("🧱 Bubbles: " .. formatNumber(state.stats.bubbles))
            state.labels.hatches:Set("🥚 Hatches: " .. formatNumber(state.stats.hatches))
            if state.labels.easterHunt then
                state.labels.easterHunt:Set("🧩 " .. tostring(state.easterHuntStatusText or "Hunt: waiting for data"))
            end
            if state.labels.easterMilestone then
                state.labels.easterMilestone:Set("📈 " .. tostring(state.easterMilestoneStatusText or "Milestones: waiting for data"))
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
                            if state.labels.adminEvent then
                                state.labels.adminEvent:Set("👑 Admin Event: Super Egg (ACTIVE!)")
                            end
                        end)

                        -- Teleport to the egg's Plate
                        local plate = superEgg:FindFirstChild("Plate")
                        if plate then
                            tpToModel(superEgg)
      -- Rayfield:Notify({
      -- Title = "🎉 Admin Event: Super Egg!",
      -- Content = "Teleporting to Super Egg now!",
      -- Duration = 4,
      -- Image = 4483362458,
      -- })

                            -- Set as priority egg
                            state.eggPriority = "Super Egg"
      -- Rayfield:Notify({
      -- Title = "🥚 Priority: Super Egg",
      -- Content = "Now auto-hatching Super Egg!",
      -- Duration = 3,
      -- })
                        end
                    else
                        pcall(function()
                            if state.labels.adminEvent then
                                state.labels.adminEvent:Set("👑 Admin Event: Island Active (No Egg Yet)")
                            end
                        end)
                    end
                else
                    -- No AdminIsland found
                    pcall(function()
                        if state.labels.adminEvent then
                            state.labels.adminEvent:Set("👑 Admin Event: Not Active")
                        end
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
    local PickupCollectRemote = RS:WaitForChild("Remotes"):WaitForChild("Pickups"):WaitForChild("CollectPickup")
    local potionRetryGuard = {}
    local potionDebugNextLog = {}
    local lastPotionGlobalDebug = 0
    local powerupRetryGuard = {}

    -- Run potion automation in a separate lightweight worker to avoid stuttering the fast loop.
    task.spawn(function()
        while task.wait(0.35) do
            if state.autoPotionEnabled then
                pcall(function()
                    local selectedPotionNames = getSelectedPotionNames(state.selectedPotions)
                    if #selectedPotionNames == 0 then
                        local nowTick = tick()
                        if nowTick - lastPotionGlobalDebug >= 12 then
                            lastPotionGlobalDebug = nowTick
                            potionDebug("Auto potion enabled but no potions are selected.")
                        end
                        return
                    end

                    local playerData = getPlayerData()
                    if not playerData then
                        local nowTick = tick()
                        if nowTick - lastPotionGlobalDebug >= 6 then
                            lastPotionGlobalDebug = nowTick
                            potionDebug("LocalData:Get() returned nil; cannot evaluate ActivePotions yet.")
                        end
                        return
                    end

                    if state.potionCycleIndex > #selectedPotionNames then
                        state.potionCycleIndex = 1
                    end

                    local selectedPotion = selectedPotionNames[state.potionCycleIndex]
                    state.potionCycleIndex = (state.potionCycleIndex % #selectedPotionNames) + 1

                    local potionName, requestedLevel = normalizePotionSelection(selectedPotion)
                    if not potionName then
                        return
                    end

                    local serverNow = getServerUnixTime()
                    if type(state.gamePotionData) == "table" and not state.gamePotionData[potionName] and potionName ~= "Flowers" then
                        local nextAllowedDebug = potionDebugNextLog[potionName] or 0
                        if serverNow >= nextAllowedDebug then
                            potionDebug("Skipping unknown potion name from UI: " .. tostring(potionName))
                            potionDebugNextLog[potionName] = serverNow + 10
                        end
                        return
                    end

                    local remaining, activeLevel = getActivePotionRemaining(playerData, potionName)
                    state.activePotions[potionName] = {
                        remaining = remaining,
                        level = activeLevel,
                        checkedAt = serverNow,
                    }

                    local guardUntil = potionRetryGuard[potionName] or 0
                    local nextAllowedDebug = potionDebugNextLog[potionName] or 0

                    if remaining > 0 then
                        if serverNow >= nextAllowedDebug then
                            potionDebug(string.format("%s active (level %s), %.0fs remaining. Skipping use.", potionName, tostring(activeLevel or "?"), remaining))
                            potionDebugNextLog[potionName] = serverNow + 12
                        end
                        return
                    end

                    if serverNow < guardUntil then
                        if serverNow >= nextAllowedDebug then
                            potionDebug(string.format("%s waiting for LocalData refresh (guard %.1fs left).", potionName, guardUntil - serverNow))
                            potionDebugNextLog[potionName] = serverNow + 5
                        end
                        return
                    end

                    local levelToUse = getBestOwnedPotionLevel(playerData, potionName, requestedLevel)
                    if levelToUse then
                        potionDebug(string.format("Using %s at level %d (requested=%s)", potionName, levelToUse, tostring(requestedLevel)))
                        Remote:FireServer("UsePotion", potionName, levelToUse)
                        potionRetryGuard[potionName] = serverNow + 3
                        potionDebugNextLog[potionName] = serverNow + 2
                    else
                        potionDebug(string.format("Skipping %s (requested=%s) because no owned level was found.", potionName, tostring(requestedLevel)))
                        potionDebugNextLog[potionName] = serverNow + 8
                    end
                end)
            end
        end
    end)

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
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local pickupTargets = getRenderedChunkerPickupTargets()
                local attempted = 0

                for _, target in pairs(pickupTargets) do
                    if attempted >= 30 then
                        break
                    end

                    if shouldAttemptPickupTarget(target, 0.08) then
                        if target.model and hrp then
                            movePlayerNearPickup(target.model, hrp)
                        end

                        -- Primary path observed in game: CollectPickup remote with pickup UUID string.
                        pcall(function()
                            PickupCollectRemote:FireServer(target.id)
                        end)

                        -- Fallback path kept for compatibility with older variants.
                        pcall(function()
                            Remote:FireServer("CollectPickup", target.id)
                        end)

                        attempted = attempted + 1
                    end
                end
            end)
        end

        -- (Auto Chest handled in dedicated loop below)

        -- ✅ Auto Sell Bubbles
        if state.autoSellBubbles then
            pcall(function()
                Remote:FireServer("SellBubble")
            end)
        end

        -- ✅ Auto Enchant (all pets in equipped team, one at a time)
        if state.autoEnchantEnabled and state.enchantMain then
            local success, err = pcall(function()
                --  print("🔮 [Enchant] Starting auto-enchant cycle")

                -- Get LocalData to access team and pet info
                local LocalData = require(RS.Client.Framework.Services.LocalData)
                local playerData = LocalData:Get()

                if not playerData then
                    --  print("❌ [Enchant] No playerData")
                    return
                end
                --  print("✅ [Enchant] Got playerData")

                if not playerData.Teams then
                    --  print("❌ [Enchant] No Teams in playerData")
                    return
                end
                --  print("✅ [Enchant] Teams exist, count:", #playerData.Teams)

                -- Try multiple methods to find equipped team
                local equippedTeamIndex = nil
                local team = nil

                -- Method 1: Check playerData.TeamEquipped (correct field name)
                if playerData.TeamEquipped then
                    equippedTeamIndex = playerData.TeamEquipped
                    team = playerData.Teams[equippedTeamIndex]
                    --  print("✅ [Enchant] Method 1: Found team via TeamEquipped, index:", equippedTeamIndex)
                end

                -- Method 2: Find team with Equipped = true
                if not team then
                    for idx, t in pairs(playerData.Teams) do
                        if t.Equipped == true then
                            equippedTeamIndex = idx
                            team = t
                            --  print("✅ [Enchant] Method 2: Found team via Equipped flag, index:", idx)
                            break
                        end
                    end
                end

                -- Check if team exists and has pets
                if not team then
                    --  print("❌ [Enchant] No equipped team found")
                    return
                end

                if not team.Pets or #team.Pets == 0 then
                    --  print("❌ [Enchant] Team has no pets")
                    return
                end

                --  print("✅ [Enchant] Team has", #team.Pets, "pets")
                --  print("🔢 [Enchant] Current pet index:", state.currentEnchantPetIndex)

                -- Get current pet ID from team's pet array
                local currentPetId = team.Pets[state.currentEnchantPetIndex]
                if not currentPetId then
                    --  print("❌ [Enchant] Invalid pet index, resetting to 1")
                    state.currentEnchantPetIndex = 1
                    return
                end
                --  print("✅ [Enchant] Current pet ID:", currentPetId)

                -- Find pet data by matching ID
                local petData = nil
                if playerData.Pets then
                    for _, pet in pairs(playerData.Pets) do
                        if pet.Id == currentPetId then
                            petData = pet
                            break
                        end
                    end
                end

                if not petData then
                    --  print("❌ [Enchant] Pet not found in collection, skipping to next")
                    state.currentEnchantPetIndex = state.currentEnchantPetIndex + 1
                    return
                end
                --  print("✅ [Enchant] Found pet data")

                -- Check current enchants
                local currentEnchants = petData.Enchants or {}
                --  print("🔮 [Enchant] Pet has", #currentEnchants, "enchants")

                -- Debug: print current enchants
                for i, ench in ipairs(currentEnchants) do
                    if ench and ench.Id then
                        local level = ench.Level or 1
                        --  print("  Enchant #" .. i .. ":", ench.Id, "Level:", level)
                    end
                end

                -- Track which slots are satisfied
                local slot1Satisfied = not state.enchantMainEnabled  -- If disabled, consider satisfied
                local slot2Satisfied = not state.enchantSecondEnabled  -- If disabled, consider satisfied

                -- Prepare target enchants (base name only, compare level separately)
                local mainTargetName = state.enchantMain and tostring(state.enchantMain):lower() or nil
                local secondTargetName = state.enchantSecond and tostring(state.enchantSecond):lower() or nil

                    --  print("🎯 [Enchant] Target Slot 1:", mainTargetName or "none", "(Tier:", state.enchantMainTier or 1, "Enabled:", state.enchantMainEnabled, "Auto-satisfied:", not state.enchantMainEnabled, ")")
                    --  print("🎯 [Enchant] Target Slot 2:", secondTargetName or "none", "(Tier:", state.enchantSecondTier or 1, "Enabled:", state.enchantSecondEnabled, "Auto-satisfied:", not state.enchantSecondEnabled, ")")

                -- Check if pet has the desired enchants
                for _, enchant in ipairs(currentEnchants) do
                    if enchant and enchant.Id then
                        local enchantId = tostring(enchant.Id):lower()
                        local enchantLevel = enchant.Level or 1

                        -- Check slot 1 (only if enabled and has target)
                        if state.enchantMainEnabled and mainTargetName and not slot1Satisfied then
                            if enchantId == mainTargetName and enchantLevel == state.enchantMainTier then
                                slot1Satisfied = true
                                --  print("✅ [Enchant] Slot 1 satisfied:", enchant.Id, "Level:", enchantLevel)
                            end
                        end

                        -- Check slot 2 (only if enabled and has target)
                        if state.enchantSecondEnabled and secondTargetName and not slot2Satisfied then
                            if enchantId == secondTargetName and enchantLevel == state.enchantSecondTier then
                                slot2Satisfied = true
                                --  print("✅ [Enchant] Slot 2 satisfied:", enchant.Id, "Level:", enchantLevel)
                            end
                        end

                        -- If both slots satisfied, no need to check more
                        if slot1Satisfied and slot2Satisfied then
                            break
                        end
                    end
                end

                -- Pet is ready if all enabled slots are satisfied
                local hasDesiredEnchant = slot1Satisfied and slot2Satisfied
                --  print("📊 [Enchant] Result - Slot1:", slot1Satisfied, "Slot2:", slot2Satisfied, "Ready:", hasDesiredEnchant)

                -- If pet has desired enchant, move to next pet
                if hasDesiredEnchant then
                    --  print("➡️ [Enchant] Moving to next pet")
                    state.currentEnchantPetIndex = state.currentEnchantPetIndex + 1
                    if state.currentEnchantPetIndex > #team.Pets then
                        --  print("🔄 [Enchant] Reached end of team, looping back to pet 1")
                        state.currentEnchantPetIndex = 1
                    end
                else
                    -- Reroll specific slots that need rerolling
                    local RemoteEvent = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

                    -- Reroll slot 1 if it's enabled and not satisfied
                    if state.enchantMainEnabled and not slot1Satisfied then
                        --  print("🎲 [Enchant] Rerolling slot 1 for pet:", currentPetId)
                        local rerollSuccess, rerollErr = pcall(function()
                            RemoteEvent:FireServer("RerollEnchant", currentPetId, 1)
                        end)
                        if not rerollSuccess then
                            --  print("❌ [Enchant] Slot 1 reroll failed:", rerollErr)
                        else
                            --  print("✅ [Enchant] Slot 1 rerolled")
                        end
                    end

                    -- Reroll slot 2 if it's enabled and not satisfied
                    if state.enchantSecondEnabled and not slot2Satisfied then
                        --  print("🎲 [Enchant] Rerolling slot 2 for pet:", currentPetId)
                        local rerollSuccess, rerollErr = pcall(function()
                            RemoteEvent:FireServer("RerollEnchant", currentPetId, 2)
                        end)
                        if not rerollSuccess then
                            --  print("❌ [Enchant] Slot 2 reroll failed:", rerollErr)
                        else
                            --  print("✅ [Enchant] Slot 2 rerolled")
                        end
                    end
                end
            end)

            if not success then
                --  print("❌ [Enchant] Error:", err)
            end
        end

        -- ✅ Auto Collect Flowers (Spring Event)
        if state.autoCollectFlowers and state.springEventActive then
            pcall(function()
                local spring = Workspace:FindFirstChild("Spring")
                if spring then
                    local pickPetals = spring:FindFirstChild("PickPetals")
                    if pickPetals then
                        -- Get player character
                        local character = player.Character
                        if character then
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                -- Teleport to each flower's Root part
                                for _, flower in pairs(pickPetals:GetChildren()) do
                                    if flower:IsA("Model") then
                                        local root = flower:FindFirstChild("Root")
                                        if root and root:IsA("BasePart") then
                                            -- Teleport to Root part
                                            hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                                            task.wait(0.5) -- Wait 0.5s before next flower
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- ✅ Auto Flowers + Egg (Combo: Stay at egg, flowers come to you ONE AT A TIME)
        if state.autoFlowersEgg and state.springEventActive then
            pcall(function()
                local currentTime = tick()
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if hrp then
                    -- Re-teleport player to egg every 10 seconds
                    if currentTime - state.lastFlowerEggTeleport >= 10 then
                        -- Find the selected egg
                        local egg = nil
                        for _, eggModel in pairs(state.currentEggs) do
                            if eggModel.name == state.flowersEggChoice then
                                egg = eggModel.instance
                                break
                            end
                        end

                        -- If egg found, teleport to its Plate part
                        if egg then
                            local plate = egg:FindFirstChild("Plate")
                            if plate and plate:IsA("BasePart") then
                                hrp.CFrame = plate.CFrame + Vector3.new(0, 5, 0)
                                state.lastFlowerEggTeleport = currentTime
                            end
                        end
                    end

                    -- Teleport each flower ROOT under player's feet ONE AT A TIME
                    local spring = Workspace:FindFirstChild("Spring")
                    if spring then
                        local pickPetals = spring:FindFirstChild("PickPetals")
                        if pickPetals then
                            -- Loop through each flower sequentially
                            for _, flower in pairs(pickPetals:GetChildren()) do
                                if flower:IsA("Model") then
                                    local root = flower:FindFirstChild("Root")
                                    if root and root:IsA("BasePart") then
                                        -- Save original position
                                        local originalCFrame = root.CFrame

                                        -- Move flower Root at player's feet level (not underground)
                                        root.CFrame = hrp.CFrame + Vector3.new(0, -1, 0)

                                        -- Wait for collection
                                        task.wait(0.1)

                                        -- Move flower back to original position
                                        root.CFrame = originalCFrame
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- Auto potions run in dedicated background worker above.

        -- ✅ Auto Use Powerups
        if state.autoPowerupEnabled then
            pcall(function()
                local pwNames = getSelectedPotionNames(state.selectedPowerups)
                if #pwNames == 0 then return end

                local playerData = getPlayerData()
                if not playerData then return end
                local powerups = playerData.Powerups or {}
                local serverNow = getServerUnixTime()

                for _, powerupName in ipairs(pwNames) do
                    local guardUntil = powerupRetryGuard[powerupName] or 0
                    if serverNow < guardUntil then continue end

                    local owned = powerups[powerupName] or 0
                    if owned <= 0 then continue end

                    if powerupName == "Golden Orb" then
                        -- UseGoldenOrb() — no arguments
                        Remote:FireServer("UseGoldenOrb")
                        powerupRetryGuard[powerupName] = serverNow + 5
                        potionDebug("Powerup: Used Golden Orb")

                    elseif powerupName == "Power Orb" then
                        -- UsePowerOrb(petId) — needs a pet below max level
                        local petId = nil
                        local pets = playerData.Pets
                        if type(pets) == "table" then
                            for _, pet in ipairs(pets) do
                                if type(pet) == "table" and pet.Id then
                                    petId = pet.Id
                                    break
                                end
                            end
                        end
                        if petId then
                            Remote:FireServer("UsePowerOrb", petId)
                            powerupRetryGuard[powerupName] = serverNow + 5
                            potionDebug("Powerup: Used Power Orb on pet " .. tostring(petId))
                        else
                            powerupRetryGuard[powerupName] = serverNow + 10
                        end

                    elseif powerupName:find("Fragment") then
                        -- UseFragment(type) — strip " Fragment" suffix
                        local fragType = powerupName:gsub(" Fragment", "")
                        Remote:FireServer("UseFragment", fragType)
                        powerupRetryGuard[powerupName] = serverNow + 5
                        potionDebug("Powerup: Used Fragment " .. fragType)

                    elseif powerupName == "Reroll Orb" or powerupName == "Shadow Crystal" then
                        -- These require UI interaction (enchant slot picker) — skip automation
                        powerupRetryGuard[powerupName] = serverNow + 60
                        potionDebug("Powerup: " .. powerupName .. " requires UI interaction, skipping")

                    else
                        -- Gift-type: Mystery Box, Spin Ticket, Dice, Crate, etc.
                        -- UseGift(name, count)
                        local useCount = math.min(owned, 10)
                        Remote:FireServer("UseGift", powerupName, useCount)
                        powerupRetryGuard[powerupName] = serverNow + 3
                        potionDebug("Powerup: Used " .. powerupName .. " x" .. useCount)
                    end

                    task.wait(0.1)
                end
            end)
        end

        -- ✅ Easter: Auto Collect Pickups (Teleport path + Farm pickup logic)
        if state.easterAutoPickup then
            pcall(function()
                local now = tick()
                local lastTp = state.lastEasterPickupPortalTeleport or 0
                if (now - lastTp) >= 1.5 then
                    local path = getEasterPickupTeleportPath(state.easterPickupZone)
                    if path and path ~= "" then
                        pcall(function()
                            Remote:FireServer("Teleport", path)
                        end)
                        state.lastEasterPickupPortalTeleport = now
                    end
                end

                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local pickupTargets = getRenderedChunkerPickupTargets()
                local attempted = 0

                for _, target in pairs(pickupTargets) do
                    if attempted >= 30 then
                        break
                    end

                    if shouldAttemptPickupTarget(target, 0.08) then
                        if target.model and hrp then
                            movePlayerNearPickup(target.model, hrp)
                        end

                        pcall(function()
                            PickupCollectRemote:FireServer(target.id)
                        end)

                        pcall(function()
                            Remote:FireServer("CollectPickup", target.id)
                        end)

                        attempted = attempted + 1
                    end
                end
            end)
        end

        -- ✅ Easter: Auto Buy Event Shop
        if state.easterAutoShop and not state.easterAdvancedShop then
            local now = tick()
            if now - state.lastEasterShopBuy >= 1 then
                pcall(function()
                    Remote:FireServer("BuyShopItem", "easter-shop", state.easterShopTier, false)
                end)
                state.lastEasterShopBuy = now
            end
        end

        -- ✅ Easter: Advanced Shop Mode (supports easter-shop, carrot-shop, secretegg-shop)
        if state.easterAdvancedShop then
            local now = tick()
            if now - (state.lastEasterAdvancedShopBuy or 0) >= 1.25 then
                pcall(function()
                    local shopId = state.easterShopId or "easter-shop"
                    local slot = math.clamp(tonumber(state.easterShopTier) or 1, 1, 6)
                    if shopId == "secretegg-shop" then
                        slot = 1
                    elseif shopId == "carrot-shop" then
                        slot = math.clamp(slot, 1, 2)
                    end
                    Remote:FireServer("BuyShopItem", shopId, slot, false)
                end)
                state.lastEasterAdvancedShopBuy = now
            end
        end

        -- ✅ Easter: Auto Buy Secret Shop
        if state.easterSecretShop then
            local now = tick()
            if now - state.lastEasterSecretShopBuy >= 1 then
                pcall(function()
                    Remote:FireServer("BuyShopItem", "secret-shop", 1, false)
                end)
                state.lastEasterSecretShopBuy = now
            end
        end

        -- ✅ Easter: Auto Hatch Selected Event Egg (with priority override)
        if state.easterAutoEgg then
            local now = tick()
            local hatchInterval = state.easterLowLagHatch and 0.7 or 0.3
            if now - state.lastEasterEggHatch >= hatchInterval then
                pcall(function()
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        return
                    end

                    if not isInEasterEventArea(hrp) then
                        teleportToEasterEvent(Remote, false)
                        return
                    end

                    local scanInterval = state.easterLowLagHatch and 0.8 or 0.4
                    if now - (state.lastEasterEggScan or 0) >= scanInterval then
                        scanEasterEventEggs()
                        state.lastEasterEggScan = now
                    end

                    local targetEggName = state.easterSelectedEgg
                    local function normalizeEasterEggName(name)
                        if type(name) ~= "string" then
                            return ""
                        end
                        if name == "4X Luck Fortune Egg" or name == "4X Gaelic Egg" or name == "4X Luck Gaelic Egg" then
                            return "4x Luck Easter Bunny Egg"
                        elseif name == "Gaelic Egg" or name == "Fortune Egg" then
                            return "Easter Bunny Egg"
                        elseif name == "Lucky Egg" then
                            return "Basket Egg"
                        end
                        return name
                    end

                    -- Priority mode overrides normal selected egg while priority egg is spawned
                    if state.easterPriorityEggMode and type(state.easterPriorityEggs) == "table" and #state.easterPriorityEggs > 0 then
                        local foundPriority = nil
                        local bestPriorityScore = -1

                        local function getEasterPriorityScore(name)
                            local normalized = normalizeEasterEggName(name)
                            if normalized == "4x Luck Easter Bunny Egg" then
                                return 300
                            elseif normalized == "Easter Bunny Egg" then
                                return 200
                            elseif normalized == "Basket Egg" then
                                return 100
                            elseif normalized == "Painted Egg" then
                                return 50
                            end
                            return 0
                        end

                        for _, priorityName in ipairs(state.easterPriorityEggs) do
                            for _, eventEgg in ipairs(state.currentEventEggs) do
                                local normalizedEventEggName = normalizeEasterEggName(eventEgg.name)
                                local normalizedPriorityName = normalizeEasterEggName(priorityName)
                                if normalizedEventEggName == normalizedPriorityName and eventEgg.instance and eventEgg.instance:IsDescendantOf(Workspace) then
                                    local score = getEasterPriorityScore(eventEgg.name)
                                    if score > bestPriorityScore then
                                        bestPriorityScore = score
                                        foundPriority = eventEgg.name
                                    end
                                end
                            end
                        end
                        if foundPriority then
                            targetEggName = foundPriority
                        end
                    end

                    if not targetEggName then return end

                    if state.easterLastEggTarget ~= targetEggName then
                        state.easterLastEggTarget = targetEggName
                        state.easterLastEggPosition = nil
                    end

                    local matchedEgg = false
                    for _, egg in pairs(state.currentEventEggs) do
                        if egg.name == targetEggName and egg.instance and egg.instance:IsDescendantOf(Workspace) then
                            matchedEgg = true
                            local eggPos = egg.instance:GetPivot().Position
                            local teleportThreshold = state.easterLowLagHatch and 45 or 25
                            local shouldTeleport = (not state.easterLastEggPosition)
                                or ((eggPos - state.easterLastEggPosition).Magnitude > 8)
                                or ((hrp.Position - eggPos).Magnitude > teleportThreshold)

                            if shouldTeleport then
                                tpToModel(egg.instance)
                                task.wait(0.15)
                            end

                            state.easterLastEggPosition = eggPos
                            local hatchAmount = math.clamp(tonumber(state.easterHatchAmount) or 3, 1, 99)
                            if state.easterLowLagHatch then
                                hatchAmount = 1
                            end
                            Remote:FireServer("HatchEgg", egg.name, hatchAmount)
                            if state.easterHideEggAnim then
                                task.defer(stopHatchAnimation)
                            end
                            break
                        end
                    end

                    if not matchedEgg then
                        scanEasterEventEggs()
                    end
                end)
                state.lastEasterEggHatch = now
            end
        end

        -- ✅ Easter: Auto Claim Easter Chest
        if state.easterAutoChest then
            local now = tick()
            if now - state.lastEasterChestClaim >= 2 then
                pcall(function()
                    local claimNames = {"Easter Chest", "Easter chest"}
                    for _, chestName in ipairs(claimNames) do
                        Remote:FireServer("ClaimChest", chestName, true)
                    end
                end)
                state.lastEasterChestClaim = now
            end
        end

        -- ✅ Easter: Hunt/Jester/Rewards/Mastery helpers
        if state.easterAutoHunt or state.easterAutoJester or state.easterAutoClaimRewards or state.easterAutoMastery then
            pcall(function()
                local playerData = getPlayerData()
                if not playerData then
                    return
                end

                updateEasterProgressText(playerData)
                tryEasterHuntAction(Remote, playerData)
                tryEasterJesterAction(Remote, playerData)
                tryEasterRewardsAndMastery(Remote)
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

                    -- Get IslandTeleport position to find closest fishing area
                    local islandTeleport = island:FindFirstChild("IslandTeleport")
                    if not islandTeleport then
                        log("❌ [Fishing] ERROR: IslandTeleport not found in " .. state.fishingIsland)
                        return
                    end

                    local teleportSpawn = islandTeleport:FindFirstChild("Spawn") or islandTeleport
                    local teleportPosition = teleportSpawn:IsA("BasePart") and teleportSpawn.Position or teleportSpawn:GetPivot().Position
                    log("✅ [Fishing] Island teleport position: " .. tostring(teleportPosition))

                    -- Get all fishing areas (UUID named models)
                    local areaList = fishingAreas:GetChildren()
                    if #areaList == 0 then
                        log("❌ [Fishing] ERROR: No fishing areas found")
                        return
                    end
                    log("✅ [Fishing] Found " .. #areaList .. " fishing areas")

                    -- Smart area selection: Filter out potentially bugged areas and calculate distances
                    local validAreas = {}
                    for i, area in ipairs(areaList) do
                        if area:IsA("Model") then
                            local cframe, size = area:GetBoundingBox()
                            -- Only include areas with reasonable size (not tiny/bugged)
                            if size.Magnitude > 10 then
                                local center = cframe.Position
                                local distance = (center - teleportPosition).Magnitude
                                table.insert(validAreas, {
                                    index = i,
                                    area = area,
                                    size = size,
                                    center = center,
                                    distance = distance
                                })
                                log("  ✅ Valid fishing area #" .. i .. " - Size: " .. tostring(size) .. ", Distance from teleport: " .. tostring(math.floor(distance)) .. " studs")
                            else
                                log("  ⚠️ Skipping area #" .. i .. " (too small, possibly bugged) - Size: " .. tostring(size))
                            end
                        end
                    end

                    if #validAreas == 0 then
                        log("❌ [Fishing] ERROR: No valid fishing areas found")
                        return
                    end
                    log("✅ [Fishing] " .. #validAreas .. " valid fishing areas")

                    -- Sort fishing areas by distance from IslandTeleport (closest first)
                    table.sort(validAreas, function(a, b)
                        return a.distance < b.distance
                    end)

                    log("🎯 [Fishing] Closest fishing area is #" .. validAreas[1].index .. " at " .. tostring(math.floor(validAreas[1].distance)) .. " studs")

                    -- Check if we're stuck (no successful cast in 10 seconds after starting)
                    local currentTime2 = tick()
                    if state.fishingStuckCheckTime == 0 then
                        state.fishingStuckCheckTime = currentTime2
                    elseif currentTime2 - state.lastSuccessfulCast > 10 and state.lastSuccessfulCast > 0 then
                        -- Stuck! Try next fishing spot (already sorted by distance)
                        state.fishingAreaIndex = state.fishingAreaIndex + 1
                        if state.fishingAreaIndex > #validAreas then
                            state.fishingAreaIndex = 1  -- Loop back to closest spot
                        end
                        state.fishingTeleported = false  -- Force re-teleport
                        state.fishingRodEquipped = false  -- Force re-equip
                        log("⚠️ [Fishing] Stuck detected! Trying fishing spot #" .. state.fishingAreaIndex)
                        return
                    end

                    -- Pick fishing area from sorted list (closest first, cycles if stuck)
                    local areaIndex = math.min(state.fishingAreaIndex, #validAreas)
                    local areaData = validAreas[areaIndex]
                    local area = areaData.area
                    local center = areaData.center
                    local size = areaData.size
                    log("🎣 [Fishing] Using fishing spot #" .. areaIndex .. " of " .. #validAreas .. " (distance: " .. tostring(math.floor(areaData.distance)) .. " studs)")
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

                    -- Get player character
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        log("❌ [Fishing] ERROR: HumanoidRootPart not found")
                        return
                    end

                    -- TELEPORT PLAYER TO CENTER OF FISHING AREA
                    local fishingPosition = CFrame.new(center) * CFrame.new(0, 3, 0)  -- At center, raised by 3 studs
                    hrp.CFrame = fishingPosition
                    task.wait(0.3)

                    log("✅ [Fishing] Positioned at center (" .. tostring(hrp.Position) .. ") of closest fishing area")

                    -- ONE-TIME SETUP: Equip rod, enable AutoFish, and setup event listeners
                    if not state.fishingRodEquipped then
                        -- Check if fishing was disabled during wait
                        if not state.autoFishEnabled then
                            log("⚠️ [Fishing] Disabled during setup, aborting")
                            return
                        end

                        log("🎣 [Fishing] Setting up rod and event listeners...")
                        Remote:FireServer("SetEquippedRod", state.fishingRod, false)
                        task.wait(1)

                        if not state.autoFishEnabled then return end

                        Remote:FireServer("EquipRod")
                        task.wait(2)

                        if not state.autoFishEnabled then return end

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

                    -- Check if fishing still enabled before casting
                    if not state.autoFishEnabled then
                        log("⚠️ [Fishing] Disabled before cast, aborting")
                        return
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
                                if not state.autoFishEnabled then
                                    log("  ⚠️ Fishing disabled, stopping wait")
                                    error("Fishing disabled")
                                end
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
                            if not state.autoFishEnabled then error("Fishing disabled") end
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
                                if not state.autoFishEnabled then error("Fishing disabled") end
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end
                            log("  ✅ Casting state - bobber in water")

                            -- Wait for Waiting state (waiting for fish)
                            maxWait = 0
                            while fsm:GetCurrentState() ~= FishingState.Waiting and maxWait < 50 do
                                if not state.autoFishEnabled then error("Fishing disabled") end
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end
                            log("  ✅ Waiting state - fish will bite soon")

                            -- Wait for Reeling state (fish bit!)
                            log("  ⏳ Waiting for fish bite...")
                            maxWait = 0
                            while fsm:GetCurrentState() ~= FishingState.Reeling and maxWait < 200 do
                                if not state.autoFishEnabled then
                                    log("  ⚠️ Fishing disabled while waiting for bite")
                                    error("Fishing disabled")
                                end
                                task.wait(0.1)
                                maxWait = maxWait + 1
                            end

                            if fsm:GetCurrentState() == FishingState.Reeling then
                                log("  🐟 Fish bit! Reeling... (AutoFish handles this)")

                                -- Wait for Idle state (fish caught, cycle complete)
                                maxWait = 0
                                while fsm:GetCurrentState() ~= FishingState.Idle and maxWait < 150 do
                                    if not state.autoFishEnabled then error("Fishing disabled") end
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

                        -- Check if still enabled before fallback
                        if not state.autoFishEnabled then
                            log("⚠️ [Fishing] Disabled during event failure, aborting fallback")
                            return
                        end

                        -- Fallback: Use input events with hardcoded timing
                        pcall(function()
                            local FishingInput = require(RS.Client.Gui.Frames.Fishing.FishingInput)
                            FishingInput.Pressed:Fire()
                            task.wait(0.4)
                            FishingInput.Released:Fire()
                        end)

                        -- Wait with hardcoded time as fallback (check every second for instant stop)
                        log("  ⏳ Waiting 30s (fallback timing)")
                        for i = 1, 30 do
                            if not state.autoFishEnabled then
                                log("  ⚠️ Fishing disabled during fallback wait")
                                return
                            end
                            task.wait(1)
                        end
                        castComplete = true
                    end

                    if castComplete then
                        state.lastFishingAttempt = currentTime
                        state.lastSuccessfulCast = tick()  -- Mark successful cast
                        state.fishingStuckCheckTime = tick()  -- Reset stuck check timer
                        log("✅ [Fishing] Cast cycle complete! Ready for next cast")
                    else
                        log("⚠️ [Fishing] Cast cycle incomplete, waiting before retry")
                        for i = 1, 5 do
                            if not state.autoFishEnabled then return end
                            task.wait(1)
                        end
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
-- --  print("[Rift] Priority rift '" .. state.farmingPriorityRift .. "' despawned - reverting")
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
-- --  print("[Rift] Teleported back to normal egg: " .. state.previousEggPriority)
                                    break
                                end
                            end
                        end
                    end
                end

                -- If we found a priority rift that's spawned, farm it
                if priorityRiftName and priorityRiftInstance then
                    if not priorityRiftInstance:IsDescendantOf(Workspace) then
-- --  print("[Rift] Priority rift instance not in workspace, skipping")
                        return
                    end

                    -- Save previous if we're switching to this priority rift
                    if state.farmingPriorityRift ~= priorityRiftName then
                        state.previousEggPriority = state.eggPriority
                        state.previousRiftPriority = state.riftPriority
                        state.farmingPriorityRift = priorityRiftName
-- --  print("[Rift] Switching to priority rift: " .. priorityRiftName)
                    end

                    -- Teleport to rift
                    tpToModel(priorityRiftInstance)
                    task.wait(0.3)

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
                    task.wait(0.3)

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
-- --  print("[Rift] Selected rift '" .. tostring(state.riftPriority) .. "' not found in spawned rifts")
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
-- --  print("[Egg] Switching to priority egg: " .. priorityEggName)
                            end
                        end

                        -- Teleport to priority egg
                        tpToModel(priorityEggInstance)
                        task.wait(0.3)

                        -- Hatch the priority egg
                        Remote:FireServer("HatchEgg", priorityEggName, 99)
                        task.defer(stopHatchAnimation)

                        handledByPriorityEgg = true
                    end
                else
                    -- No priority egg found, revert to previous if we had one
                    if state.previousEggPriority and state.previousEggPriority ~= state.eggPriority then
-- --  print("[Egg] Priority egg gone, reverting to: " .. state.previousEggPriority)
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
-- --  print("[Egg] Normal egg instance not in workspace, rescanning")
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
                            task.wait(0.3)
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
-- --  print("📦 Stopped chest farming")
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
-- --  print("✅ Claimed playtime gifts")
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

-- ✅ AUTO OBBY CHEST CLAIM: Every 2 seconds
task.spawn(function()
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while task.wait(2) do
        if state.autoObbyChestClaim then
            pcall(function()
                Remote:FireServer("ClaimObbyChest", false)
            end)
        end
    end
end)

-- ✅ AUTO OBBY FARM: Runs selected obbies in Easy -> Medium -> Hard order
task.spawn(function()
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")
    local LocalData = nil
    pcall(function()
        LocalData = require(RS.Client.Framework.Services.LocalData)
    end)

    while task.wait(0.25) do
        if state.autoObbyFarm and not state.obbyInProgress then
            local selected = state.selectedObbies or {}
            if #selected == 0 then
                task.wait(1)
                continue
            end

            local orderMap = {Easy = 1, Medium = 2, Hard = 3}
            local ordered = {}
            for _, name in ipairs(selected) do
                if orderMap[name] then
                    table.insert(ordered, name)
                end
            end

            table.sort(ordered, function(a, b)
                return orderMap[a] < orderMap[b]
            end)

            if #ordered == 0 then
                task.wait(1)
                continue
            end

            local now = tick()
            if now - (state.lastObbyRun or 0) < 3 then
                continue
            end

            -- Respect game cooldowns: only start obbies whose cooldown has finished.
            local cooldowns = nil
            local nowEpoch = os.time()
            pcall(function()
                if LocalData then
                    local playerData = LocalData:Get()
                    if playerData then
                        cooldowns = playerData.ObbyCooldowns
                    end
                end
            end)

            local startFrom = math.min(state.obbyNextIndex or 1, #ordered)
            local readyIndex = nil
            for offset = 0, #ordered - 1 do
                local idx = ((startFrom - 1 + offset) % #ordered) + 1
                local obbyName = ordered[idx]
                local cooldownUntil = cooldowns and cooldowns[obbyName]

                if not cooldownUntil or nowEpoch >= cooldownUntil then
                    readyIndex = idx
                    break
                end
            end

            -- No selected obby is ready yet, wait and retry later.
            if not readyIndex then
                task.wait(1)
                continue
            end

            state.obbyInProgress = true

            pcall(function()
                local currentIndex = readyIndex
                local obbyName = ordered[currentIndex]

                Remote:FireServer("StartObby", obbyName)
                task.wait(0.75)
                if not state.autoObbyFarm then
                    return
                end

                local obbysFolder = Workspace:FindFirstChild("Obbys")
                local obbyFolder = obbysFolder and obbysFolder:FindFirstChild(obbyName)
                local chest = obbyFolder and obbyFolder:FindFirstChild("Chest")
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

                if chest and hrp then
                    local chestCFrame
                    if chest:IsA("BasePart") then
                        chestCFrame = chest.CFrame
                    else
                        chestCFrame = chest:GetPivot()
                    end
                    hrp.CFrame = chestCFrame + Vector3.new(0, 4, 0)
                end

                -- Wait for natural completion, then force CompleteObby if needed
                task.wait(1.5)
                if not state.autoObbyFarm then
                    return
                end

                Remote:FireServer("CompleteObby")
                task.wait(0.2)
                Remote:FireServer("Teleport", "Workspace.Worlds.Seven Seas.Areas.Classic Island.HouseSpawn")

                state.obbyNextIndex = currentIndex + 1
                if state.obbyNextIndex > #ordered then
                    state.obbyNextIndex = 1
                end
                state.lastObbyRun = tick()
            end)

            state.obbyInProgress = false
        elseif not state.autoObbyFarm then
            state.obbyInProgress = false
        end
    end
end)

-- === INITIAL SETUP ===
-- --  print("✅ Performing initial scans...")

-- Populate priority dropdowns with game data (all eggs/rifts, not just spawned ones)
task.spawn(function()
    task.wait(0.5)  -- Wait for game data to load

    if #state.gameEggList > 0 then
        pcall(function()
            PriorityEggDropdown:Refresh(state.gameEggList, true)
        end)
    end

    if #state.gameRiftList > 0 then
        pcall(function()
            PriorityRiftDropdown:Refresh(state.gameRiftList, true)
        end)
    end

    if #state.gamePotionList > 0 then
        pcall(function()
            PotionDropdown:Refresh(state.gamePotionList, true)
        end)
    end

    if #state.gamePowerupList > 0 then
        pcall(function()
            PowerupDropdown:Refresh(state.gamePowerupList, true)
        end)
    end

    if #state.gameEnchantList > 0 then
        pcall(function()
            EnchantMainDropdown:Refresh(state.gameEnchantList, true)
            EnchantSecondDropdown:Refresh(state.gameEnchantList, true)
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
-- --  print("✅ Found " .. #eggNames .. " spawned eggs")
    else
-- --  print("⚠️ No eggs found yet")
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
-- --  print("✅ Found " .. #riftNames .. " spawned rifts")
    else
-- --  print("⚠️ No rifts spawned yet")
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
-- --  print("🏆 Auto-selected best fishing island: " .. bestIsland)
            else
                -- Fallback: use first island
                state.fishingIsland = islands[1]
                log("📍 [Fishing] Using first island: " .. islands[1])
            end
        end)
        log("✅ [Fishing] Found " .. #islands .. " fishing islands: " .. table.concat(islands, ", "))
-- --  print("✅ Found " .. #islands .. " fishing islands")
    else
        log("⚠️ [Fishing] No fishing islands found")
-- --  print("⚠️ No fishing islands found yet")
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

      -- Rayfield:Notify({
      -- Title = "Fishing Island Upgraded!",
      -- Content = "Now fishing at " .. bestIsland,
      -- Duration = 4,
      -- Image = 4483362458,
      -- })
                    end
                end
            end

            lastLevel = currentLevel
        end)

        log("✅ [Fishing] Auto-upgrade monitor active")
    end)
end)

-- === DEDICATED AUTO CHEST LOOP (every 3 seconds) ===
task.spawn(function()
    local RemoteEvent = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    -- Known cooldowns from Shared.Data.Chests (seconds).
    -- Used as a LOCAL fallback when playerData.Cooldowns isn't fresh yet.
    local CHEST_COOLDOWNS = {
        ["Giant Chest"]      = 900,
        ["Void Chest"]       = 2400,
        ["Ticket Chest"]     = 1800,
        ["Peppermint Chest"] = 900,
        ["Infinity Chest"]   = 600,
    }

    -- Per-chest: when WE last successfully fired ClaimChest.
    -- Keyed by chest name, value = tick() at claim time.
    local localClaimTime = {}

    -- Get LocalData for server-authoritative cooldown checking
    local LocalDataModule = nil
    pcall(function()
        LocalDataModule = require(RS.Client.Framework.Services.LocalData)
    end)

    -- workspace:GetServerTimeNow() matches how BGSI stores cooldown Unix timestamps
    local function getServerTime()
        local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
        return ok and t or os.time()
    end

    -- Returns seconds remaining on cooldown (<=0 = ready).
    -- Uses playerData.Cooldowns when available, falls back to local estimate.
    local function chestCooldownRemaining(chestName, playerData)
        -- 1) Server-authoritative: playerData.Cooldowns stores Unix expiry timestamp
        if playerData and playerData.Cooldowns then
            local expiry = playerData.Cooldowns[chestName]
            if expiry and expiry > 0 then
                local remaining = expiry - getServerTime()
                if remaining > 0 then
                    return remaining
                end
            end
        end

        -- 2) Local estimate: if we personally claimed it recently, respect the cd
        local lastClaim = localClaimTime[chestName]
        if lastClaim then
            local knownCd = CHEST_COOLDOWNS[chestName] or 600
            local elapsed = tick() - lastClaim
            if elapsed < knownCd then
                return knownCd - elapsed
            end
        end

        return 0
    end

    local lastStatusLog = 0

    while true do
        task.wait(3)

        if not state.autoChest then
            continue
        end

        pcall(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local rendered = Workspace:FindFirstChild("Rendered")
            if not rendered then return end

            local chestsFolder = rendered:FindFirstChild("Chests")
            if not chestsFolder then return end

            local allChests = chestsFolder:GetChildren()
            if #allChests == 0 then return end

            local playerData = nil
            if LocalDataModule then
                pcall(function() playerData = LocalDataModule:Get() end)
            end

            local now = tick()
            local claimed = 0
            local skippedCooldown = {}
            local readyNames = {}

            for _, chest in pairs(allChests) do
                if not chest:IsDescendantOf(Workspace) then continue end

                local name = chest.Name
                local cdRemaining = chestCooldownRemaining(name, playerData)

                if cdRemaining > 0 then
                    table.insert(skippedCooldown, name .. string.format("(%.0fs)", cdRemaining))
                    continue
                end

                table.insert(readyNames, name)

                -- Chests in workspace.Rendered.Chests are BaseParts, not Models.
                -- getModelPosition() checks IsA("Model") and returns nil for BaseParts,
                -- so we must read .Position directly to get a valid chest position.
                if hrp then
                    local chestPos = nil
                    pcall(function()
                        if chest:IsA("BasePart") then
                            chestPos = chest.Position
                        elseif chest:IsA("Model") then
                            chestPos = chest:GetPivot().Position
                        end
                    end)
                    if chestPos then
                        pcall(function()
                            hrp.CFrame = CFrame.new(chestPos + Vector3.new(0, 3, 0))
                        end)
                        task.wait(0.3)  -- wait for server to register new HRP position
                    else
                        log("📦 [Chest] No position for: " .. name .. " (" .. chest.ClassName .. ")")
                    end
                end

                -- Fire WITHOUT 'true' — exactly matches physical proximity-prompt:
                -- v_u_9:FireServer("ClaimChest", name)  (no extra arg)
                pcall(function()
                    RemoteEvent:FireServer("ClaimChest", name)
                end)

                localClaimTime[name] = tick()
                claimed = claimed + 1
                task.wait(0.25)
            end
            if claimed > 0 then
                log("📦 [Chest] Claimed " .. claimed .. ": " .. table.concat(readyNames, ", "))
            end

            if #skippedCooldown > 0 and (now - lastStatusLog) >= 60 then
                lastStatusLog = now
                log("📦 [Chest] On cooldown: " .. table.concat(skippedCooldown, ", "))
            end
        end)
    end
end)

-- Rayfield config disabled - using custom JSON config system
-- Rayfield:LoadConfiguration()

-- --  print("✅ ==========================================")
-- --  print("✅ Lorio (BGSI) - READY!")
-- --  print("✅ ==========================================")
-- --  print("📱 Lorio is mobile-optimized (Rayfield)")
-- --  print("   • Single column layout")
-- --  print("   • Auto-resizes to your screen")
-- --  print("   • Touch-friendly buttons")
-- --  print("✅ ==========================================")
-- --  print("🔄 AUTO-SCANNING:")
-- --  print("   • Rifts: Every 2 seconds")
-- --  print("   • Eggs: Every 2 seconds")
-- --  print("   • Stats: Every 1 second")
-- --  print("   • Admin Events: Every 3 seconds")
-- --  print("   • Playtime Gifts: Every 60 seconds")
-- --  print("   • Fishing: Auto-selects best island")
-- --  print("   • Anti-AFK: Every 15-19 minutes")
-- --  print("✅ ==========================================")
-- --  print("📋 Tabs:")
-- --  print("   🏠 Main - Live stats (ALL 18 currencies!)")
-- --  print("   🔧 Farm - Auto blow, pickup, fishing, anti-AFK, event detector")
-- --  print("   🥚 Eggs - Auto-scanned eggs + auto hatch")
-- --  print("   🌌 Rifts - Auto-scanned rifts + priority mode")
-- --  print("   📊 Webhook - Pet hatches, stats, rarity filter")
-- --  print("   📋 Data - Pet information")
-- --  print("✅ ==========================================")
-- --  print("🎉 WEBHOOK FEATURES:")
-- --  print("   ⚡ INSTANT pet hatch detection (event-driven!)")
-- --  print("   🎯 Multi-egg support (3x, 7x hatches)")
-- --  print("   ✨ Shiny/Mythic stat multipliers (x2.5, x10, x25)")
-- --  print("   🎨 Rarity filtering (multi-select)")
-- --  print("   🎲 Chance threshold (only rare pets)")
-- --  print("   📊 User stats webhook (editable, no spam)")
-- --  print("   🔒 No duplicates, no freezing, no missed pets")
-- --  print("✅ ==========================================")

      -- Rayfield:Notify({
      -- Title = "Lorio (BGSI) Ready!",
      -- Content = "Mobile-optimized | All systems active!",
      -- Duration = 5,
      -- Image = 4483362458,
      -- })

-- --  print("Lorio (BGSI) loaded successfully!")
-- --  print("💡 Rifts and eggs will auto-refresh every 2 seconds")
-- --  print("💡 Enable webhook for pet hatch notifications!")
-- --  print("🎣 Fishing: Auto-selects best island + upgrades on level up")
-- --  print("🎣 Fishing logs: lorio_bgsi_fishing_log.txt")

-- === WORLD + SEASON AUTOMATION TASKS ===
task.spawn(function()
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while true do
        task.wait(0.4)
        local now = tick()

        if state.autoDiscoverIslands and now - state.lastDiscoverStep >= 0.9 then
            state.lastDiscoverStep = now

            local didStep = false
            local discoverReason = "idle"
            pcall(function()
                didStep, discoverReason = doIslandDiscoverStep()
            end)

            if not didStep and now - state.lastDiscoverDoneLog >= 20 then
                state.lastDiscoverDoneLog = now
                if discoverReason == "all-unlocked" then
                    log("🗺️ [Discover] All islands already unlocked for selected world target")
                elseif discoverReason == "no-targets" then
                    log("🗺️ [Discover] No discover targets found in current world structure")
                elseif discoverReason == "no-character" then
                    log("🗺️ [Discover] Waiting for character/HumanoidRootPart")
                else
                    log("🗺️ [Discover] No new discover step this cycle")
                end
            end
        end

        if state.autoUnlockWorlds and now - state.lastWorldUnlockAttempt >= 5 then
            state.lastWorldUnlockAttempt = now

            pcall(function()
                local playerData = getPlayerData()
                local targets = state.selectedUnlockWorlds or {}

                for _, worldName in ipairs(targets) do
                    if worldName and worldName ~= "" and not isWorldUnlocked(playerData, worldName) then
                        Remote:FireServer("UnlockWorld", worldName)
                        log("🔓 [World Unlock] Attempted unlock: " .. worldName)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local Remote = RS.Shared.Framework.Network.Remote:WaitForChild("RemoteEvent")

    while true do
        task.wait(0.3)
        local now = tick()

        if state.autoSeasonQuest and now - state.lastSeasonQuestAction >= 0.55 then
            state.lastSeasonQuestAction = now

            pcall(function()
                local playerData = getPlayerData()
                local activeQuest = getActiveSeasonQuest(playerData)

                if not activeQuest then
                    state.seasonActiveQuestId = nil
                    return
                end

                if state.seasonActiveQuestId ~= activeQuest.id then
                    state.seasonActiveQuestId = activeQuest.id
                    log(string.format("📅 [Season] Active quest: %s (%d/%d)", activeQuest.id or "unknown", activeQuest.progress or 0, activeQuest.amount or 0))
                end

                local taskTypeLower = type(activeQuest.taskType) == "string" and activeQuest.taskType:lower() or ""

                if activeQuest.type == "bubble" then
                    Remote:FireServer("BlowBubble")
                    return
                end

                if activeQuest.type == "hatch" then
                    local eggName = activeQuest.specificEgg or state.seasonFallbackEgg or "Infinity Egg"
                    local teleported = false
                    local eggModel = findEggModelByName(eggName)

                    if eggModel then
                        tpToModel(eggModel)
                        teleported = true
                    else
                        local eggInfo = state.eggDatabase and state.eggDatabase[eggName]
                        if eggInfo and eggInfo.position then
                            tpToPosition(eggInfo.position)
                            teleported = true
                        end
                    end

                    if teleported then
                        task.wait(0.12)
                    elseif now - (state.lastSeasonEggNotFoundLog or 0) >= 6 then
                        state.lastSeasonEggNotFoundLog = now
                        log("📅 [Season] Hatch quest egg not found in loaded world: " .. tostring(eggName))
                    end

                    Remote:FireServer("HatchEgg", eggName, 99)
                    task.defer(stopHatchAnimation)
                    return
                end

                if taskTypeLower:find("collect") or taskTypeLower:find("pickup") or taskTypeLower:find("coin") then
                    local pickupCollectRemote = RS:WaitForChild("Remotes"):WaitForChild("Pickups"):WaitForChild("CollectPickup")
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    local attempted = 0
                                        table.insert(readyNames, name)

                                        -- Chests in workspace.Rendered.Chests are BaseParts, not Models.
                                        -- getModelPosition() checks IsA("Model") and returns nil for BaseParts,
                                        -- so we must read .Position directly.
                                        if hrp then
                                            local chestPos = nil
                                            pcall(function()
                                                if chest:IsA("BasePart") then
                                                    chestPos = chest.Position
                                                elseif chest:IsA("Model") then
                                                    chestPos = chest:GetPivot().Position
                                                end
                                            end)
                                            if chestPos then
                                                pcall(function()
                                                    hrp.CFrame = CFrame.new(chestPos + Vector3.new(0, 3, 0))
                                                end)
                                                task.wait(0.3)  -- wait for server to register new HRP position
                                            else
                                                log("📦 [Chest] No position for: " .. name .. " (" .. chest.ClassName .. ")")
                                            end
                                        end

                                        -- Fire WITHOUT 'true' — matches the physical proximity-prompt interaction
                                        -- exactly: v_u_9:FireServer("ClaimChest", name)
                                        pcall(function()
                                            RemoteEvent:FireServer("ClaimChest", name)
                                        end)

                                        localClaimTime[name] = tick()
                                        claimed = claimed + 1
                                        task.wait(0.25)
                                    end

            end)
        end

        if state.autoSeasonClaimRewards and state.autoSeasonInfinite and now - state.lastSeasonInfiniteAttempt >= 30 then
            state.lastSeasonInfiniteAttempt = now
            pcall(function()
                Remote:FireServer("BeginSeasonInfinite")
            end)
        end
    end
end)

-- === COMPETITIVE BACKGROUND TASK ===
task.spawn(function()
    --  print("🏆 [Competitive] System initialized")

    while true do
        task.wait(0.5)  -- Check every 0.5 seconds for fast rerolls

        if state.compAutoEnabled then
            local success, err = pcall(function()
                -- Get Remote module
                local Remote = nil
                pcall(function()
                    Remote = require(RS.Shared.Framework.Network.Remote)
                end)

                if not Remote then
                    return
                end
                local localDataModule = RS:FindFirstChild("Client", true)
                if localDataModule then
                    localDataModule = localDataModule:FindFirstChild("Framework", true)
                    if localDataModule then
                        localDataModule = localDataModule:FindFirstChild("Services", true)
                        if localDataModule then
                            localDataModule = localDataModule:FindFirstChild("LocalData", true)
                        end
                    end
                end

                if not localDataModule then
                    return
                end

                local LocalData = require(localDataModule)
                local playerData = LocalData:Get()

                if not playerData or not playerData.Competitive then
                    return
                end

                -- === QUEST SELECTION & REROLL LOGIC ===
                local questData = playerData.Quests or {}

                -- Auto-reroll non-selected quest types (slots 3-4 only)
                if state.compRerollNonBubble then
                    for slotNum = 3, 4 do
                        local questId = "competitive-" .. slotNum
                        local quest = nil

                        -- Find quest by ID
                        for _, q in pairs(questData) do
                            if type(q) == "table" and q.Id == questId then
                                quest = q
                                break
                            end
                        end

                        if quest then
                            local questInfo = parseQuest(quest)

                            if questInfo and shouldSkipQuest(questInfo) then
                                --  print(string.format("🔄 [Competitive] Rerolling slot %d (Type: %s - disabled)", slotNum, questInfo.type))

                                -- Fire reroll remote
                                pcall(function()
                                    Remote:FireServer("CompetitiveReroll", slotNum)
                                end)
                            end
                        end
                    end
                end

                -- === HATCH QUEST HANDLING ===
                if state.compDoHatchQuests then
                    -- Get all competitive hatch quests (slots 1-4)
                    local compHatchQuests = getCompetitiveHatchQuests(playerData)

                    if #compHatchQuests > 0 then
                        -- Get season hatch quests for syncing
                        local seasonHatchQuests = getSeasonHatchQuests(playerData)

                        -- Find first incomplete comp hatch quest
                        local activeCompQuest = nil
                        for _, quest in ipairs(compHatchQuests) do
                            if quest.progress < quest.amount then
                                activeCompQuest = quest
                                break
                            end
                        end

                        if activeCompQuest then
                            -- Find best egg to hatch
                            local bestEgg, matchesSeason = findBestHatchEgg(activeCompQuest, seasonHatchQuests)

                            -- Update state
                            if state.compCurrentHatchEgg ~= bestEgg then
                                state.compCurrentHatchEgg = bestEgg
                                state.compHatchActive = true

                                local syncMsg = matchesSeason and " (synced with season quest)" or ""
                                --  print(string.format("🥚 [Competitive] Starting hatch quest: %s%s", bestEgg, syncMsg))
                                --  print(string.format("   └─ Progress: %d/%d", activeCompQuest.progress, activeCompQuest.amount))
                            end
                        else
                            -- All comp hatch quests complete
                            if state.compHatchActive then
                                --  print("✅ [Competitive] All hatch quests completed!")
                                state.compHatchActive = false
                                state.compCurrentHatchEgg = nil
                            end
                        end
                    else
                        -- No hatch quests available
                        if state.compHatchActive then
                            state.compHatchActive = false
                            state.compCurrentHatchEgg = nil
                        end
                    end
                end

                -- Send competitive webhook at interval
                if state.compWebhookUrl ~= "" then
                    local currentTime = tick()

                    if currentTime - state.compLastWebhook >= state.compWebhookInterval then
                        state.compLastWebhook = currentTime
                        --  print("📊 [Competitive] Sending webhook stats...")
                        pcall(function()
                            sendCompetitiveWebhook(false)
                        end)
                    end
                end
            end)

            if not success then
                --  print("❌ [Competitive] Error: " .. tostring(err))
            end
        end
    end
end)

-- === COMPETITIVE HATCH EXECUTION LOOP ===
task.spawn(function()
    --  print("🥚 [Competitive Hatch] System initialized")

    while true do
        task.wait(0.3)  -- Hatch every 0.3 seconds

        if state.compAutoEnabled and state.compHatchActive and state.compCurrentHatchEgg then
            pcall(function()
                -- Get Remote module
                local Remote = nil
                pcall(function()
                    Remote = require(RS.Shared.Framework.Network.Remote)
                end)

                if not Remote then
                    return
                end

                -- Find the egg in workspace
                local eggFound = false
                for _, egg in pairs(state.currentEggs) do
                    if egg.name == state.compCurrentHatchEgg then
                        eggFound = true

                        -- Validate egg still exists
                        if not egg.instance:IsDescendantOf(Workspace) then
                            return
                        end

                        -- TP to egg if needed
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local eggPos = egg.instance:GetPivot().Position
                            local distance = (hrp.Position - eggPos).Magnitude

                            if distance > 15 then
                                tpToModel(egg.instance)
                                task.wait(0.1)
                            end
                        end

                        -- Send hatch command (99 eggs at once)
                        Remote:FireServer("HatchEgg", state.compCurrentHatchEgg, 99)
                        task.defer(stopHatchAnimation)

                        break
                    end
                end

                -- If egg not found in current eggs, might be infinity egg
                if not eggFound and state.compCurrentHatchEgg == "Infinity Egg" then
                    -- Try to hatch infinity egg directly (it might not be spawned)
                    Remote:FireServer("HatchEgg", "Infinity Egg", 99)
                    task.defer(stopHatchAnimation)
                end
            end)
        end
    end
end)

-- === ANTI-AFK BACKGROUND TASK ===
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")

    -- Capture controller once at startup
    VirtualUser:CaptureController()

    --  print("🛡️ [Anti-AFK] System initialized")
    --  print("🛡️ [Anti-AFK] Waiting for toggle to be enabled...")

    while true do
        if state.antiAFK then
            -- Random interval between 1-2 minutes (60-120 seconds)
            local interval = math.random(60, 120)
            --  print("🛡️ [Anti-AFK] ✅ ENABLED - Next input in " .. interval .. " seconds (" .. math.floor(interval/60) .. "m " .. (interval%60) .. "s)")

            -- Wait for the interval
            task.wait(interval)

            -- Check if still enabled after waiting
            if state.antiAFK then
                --  print("🛡️ [Anti-AFK] Simulating user input...")

                -- Simulate right-click input to prevent AFK kick
                local success, err = pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    --  print("🛡️ [Anti-AFK]   └─ ✅ INPUT SIMULATED - AFK timer reset!")
                end)

                if not success then
                    --  print("🛡️ [Anti-AFK]   └─ ❌ Error during input simulation: " .. tostring(err))
                end
            else
                --  print("🛡️ [Anti-AFK] Toggle was disabled during wait period")
            end
        else
            -- Check every 10 seconds when disabled
            task.wait(10)
        end
    end
end)
