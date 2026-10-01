--============================================================
-- SIGMAGOON HUB v7.0 — P4 (Player List + 3D Preview + Extras)
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
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = _G.SG_CONFIG
local getHRP = _G.SG_getHRP
local isSameTeam = _G.SG_isSameTeam
local COL = _G.SG_COL
local notify = _G.SG_notify

print("[SG v7.0] P4 เริ่มโหลด")

--============================================================
-- SERVER HOP
--============================================================
_G.SG_ServerHop = function()
    local placeId = game.PlaceId
    notify("🌐 กำลังหาเซิร์ฟเวอร์ใหม่...", Color3.fromRGB(0, 200, 255))
    
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
        notify("❌ ดึงข้อมูลไม่ได้", Color3.fromRGB(255, 60, 60))
        return
    end
    
    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            notify("✅ พบเซิร์ฟเวอร์ — กำลังย้าย...", Color3.fromRGB(0, 255, 100))
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
            end)
            return
        end
    end
    notify("⚠ ไม่พบเซิร์ฟเวอร์ว่าง", Color3.fromRGB(255, 180, 60))
end

--============================================================
-- 3D PLAYER PREVIEW SYSTEM
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
        notify("❌ ผู้เล่นไม่มีตัวละคร", Color3.fromRGB(255, 60, 60))
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
    
    -- ลบ Humanoid (เพื่อไม่ให้มี Physics)
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
    local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Head") or clone.PrimaryPart
    if hrp then
        hrp.CFrame = CFrame.new(previewPosition or (camera.CFrame.Position + camera.CFrame.LookVector * 10))
        clone.PrimaryPart = hrp
    end
    
    -- เพิ่มป้ายชื่อ
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
        notify("❌ วาร์ปไปตัวเองไม่ได้", Color3.fromRGB(255, 60, 60))
        return
    end
    if not targetPlayer.Character then
        notify("❌ ผู้เล่นไม่มีตัวละคร", Color3.fromRGB(255, 60, 60))
        return
    end
    
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if not targetHRP or not myHRP then return end
    
    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -5)
    notify("🌍 วาร์ปไปหา: " .. targetPlayer.Name, Color3.fromRGB(0, 200, 255))
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
    info = info .. "Membership: " .. (targetPlayer.MembershipType.Name or "None") .. "\n"
    
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
        notify("📋 คัดลอกข้อมูล " .. targetPlayer.Name, Color3.fromRGB(0, 255, 100))
    else
        notify("❌ ไม่รองรับ clipboard", Color3.fromRGB(255, 60, 60))
    end
    return info
end

--============================================================
-- SCREENSHOT
--============================================================
_G.SG_Screenshot = function()
    local hiddenGuis = {}
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g:IsA("ScreenGui") and (g.Name:find("SIGMAGOON") or g.Name:find("SG_")) then
            hiddenGuis[g] = g.Enabled
            g.Enabled = false
        end
    end
    
    task.wait(0.2)
    
    local fileName = "sigmagoon_" .. os.time() .. ".png"
    local ok = pcall(function()
        if captureScreenshot then
            captureScreenshot(fileName)
        elseif screenshot then
            screenshot(fileName)
        else
            error("ไม่รองรับ")
        end
    end)
    
    task.wait(0.1)
    
    for g, enabled in pairs(hiddenGuis) do
        if g and g.Parent then g.Enabled = enabled end
    end
    
    if ok then
        notify("📸 บันทึกภาพแล้ว", Color3.fromRGB(0, 255, 100))
    else
        notify("❌ ไม่รองรับ Screenshot", Color3.fromRGB(255, 60, 60))
    end
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

if not sgHub then
    warn("[SG] ไม่พบ SIGMAGOON_HUB")
    return
end

local main = sgHub:FindFirstChild("Main")
local contentArea = main and main:FindFirstChild("ContentArea")
if not contentArea then
    warn("[SG] ไม่พบ ContentArea")
    return
end

-- สร้างหน้า Players
local pagePlayers = Instance.new("ScrollingFrame")
pagePlayers.Name = "PagePlayers"
pagePlayers.Size = UDim2.new(1, 0, 1, 0)
pagePlayers.BackgroundTransparency = 1
pagePlayers.BorderSizePixel = 0
pagePlayers.ScrollBarThickness = 3
pagePlayers.ScrollBarImageColor3 = COL.accent
pagePlayers.CanvasSize = UDim2.new(0, 0, 0, 0)
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

-- Player list holder
local listHolder = Instance.new("Frame")
listHolder.Size = UDim2.new(1, -20, 1, -55)
listHolder.Position = UDim2.new(0, 10, 0, 45)
listHolder.BackgroundTransparency = 1
listHolder.Parent = pagePlayers

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = listHolder

-- Refresh button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, -20, 0, 30)
refreshBtn.Position = UDim2.new(0, 10, 1, -40)
refreshBtn.BackgroundColor3 = COL.accent
refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "🔄 รีเฟรชรายชื่อ"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 12
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.Parent = pagePlayers
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)

--============================================================
-- CREATE PLAYER ROW
--============================================================
local function createPlayerRow(targetPlayer)
    local row = Instance.new("Frame")
    row.Name = "Row_" .. targetPlayer.Name
    row.Size = UDim2.new(1, 0, 0, 60)
    row.BackgroundColor3 = COL.bg3
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = listHolder
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    
    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 44, 0, 44)
    avatar.Position = UDim2.new(0, 8, 0, 8)
    avatar.BackgroundColor3 = COL.bg
    avatar.BorderSizePixel = 0
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
    avatar.Parent = row
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 8)
    
    -- Name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -180, 0, 18)
    nameLbl.Position = UDim2.new(0, 58, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = targetPlayer.Name
    nameLbl.TextColor3 = COL.text
    nameLbl.TextSize = 13
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = row
    
    -- User ID
    local idLbl = Instance.new("TextLabel")
    idLbl.Size = UDim2.new(1, -180, 0, 14)
    idLbl.Position = UDim2.new(0, 58, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = "ID: " .. targetPlayer.UserId
    idLbl.TextColor3 = COL.textDim
    idLbl.TextSize = 10
    idLbl.Font = Enum.Font.Gotham
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    idLbl.Parent = row
    
    -- Distance
    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(1, -180, 0, 14)
    distLbl.Position = UDim2.new(0, 58, 0, 38)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "ระยะ: --"
    distLbl.TextColor3 = COL.warn
    distLbl.TextSize = 10
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Parent = row
    
    -- View 3D Button
    local view3DBtn = Instance.new("TextButton")
    view3DBtn.Size = UDim2.new(0, 60, 0, 24)
    view3DBtn.Position = UDim2.new(1, -130, 0, 8)
    view3DBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    view3DBtn.BorderSizePixel = 0
    view3DBtn.Text = "👁 ดู 3D"
    view3DBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    view3DBtn.TextSize = 10
    view3DBtn.Font = Enum.Font.GothamBold
    view3DBtn.Parent = row
    Instance.new("UICorner", view3DBtn).CornerRadius = UDim.new(0, 5)
    view3DBtn.MouseButton1Click:Connect(function()
        local spawnPos = camera.CFrame.Position + camera.CFrame.LookVector * 10
        _G.SG_showPlayerPreview(targetPlayer, spawnPos)
        notify("👁 แสดง 3D: " .. targetPlayer.Name, Color3.fromRGB(140, 80, 255))
    end)
    
    -- Teleport Button
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 60, 0, 24)
    tpBtn.Position = UDim2.new(1, -130, 0, 34)
    tpBtn.BackgroundColor3 = COL.accent
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "🌍 วาร์ป"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.TextSize = 10
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.Parent = row
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)
    tpBtn.MouseButton1Click:Connect(function()
        _G.SG_TeleportToPlayer(targetPlayer)
    end)
    
    -- Copy Info Button
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 26, 0, 26)
    copyBtn.Position = UDim2.new(1, -62, 0, 8)
    copyBtn.BackgroundColor3 = COL.on
    copyBtn.BorderSizePixel = 0
    copyBtn.Text = "📋"
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 12
    copyBtn.Parent = row
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)
    copyBtn.MouseButton1Click:Connect(function()
        _G.SG_CopyPlayerInfo(targetPlayer)
    end)
    
    -- Hide 3D Button
    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0, 26, 0, 26)
    hideBtn.Position = UDim2.new(1, -62, 0, 34)
    hideBtn.BackgroundColor3 = COL.red
    hideBtn.BorderSizePixel = 0
    hideBtn.Text = "❌"
    hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideBtn.TextSize = 12
    hideBtn.Parent = row
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 5)
    hideBtn.MouseButton1Click:Connect(function()
        _G.SG_hidePlayerPreview(targetPlayer)
    end)
    
    -- Distance Update Loop
    task.spawn(function()
        while row.Parent and targetPlayer.Parent do
            task.wait(0.5)
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local tHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and tHRP then
                local dist = (myHRP.Position - tHRP.Position).Magnitude
                distLbl.Text = "ระยะ: " .. math.floor(dist) .. " studs"
            else
                distLbl.Text = "ระยะ: --"
            end
        end
    end)
    
    return row
end

--============================================================
-- REFRESH PLAYER LIST
--============================================================
local function refreshPlayerList()
    for _, c in ipairs(listHolder:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            createPlayerRow(plr)
        end
    end
    listHolder.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

--============================================================
-- ADD SIDEBAR BUTTON
--============================================================
local sidebarBtnHolder = main:FindFirstChild("Sidebar")
    and main.Sidebar:FindFirstChild("sidebarBtnHolder")

if not sidebarBtnHolder then
    for _, v in ipairs(main:GetDescendants()) do
        if v:IsA("Frame") and v.Name == "sidebarBtnHolder" then
            sidebarBtnHolder = v
            break
        end
    end
end

if sidebarBtnHolder and _G.SG_showPage and _G.SG_makeSidebarBtn then
    local bPlayer = _G.SG_makeSidebarBtn("👥  Players", 224, function()
        -- ซ่อนทุกหน้า
        for _, c in ipairs(contentArea:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        -- แสดงหน้า Players
        pagePlayers.Visible = true
        -- Highlight
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
    
    print("[SG] เพิ่มปุ่ม Players เข้า Sidebar แล้ว")
end

--============================================================
-- ADD EXTRA BUTTONS IN UTILITY PAGE
--============================================================
local pageUtility = _G.SG_pageUtility
if pageUtility then
    -- หา y ล่าสุด
    local maxY = 0
    for _, c in ipairs(pageUtility:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then
            local y = c.Position.Y.Offset
            if y + c.Size.Y.Offset > maxY then
                maxY = y + c.Size.Y.Offset
            end
        end
    end
    
    -- เพิ่มปุ่ม Server Hop
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
    
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, -20, 0, 30)
    hopBtn.Position = UDim2.new(0, 10, 0, maxY + 40)
    hopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    hopBtn.BorderSizePixel = 0
    hopBtn.Text = "🌐 Server Hop (ย้ายเซิร์ฟเวอร์)"
    hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hopBtn.TextSize = 12
    hopBtn.Font = Enum.Font.GothamBold
    hopBtn.Parent = pageUtility
    Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 6)
    hopBtn.MouseButton1Click:Connect(_G.SG_ServerHop)
    
    -- เพิ่มปุ่ม Hide All Previews
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
        notify("🗑 ลบ preview ทั้งหมดแล้ว", COL.red)
    end)
    
    pageUtility.CanvasSize = UDim2.new(0, 0, 0, maxY + 120)
end

-- Auto refresh player list
task.spawn(function()
    while _G.SG5_P1 do
        task.wait(5)
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

print("[SG v7.0] P4 โหลดเสร็จ — Player List + 3D Preview พร้อมใช้งาน")
print("════════════════════════════════════════════")
print("✅ SIGMAGOON HUB v7.0 โหลดครบทั้ง 4 ส่วน")
print("📋 8 หน้า: หน้าหลัก / Combat / ดวงตาเทพ / มองบอท / รถถัง / Combat Extras / Utility / Players")
print("🎯 34 ฟีเจอร์: Movement + Combat + ESP + Utility + Server Hop")
print("👁 3D Preview: แสดงโมเดลผู้เล่น 3D หมุนได้")
print("════════════════════════════════════════════")
