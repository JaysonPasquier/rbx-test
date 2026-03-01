-- Season Reward Predictor
-- Calculates your exact infinite rewards for any tier

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Get your season data
local function getSeasonData()
    local network = RS:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network")
    local remote = network:WaitForChild("Bindable"):WaitForChild("GetSeasonXP")

    -- Your season seed is stored server-side, but we can extract it
    -- by comparing predicted vs actual rewards

    -- For now, let's extract it from the infinity tiers
    local gui = player.PlayerGui.ScreenGui.HUD.Season
    -- Access the GUI to see current tier data

    print("=== SEASON SEED EXTRACTOR ===")
    print("Looking for your Season Seed...")

    -- Check current infinity track rewards
    local infinityFrame = gui.MainFrame.Pages.Infinite.Content.Track

    for _, tierFrame in ipairs(infinityFrame:GetChildren()) do
        if tierFrame:IsA("Frame") and tierFrame.Name:match("Tier") then
            local tierNum = tonumber(tierFrame.Name:match("%d+"))
            print("Tier " .. tierNum .. " visible in UI")
        end
    end
end

-- Weighted random selection (same as game)
local function getRandomWeightedItem(pool, rng)
    local totalWeight = 0
    for _, item in ipairs(pool) do
        totalWeight = totalWeight + item.Chance
    end

    local roll = rng:NextNumber() * totalWeight
    local cumulative = 0

    for _, item in ipairs(pool) do
        cumulative = cumulative + item.Chance
        if roll <= cumulative then
            return item.Item
        end
    end

    return pool[#pool].Item
end

-- Season 14 (Sakura) infinity reward pool - Updated from actual game data
local infinityPool = {
    {Chance = 10, Item = {Type = "Currency", Currency = "Gems", Amount = 750}},
    {Chance = 4, Item = {Type = "Powerup", Name = "Reroll Orb", Amount = 10}},
    {Chance = 1, Item = {Type = "Bait", Name = "Galaxy Bait", Amount = 2}},
    {Chance = 0.5, Item = {Type = "Bait", Name = "Chromatic Bait", Amount = 2}},
    {Chance = 10, Item = {Type = "Powerup", Name = "Season Sakura Egg", Amount = 16}},
    {Chance = 5, Item = {Type = "Powerup", Name = "Season Sakura Egg", Amount = 32}},
    {Chance = 2, Item = {Type = "Powerup", Name = "Season Sakura Egg", Amount = 64}},
    {Chance = 0.25, Item = {Type = "Powerup", Name = "Season Sakura Egg", Amount = 256}},
    {Chance = 0.1, Item = {Type = "Powerup", Name = "Season Sakura Egg", Amount = 1024}},
    {Chance = 3, Item = {Type = "Potion", Name = "Lucky", Level = 5, Amount = 1}},
    {Chance = 3, Item = {Type = "Potion", Name = "Speed", Level = 5, Amount = 1}},
    {Chance = 3, Item = {Type = "Potion", Name = "Mythic", Level = 5, Amount = 1}},
    {Chance = 2, Item = {Type = "Powerup", Name = "Lunar Spin Ticket", Amount = 3}},
    {Chance = 1.5, Item = {Type = "Powerup", Name = "Super Ticket", Amount = 5}},
    {Chance = 1, Item = {Type = "Powerup", Name = "Royal Key", Amount = 3}},
    {Chance = 1, Item = {Type = "Powerup", Name = "Super Key", Amount = 2}},
    {Chance = 1, Item = {Type = "Powerup", Name = "Moon Key", Amount = 3}},
    {Chance = 2, Item = {Type = "Powerup", Name = "Enchant Stone", Amount = 1}},
    {Chance = 2, Item = {Type = "Potion", Name = "Lucky", Level = 6, Amount = 1}},
    {Chance = 2, Item = {Type = "Potion", Name = "Speed", Level = 6, Amount = 1}},
    {Chance = 2, Item = {Type = "Potion", Name = "Mythic", Level = 6, Amount = 1}},
    {Chance = 1, Item = {Type = "Potion", Name = "Lucky", Level = 7, Amount = 1}},
    {Chance = 1, Item = {Type = "Potion", Name = "Speed", Level = 7, Amount = 1}},
    {Chance = 1, Item = {Type = "Potion", Name = "Mythic", Level = 7, Amount = 1}},
    {Chance = 2, Item = {Type = "Potion", Name = "Lunar New Years Lantern", Amount = 1}},
    {Chance = 1, Item = {Type = "Potion", Name = "Secret Elixir", Amount = 1}},
    {Chance = 1, Item = {Type = "Potion", Name = "Egg Elixir", Amount = 1}},
    {Chance = 1, Item = {Type = "Potion", Name = "Infinity Elixir", Amount = 1}},
    {Chance = 0.5, Item = {Type = "Potion", Name = "Secret Elixir", Amount = 3}},
    {Chance = 0.5, Item = {Type = "Potion", Name = "Egg Elixir", Amount = 3}},
    {Chance = 0.5, Item = {Type = "Potion", Name = "Infinity Elixir", Amount = 3}},
    {Chance = 0.5, Item = {Type = "Powerup", Name = "Infinity Mystery Box", Amount = 3}},
    {Chance = 0.1, Item = {Type = "Powerup", Name = "Infinity Mystery Box", Amount = 10}},
    {Chance = 0.01, Item = {Type = "Powerup", Name = "Infinity Mystery Box", Amount = 100}},
    {Chance = 1, Item = {Type = "Powerup", Name = "Shadow Crystal", Amount = 2}},
    {Chance = 0.5, Item = {Type = "Powerup", Name = "Rune Rock", Amount = 3}},
    {Chance = 0.1, Item = {Type = "Powerup", Name = "Rainbow Fragment", Amount = 1}},
    {Chance = 0.75, Item = {Type = "Powerup", Name = "Dream Shard", Amount = 3}},
    {Chance = 0.1, Item = {Type = "Pet", Name = "Sakura Sprout", Amount = 1}},
    {Chance = 0.01, Item = {Type = "Pet", Name = "Sakuralord", Amount = 1}},
    {Chance = 0.005, Item = {Type = "Pet", Name = "Blossom Chime", Amount = 1}},
    {Chance = 0.025, Item = {Type = "FishingRod", Name = "Abyssal Rod", Amount = 1}},
    {Chance = 0.0001, Item = {Type = "Pet", Name = "The Infinity Gem", Amount = 1}},
}

-- Format item for display
local function formatItem(item)
    if item.Type == "Currency" then
        return string.format("%s x%d", item.Currency, item.Amount)
    elseif item.Type == "Potion" and item.Level then
        return string.format("%s Potion Lv%d x%d", item.Name, item.Level, item.Amount)
    elseif item.Type == "Potion" then
        return string.format("%s x%d", item.Name, item.Amount)
    elseif item.Type == "Pet" then
        return string.format("🐾 %s x%d", item.Name, item.Amount)
    elseif item.Type == "FishingRod" then
        return string.format("🎣 %s x%d", item.Name, item.Amount)
    elseif item.Type == "Bait" then
        return string.format("🪱 %s x%d", item.Name, item.Amount)
    else
        return string.format("%s x%d", item.Name, item.Amount)
    end
end

-- Predict rewards for a tier
local function predictReward(seed, tier)
    local rng = Random.new(seed + tier)

    -- Get free reward
    local freeReward = getRandomWeightedItem(infinityPool, rng)

    -- Get premium reward
    local premiumReward = getRandomWeightedItem(infinityPool, rng)

    return {
        Free = freeReward,
        Premium = premiumReward
    }
end

-- USAGE: Try different seeds to find yours
print("\n=== TESTING SEED PREDICTION ===\n")

-- Test with a sample seed (you need to find your actual seed)
local testSeed = 1234567  -- REPLACE THIS

print("Testing with Seed: " .. testSeed)
print(string.rep("=", 60))

-- Predict next 50 tiers
for tier = 1, 50 do
    local rewards = predictReward(testSeed, tier)

    local requiresCost = (tier > 3 and tier % 4 == 0)
    local costMarker = requiresCost and " 💰" or ""

    print(string.format("Tier %3d%s | Free: %-30s | Premium: %s",
        tier,
        costMarker,
        formatItem(rewards.Free),
        formatItem(rewards.Premium)
    ))

    -- Highlight special tiers
    if tier % 20 == 0 then
        print("    ⭐ SPECIAL: Tier 20 bonus (Level 7 Potion)")
    end
    if tier % 35 == 0 then
        print("    ⭐ SPECIAL: Tier 35 bonus (Infinity Elixir)")
    end

    -- Highlight valuable rewards
    if rewards.Free.Type == "Pet" or rewards.Premium.Type == "Pet" then
        print("    🎉 PET DETECTED!")
    end
end

print("\n=== SEED FINDER ===")
print("To find your actual seed:")
print("1. Look at your current infinity tier rewards in-game")
print("2. Try different seed values (0 to 10,000,000)")
print("3. When predictions match your game rewards, you found it!")
print("4. Once you have your seed, you know ALL future rewards!")
