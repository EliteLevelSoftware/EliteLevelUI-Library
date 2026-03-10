--[[
    Elite Level Scripts — Key Input Screen (EliteLevelUI)
    
    Shows a branded key prompt before loading the main script.
    - Text input for key
    - Validate button
    - Get Key button (links to Discord)
    - Saves key to file for next time
    - Shows tier/expiry info on success
    
    USAGE IN YOUR SCRIPT:
    
    local KeyScreen = loadstring(game:HttpGet("https://raw.githubusercontent.com/EliteLevelSoftware/EliteLevelUI-Library/main/KeyScreen.lua"))()
    local result = KeyScreen:Show()
    -- result.success = true/false
    -- result.tier = "free"/"basic"/"premium"
    -- result.features = {"autofarm", "teleport", ...}
    -- result.key = "ELS-FREE-XXXXXXXX"
    
    if not result.success then return end
    -- Now load your main script with result.features
]]

local KeyScreen = {}

-- ── CONFIG ──
local CONFIG = {
    API_URL    = "https://elitelevelskripts.ngrok.dev",
    API_SECRET = "els-keysystem-2026-elk",
    DISCORD_INVITE = "https://discord.gg/Nfvm8tVttW",
    SAVE_FILE  = "ELS_Key.txt",
    
    COLORS = {
        Background  = Color3.fromRGB(13, 13, 13),
        Card        = Color3.fromRGB(26, 26, 26),
        Border      = Color3.fromRGB(42, 42, 42),
        Gold        = Color3.fromRGB(212, 175, 55),
        Red         = Color3.fromRGB(112, 31, 39),
        Green       = Color3.fromRGB(46, 204, 113),
        Text        = Color3.fromRGB(224, 224, 224),
        TextDim     = Color3.fromRGB(136, 136, 136),
        InputBg     = Color3.fromRGB(17, 17, 17),
        ButtonHover = Color3.fromRGB(228, 195, 90),
        Error       = Color3.fromRGB(231, 76, 60),
    }
}


-- ── SERVICES ──
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- ── HWID ──
local function GetHWID()
    local ok, r = pcall(function() if gethwid then return gethwid() end end)
    if ok and r then return tostring(r) end
    local ok2, r2 = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok2 and r2 then return tostring(r2) end
    local ok3, r3 = pcall(function()
        if identifyexecutor then local n,_ = identifyexecutor(); return n.."_"..player.UserId end
    end)
    if ok3 and r3 then return tostring(r3) end
    return "UNKNOWN_"..tostring(player.UserId)
end

-- ── SAVE/LOAD KEY ──
local function SaveKey(key)
    pcall(function()
        if writefile then writefile(CONFIG.SAVE_FILE, key) end
    end)
end

local function LoadKey()
    local ok, data = pcall(function()
        if isfile and isfile(CONFIG.SAVE_FILE) then
            return readfile(CONFIG.SAVE_FILE)
        end
    end)
    if ok and data and data ~= "" then return data end
    return nil
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

-- ── VALIDATE KEY ──
local function ValidateKey(key)
    if not key or key == "" then return {success=false, message="No key provided."} end
    key = key:gsub("%s+",""):upper()
    local result, err = PostJSON(CONFIG.API_URL.."/api/validate", {key=key, hwid=GetHWID()})
    if not result then return {success=false, message="Server unreachable: "..(err or "")} end
    return result
end


-- ── BUILD UI ──
function KeyScreen:Show()
    local C = CONFIG.COLORS
    local validationResult = nil
    local closed = false
    
    -- Destroy old UI if exists
    local old = CoreGui:FindFirstChild("ELSKeyScreen")
    if old then old:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ELSKeyScreen"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3 = C.Background
    overlay.BackgroundTransparency = 0.15
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    -- Main card
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0,380,0,420)
    card.Position = UDim2.new(0.5,-190,0.5,-210)
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel = 0
    card.Parent = screenGui
    

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0,12)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = C.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,32)
    title.Position = UDim2.new(0,0,0,24)
    title.BackgroundTransparency = 1
    title.Text = "Elite Level Scripts"
    title.TextColor3 = C.Gold
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = card

    -- Subtitle
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1,0,0,16)
    sub.Position = UDim2.new(0,0,0,56)
    sub.BackgroundTransparency = 1
    sub.Text = "KEY SYSTEM"
    sub.TextColor3 = C.Red
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 11
    sub.Parent = card


    -- Key input box
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1,-48,0,40)
    inputFrame.Position = UDim2.new(0,24,0,95)
    inputFrame.BackgroundColor3 = C.InputBg
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = card
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0,8)
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = C.Border
    inputStroke.Thickness = 1
    inputStroke.Parent = inputFrame

    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(1,-16,1,0)
    keyInput.Position = UDim2.new(0,8,0,0)
    keyInput.BackgroundTransparency = 1
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter your key (ELS-FREE-XXXXXXXX)"
    keyInput.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    keyInput.TextColor3 = C.Gold
    keyInput.Font = Enum.Font.Code
    keyInput.TextSize = 14
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = inputFrame

    -- Load saved key
    local savedKey = LoadKey()
    if savedKey then keyInput.Text = savedKey end


    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1,-48,0,20)
    statusLabel.Position = UDim2.new(0,24,0,142)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = C.TextDim
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card

    -- Helper: create button
    local function MakeButton(text, pos, color, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-48,0,38)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = color == C.Gold and C.Background or Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = true
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
        return btn
    end


    -- Validate button
    local validateBtn = MakeButton("Validate Key", UDim2.new(0,24,0,172), C.Gold, card)
    
    -- Get Key button (Discord link)
    local getKeyBtn = MakeButton("Get Key from Discord", UDim2.new(0,24,0,220), C.Red, card)

    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1,-48,0,1)
    divider.Position = UDim2.new(0,24,0,275)
    divider.BackgroundColor3 = C.Border
    divider.BorderSizePixel = 0
    divider.Parent = card

    -- Info section
    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1,-48,0,18)
    infoTitle.Position = UDim2.new(0,24,0,288)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "Tier Information"
    infoTitle.TextColor3 = C.Gold
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextSize = 13
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = card

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1,-48,0,80)
    infoText.Position = UDim2.new(0,24,0,310)
    infoText.BackgroundTransparency = 1

    infoText.Text = "Free — 24 hours\nBasic ($2.99/wk) — 7 days\nPremium ($4.99/wk) — 7 days, ALL features\n\nKeys are HWID-locked to one device."
    infoText.TextColor3 = C.TextDim
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 11
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.TextWrapped = true
    infoText.Parent = card

    -- Credit
    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1,0,0,16)
    credit.Position = UDim2.new(0,0,0,396)
    credit.BackgroundTransparency = 1
    credit.Text = "Elite Level Scripts"
    credit.TextColor3 = C.Red
    credit.Font = Enum.Font.Gotham
    credit.TextSize = 10
    credit.Parent = card


    -- ── BUTTON HANDLERS ──
    
    -- Validate button
    validateBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text:gsub("%s+","")
        if key == "" then
            statusLabel.Text = "Please enter a key."
            statusLabel.TextColor3 = C.Error
            return
        end
        
        validateBtn.Text = "Validating..."
        validateBtn.BackgroundColor3 = C.TextDim
        statusLabel.Text = "Contacting server..."
        statusLabel.TextColor3 = C.TextDim
        
        local result = ValidateKey(key)
        
        if result.success then
            SaveKey(key)
            statusLabel.Text = "Key valid! Tier: " .. (result.tier or "free"):upper() .. " — Loading script..."
            statusLabel.TextColor3 = C.Green
            validateBtn.Text = "Success!"
            validateBtn.BackgroundColor3 = C.Green
            inputStroke.Color = C.Green
            
            validationResult = result
            validationResult.key = key
            
            -- Auto-close after 1.5 seconds
            task.delay(1.5, function()
                closed = true
            end)
        else
            statusLabel.Text = result.message or "Invalid key."
            statusLabel.TextColor3 = C.Error
            validateBtn.Text = "Validate Key"
            validateBtn.BackgroundColor3 = C.Gold
            inputStroke.Color = C.Error
            
            task.delay(2, function()
                inputStroke.Color = C.Border
            end)
        end
    end)


    -- Get Key button — copy Discord link to clipboard
    getKeyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard(CONFIG.DISCORD_INVITE)
                statusLabel.Text = "Discord invite copied! Paste it in your browser."
                statusLabel.TextColor3 = C.Green
            elseif toclipboard then
                toclipboard(CONFIG.DISCORD_INVITE)
                statusLabel.Text = "Discord invite copied! Paste it in your browser."
                statusLabel.TextColor3 = C.Green
            else
                statusLabel.Text = "Join: " .. CONFIG.DISCORD_INVITE
                statusLabel.TextColor3 = C.Gold
            end
        end)
    end)

    -- Auto-validate saved key
    if savedKey and savedKey ~= "" then
        task.defer(function()
            validateBtn.Text = "Checking saved key..."
            validateBtn.BackgroundColor3 = C.TextDim
            statusLabel.Text = "Validating saved key..."
            statusLabel.TextColor3 = C.TextDim
            
            local result = ValidateKey(savedKey)
            if result.success then
                SaveKey(savedKey)
                statusLabel.Text = "Saved key valid! Tier: " .. (result.tier or "free"):upper() .. " — Loading..."
                statusLabel.TextColor3 = C.Green
                validateBtn.Text = "Success!"
                validateBtn.BackgroundColor3 = C.Green
                inputStroke.Color = C.Green
                validationResult = result
                validationResult.key = savedKey
                task.delay(1, function() closed = true end)
            else
                statusLabel.Text = "Saved key expired or invalid. Enter a new one."
                statusLabel.TextColor3 = C.Error
                validateBtn.Text = "Validate Key"
                validateBtn.BackgroundColor3 = C.Gold
                keyInput.Text = ""
            end
        end)
    end


    -- Intro animation — fade card in
    card.BackgroundTransparency = 1
    for _, child in ipairs(card:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            child.TextTransparency = 1
        end
        if child:IsA("Frame") then child.BackgroundTransparency = 1 end
    end
    
    local fadeIn = TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})
    fadeIn:Play()
    task.delay(0.1, function()
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            end
            if child:IsA("Frame") and child ~= card then
                TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            end
        end
    end)

    -- Wait for validation or close
    repeat task.wait(0.1) until closed

    -- Fade out
    for _, child in ipairs(card:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        end
    end
    TweenService:Create(card, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    task.wait(0.35)
    screenGui:Destroy()

    return validationResult or {success = false, message = "Closed."}
end

return KeyScreen
