--============================================================
-- SIGMAGOON HUB v8.0 — P4 (Player List + 3D Preview + Server Hop)
--============================================================
if not _G.SG5_P3 then
    warn("[SG] ต้องรัน P3 ก่อน!")
    return
end
_G.SG5_P4 = true

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local CoreGui    = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = _G.SG_CONFIG
local getHRP = _G.SG_getHRP
local isSameTeam = _G.SG_isSameTeam
local COL = _G.SG_COL
local notify = _G.SG_notify
local makeSidebarBtn = _G.SG_makeSidebarBtn

print("[SG v8.0] P4 เริ่มโหลด")

--============================================================
-- SERVER HOP
--============================================================
_G.SG_ServerHop = function()
    local placeId = game.PlaceId
    if notify then notify("🌐 กำลังหาเซิร์ฟเวอร์ใหม่...", Color3.fromRGB(0, 200, 255)) end

    local function getServers()
        local url = "https://games.roblox.com/v1/games/" .. placeId 
            .. "/servers/Public?sortOrder=Asc&limit=100"
        local ok, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if ok and result and result.data then return result.data end
        return nil
    end

    local servers = getServers()
    if not servers then
        if notify then notify("❌ ดึงข้อมูลไม่ได้", Color3.fromRGB(255, 60, 60)) end
        return
    end

    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            if notify then notify("✅ พบเซิร์ฟเวอร์ — กำลังย้าย...", Color3.fromRGB(0, 255, 100)) end
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
            end)
            return
        end
    end
    if notify then notify("⚠ ไม่พบเซิร์ฟเวอร์ว่าง", Color3.fromRGB(255, 180, 60)) end
end

--============================================================
-- 3D PLAYER PREVIEW
--============================================================
local previewFolder = Instance.new("Folder")
previewFolder.Name = "__SG_Preview"
previewFolder.Parent = workspace

local previewModels = {}
_G.SG_previewModels = previewModels

_G.SG_showPlayerPreview = function(targetPlayer, previewPosition)
    if previewModels[targetPlayer] then
        previewModels[targetPlayer]:Destroy()
        previewModels[targetPlayer] = nil
    end

    if not targetPlayer or not targetPlayer.Character then
        if notify then notify("❌ ผู้เล่นไม่มีตัวละคร", Color3.fromRGB(255, 60, 60)) end
        return
    end

    local char = targetPlayer.Character
    local clone = char:Clone()
    clone.Name = "Preview_" .. targetPlayer.Name

    -- ลบ Scripts/Animations
    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript")
            or v:IsA("Animator") or v:IsA("Animation") then
            v:Destroy()
        end
    end

    -- ลบ Humanoid
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then hum:Destroy() end

    -- Anchor ทุก BasePart
    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
        end
    end

    -- ตั้งตำแหน่ง
    local hrp = clone:FindFirstChild("HumanoidRootPart") 
        or clone:FindFirstChild("Head") 
        or clone.PrimaryPart
    if hrp then
        hrp.CFrame = CFrame.new(previewPosition or (camera.CFrame.Position + camera.CFrame.LookVector * 10))
        clone.PrimaryPart = hrp
    end

    -- ป้ายชื่อ
    local head = clone:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = head
        billboard.AlwaysOnTop = true
        billboard.Parent = clone

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = targetPlayer.DisplayName
        nameLbl.TextColor3 = Color3.fromRGB(0, 200, 255)
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        nameLbl.TextSize = 16
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.Parent = billboard

        local infoLbl = Instance.new("TextLabel")
        infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
        infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = "@" .. targetPlayer.Name
        infoLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
        infoLbl.TextStrokeTransparency = 0
        infoLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        infoLbl.TextSize = 12
        infoLbl.Font = Enum.Font.Gotham
        infoLbl.Parent = billboard
    end

    clone.Parent = previewFolder
    previewModels[targetPlayer] = clone

    -- หมุนช้า ๆ
    task.spawn(function()
        local rot = 0
        while clone.Parent and previewModels[targetPlayer] == clone do
            task.wait(0.03)
            rot = rot + 1
            if hrp and hrp.Parent then
                local basePos = hrp.Position
                hrp.CFrame = CFrame.new(basePos) * CFrame.Angles(0, math.rad(rot), 0)
            end
        end
    end)

    return clone
end

_G.SG_hidePlayerPreview = function(targetPlayer)
    if targetPlayer and previewModels[targetPlayer] then
        previewModels[targetPlayer]:Destroy()
        previewModels[targetPlayer] = nil
    end
end

_G.SG_hideAllPreviews = function()
    for _, m in pairs(previewModels) do
        if m and m.Parent then m:Destroy() end
    end
    table.clear(previewModels)
end

--============================================================
-- TELEPORT TO PLAYER
--============================================================
_G.SG_TeleportToPlayer = function(targetPlayer)
    if not targetPlayer then return end
    if targetPlayer == player then
        if notify then notify("❌ วาร์ปไปตัวเองไม่ได้", Color3.fromRGB(255, 60, 60)) end
        return
    end
    if not targetPlayer.Character then
        if notify then notify("❌ ผู้เล่นไม่มีตัวละคร", Color3.fromRGB(255, 60, 60)) end
        return
    end

    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if not targetHRP or not myHRP then return end

    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -5)
    if notify then notify("🌍 วาร์ปไปหา: " .. targetPlayer.Name, Color3.fromRGB(0, 200, 255)) end
end

--============================================================
-- COPY PLAYER INFO
--============================================================
_G.SG_CopyPlayerInfo = function(targetPlayer)
    if not targetPlayer then return end

    local info = "=== PLAYER INFO ===\n"
    info = info .. "Name: " .. targetPlayer.Name .. "\n"
    info = info .. "DisplayName: " .. targetPlayer.DisplayName .. "\n"
    info = info .. "UserId: " .. targetPlayer.UserId .. "\n"
    info = info .. "AccountAge: " .. targetPlayer.AccountAge .. " days\n"
    info = info .. "Team: " .. (targetPlayer.Team and targetPlayer.Team.Name or "None") .. "\n"

    if targetPlayer.Character then
        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            info = info .. "Position: " .. string.format("(%.1f, %.1f, %.1f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) .. "\n"
        end
        local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            info = info .. "Health: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "\n"
        end
    end

    if setclipboard then
        setclipboard(info)
        if notify then notify("📋 คัดลอกข้อมูล " .. targetPlayer.Name, Color3.fromRGB(0, 255, 100)) end
    else
        if notify then notify("❌ ไม่รองรับ clipboard", Color3.fromRGB(255, 60, 60)) end
    end
    return info
end

--============================================================
-- CREATE PLAYER LIST PAGE
--============================================================
local sgHub = nil
for _, g in ipairs(CoreGui:GetChildren()) do
    if g.Name == "SIGMAGOON_HUB" then sgHub = g; break end
end
if not sgHub then
    for _, g in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
        if g.Name == "SIGMAGOON_HUB" then sgHub = g; break end
    end
end

if not sgHub then warn("[SG v8.0] ไม่พบ SIGMAGOON_HUB"); return end

local main = sgHub:FindFirstChild("Main")
local contentArea = main and main:FindFirstChild("ContentArea")
local sidebarBtnHolder = main and main.Sidebar and main.Sidebar:FindFirstChild("sidebarBtnHolder")

if not contentArea then warn("[SG v8.0] ไม่พบ ContentArea"); return end

-- ลบหน้า Players เก่า (ถ้ามี)
local oldPlayers = contentArea:FindFirstChild("PagePlayers")
if oldPlayers then oldPlayers:Destroy() end

-- สร้างหน้า Players ใหม่เป็น ScrollingFrame (เลื่อนได้)
local pagePlayers = Instance.new("ScrollingFrame")
pagePlayers.Name = "PagePlayers"
pagePlayers.Size = UDim2.new(1, 0, 1, 0)
pagePlayers.BackgroundTransparency = 1
pagePlayers.BorderSizePixel = 0
pagePlayers.ScrollBarThickness = 4
pagePlayers.ScrollBarImageColor3 = COL.accent
pagePlayers.CanvasSize = UDim2.new(0, 0, 0, 0)
pagePlayers.AutomaticCanvasSize = Enum.AutomaticSize.Y
pagePlayers.ScrollingDirection = Enum.ScrollingDirection.Y
pagePlayers.Visible = false
pagePlayers.Parent = contentArea
Instance.new("UICorner", pagePlayers).CornerRadius = UDim.new(0, 8)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, -20, 0, 30)
header.Position = UDim2.new(0, 10, 0, 10)
header.BackgroundColor3 = COL.bg3
header.BorderSizePixel = 0
header.Parent = pagePlayers
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -16, 1, 0)
headerLabel.Position = UDim2.new(0, 8, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "👥 รายชื่อผู้เล่น"
headerLabel.TextColor3 = COL.accent
headerLabel.TextSize = 13
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = header

-- List holder (ใช้ AutomaticSize)
local listHolder = Instance.new("Frame")
listHolder.Name = "ListHolder"
listHolder.Size = UDim2.new(1, -20, 0, 0)
listHolder.Position = UDim2.new(0, 10, 0, 50)
listHolder.BackgroundTransparency = 1
listHolder.AutomaticSize = Enum.AutomaticSize.Y
listHolder.Parent = pagePlayers

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = listHolder

--============================================================
-- CREATE PLAYER ROW
--============================================================
local function createPlayerRow(targetPlayer)
    local row = Instance.new("Frame")
    row.Name = "Row_" .. targetPlayer.Name
    row.Size = UDim2.new(1, 0, 0, 70)
    row.BackgroundColor3 = COL.bg3
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = listHolder
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 10, 0, 10)
    avatar.BackgroundColor3 = COL.bg
    avatar.BorderSizePixel = 0
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
    avatar.Parent = row
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 8)

    -- DisplayName
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -200, 0, 18)
    nameLbl.Position = UDim2.new(0, 68, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = targetPlayer.DisplayName
    nameLbl.TextColor3 = COL.text
    nameLbl.TextSize = 13
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = row

    -- @Username
    local userLbl = Instance.new("TextLabel")
    userLbl.Size = UDim2.new(1, -200, 0, 14)
    userLbl.Position = UDim2.new(0, 68, 0, 26)
    userLbl.BackgroundTransparency = 1
    userLbl.Text = "@" .. targetPlayer.Name
    userLbl.TextColor3 = COL.accent
    userLbl.TextSize = 10
    userLbl.Font = Enum.Font.Gotham
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.Parent = row

    -- Distance
    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(1, -200, 0, 14)
    distLbl.Position = UDim2.new(0, 68, 0, 42)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "📏 ระยะ: --"
    distLbl.TextColor3 = COL.warn
    distLbl.TextSize = 10
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Parent = row

    -- Button Holder
    local btnHolder = Instance.new("Frame")
    btnHolder.Size = UDim2.new(0, 130, 0, 50)
    btnHolder.Position = UDim2.new(1, -140, 0, 10)
    btnHolder.BackgroundTransparency = 1
    btnHolder.Parent = row

    -- View 3D
    local view3DBtn = Instance.new("TextButton")
    view3DBtn.Size = UDim2.new(0, 62, 0, 22)
    view3DBtn.Position = UDim2.new(0, 0, 0, 0)
    view3DBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    view3DBtn.BorderSizePixel = 0
    view3DBtn.Text = "👁 3D"
    view3DBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    view3DBtn.TextSize = 10
    view3DBtn.Font = Enum.Font.GothamBold
    view3DBtn.Parent = btnHolder
    Instance.new("UICorner", view3DBtn).CornerRadius = UDim.new(0, 5)
    view3DBtn.MouseButton1Click:Connect(function()
        if _G.SG_showPlayerPreview then
            local spawnPos = camera.CFrame.Position + camera.CFrame.LookVector * 10
            _G.SG_showPlayerPreview(targetPlayer, spawnPos)
            if notify then notify("👁 แสดง 3D: " .. targetPlayer.Name, Color3.fromRGB(140, 80, 255)) end
        end
    end)

    -- Teleport
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 62, 0, 22)
    tpBtn.Position = UDim2.new(0, 66, 0, 0)
    tpBtn.BackgroundColor3 = COL.accent
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "🌍 วาร์ป"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.TextSize = 10
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.Parent = btnHolder
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)
    tpBtn.MouseButton1Click:Connect(function()
        if _G.SG_TeleportToPlayer then
            _G.SG_TeleportToPlayer(targetPlayer)
        end
    end)

    -- Copy Info
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 62, 0, 22)
    copyBtn.Position = UDim2.new(0, 0, 0, 26)
    copyBtn.BackgroundColor3 = COL.on
    copyBtn.BorderSizePixel = 0
    copyBtn.Text = "📋 Copy"
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 10
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.Parent = btnHolder
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)
    copyBtn.MouseButton1Click:Connect(function()
        if _G.SG_CopyPlayerInfo then
            _G.SG_CopyPlayerInfo(targetPlayer)
        end
    end)

    -- Hide 3D
    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0, 62, 0, 22)
    hideBtn.Position = UDim2.new(0, 66, 0, 26)
    hideBtn.BackgroundColor3 = COL.red
    hideBtn.BorderSizePixel = 0
    hideBtn.Text = "❌ ซ่อน"
    hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideBtn.TextSize = 10
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.Parent = btnHolder
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 5)
    hideBtn.MouseButton1Click:Connect(function()
        if _G.SG_hidePlayerPreview then
            _G.SG_hidePlayerPreview(targetPlayer)
        end
    end)

    -- Distance update loop (safe)
    task.spawn(function()
        while row.Parent and targetPlayer.Parent do
            task.wait(0.5)
            local ok, dist = pcall(function()
                local myChar = player.Character
                local tChar = targetPlayer.Character
                if not myChar or not tChar then return nil end
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                if not myHRP or not tHRP then return nil end
                return (myHRP.Position - tHRP.Position).Magnitude
            end)
            if ok and dist then
                distLbl.Text = "📏 ระยะ: " .. math.floor(dist) .. " studs"
            else
                distLbl.Text = "📏 ระยะ: --"
            end
        end
    end)

    return row
end

--============================================================
-- REFRESH
--============================================================
local function refreshPlayerList()
    for _, c in ipairs(listHolder:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            createPlayerRow(plr)
            count = count + 1
        end
    end
    headerLabel.Text = "👥 รายชื่อผู้เล่น (" .. count .. " คน)"
end

--============================================================
-- ADD SIDEBAR BUTTONS
--============================================================
if sidebarBtnHolder and makeSidebarBtn then
    -- ลบปุ่มเก่า (ถ้ามี)
    for _, c in ipairs(sidebarBtnHolder:GetChildren()) do
        if c:IsA("TextButton") then
            if c.Text:find("Players") or c.Text:find("Anti") then
                c:Destroy()
            end
        end
    end

    -- ปุ่ม Players
    local bPlayer = makeSidebarBtn("👥  Players", 224, function()
        for _, c in ipairs(contentArea:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        pagePlayers.Visible = true
        for _, c in ipairs(sidebarBtnHolder:GetChildren()) do
            if c:IsA("TextButton") then
                Tween:Create(c, TweenInfo.new(0.15), {
                    BackgroundColor3 = COL.bg3,
                    BackgroundTransparency = 0.5,
                    TextColor3 = COL.textDim,
                }):Play()
            end
        end
        Tween:Create(bPlayer, TweenInfo.new(0.15), {
            BackgroundColor3 = COL.accent,
            BackgroundTransparency = 0,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }):Play()
        refreshPlayerList()
    end)

    print("[SG v8.0] เพิ่มปุ่ม Players แล้ว")
end

-- Auto refresh
task.spawn(function()
    while _G.SG5_P1 do
        task.wait(3)
        if pagePlayers.Visible then
            refreshPlayerList()
        end
    end
end)

Players.PlayerAdded:Connect(function()
    if pagePlayers.Visible then refreshPlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    _G.SG_hidePlayerPreview(plr)
    if pagePlayers.Visible then refreshPlayerList() end
end)

--============================================================
-- เพิ่มปุ่ม Server Hop ใน Utility
--============================================================
local pageUtility = _G.SG_pageUtility
if pageUtility then
    local maxY = 0
    for _, c in ipairs(pageUtility:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then
            local y = c.Position.Y.Offset + c.Size.Y.Offset
            if y > maxY then maxY = y end
        end
    end

    -- Section
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 24)
    section.Position = UDim2.new(0, 10, 0, maxY + 10)
    section.BackgroundColor3 = COL.bg3
    section.BackgroundTransparency = 0.4
    section.BorderSizePixel = 0
    section.Parent = pageUtility
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 6)

    local sectionLabel = Instance.new("TextLabel")
    sectionLabel.Size = UDim2.new(1, -16, 1, 0)
    sectionLabel.Position = UDim2.new(0, 8, 0, 0)
    sectionLabel.BackgroundTransparency = 1
    sectionLabel.Text = "🌐 SERVER"
    sectionLabel.TextColor3 = COL.accent
    sectionLabel.TextSize = 12
    sectionLabel.Font = Enum.Font.GothamBold
    sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel.Parent = section

    -- Server Hop Button
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, -20, 0, 30)
    hopBtn.Position = UDim2.new(0, 10, 0, maxY + 40)
    hopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    hopBtn.BorderSizePixel = 0
    hopBtn.Text = "🌐 Server Hop"
    hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hopBtn.TextSize = 12
    hopBtn.Font = Enum.Font.GothamBold
    hopBtn.Parent = pageUtility
    Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 6)
    hopBtn.MouseButton1Click:Connect(_G.SG_ServerHop)

    -- Hide All 3D
    local hideAllBtn = Instance.new("TextButton")
    hideAllBtn.Size = UDim2.new(1, -20, 0, 30)
    hideAllBtn.Position = UDim2.new(0, 10, 0, maxY + 76)
    hideAllBtn.BackgroundColor3 = COL.red
    hideAllBtn.BorderSizePixel = 0
    hideAllBtn.Text = "🗑 ลบ 3D Preview ทั้งหมด"
    hideAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideAllBtn.TextSize = 12
    hideAllBtn.Font = Enum.Font.GothamBold
    hideAllBtn.Parent = pageUtility
    Instance.new("UICorner", hideAllBtn).CornerRadius = UDim.new(0, 6)
    hideAllBtn.MouseButton1Click:Connect(function()
        _G.SG_hideAllPreviews()
        if notify then notify("🗑 ลบ preview ทั้งหมดแล้ว", COL.red) end
    end)

    pageUtility.CanvasSize = UDim2.new(0, 0, 0, maxY + 120)
end

-- Refresh function external
_G.SG_refreshPlayerList = refreshPlayerList

print("[SG v8.0] P4 โหลดเสร็จ — Player List + 3D Preview + Server Hop")
