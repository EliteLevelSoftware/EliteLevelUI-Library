--[[
    Elite Level Scripts — Tier Gate Helper
    
    Wraps your UI creation so locked features show a 🔒 and 
    prompt users to upgrade when clicked.
    
    USAGE:
    local Gate = loadstring(game:HttpGet("https://raw.githubusercontent.com/EliteLevelSoftware/EliteLevelUI-Library/main/TierGate.lua"))()
    Gate:SetTier(result.tier) -- "free", "basic", or "premium"
    
    -- Then instead of creating toggles directly:
    Gate:Toggle(Tab, "Auto Farm", "free", function(val) ... end)
    Gate:Toggle(Tab, "Kill Aura", "premium", function(val) ... end)
    
    -- The second argument is the MINIMUM tier required.
    -- If user's tier is lower, the toggle shows as locked.
]]

local TierGate = {}
TierGate.__index = TierGate

local TIER_LEVELS = { free = 1, basic = 2, premium = 3 }
local TIER_NAMES = { "Free", "Basic", "Premium" }
local currentTier = "free"
local currentLevel = 1


function TierGate:SetTier(tier)
    currentTier = tier or "free"
    currentLevel = TIER_LEVELS[currentTier] or 1
end

function TierGate:GetTier()
    return currentTier
end

function TierGate:CanAccess(requiredTier)
    local required = TIER_LEVELS[requiredTier] or 1
    return currentLevel >= required
end

-- Get the display name for a locked feature
local function lockLabel(name, requiredTier)
    return "🔒 " .. name .. " [" .. (TIER_NAMES[TIER_LEVELS[requiredTier] or 1]) .. "+]"
end

local function unlockLabel(name)
    return name
end


-- ══════════════════════════════════════
-- RAYFIELD SUPPORT
-- ══════════════════════════════════════

function TierGate:RayfieldToggle(tab, name, requiredTier, callback, default)
    if self:CanAccess(requiredTier) then
        -- User has access — create normal toggle
        return tab:CreateToggle({
            Name = name,
            CurrentValue = default or false,
            Flag = name:gsub("%s+",""),
            Callback = callback or function() end,
        })
    else
        -- Locked — create a toggle that shows upgrade prompt
        return tab:CreateToggle({
            Name = lockLabel(name, requiredTier),
            CurrentValue = false,
            Flag = name:gsub("%s+","") .. "_locked",
            Callback = function(val)
                -- Force it back off
                -- Show notification
                if Rayfield and Rayfield.Notify then
                    Rayfield:Notify({
                        Title = "Feature Locked",
                        Content = name .. " requires " .. TIER_NAMES[TIER_LEVELS[requiredTier] or 1] .. " tier or higher.\nUpgrade at discord.gg/VHhBBCqfDa",
                        Duration = 4,
                    })
                end
            end,
        })
    end
end


-- ══════════════════════════════════════
-- ELITELEVELUI SUPPORT
-- ══════════════════════════════════════

function TierGate:ELUIToggle(tab, name, requiredTier, callback, default)
    if self:CanAccess(requiredTier) then
        return tab:CreateToggle({
            Name = name,
            CurrentValue = default or false,
            Flag = name:gsub("%s+",""),
            Callback = callback or function() end,
        })
    else
        return tab:CreateToggle({
            Name = lockLabel(name, requiredTier),
            CurrentValue = false,
            Flag = name:gsub("%s+","") .. "_locked",
            Callback = function(val)
                -- Notify via EliteLevelUI if available
                pcall(function()
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Feature Locked",
                        Text = name .. " requires " .. TIER_NAMES[TIER_LEVELS[requiredTier] or 1] .. "+\nUpgrade in our Discord!",
                        Duration = 4,
                    })
                end)
            end,
        })
    end
end


-- ══════════════════════════════════════
-- UNIVERSAL TOGGLE (auto-detects UI)
-- ══════════════════════════════════════

function TierGate:Toggle(tab, name, requiredTier, callback, default)
    -- Try EliteLevelUI style first, fall back to Rayfield
    if self:CanAccess(requiredTier) then
        return tab:CreateToggle({
            Name = name,
            CurrentValue = default or false,
            Flag = name:gsub("%s+",""),
            Callback = callback or function() end,
        })
    else
        return tab:CreateToggle({
            Name = lockLabel(name, requiredTier),
            CurrentValue = false,
            Flag = name:gsub("%s+","") .. "_locked",
            Callback = function(val)
                -- Try Rayfield notification
                pcall(function()
                    if Rayfield and Rayfield.Notify then
                        Rayfield:Notify({
                            Title = "Feature Locked",
                            Content = name .. " requires " .. TIER_NAMES[TIER_LEVELS[requiredTier] or 1] .. " tier or higher.\nUpgrade at discord.gg/VHhBBCqfDa",
                            Duration = 4,
                        })
                        return
                    end
                end)
                -- Fallback to Roblox notification
                pcall(function()
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Feature Locked",
                        Text = name .. " requires " .. TIER_NAMES[TIER_LEVELS[requiredTier] or 1] .. "+\nUpgrade in our Discord!",
                        Duration = 4,
                    })
                end)
            end,
        })
    end
end


-- ══════════════════════════════════════
-- BUTTON / LABEL HELPERS
-- ══════════════════════════════════════

-- Gate a button — locked buttons show upgrade prompt
function TierGate:Button(tab, name, requiredTier, callback)
    if self:CanAccess(requiredTier) then
        return tab:CreateButton({
            Name = name,
            Callback = callback or function() end,
        })
    else
        return tab:CreateButton({
            Name = lockLabel(name, requiredTier),
            Callback = function()
                pcall(function()
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Feature Locked",
                        Text = name .. " requires " .. TIER_NAMES[TIER_LEVELS[requiredTier] or 1] .. "+",
                        Duration = 4,
                    })
                end)
            end,
        })
    end
end

-- Gate a section — returns true/false so you can wrap blocks of code
function TierGate:Section(requiredTier)
    return self:CanAccess(requiredTier)
end

return TierGate
