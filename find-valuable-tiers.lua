-- Season Tier Scanner - Find Valuable Rewards
-- Scans next 1000 tiers for rare pets and items
-- Saves results to file

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("\n" .. string.rep("=", 70))
print("        🌸 SAKURA SEASON - VALUABLE TIER FINDER 🌸")
print(string.rep("=", 70) .. "\n")

-- Get current tier
local LocalData = require(RS.Client.Framework.Services.LocalData)
local playerData = LocalData:Get()

if not playerData or not playerData.Season then
    print("❌ Error: Could not access season data!")
    return
end

local currentTier = playerData.Season.Level
local seed = playerData.Season.Seed

print("📊 Your Season Info:")
print("   Seed: " .. seed)
print("   Current Tier: " .. currentTier)
print("   Premium: " .. tostring(playerData.Season.Premium))
print("   IsInfinite: " .. tostring(playerData.Season.IsInfinite))
print("")

-- Sakura Season Pool
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

-- Weighted random selection
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

-- Check if item is valuable (one we're looking for)
local function isValuableItem(item)
    if item.Type == "Pet" then
        if item.Name == "Sakura Sprout" or
           item.Name == "Sakuralord" or
           item.Name == "Blossom Chime" or
           item.Name == "The Infinity Gem" then
            return true
        end
    elseif item.Type == "FishingRod" and item.Name == "Abyssal Rod" then
        return true
    elseif item.Type == "Powerup" and item.Name == "Dream Shard" and item.Amount == 3 then
        return true
    end
    return false
end

-- Format item for display
local function formatItem(item)
    if item.Type == "Pet" then
        return "🐾 " .. item.Name
    elseif item.Type == "FishingRod" then
        return "🎣 " .. item.Name
    elseif item.Type == "Powerup" then
        return "⚡ " .. item.Name .. " x" .. item.Amount
    else
        return item.Name
    end
end

-- Scan tiers
print("🔍 Scanning next 1000 tiers from tier " .. currentTier .. "...")
print("   Looking for: Sakura Sprout, Sakuralord, Blossom Chime,")
print("                The Infinity Gem, Abyssal Rod, Dream Shard x3")
print("")

local findings = {}
local startTier = currentTier
local endTier = currentTier + 1000

for tier = startTier, endTier do
    local rng = Random.new(seed + tier)

    -- Get free reward
    local freeReward = getRandomWeightedItem(infinityPool, rng)

    -- Get premium reward
    local premiumReward = getRandomWeightedItem(infinityPool, rng)

    -- Check if either reward is valuable
    if isValuableItem(freeReward) then
        table.insert(findings, {
            tier = tier,
            slot = "Free",
            item = freeReward
        })
    end

    if isValuableItem(premiumReward) then
        table.insert(findings, {
            tier = tier,
            slot = "Premium",
            item = premiumReward
        })
    end
end

print("✅ Scan complete! Found " .. #findings .. " valuable rewards.\n")

-- Build output
local output = string.rep("=", 70) .. "\n"
output = output .. "        🌸 SAKURA SEASON - VALUABLE TIER FINDER 🌸\n"
output = output .. string.rep("=", 70) .. "\n\n"

output = output .. "📊 Your Season Info:\n"
output = output .. "   Seed: " .. seed .. "\n"
output = output .. "   Current Tier: " .. currentTier .. "\n"
output = output .. "   Scan Range: Tier " .. startTier .. " - " .. endTier .. "\n"
output = output .. "   Premium Pass: " .. tostring(playerData.Season.Premium) .. "\n\n"

output = output .. "🎯 VALUABLE ITEMS FOUND: " .. #findings .. "\n"
output = output .. string.rep("=", 70) .. "\n\n"

-- Count by type
local counts = {
    ["Sakura Sprout"] = 0,
    ["Sakuralord"] = 0,
    ["Blossom Chime"] = 0,
    ["The Infinity Gem"] = 0,
    ["Abyssal Rod"] = 0,
    ["Dream Shard"] = 0
}

for _, finding in ipairs(findings) do
    local name = finding.item.Name
    if counts[name] then
        counts[name] = counts[name] + 1
    end
end

output = output .. "📈 Summary:\n"
output = output .. string.format("   🐾 Sakura Sprout: %d times\n", counts["Sakura Sprout"])
output = output .. string.format("   🐾 Sakuralord: %d times\n", counts["Sakuralord"])
output = output .. string.format("   🐾 Blossom Chime: %d times\n", counts["Blossom Chime"])
output = output .. string.format("   🐾 The Infinity Gem: %d times\n", counts["The Infinity Gem"])
output = output .. string.format("   🎣 Abyssal Rod: %d times\n", counts["Abyssal Rod"])
output = output .. string.format("   ⚡ Dream Shard x3: %d times\n\n", counts["Dream Shard"])

output = output .. string.rep("=", 70) .. "\n"
output = output .. "📋 DETAILED FINDINGS:\n"
output = output .. string.rep("=", 70) .. "\n\n"

-- Sort findings by tier
table.sort(findings, function(a, b) return a.tier < b.tier end)

for _, finding in ipairs(findings) do
    local tiersAway = finding.tier - currentTier
    local requiresCost = (finding.tier > 3 and finding.tier % 4 == 0)
    local costMarker = requiresCost and " 💰" or ""

    output = output .. string.format("Tier %d%s (+%d tiers) | %s | %s\n",
        finding.tier,
        costMarker,
        tiersAway,
        finding.slot,
        formatItem(finding.item)
    )
end

output = output .. "\n" .. string.rep("=", 70) .. "\n"
output = output .. "💡 NOTES:\n"
output = output .. "   - Tiers marked with 💰 require coins to unlock\n"
output = output .. "   - Premium rewards only available if you own Premium Pass\n"
output = output .. "   - Scan based on seed: " .. seed .. "\n"
output = output .. "   - Results are deterministic (won't change unless seed changes)\n"
output = output .. "\n⚠️ IMPORTANT:\n"
output = output .. "   This predictor may not be 100% accurate due to:\n"
output = output .. "   - PassLuck multipliers modifying reward weights\n"
output = output .. "   - Special tier bonuses (every 20th/35th tier)\n"
output = output .. "   - Server-side adjustments to the pool\n"
output = output .. "\n💎 NEXT CLOSEST VALUABLE REWARDS:\n"

-- Show next 5 valuable items
for i = 1, math.min(5, #findings) do
    local finding = findings[i]
    local tiersAway = finding.tier - currentTier
    output = output .. string.format("   %d. Tier %d (+%d) - %s in %s slot\n",
        i,
        finding.tier,
        tiersAway,
        formatItem(finding.item),
        finding.slot
    )
end

output = output .. "\n" .. string.rep("=", 70) .. "\n"
output = output .. "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
output = output .. string.rep("=", 70) .. "\n"

-- Save to file
local filename = "SakuraSeason_ValuableTiers_" .. seed .. ".txt"
writefile(filename, output)

-- Print to console
print(output)

print("\n✅ Results saved to: " .. filename)
print("📂 Check your executor's workspace folder!")
print("\n🎯 Next valuable reward: Tier " .. (findings[1] and findings[1].tier or "None") ..
      " (" .. (findings[1] and formatItem(findings[1].item) or "N/A") .. ")")
