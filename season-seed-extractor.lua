-- Season Seed Extractor
-- Hooks game functions to extract your Season Seed

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("=== SEASON SEED EXTRACTOR ===\n")

-- Method 1: Hook the SeasonUtil module
local SeasonUtil = require(RS.Shared.Utils.Stats.SeasonUtil)

-- Store original function
local originalGetInfiniteSegment = SeasonUtil.GetInfiniteSegment

-- Hook it
SeasonUtil.GetInfiniteSegment = function(self, playerData, seasonData, tier, useFixed)
    -- Extract the seed!
    if playerData.Season and playerData.Season.Seed then
        print("🎯 YOUR SEASON SEED: " .. playerData.Season.Seed)
        print("Save this number! It determines all your infinite rewards.")
        print(string.rep("=", 60))

        -- Also print current tier info
        print("Current Level: " .. (playerData.Season.Level or 0))
        print("Is Infinite: " .. tostring(playerData.Season.IsInfinite or false))
        print("Premium: " .. tostring(playerData.Season.Premium or false))
        print("")
    end

    -- Call original function
    return originalGetInfiniteSegment(self, playerData, seasonData, tier, useFixed)
end

print("✓ Hook installed!")
print("Now open the Season Pass UI and scroll through infinite tiers.")
print("Your seed will be printed above.\n")

-- Method 2: Monitor network calls
local Bindable = require(RS.Shared.Framework.Network.Bindable)

-- Hook GetSeasonXP if it exists
spawn(function()
    wait(2)

    -- Try to access player data directly
    local success, result = pcall(function()
        -- This might work if client has access to local data
        local LocalData = require(RS.Client.Framework.Services.LocalData)

        if LocalData and LocalData.Session then
            local session = LocalData.Session
            if session.Season then
                print("📦 FOUND VIA LocalData:")
                print("Season Seed: " .. tostring(session.Season.Seed))
                print("Level: " .. tostring(session.Season.Level))
                print(string.rep("=", 60))
            end
        end
    end)

    if not success then
        print("⚠️ LocalData access failed (expected on some executors)")
        print("Use Method 1: Open Season Pass UI to trigger hook")
    end
end)

-- Method 3: Reverse-engineer from known rewards
print("\n=== ALTERNATIVE: BRUTE FORCE SEED FINDER ===")
print("If hooks don't work, use this method:")
print("")
print("1. Open Season Pass and look at 3 consecutive tier rewards")
print("2. Note exactly what they are (item name, amount, type)")
print("3. Run the brute force script below")
print("")

-- Simplified brute force (checks 100,000 seeds - takes a few seconds)
local function bruteForceFind(tier1Reward, tier2Reward, tier3Reward)
    print("Searching for seed... (this may take 10-30 seconds)")

    -- You would compare against your actual rewards
    -- Example: tier1Reward = "Gems x750"

    for seed = 0, 10000000, 100 do  -- Check every 100th seed
        local rng1 = Random.new(seed + 1)
        local rng2 = Random.new(seed + 2)
        local rng3 = Random.new(seed + 3)

        -- Generate rewards (simplified)
        -- Compare against tier1Reward, tier2Reward, tier3Reward

        -- If match found:
        -- print("FOUND SEED: " .. seed)
        -- break
    end
end

print("\n💡 TIP: Once you have your seed, you can:")
print("- Predict ALL future infinite rewards")
print("- Know which tiers have legendary pets")
print("- Skip to specific tiers for items you want")
print("- Calculate exact cost to reach any tier")
