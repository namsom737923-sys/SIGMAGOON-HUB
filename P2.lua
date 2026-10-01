--============================================================
-- SIGMAGOON HUB v3.1 — P2/2 (UI)
--============================================================
if not _G.SG_Loaded then
    warn("[SG] ต้องรัน P1 ก่อน!")
    return
end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = _G.SG_CONFIG
local laserFolder = _G.SG_laserFolder
local getHRP = _G.SG_getHRP
local getHum = _G.SG_getHum
local safeFindAtt = _G.SG_safeFindAtt
local isSameTeam = _G.SG_isSameTeam
local createLaser = _G.SG_createLaser
local destroyLaser = _G.SG_destroyLaser
local updateLaser = _G.SG_updateLaser
local findBestTarget = _G.SG_findBestTarget
local predictPos = _G.SG_predictPos
local startFly = _G.SG_startFly
local stopFly = _G.SG_stopFly
local applyNC = _G.SG_applyNC
local revertNC = _G.SG_revertNC
local setInvisible = _G.SG_setInvisible
local setGodmode = _G.SG_setGodmode

--============================================================
-- GRAPHICS
--============================================================
local origGraphics = nil
local function applyLowGraphics()
    pcall(function()
        if not origGraphics then
            origGraphics = {
                GlobalShadows = Lighting.GlobalShadows,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                Brightness = Lighting.Brightness,
            }
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Atmosphere") then
                obj.Density=0; obj.Haze=0; obj.Glare=0
            elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") then
                obj.Enabled = false
            end
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end)
end
local function revertGraphics()
    pcall(function()
        if not origGraphics then return end
        Lighting.GlobalShadows = origGraphics.GlobalShadows
        Lighting.FogEnd = origGraphics.FogEnd
        Lighting.FogStart = origGraphics.FogStart
        Lighting.Brightness = origGraphics.Brightness
    end)
end

--============================================================
-- ESP
--============================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "__ESP_Container"
espFolder.Parent = camera

local espData = {}

local function destroyESPEntry(model)
    local entry = espData[model]
    if not entry then return end
    if entry.highlight and entry.highlight.Parent then entry.highlight:Destroy() end
    if entry.billboard and entry.billboard.Parent then entry.billboard:Destroy() end
    espData[model] = nil
end

local function createESPEntry(model, color, opts)
    if not model or espData[model] then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    opts = opts or {}
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 180, 0, 44)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = CONFIG.ESPMaxDist
    billboard.Parent = espFolder
    billboard.Adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = model.Name
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(255,255,255)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = billboard
    espData[model] = {
        highlight = highlight, billboard = billboard,
        nameLabel = nameLabel, distLabel = distLabel,
        color = color,
        showName = opts.showName, showDistance = opts.showDistance,
        showHealth = opts.showHealth,
        isPlayer = opts.isPlayer, isVehicle = opts.isVehicle,
    }
end

local function updateESPTexts()
    local camPos = camera.CFrame.Position
    for model, entry in pairs(espData) do
        if not model.Parent or not entry.billboard.Parent then
            destroyESPEntry(model)
            continue
        end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        local head = model:FindFirstChild("Head")
        local refPart = head or hrp
        if not refPart then destroyESPEntry(model); continue end
        entry.billboard.Adornee = refPart
        local dist = (refPart.Position - camPos).Magnitude
        local t = math.clamp(1 - (dist/CONFIG.ESPMaxDist), 0, 1)
        local size = CONFIG.ESPTextSizeMin + (CONFIG.ESPTextSizeMax - CONFIG.ESPTextSizeMin)*t
        if entry.showName then
            entry.nameLabel.TextSize = size
            entry.nameLabel.Text = model.Name
        else
            entry.nameLabel.Text = ""
        end
        local info = {}
        if entry.showDistance then table.insert(info, string.format("%d m", math.floor(dist))) end
        if entry.showHealth then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum then table.insert(info, string.format("HP %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))) end
        end
        entry.distLabel.Text = table.concat(info, "  •  ")
        entry.distLabel.TextSize = math.max(8, size-2)
    end
end

local function scanPlayerESP()
    if not CONFIG.PlayerESPEnabled then
        for model, entry in pairs(espData) do
            if entry.isPlayer then destroyESPEntry(model) end
        end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if not (CONFIG.PlayerESPTeamCheck and isSameTeam(plr)) then
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart")
                    and char:FindFirstChildOfClass("Humanoid")
                    and char.Humanoid.Health>0 then
                    if not espData[char] then
                        createESPEntry(char, CONFIG.PlayerESPColor, {
                            showName = CONFIG.PlayerESPShowName,
                            showDistance = CONFIG.PlayerESPShowDistance,
                            showHealth = false, isPlayer = true,
                        })
                    else
                        local e = espData[char]
                        e.highlight.FillColor = CONFIG.PlayerESPColor
                        e.highlight.OutlineColor = CONFIG.PlayerESPColor
                    end
                end
            else
                local char = plr.Character
                if char and espData[char] then destroyESPEntry(char) end
            end
        end
    end
end

local function scanBotESP()
    if not CONFIG.BotESPEnabled then
        for model, entry in pairs(espData) do
            if not entry.isPlayer and not entry.isVehicle then destroyESPEntry(model) end
        end
        return
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hum and hrp and hum.Health>0 then
                if not espData[obj] then
                    createESPEntry(obj, CONFIG.BotESPColor, {
                        showName = CONFIG.BotESPShowName,
                        showHealth = CONFIG.BotESPShowHealth,
                        isPlayer = false,
                    })
                end
            end
        end
    end
end

local function scanVehicleESP()
    if not CONFIG.VehicleESPEnabled then
        for model, entry in pairs(espData) do
            if entry.isVehicle then destroyESPEntry(model) end
        end
        return
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            local hasSeat = obj:FindFirstChildWhichIsA("VehicleSeat", true)
            local hasTank = obj.Name:lower():find("tank") or obj.Name:lower():find("vehicle")
            if (hasSeat or hasTank) and not Players:GetPlayerFromCharacter(obj) then
                if not espData[obj] then
                    createESPEntry(obj, CONFIG.VehicleESPColor, {
                        showName = true, showHealth = true, isVehicle = true,
                    })
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    for model, entry in pairs(espData) do
        if not model.Parent then destroyESPEntry(model) end
    end
end)

--============================================================
-- UI COLORS
--============================================================
local COL = {
    bg = Color3.fromRGB(15,15,18),
    bg2 = Color3.fromRGB(22,22,28),
    bg3 = Color3.fromRGB(30,30,38),
    accent = Color3.fromRGB(0,170,255),
    text = Color3.fromRGB(235,235,240),
    textDim = Color3.fromRGB(150,150,165),
    on = Color3.fromRGB(0,200,100),
    off = Color3.fromRGB(60,60,70),
    red = Color3.fromRGB(200,60,60),
    green = Color3.fromRGB(0,255,80),
    warn = Color3.fromRGB(255,180,60),
}

for _, g in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
    if g.Name:find("SIGMAGOON") then g:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "SIGMAGOON_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

print("[SG v3.1] Gui สร้างแล้ว")

local mainW, mainH = 660, 440
local main = Instance.new("Frame")
main.Size = UDim2.new(0, mainW, 0, mainH)
main.Position = UDim2.new(0.5, -mainW/2, 0.5, -mainH/2)
main.BackgroundColor3 = COL.bg
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COL.accent
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.4
mainStroke.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = COL.bg2
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = COL.bg2
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -140, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "SIGMAGOON HUB  |  v3.1"
titleText.TextColor3 = COL.text
titleText.TextSize = 15
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 24, 0, 20)
collapseBtn.Position = UDim2.new(1, -42, 0.5, -10)
collapseBtn.BackgroundColor3 = COL.red
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "➖"
collapseBtn.TextColor3 = Color3.fromRGB(255,255,255)
collapseBtn.TextSize = 13
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.Parent = titleBar
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0,5)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 170, 1, -52)
sidebar.Position = UDim2.new(0, 8, 0, 46)
sidebar.BackgroundColor3 = COL.bg2
sidebar.BorderSizePixel = 0
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,8)

local profileCard = Instance.new("Frame")
profileCard.Size = UDim2.new(1, -12, 0, 106)
profileCard.Position = UDim2.new(0, 6, 0, 6)
profileCard.BackgroundColor3 = COL.bg3
profileCard.BorderSizePixel = 0
profileCard.Parent = sidebar
Instance.new("UICorner", profileCard).CornerRadius = UDim.new(0,8)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 42, 0, 42)
avatar.Position = UDim2.new(0, 8, 0, 8)
avatar.BackgroundColor3 = COL.bg
avatar.BorderSizePixel = 0
avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
avatar.Parent = profileCard
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0,8)

local nameLbl = Instance.new("TextLabel")
nameLbl.Size = UDim2.new(1, -60, 0, 16)
nameLbl.Position = UDim2.new(0, 56, 0, 8)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = player.DisplayName
nameLbl.TextColor3 = COL.text
nameLbl.TextSize = 13
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
nameLbl.Parent = profileCard

local userLbl = Instance.new("TextLabel")
userLbl.Size = UDim2.new(1, -60, 0, 14)
userLbl.Position = UDim2.new(0, 56, 0, 24)
userLbl.BackgroundTransparency = 1
userLbl.Text = "@" .. player.Name
userLbl.TextColor3 = COL.accent
userLbl.TextSize = 11
userLbl.Font = Enum.Font.Gotham
userLbl.TextXAlignment = Enum.TextXAlignment.Left
userLbl.Parent = profileCard

local fpsLbl = Instance.new("TextLabel")
fpsLbl.Size = UDim2.new(1, -60, 0, 14)
fpsLbl.Position = UDim2.new(0, 56, 0, 38)
fpsLbl.BackgroundTransparency = 1
fpsLbl.Text = "FPS 60"
fpsLbl.TextColor3 = COL.warn
fpsLbl.TextSize = 11
fpsLbl.Font = Enum.Font.GothamBold
fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
fpsLbl.Parent = profileCard

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, -16, 0, 14)
healthText.Position = UDim2.new(0, 8, 0, 58)
healthText.BackgroundTransparency = 1
healthText.Text = "Health --/--"
healthText.TextColor3 = COL.green
healthText.TextSize = 11
healthText.Font = Enum.Font.GothamBold
healthText.TextXAlignment = Enum.TextXAlignment.Left
healthText.Parent = profileCard

local healthBarBg = Instance.new("Frame")
healthBarBg.Size = UDim2.new(1, -16, 0, 5)
healthBarBg.Position = UDim2.new(0, 8, 0, 76)
healthBarBg.BackgroundColor3 = COL.off
healthBarBg.BorderSizePixel = 0
healthBarBg.Parent = profileCard
Instance.new("UICorner", healthBarBg).CornerRadius = UDim.new(1,0)

local healthBarFill = Instance.new("Frame")
healthBarFill.Size = UDim2.new(1, 0, 1, 0)
healthBarFill.BackgroundColor3 = COL.green
healthBarFill.BorderSizePixel = 0
healthBarFill.Parent = healthBarBg
Instance.new("UICorner", healthBarFill).CornerRadius = UDim.new(1,0)

local mapLbl = Instance.new("TextLabel")
mapLbl.Size = UDim2.new(1, -12, 0, 14)
mapLbl.Position = UDim2.new(0, 6, 0, 88)
mapLbl.BackgroundTransparency = 1
mapLbl.Text = "📍 Map: " .. game.PlaceId
mapLbl.TextColor3 = COL.text
mapLbl.TextSize = 10
mapLbl.Font = Enum.Font.GothamBold
mapLbl.TextXAlignment = Enum.TextXAlignment.Left
mapLbl.TextTruncate = Enum.TextTruncate.AtEnd
mapLbl.Parent = sidebar

local idLbl = Instance.new("TextLabel")
idLbl.Size = UDim2.new(1, -12, 0, 14)
idLbl.Position = UDim2.new(0, 6, 0, 102)
idLbl.BackgroundTransparency = 1
idLbl.Text = "🆔 " .. tostring(game.PlaceId)
idLbl.TextColor3 = COL.textDim
idLbl.TextSize = 10
idLbl.Font = Enum.Font.Gotham
idLbl.TextXAlignment = Enum.TextXAlignment.Left
idLbl.Parent = sidebar

local sidebarBtnHolder = Instance.new("Frame")
sidebarBtnHolder.Size = UDim2.new(1, -12, 0, 220)
sidebarBtnHolder.Position = UDim2.new(0, 6, 0, 124)
sidebarBtnHolder.BackgroundTransparency = 1
sidebarBtnHolder.Parent = sidebar

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -186, 1, -52)
contentArea.Position = UDim2.new(0, 178, 0, 46)
contentArea.BackgroundColor3 = COL.bg2
contentArea.BorderSizePixel = 0
contentArea.Parent = main
Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0,8)

local function makePage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = COL.accent
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = false
    p.Parent = contentArea
    Instance.new("UICorner", p).CornerRadius = UDim.new(0,8)
    return p
end

local pageMain = makePage()
local pageMain2 = makePage()
local pageEyes = makePage()
local pageBots = makePage()
local pageVehicle = makePage()
local pageSettings = makePage()
pageMain.Visible = true

local function buildContent(page)
    local ctx = { y = 10 }
    function ctx.section(text)
        local h = Instance.new("Frame")
        h.Size = UDim2.new(1, -20, 0, 24)
        h.Position = UDim2.new(0, 10, 0, ctx.y)
        h.BackgroundColor3 = COL.bg3
        h.BackgroundTransparency = 0.4
        h.BorderSizePixel = 0
        h.Parent = page
        Instance.new("UICorner", h).CornerRadius = UDim.new(0,6)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -16, 1, 0)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = COL.accent
        l.TextSize = 12
        l.Font = Enum.Font.GothamBold
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = h
        ctx.y = ctx.y + 30
    end
    function ctx.label(text, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 16)
        l.Position = UDim2.new(0, 10, 0, ctx.y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or COL.textDim
        l.TextSize = 11
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = page
        ctx.y = ctx.y + 18
        return l
    end
    function ctx.toggle(label, get, set)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 34)
        row.Position = UDim2.new(0, 10, 0, ctx.y)
        row.BackgroundColor3 = COL.bg3
        row.BackgroundTransparency = 0.4
        row.BorderSizePixel = 0
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = COL.text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 40, 0, 20)
        sw.Position = UDim2.new(1, -48, 0.5, -10)
        sw.BackgroundColor3 = COL.off
        sw.BorderSizePixel = 0
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = row
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.BorderSizePixel = 0
        knob.Parent = sw
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local function refresh()
            if get() then
                Tween:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = COL.on }):Play()
                Tween:Create(knob, TweenInfo.new(0.15), { Position = UDim2.new(1, -18, 0.5, -8) }):Play()
            else
                Tween:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = COL.off }):Play()
                Tween:Create(knob, TweenInfo.new(0.15), { Position = UDim2.new(0, 2, 0.5, -8) }):Play()
            end
        end
        sw.MouseButton1Click:Connect(function() set(not get()); refresh() end)
        refresh()
        ctx.y = ctx.y + 38
    end
    function ctx.slider(label, minV, maxV, get, set)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -20, 0, 46)
        holder.Position = UDim2.new(0, 10, 0, ctx.y)
        holder.BackgroundColor3 = COL.bg3
        holder.BackgroundTransparency = 0.4
        holder.BorderSizePixel = 0
        holder.Parent = page
        Instance.new("UICorner", holder).CornerRadius = UDim.new(0,6)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = COL.text
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = holder
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -20, 0, 5)
        bg.Position = UDim2.new(0, 10, 0, 28)
        bg.BackgroundColor3 = COL.off
        bg.BorderSizePixel = 0
        bg.Parent = holder
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = COL.accent
        fill.BorderSizePixel = 0
        fill.Parent = bg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = bg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local function refresh()
            local v = get()
            local rel = math.clamp((v-minV)/(maxV-minV), 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            lbl.Text = label .. ": " .. tostring(math.floor(v))
        end
        local dragging = false
        local function update(inputX)
            local rel = math.clamp((inputX - bg.AbsolutePosition.X) / math.max(bg.AbsoluteSize.X, 1), 0, 1)
            set(minV + rel*(maxV-minV))
            refresh()
        end
        bg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; update(input.Position.X)
            end
        end)
        UserInput.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)
        UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        refresh()
        ctx.y = ctx.y + 52
    end
    function ctx.button(text, color, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 30)
        b.Position = UDim2.new(0, 10, 0, ctx.y)
        b.BackgroundColor3 = color or COL.accent
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.TextSize = 12
        b.Font = Enum.Font.GothamBold
        b.Parent = page
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        if callback then b.MouseButton1Click:Connect(callback) end
        ctx.y = ctx.y + 36
        return b
    end
    function ctx.colorPicker(label, get, set)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -20, 0, 34)
        holder.Position = UDim2.new(0, 10, 0, ctx.y)
        holder.BackgroundColor3 = COL.bg3
        holder.BackgroundTransparency = 0.4
        holder.BorderSizePixel = 0
        holder.Parent = page
        Instance.new("UICorner", holder).CornerRadius = UDim.new(0,6)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = COL.text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = holder
        local preview = Instance.new("Frame")
        preview.Size = UDim2.new(0, 40, 0, 20)
        preview.Position = UDim2.new(1, -48, 0.5, -10)
        preview.BackgroundColor3 = get()
        preview.BorderSizePixel = 0
        preview.Parent = holder
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0,4)
        local colors = {
            Color3.fromRGB(255,40,40),
            Color3.fromRGB(255,180,40),
            Color3.fromRGB(0,255,80),
            Color3.fromRGB(80,160,255),
            Color3.fromRGB(255,80,255),
            Color3.fromRGB(255,255,255),
        }
        local idx = 1
        for i, c in ipairs(colors) do
            if c == get() then idx = i break end
        end
        preview.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                idx = idx % #colors + 1
                set(colors[idx])
                preview.BackgroundColor3 = colors[idx]
            end
        end)
        ctx.y = ctx.y + 38
    end
    function ctx.finalize()
        page.CanvasSize = UDim2.new(0, 0, 0, ctx.y + 10)
    end
    return ctx
end

-- PAGE 1: หน้าหลัก
local ctxMain = buildContent(pageMain)
ctxMain.section("⚙ การเคลื่อนไหว")
ctxMain.toggle("บิน", function() return CONFIG.FlyEnabled end,
    function(v) CONFIG.FlyEnabled = v; if v then startFly() else stopFly() end end)
ctxMain.slider("ความเร็วบิน", 1, 500, function() return CONFIG.FlySpeed end,
    function(v) CONFIG.FlySpeed = v end)
ctxMain.toggle("วิ่งเร็ว", function() return CONFIG.SpeedEnabled end,
    function(v) CONFIG.SpeedEnabled = v; if not v then local h=getHum(); if h then h.WalkSpeed=16 end end end)
ctxMain.slider("ความเร็ววิ่ง", 16, 500, function() return CONFIG.SpeedValue end,
    function(v) CONFIG.SpeedValue = v end)
ctxMain.section("🦘 กระโดด / ซ่อน / อมตะ")
ctxMain.toggle("กระโดดไม่จำกัด", function() return CONFIG.JumpEnabled end,
    function(v) CONFIG.JumpEnabled = v end)
ctxMain.slider("ความสูงกระโดด", 50, 500, function() return CONFIG.JumpPower end,
    function(v) CONFIG.JumpPower = v end)
ctxMain.toggle("เดินทะลุหญ้า", function() return CONFIG.NoCollideEnabled end,
    function(v) CONFIG.NoCollideEnabled = v; if v then applyNC() else revertNC() end end)
ctxMain.toggle("หายตัว", function() return CONFIG.InvisibleEnabled end,
    function(v) CONFIG.InvisibleEnabled = v; setInvisible(v) end)
ctxMain.toggle("อมตะ", function() return CONFIG.GodmodeEnabled end,
    function(v) CONFIG.GodmodeEnabled = v; setGodmode(v) end)
ctxMain.section("📍 จุดวาร์ป")
ctxMain.button("💾 ตั้งจุดสปอร์ตปัจจุบัน", COL.on, _G.SG_saveCurrentSpawn)
ctxMain.button("🚀 วาร์ปไปจุดสปอร์ต", COL.accent, _G.SG_warpToSpawn)
ctxMain.button("💀 บันทึกจุดตาย", Color3.fromRGB(150,80,80), _G.SG_saveDeathPoint)
ctxMain.button("⚰ วาร์ปไปจุดตาย", Color3.fromRGB(200,80,80), _G.SG_warpToDeath)
ctxMain.button("🗑 เคลียร์", COL.red, _G.SG_clearSpawn)
ctxMain.section("🌐 Teleport Points")
local tpListLabel = ctxMain.label("ยังไม่มีจุด", COL.textDim)
ctxMain.button("➕ เพิ่มจุด", COL.accent, function()
    _G.SG_addTeleportPoint()
    tpListLabel.Text = "มี " .. #_G.SG_getTeleportPoints() .. " จุด"
end)
ctxMain.button("➖ ลบจุดล่าสุด", COL.warn, function()
    _G.SG_removeLastTP()
    tpListLabel.Text = "มี " .. #_G.SG_getTeleportPoints() .. " จุด"
end)
for i = 1, 5 do
    ctxMain.button("➡ วาร์ปไปจุดที่ " .. i, Color3.fromRGB(50,80,130), function() _G.SG_warpToTP(i) end)
end
ctxMain.section("📊 ข้อมูล")
local coordsLabel = ctxMain.label("X: 0  Y: 0  Z: 0", COL.warn)
ctxMain.button("🔄 รายงานพิกัด", COL.accent, function()
    coordsLabel.Text = _G.SG_reportCoords()
end)
ctxMain.finalize()

-- PAGE 2: หน้าหลัก 2
local ctxM2 = buildContent(pageMain2)
ctxM2.section("🔦 เลเซอร์")
ctxM2.toggle("เปิดเลเซอร์", function() return CONFIG.LaserEnabled end,
    function(v) CONFIG.LaserEnabled = v end)
ctxM2.slider("ระยะเลเซอร์", 10, 1000, function() return CONFIG.MaxDistance end,
    function(v) CONFIG.MaxDistance = v end)
ctxM2.section("🎯 AIMBOT")
ctxM2.toggle("เปิด AIMBOT", function() return CONFIG.AimbotEnabled end,
    function(v) CONFIG.AimbotEnabled = v; fovCircle.Visible = v end)
ctxM2.slider("FOV", 10, 180, function() return CONFIG.AimbotFOV end,
    function(v) CONFIG.AimbotFOV = v; updateFovCircleSize() end)
ctxM2.slider("ความแรงดูด", 1, 10, function() return CONFIG.AimbotStrength end,
    function(v) CONFIG.AimbotStrength = v end)
ctxM2.toggle("เช็คกำแพง", function() return CONFIG.AimbotWallCheck end,
    function(v) CONFIG.AimbotWallCheck = v end)
ctxM2.toggle("ไม่ล็อกทีม", function() return CONFIG.AimbotTeamCheck end,
    function(v) CONFIG.AimbotTeamCheck = v end)
ctxM2.section("🚀 TP WALK")
ctxM2.toggle("เปิด TP WALK", function() return CONFIG.TPWalkEnabled end,
    function(v) CONFIG.TPWalkEnabled = v end)
ctxM2.slider("ความเร็ว TP", 0, 1000, function() return CONFIG.TPWalkSpeed end,
    function(v) CONFIG.TPWalkSpeed = v end)
ctxM2.toggle("กันตกวอยซ์", function() return CONFIG.TPWalkAntiVoid end,
    function(v) CONFIG.TPWalkAntiVoid = v end)
ctxM2.toggle("เดินบนน้ำ", function() return CONFIG.TPWalkWaterWalk end,
    function(v) CONFIG.TPWalkWaterWalk = v end)
ctxM2.finalize()

-- PAGE 3: ดวงตาเทพ
local ctxEyes = buildContent(pageEyes)
ctxEyes.section("👁 ดวงตาเทพ")
ctxEyes.toggle("เปิดดวงตาเทพ", function() return CONFIG.PlayerESPEnabled end,
    function(v) CONFIG.PlayerESPEnabled = v end)
ctxEyes.colorPicker("สีไฮไลท์", function() return CONFIG.PlayerESPColor end,
    function(c) CONFIG.PlayerESPColor = c end)
ctxEyes.toggle("แสดงชื่อ", function() return CONFIG.PlayerESPShowName end,
    function(v) CONFIG.PlayerESPShowName = v end)
ctxEyes.toggle("แสดงระยะ", function() return CONFIG.PlayerESPShowDistance end,
    function(v) CONFIG.PlayerESPShowDistance = v end)
ctxEyes.toggle("ไม่แสดงเพื่อนทีม", function() return CONFIG.PlayerESPTeamCheck end,
    function(v) CONFIG.PlayerESPTeamCheck = v end)
ctxEyes.section("📏 ขนาด")
ctxEyes.slider("ขนาดเล็กสุด", 6, 20, function() return CONFIG.ESPTextSizeMin end,
    function(v) CONFIG.ESPTextSizeMin = v end)
ctxEyes.slider("ขนาดใหญ่สุด", 10, 40, function() return CONFIG.ESPTextSizeMax end,
    function(v) CONFIG.ESPTextSizeMax = v end)
ctxEyes.slider("ระยะมองไกลสุด", 100, 5000, function() return CONFIG.ESPMaxDist end,
    function(v) CONFIG.ESPMaxDist = v end)
ctxEyes.finalize()

-- PAGE 4: มองบอท
local ctxBots = buildContent(pageBots)
ctxBots.section("🤖 มองบอท")
ctxBots.toggle("เปิดมองบอท", function() return CONFIG.BotESPEnabled end,
    function(v) CONFIG.BotESPEnabled = v end)
ctxBots.colorPicker("สีไฮไลท์", function() return CONFIG.BotESPColor end,
    function(c) CONFIG.BotESPColor = c end)
ctxBots.toggle("แสดงชื่อบอท", function() return CONFIG.BotESPShowName end,
    function(v) CONFIG.BotESPShowName = v end)
ctxBots.toggle("แสดง HP", function() return CONFIG.BotESPShowHealth end,
    function(v) CONFIG.BotESPShowHealth = v end)
ctxBots.finalize()

-- PAGE 5: ESP รถถัง
local ctxVeh = buildContent(pageVehicle)
ctxVeh.section("🚗 ESP รถถัง")
ctxVeh.toggle("เปิด ESP รถถัง", function() return CONFIG.VehicleESPEnabled end,
    function(v) CONFIG.VehicleESPEnabled = v end)
ctxVeh.colorPicker("สีไฮไลท์", function() return CONFIG.VehicleESPColor end,
    function(c) CONFIG.VehicleESPColor = c end)
ctxVeh.finalize()

-- PAGE 6: ตั้งค่า
local ctxSet = buildContent(pageSettings)
ctxSet.section("🎨 กราฟฟิก")
ctxSet.toggle("ลดกราฟฟิก", function() return CONFIG.AutoLowGraphics end,
    function(v) CONFIG.AutoLowGraphics = v; if v then applyLowGraphics() else revertGraphics() end end)
ctxSet.finalize()

-- FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 5
fovCircle.Parent = gui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1,0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = COL.warn
fovStroke.Thickness = 1.6
fovStroke.Transparency = 0.4
fovStroke.Parent = fovCircle
local function updateFovCircleSize()
    local vp = camera.ViewportSize
    local camFov = math.rad(camera.FieldOfView)
    local halfFovRad = math.rad(CONFIG.AimbotFOV/2)
    local radiusPx = (math.tan(halfFovRad)/math.tan(camFov/2)) * (vp.Y/2)
    fovCircle.Size = UDim2.new(0, radiusPx*2, 0, radiusPx*2)
end
updateFovCircleSize()

-- Status Bar
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 340, 0, 38)
statusFrame.Position = UDim2.new(0.5, -170, 0, 12)
statusFrame.BackgroundColor3 = COL.bg
statusFrame.BackgroundTransparency = 0.15
statusFrame.BorderSizePixel = 0
statusFrame.Parent = gui
Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0,8)
local statusStroke = Instance.new("UIStroke")
statusStroke.Color = COL.green
statusStroke.Thickness = 1.5
statusStroke.Transparency = 0.3
statusStroke.Parent = statusFrame
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -14, 0, 18)
statusLabel.Position = UDim2.new(0, 7, 0, 2)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⚫ ไม่มีเป้า"
statusLabel.TextColor3 = COL.text
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusFrame
local gunLabel = Instance.new("TextLabel")
gunLabel.Size = UDim2.new(1, -14, 0, 14)
gunLabel.Position = UDim2.new(0, 7, 0, 20)
gunLabel.BackgroundTransparency = 1
gunLabel.Text = "🔫 ไม่ได้ถืออาวุธ"
gunLabel.TextColor3 = COL.warn
gunLabel.TextSize = 10
gunLabel.Font = Enum.Font.Gotham
gunLabel.TextXAlignment = Enum.TextXAlignment.Left
gunLabel.Parent = statusFrame

local currentStatusColor = COL.green
_G.SG_statusFunc = function(text, color)
    statusLabel.Text = text
    statusStroke.Color = color
    if currentStatusColor ~= color then
        currentStatusColor = color
        statusFrame.BackgroundColor3 = color:Lerp(COL.bg, 0.85)
        Tween:Create(statusFrame, TweenInfo.new(0.3), { BackgroundColor3 = COL.bg }):Play()
    end
end
_G.SG_gunLabel = gunLabel

print("[SG v3.1] UI เสร็จแล้ว")

-- Sidebar
local function makeSidebarBtn(text, yPos, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.Position = UDim2.new(0, 0, 0, yPos)
    b.BackgroundColor3 = COL.bg3
    b.BackgroundTransparency = 0.5
    b.BorderSizePixel = 0
    b.Text = "   " .. text
    b.TextColor3 = COL.textDim
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = sidebarBtnHolder
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(callback)
    return b
end
local function setActiveBtn(btn, active)
    if active then
        Tween:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = COL.accent, BackgroundTransparency = 0,
            TextColor3 = Color3.fromRGB(255,255,255),
        }):Play()
    else
        Tween:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = COL.bg3, BackgroundTransparency = 0.5,
            TextColor3 = COL.textDim,
        }):Play()
    end
end
local pages = { pageMain, pageMain2, pageEyes, pageBots, pageVehicle, pageSettings }
local btns = {}
local function showPage(idx)
    for i, p in ipairs(pages) do p.Visible = (i == idx) end
    for i, b in ipairs(btns) do setActiveBtn(b, i == idx) end
end
local bMain = makeSidebarBtn("🏠  หน้าหลัก", 0, function() showPage(1) end)
local bMain2 = makeSidebarBtn("⚡  หน้าหลัก 2", 32, function() showPage(2) end)
local bEyes = makeSidebarBtn("👁  ดวงตาเทพ", 64, function() showPage(3) end)
local bBots = makeSidebarBtn("🤖  มองบอท", 96, function() showPage(4) end)
local bVeh = makeSidebarBtn("🚗  ESP รถถัง", 128, function() showPage(5) end)
local bSet = makeSidebarBtn("⚙  ตั้งค่า", 160, function() showPage(6) end)
btns = { bMain, bMain2, bEyes, bBots, bVeh, bSet }
showPage(1)

-- Collapse + Drag
local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 170, 0, 36)
miniBtn.Position = UDim2.new(1, -182, 0, 12)
miniBtn.BackgroundColor3 = COL.bg2
miniBtn.BackgroundTransparency = 0.05
miniBtn.BorderSizePixel = 0
miniBtn.Text = "⚡ SIGMAGOON HUB"
miniBtn.TextColor3 = COL.text
miniBtn.TextSize = 13
miniBtn.Font = Enum.Font.GothamBold
miniBtn.Visible = false
miniBtn.ZIndex = 200
miniBtn.Parent = gui
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0,8)
collapseBtn.MouseButton1Click:Connect(function()
    main.Visible = false; miniBtn.Visible = true
end)
miniBtn.MouseButton1Click:Connect(function()
    main.Visible = true; miniBtn.Visible = false
    main.Position = UDim2.new(0.5, -mainW/2, 0.5, -mainH/2)
end)

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UserInput.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInput.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- FPS counter
local fpsAccum, fpsFrames = 0, 0
RunService.RenderStepped:Connect(function(dt)
    fpsAccum = fpsAccum + dt
    fpsFrames = fpsFrames + 1
    if fpsAccum >= 0.5 then
        fpsLbl.Text = "FPS " .. math.floor(fpsFrames / fpsAccum)
        fpsAccum = 0; fpsFrames = 0
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(0.3)
        local hum = getHum()
        if hum then
            local h = math.floor(hum.Health)
            local m = math.floor(hum.MaxHealth)
            if m == math.huge or m > 100000 then
                healthText.Text = "Health ∞/∞"
                healthBarFill.Size = UDim2.new(1, 0, 1, 0)
                healthBarFill.BackgroundColor3 = COL.green
            else
                healthText.Text = "Health " .. h .. "/" .. m
                local rel = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                healthBarFill.Size = UDim2.new(rel, 0, 1, 0)
                if rel > 0.5 then healthBarFill.BackgroundColor3 = COL.green
                elseif rel > 0.2 then healthBarFill.BackgroundColor3 = COL.warn
                else healthBarFill.BackgroundColor3 = COL.red end
            end
        end
        local hrp = getHRP()
        if hrp and coordsLabel then
            local p = hrp.Position
            coordsLabel.Text = string.format("X: %.0f  Y: %.0f  Z: %.0f", p.X, p.Y, p.Z)
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(0.15)
        pcall(function()
            scanPlayerESP()
            scanBotESP()
            scanVehicleESP()
            updateESPTexts()
        end)
    end
end)

local toolLaser, vehicleLaser = nil, nil
local toolConns, charConns = {}, {}
local function clearToolLaser() destroyLaser(toolLaser); toolLaser=nil end
local function clearVehicleLaser() destroyLaser(vehicleLaser); vehicleLaser=nil end
local function disconnectAll(list)
    for _, c in ipairs(list) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(list)
end

local function attachToolLaser(tool)
    clearToolLaser()
    if gunLabel then gunLabel.Text = tool and ("🔫 "..tool.Name) or "🔫 ไม่ได้ถืออาวุธ" end
    if not tool or not tool.Parent then return end
    local att = safeFindAtt(tool, CONFIG.MuzzleNames)
    if not att and CONFIG.FallbackToHandle then
        local handle = tool:FindFirstChild("Handle")
        if handle then
            att = Instance.new("Attachment")
            att.Name = "__LSAuto"
            att.CFrame = CFrame.new(0, 0, -handle.Size.Z*0.5)
            att.Parent = handle
        end
    end
    if not att then return end
    toolLaser = createLaser(att)
end

local function hookTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    table.insert(toolConns, tool.Equipped:Connect(function() attachToolLaser(tool) end))
    table.insert(toolConns, tool.Unequipped:Connect(function()
        if toolLaser and toolLaser.att and toolLaser.att:IsDescendantOf(tool) then
            clearToolLaser()
            if gunLabel then gunLabel.Text = "🔫 ไม่ได้ถืออาวุธ" end
        end
    end))
    local hum = getHum()
    if hum and hum.EquippedTool == tool then attachToolLaser(tool) end
end

local function attachVehicleLaser(seat)
    clearVehicleLaser()
    if not seat then return end
    local vm = seat:FindFirstAncestorOfClass("Model")
    local att = safeFindAtt(vm, CONFIG.VehicleMuzzleNames)
        or safeFindAtt(seat, CONFIG.VehicleMuzzleNames)
    if not att then return end
    vehicleLaser = createLaser(att)
end

local function hookCharacter(character)
    clearToolLaser(); clearVehicleLaser()
    disconnectAll(toolConns); disconnectAll(charConns)
    if gunLabel then gunLabel.Text = "🔫 ไม่ได้ถืออาวุธ" end
    for _, c in ipairs(character:GetChildren()) do
        if c:IsA("Tool") then hookTool(c) end
    end
    table.insert(charConns, character.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then hookTool(c) end
    end))
    table.insert(charConns, character.ChildRemoved:Connect(function(c)
        if c:IsA("Tool") and toolLaser and toolLaser.att and toolLaser.att:IsDescendantOf(c) then
            clearToolLaser()
        end
    end))
    local hum = character:WaitForChild("Humanoid", 10)
    if hum then
        table.insert(charConns, hum.Seated:Connect(function(isSeated, seat)
            if isSeated and seat then task.defer(function() attachVehicleLaser(seat) end)
            else clearVehicleLaser() end
        end))
    end
    if CONFIG.InvisibleEnabled then setInvisible(true) end
    if CONFIG.GodmodeEnabled then setGodmode(true) end
end

if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)
player.CharacterRemoving:Connect(function()
    clearToolLaser(); clearVehicleLaser()
    disconnectAll(toolConns); disconnectAll(charConns)
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.AimbotEnabled then updateFovCircleSize() end
    if not CONFIG.LaserEnabled then
        if toolLaser then clearToolLaser() end
        if vehicleLaser then clearVehicleLaser() end
        return
    end
    if toolLaser then
        if toolLaser.destroyed then toolLaser=nil
        else updateLaser(toolLaser) end
    end
    if vehicleLaser then
        if vehicleLaser.destroyed then vehicleLaser=nil
        else updateLaser(vehicleLaser) end
    end
    if CONFIG.AimbotEnabled then
        local act = toolLaser or vehicleLaser
        if act and act.att and act.att.Parent then
            local origin = act.att.WorldPosition
            local aimDir = act.smoothDir or camera.CFrame.LookVector
            if origin then
                local target = findBestTarget(origin, aimDir, CONFIG.AimbotMaxDist)
                if target then
                    local lockPart = target:FindFirstChild(CONFIG.AimbotLockPart)
                        or target:FindFirstChild("HumanoidRootPart")
                        or target:FindFirstChild("Head")
                    if lockPart then
                        local tp = predictPos(target, lockPart, CONFIG.AimbotPredict)
                        local desired = CFrame.new(camera.CFrame.Position, tp)
                        local sa = CONFIG.AimbotStrength/10
                        local ba = 1 - CONFIG.AimbotSmooth
                        local fa = math.clamp(ba*(0.3+sa*1.2), 0.02, 1)
                        camera.CFrame = camera.CFrame:Lerp(desired, fa)
                    end
                end
            end
        end
    end
end)

print("[SIGMAGOON HUB v3.1] โหลดครบทั้ง 2 ส่วน ✅")
print("  ✅ 6 หน้า: หน้าหลัก / หน้าหลัก 2 / ดวงตาเทพ / มองบอท / ESP รถถัง / ตั้งค่า")
