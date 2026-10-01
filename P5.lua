--============================================================
-- SIGMAGOON HUB v8.0 — P5 (Anti-Check ขั้นสูง + Patch)
--============================================================
if not _G.SG5_P4 then
    warn("[SG] ต้องรัน P4 ก่อน!")
    return
end
_G.SG5_P5 = true

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local CoreGui    = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = _G.SG_CONFIG
local COL = _G.SG_COL
local notify = _G.SG_notify
local getHRP = _G.SG_getHRP
local getHum = _G.SG_getHum
local makeSidebarBtn = _G.SG_makeSidebarBtn

print("[SG v8.0] P5 เริ่มโหลด")

--============================================================
-- ANTI-CHECK SYSTEM
--============================================================
local ANTI_LOCK = {}
_G.SG_ANTI_LOCK = ANTI_LOCK

local function lockFeature(id, reason)
    ANTI_LOCK[id] = { locked = true, reason = reason or "ไม่รองรับ" }
end
local function unlockFeature(id)
    ANTI_LOCK[id] = nil
end
local function isLocked(id)
    return ANTI_LOCK[id] and ANTI_LOCK[id].locked
end
_G.SG_isLocked = isLocked
_G.SG_lockFeature = lockFeature
_G.SG_unlockFeature = unlockFeature

--============================================================
-- ANTI-CHECK TESTS (20 ตัว)
--============================================================
local ANTI_CHECKS = {
    { id = "walkspeed", name = "WalkSpeed", risk = "ต่ำ", test = function()
        local h = getHum(); if not h then error("ไม่มี Humanoid") end
        local s = h.WalkSpeed; h.WalkSpeed = s + 5; task.wait(0.1); h.WalkSpeed = s
    end },
    { id = "jump", name = "JumpPower", risk = "ต่ำ", test = function()
        local h = getHum(); if not h then error("ไม่มี Humanoid") end
        local s = h.JumpPower; h.JumpPower = s + 10; task.wait(0.1); h.JumpPower = s
    end },
    { id = "hipheight", name = "HipHeight", risk = "กลาง", test = function()
        local h = getHum(); if not h then error("ไม่มี Humanoid") end
        local s = h.HipHeight; h.HipHeight = s + 0.1; task.wait(0.1); h.HipHeight = s
    end },
    { id = "fly_bodyvel", name = "BodyVelocity (Fly)", risk = "สูง", test = function()
        local hrp = getHRP(); if not hrp then error("ไม่มี HRP") end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(1,1,1)
        bv.Parent = hrp; task.wait(0.1); bv:Destroy()
    end },
    { id = "fly_bodygyro", name = "BodyGyro (Fly)", risk = "สูง", test = function()
        local hrp = getHRP(); if not hrp then error("ไม่มี HRP") end
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1,1,1); bg.Parent = hrp
        task.wait(0.1); bg:Destroy()
    end },
    { id = "cframe_warp_small", name = "CFrame Warp 5 studs", risk = "กลาง", test = function()
        local hrp = getHRP(); if not hrp then error("ไม่มี HRP") end
        local s = hrp.CFrame; hrp.CFrame = s + Vector3.new(0,5,0)
        task.wait(0.05); hrp.CFrame = s
    end },
    { id = "cframe_warp_big", name = "Warp 100 studs", risk = "สูงมาก", test = function()
        local hrp = getHRP(); if not hrp then error("ไม่มี HRP") end
        local s = hrp.CFrame; hrp.CFrame = s + Vector3.new(100,0,0)
        task.wait(0.3); if hrp.Parent then hrp.CFrame = s end
    end },
    { id = "maxhealth", name = "MaxHealth = ∞", risk = "สูง", test = function()
        local h = getHum(); if not h then error("ไม่มี Humanoid") end
        local s = h.MaxHealth; h.MaxHealth = math.huge; task.wait(0.1); h.MaxHealth = s
    end },
    { id = "clear_children", name = "Character:ClearAllChildren", risk = "สูงมาก", test = function()
        local c = player.Character
        if not c or not c.ClearAllChildren then error("ไม่มี") end
    end },
    { id = "destroy_char", name = "Character:Destroy", risk = "สูงสุด", test = function()
        local c = player.Character
        if not c or not c.Destroy then error("ไม่พร้อม") end
    end },
    { id = "instance_sss", name = "Instance.new ใน SSS", risk = "สูง", test = function()
        local ok = pcall(function()
            local p = Instance.new("Part")
            p.Parent = game:GetService("ServerScriptService")
            p:Destroy()
        end)
        if not ok then error("block") end
    end },
    { id = "remove_accessory", name = "Delete Accessory", risk = "กลาง", test = function()
        local c = player.Character; if not c then error("ไม่มี") end
        if not c:FindFirstChildOfClass("Accessory") then error("ไม่มี Accessory") end
    end },
    { id = "remote_event", name = "RemoteEvent", risk = "กลาง", test = function()
        local found = false
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") then found = true break end
        end
        if not found then error("ไม่พบ") end
    end },
    { id = "animator", name = "Animator", risk = "กลาง", test = function()
        local h = getHum(); if not h then error("ไม่มี Humanoid") end
        if not h:FindFirstChildOfClass("Animator") then error("ไม่มี Animator") end
    end },
    { id = "nocollide", name = "CanCollide = false", risk = "ต่ำ", test = function()
        local c = player.Character; if not c then error("ไม่มี") end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then error("ไม่มี HRP") end
        local s = hrp.CanCollide; hrp.CanCollide = false
        task.wait(0.1); hrp.CanCollide = s
    end },
    { id = "transparency", name = "Transparency = 1", risk = "ต่ำ", test = function()
        local c = player.Character; if not c then error("ไม่มี") end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                local s = d.Transparency
                d.Transparency = 1
                task.wait(0.05)
                d.Transparency = s
                break
            end
        end
    end },
    { id = "vehicle_seat", name = "VehicleSeat", risk = "ต่ำ", test = function()
        local h = getHum(); if not h then error("ไม่มี") end
        if not h.SeatPart and not h.Sit then error("ไม่มี Seat API") end
    end },
    { id = "raycast", name = "workspace:Raycast", risk = "ต่ำ", test = function()
        workspace:Raycast(Vector3.new(0,100,0), Vector3.new(0,-200,0))
    end },
    { id = "sound_play", name = "Sound:Play", risk = "ต่ำ", test = function()
        local s = Instance.new("Sound")
        s.Parent = workspace
        local ok = pcall(function() s:Play() end)
        s:Destroy()
        if not ok then error("block") end
    end },
    { id = "camera_cframe", name = "Camera CFrame", risk = "กลาง", test = function()
        local save = camera.CFrame
        camera.CFrame = save * CFrame.new(0, 0.01, 0)
        task.wait(0.05)
        camera.CFrame = save
    end },
}
_G.SG_ANTI_CHECKS = ANTI_CHECKS

--============================================================
-- หา GUI
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

-- ลบหน้า Anti เก่า (ถ้ามี)
local oldAnti = contentArea:FindFirstChild("PageAnti")
if oldAnti then oldAnti:Destroy() end

-- สร้างหน้า Anti-Check
local pageAnti = Instance.new("ScrollingFrame")
pageAnti.Name = "PageAnti"
pageAnti.Size = UDim2.new(1, 0, 1, 0)
pageAnti.BackgroundTransparency = 1
pageAnti.BorderSizePixel = 0
pageAnti.ScrollBarThickness = 3
pageAnti.ScrollBarImageColor3 = COL.accent
pageAnti.CanvasSize = UDim2.new(0, 0, 0, 0)
pageAnti.AutomaticCanvasSize = Enum.AutomaticSize.Y
pageAnti.ScrollingDirection = Enum.ScrollingDirection.Y
pageAnti.Visible = false
pageAnti.Parent = contentArea
Instance.new("UICorner", pageAnti).CornerRadius = UDim.new(0, 8)

local ctx = { y = 10 }

local function section(text)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -20, 0, 24)
    h.Position = UDim2.new(0, 10, 0, ctx.y)
    h.BackgroundColor3 = COL.bg3
    h.BackgroundTransparency = 0.4
    h.BorderSizePixel = 0
    h.Parent = pageAnti
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
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

local function label(text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 16)
    l.Position = UDim2.new(0, 10, 0, ctx.y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or COL.textDim
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = pageAnti
    ctx.y = ctx.y + 18
    return l
end

local function button(text, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, ctx.y)
    b.BackgroundColor3 = color or COL.accent
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.Parent = pageAnti
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    if callback then b.MouseButton1Click:Connect(callback) end
    ctx.y = ctx.y + 36
    return b
end

-- Header
section("🛡 ANTI-CHECK ขั้นสูง")
label("สแกนฟีเจอร์ + ล็อคสวิตช์ที่ใช้ไม่ได้", COL.textDim)

local statusLabel = label("กดปุ่ม 'สแกนทั้งหมด' เพื่อเริ่ม", COL.textDim)

-- Result holder
local resultHolder = Instance.new("Frame")
resultHolder.Size = UDim2.new(1, -20, 0, 20)
resultHolder.Position = UDim2.new(0, 10, 0, ctx.y)
resultHolder.BackgroundTransparency = 1
resultHolder.AutomaticSize = Enum.AutomaticSize.Y
resultHolder.Parent = pageAnti
ctx.y = ctx.y + 20

local resultLayout = Instance.new("UIListLayout")
resultLayout.Padding = UDim.new(0, 4)
resultLayout.Parent = resultHolder

local function getRiskColor(risk)
    if risk:find("สูงสุด") or risk:find("สูงมาก") then return Color3.fromRGB(255, 60, 60) end
    if risk:find("สูง") then return Color3.fromRGB(255, 120, 40) end
    if risk:find("กลาง") then return Color3.fromRGB(255, 200, 60) end
    return Color3.fromRGB(0, 200, 100)
end

local function clearResults()
    for _, c in ipairs(resultHolder:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function addResult(check, ok)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = ok and Color3.fromRGB(30, 55, 40) or Color3.fromRGB(55, 30, 30)
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.Parent = resultHolder
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0, 70, 0, 16)
    statusLbl.Position = UDim2.new(0, 8, 0, 4)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = ok and "✅ ผ่าน" or "🔒 ล็อค"
    statusLbl.TextColor3 = ok and COL.green or Color3.fromRGB(120, 120, 130)
    statusLbl.TextSize = 11
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = row

    local riskLbl = Instance.new("TextLabel")
    riskLbl.Size = UDim2.new(0, 120, 0, 16)
    riskLbl.Position = UDim2.new(0, 80, 0, 4)
    riskLbl.BackgroundTransparency = 1
    riskLbl.Text = "เสี่ยง: " .. check.risk
    riskLbl.TextColor3 = getRiskColor(check.risk)
    riskLbl.TextSize = 11
    riskLbl.Font = Enum.Font.GothamBold
    riskLbl.TextXAlignment = Enum.TextXAlignment.Left
    riskLbl.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -8, 0, 16)
    nameLbl.Position = UDim2.new(0, 8, 0, 22)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = check.name .. "  [" .. check.id .. "]"
    nameLbl.TextColor3 = COL.text
    nameLbl.TextSize = 11
    nameLbl.Font = Enum.Font.Gotham
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = row
end

-- ปุ่มสแกน
button("🔍 สแกนทั้งหมด (ปลอดภัย)", COL.accent, function()
    clearResults()
    statusLabel.Text = "กำลังสแกน..."
    statusLabel.TextColor3 = COL.accent

    task.spawn(function()
        local lockedCount = 0
        for _, check in ipairs(ANTI_CHECKS) do
            local ok = pcall(check.test)
            addResult(check, ok)
            if not ok then
                lockFeature(check.id, check.name .. " ไม่รองรับ")
                lockedCount = lockedCount + 1
            else
                unlockFeature(check.id)
            end
            task.wait(0.05)
        end
        statusLabel.Text = string.format("สแกนเสร็จ — ล็อค %d / %d รายการ", lockedCount, #ANTI_CHECKS)
        statusLabel.TextColor3 = lockedCount > 0 and COL.warn or COL.green

        -- Refresh toggle ทั้งหมด
        for id, _ in pairs(ANTI_LOCK) do
            local refresh = _G["refreshToggle_" .. id]
            if refresh and type(refresh) == "function" then
                pcall(refresh)
            end
        end
    end)
end)

-- ปุ่มปลดล็อค
button("🔓 ปลดล็อคทั้งหมด", COL.warn, function()
    for id, _ in pairs(ANTI_LOCK) do
        unlockFeature(id)
    end
    statusLabel.Text = "ปลดล็อคทั้งหมดแล้ว"
    statusLabel.TextColor3 = COL.green

    for id, _ in pairs(_G) do
        if type(id) == "string" and id:find("^refreshToggle_") then
            pcall(_G[id])
        end
    end
end)

label("⚠ สวิตช์ 🔒 = ระบบนั้นไม่รองรับในเกม", COL.warn)

--============================================================
-- PATCH: Override showPage (ซ่อนทุก ScrollingFrame)
--============================================================
if _G.SG_showPage and contentArea then
    local originalShowPage = _G.SG_showPage
    _G.SG_showPage = function(idx)
        for _, c in ipairs(contentArea:GetChildren()) do
            if c:IsA("ScrollingFrame") then
                c.Visible = false
            end
        end
        originalShowPage(idx)
    end
end

--============================================================
-- เพิ่มปุ่ม Anti-Check ใน Sidebar
--============================================================
if sidebarBtnHolder and makeSidebarBtn then
    for _, c in ipairs(sidebarBtnHolder:GetChildren()) do
        if c:IsA("TextButton") and c.Text:find("Anti") then
            c:Destroy()
        end
    end

    local bAnti = makeSidebarBtn("🛡  Anti-Check", 252, function()
        for _, c in ipairs(contentArea:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        pageAnti.Visible = true

        for _, c in ipairs(sidebarBtnHolder:GetChildren()) do
            if c:IsA("TextButton") then
                Tween:Create(c, TweenInfo.new(0.15), {
                    BackgroundColor3 = COL.bg3,
                    BackgroundTransparency = 0.5,
                    TextColor3 = COL.textDim,
                }):Play()
            end
        end
        Tween:Create(bAnti, TweenInfo.new(0.15), {
            BackgroundColor3 = COL.accent,
            BackgroundTransparency = 0,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }):Play()
    end)

    print("[SG v8.0] เพิ่มปุ่ม Anti-Check แล้ว")
end

print("[SG v8.0] P5 โหลดเสร็จ — Anti-Check 20 tests + ล็อคสวิตช์")
print("════════════════════════════════════════════")
print("✅ SIGMAGOON HUB v8.0 โหลดครบทั้ง 5 ไฟล์")
print("📋 9 หน้า: Movement / Combat / ESP Player / ESP Bot / ESP Vehicle / Combat Extras / Utility / Players / Anti-Check / Settings")
print("🛡 Anti-Check: 20 tests + ล็อคสวิตช์")
print("👁 3D Preview: แสดงโมเดลผู้เล่น 3D")
print("════════════════════════════════════════════")
