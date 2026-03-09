--[[
    Elite Level Scripts — Key Validator v4.0
    
    Simplified tier-based system. No hardcoded feature lists.
    Server returns: tier = "free" / "basic" / "premium"
    Your script decides what each tier unlocks.
    
    USAGE:
    local result = KeySystem:Validate(key)
    if result.success then
        if result.tier == "premium" then
            -- unlock everything
        elseif result.tier == "basic" then
            -- unlock basic + free stuff
        else
            -- free tier only
        end
    end
]]

local KeySystem = {}
KeySystem.__index = KeySystem

local CONFIG = {
    API_URL    = "https://elitelevelskripts.ngrok.dev",
    API_SECRET = "els-keysystem-2026-elk",
}

local HttpService = game:GetService("HttpService")


-- ── HWID ──
local function GetHWID()
    local ok, r = pcall(function() if gethwid then return gethwid() end end)
    if ok and r then return tostring(r) end
    local ok2, r2 = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok2 and r2 then return tostring(r2) end
    local ok3, r3 = pcall(function()
        if identifyexecutor then local n,_ = identifyexecutor(); return n.."_"..game.Players.LocalPlayer.UserId end
    end)
    if ok3 and r3 then return tostring(r3) end
    return "UNKNOWN_"..tostring(game.Players.LocalPlayer.UserId)
end

-- ── HTTP ──
local function PostJSON(url, body)
    local json = HttpService:JSONEncode(body)
    local headers = {["Content-Type"] = "application/json"}
    if CONFIG.API_SECRET ~= "" then headers["x-api-key"] = CONFIG.API_SECRET end
    local ok, resp = pcall(function()
        if request then return request({Url=url,Method="POST",Headers=headers,Body=json})
        elseif http_request then return http_request({Url=url,Method="POST",Headers=headers,Body=json})
        elseif syn and syn.request then return syn.request({Url=url,Method="POST",Headers=headers,Body=json})
        elseif fluxus and fluxus.request then return fluxus.request({Url=url,Method="POST",Headers=headers,Body=json})
        else error("No HTTP method") end
    end)
    if not ok then return nil, tostring(resp) end
    if not resp or not resp.Body then return nil, "Empty response" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)
    if not ok2 then return nil, "Parse error" end
    return data
end


-- ── VALIDATE ──
function KeySystem:Validate(inputKey)
    if not inputKey or inputKey == "" then
        return { success = false, tier = nil, message = "No key provided." }
    end
    inputKey = inputKey:gsub("%s+",""):upper()
    local result, err = PostJSON(CONFIG.API_URL.."/api/validate", {key=inputKey, hwid=GetHWID()})
    if not result then
        return { success = false, tier = nil, message = "Server unreachable: "..(err or "") }
    end
    return result
end

-- ── TIER HELPERS ──
-- Use these in your scripts to gate content by tier

function KeySystem:IsFree(result)
    if not result or not result.success then return false end
    return true -- all valid keys have at least free access
end

function KeySystem:IsBasic(result)
    if not result or not result.success then return false end
    return result.tier == "basic" or result.tier == "premium"
end

function KeySystem:IsPremium(result)
    if not result or not result.success then return false end
    return result.tier == "premium"
end

-- Numeric tier level: free=1, basic=2, premium=3
function KeySystem:TierLevel(result)
    if not result or not result.success then return 0 end
    if result.tier == "premium" then return 3 end
    if result.tier == "basic" then return 2 end
    return 1
end

-- Check if user meets a minimum tier
-- Usage: KeySystem:MinTier(result, "basic") or KeySystem:MinTier(result, 2)
function KeySystem:MinTier(result, required)
    local level = self:TierLevel(result)
    if type(required) == "number" then return level >= required end
    if required == "premium" then return level >= 3 end
    if required == "basic" then return level >= 2 end
    return level >= 1
end

return KeySystem
