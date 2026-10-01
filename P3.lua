--============================================================
-- SIGMAGOON HUB v8.0 — P3 (Combat Extras + Utilities)
--============================================================
if not _G.SG5_P2 then
    warn("[SG] ต้องรัน P2 ก่อน!")
    return
end
_G.SG5_P3 = true

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local CoreGui    = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting   = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local CONFIG = _G.SG_CONFIG
local getHRP = _G.SG_getHRP
local getHum = _G.SG_getHum
local isSameTeam = _G.SG_isSameTeam
local COL = _G.SG_COL
local pageCombat = _G.SG_pageCombat
local pageUtility = _G.SG_pageUtility
local applyLowGraphics = _G.SG_applyLowGraphics
local revertGraphics = _G.SG_revertGraphics

print("[SG v8.0] P3 เริ่มโหลด")

--============================================================
-- CONFIG เพิ่มเติม
--============================================================
CONFIG.TriggerBotEnabled = false
CONFIG.TriggerBotDelay = 0.05
CONFIG.TriggerBotHitChance = 100

CONFIG.SilentAimEnabled = false
CONFIG.SilentAimFOV = 90
CONFIG.SilentAimHitPart = "Head"
CONFIG.SilentAimTeamCheck = true

CONFIG.AimPredictionEnabled = false
CONFIG.AimPredictionAmount = 0.15
CONFIG.TargetPriority = "closest"

CONFIG.AntiAFKEnabled = false
CONFIG.SoundDisableEnabled = false
CONFIG.AntiFlingEnabled = false
CONFIG.AntiRagdollEnabled = false
CONFIG.RGBUIEnabled = false
CONFIG.FreeCamEnabled = false
CONFIG.FootstepESPEnabled = false
CONFIG.HitMarkerEnabled = false

CONFIG.AntiVoidEnabled = false
CONFIG.AntiVoidY = -50
CONFIG.AutoRespawnEnabled = false
CONFIG.AutoRespawnDelay = 3
CONFIG.HitboxEnabled = false
CONFIG.HitboxSize = 5
CONFIG.WallWalkEnabled = false
CONFIG.SafeModeEnabled = false
CONFIG.SafeModeMaxSpeed = 100

--============================================================
-- NOTIFICATION SYSTEM
--============================================================
local notificationGui = Instance.new("ScreenGui")
notificationGui.Name = "SG_Notification"
notificationGui.ResetOnSpawn = false
notificationGui.Parent = CoreGui

_G.SG_notify = function(text, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 280, 0, 44)
    notif.Position = UDim2.new(0.5, -140, 1, 20)
    notif.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.Parent = notificationGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 1.5
    stroke.Parent = notif

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 240, 245)
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notif

    Tween:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -140, 1, -60)
    }):Play()

    task.delay(3, function()
        if not notif or not notif.Parent then return end
        Tween:Create(notif, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -140, 1, 20),
        }):Play()
        task.delay(0.3, function()
            if notif and notif.Parent then notif:Destroy() end
        end)
    end)
end

local notify = _G.SG_notify

--============================================================
-- TRIGGER BOT
--============================================================
local triggerLastFire = 0

RunService.RenderStepped:Connect(function()
    if not CONFIG.TriggerBotEnabled then return end
    local now = tick()
    if now - triggerLastFire < CONFIG.TriggerBotDelay then return end

    local target = mouse.Target
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local plr = Players:GetPlayerFromCharacter(model)
    if not plr or plr == player then return end
    if isSameTeam(plr) then return end
    if math.random(1, 100) > CONFIG.TriggerBotHitChance then return end

    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        triggerLastFire = now
        if _G.SG_showHitMarker then _G.SG_showHitMarker() end
    end
end)

--============================================================
-- SILENT AIM
--============================================================
local silentTarget = nil
local silentTargetPos = nil

local function findSilentTarget()
    if not CONFIG.SilentAimEnabled then return nil, nil end
    local camPos = camera.CFrame.Position
    local camLook = camera.CFrame.LookVector
    local best, bestPos, bestScore = nil, nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not (CONFIG.SilentAimTeamCheck and isSameTeam(plr)) then
            local char = plr.Character
            if char then
                local tp = char:FindFirstChild(CONFIG.SilentAimHitPart)
                    or char:FindFirstChild("Head")
                    or char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if tp and hum and hum.Health > 0 then
                    local toT = tp.Position - camPos
                    local dist = toT.Magnitude
                    if dist <= CONFIG.AimbotMaxDist then
                        local angle = math.deg(math.acos(math.clamp(
                            toT.Unit:Dot(camLook), -1, 1)))
                        if angle <= CONFIG.SilentAimFOV / 2 then
                            local score = angle + dist * 0.001
                            if score < bestScore then
                                bestScore = score
                                best = char
                                bestPos = tp.Position
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestPos
end

task.spawn(function()
    while _G.SG5_P1 do
        task.wait(0.03)
        local t, pos = findSilentTarget()
        silentTarget = t
        silentTargetPos = pos
    end
end)

-- Hook VisualizeBullet
local RS = game:GetService("ReplicatedStorage")
local visualBullet = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("VisualizeBullet")

if visualBullet then
    local mt = getrawmetatable(game)
    if mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if self == visualBullet and getnamecallmethod() == "FireServer" 
                and CONFIG.SilentAimEnabled and silentTargetPos then
                local args = {...}
                if args[4] and args[4]:IsA("Attachment") then
                    local origin = args[4].WorldPosition
                    local dir = (silentTargetPos - origin).Unit

                    if args[3] and type(args[3]) == "table" then
                        local newArgs3 = {}
                        for k, v in pairs(args[3]) do newArgs3[k] = v end
                        args[3] = newArgs3
                        if args[3][1] and args[3][1][1] then
                            args[3][1][1] = dir
                        end
                    end
                    if args[6] and type(args[6]) == "table" then
                        local newArgs6 = {}
                        for k, v in pairs(args[6]) do newArgs6[k] = v end
                        args[6] = newArgs6
                        if args[6][1] and args[6][1].MousePosition then
                            args[6][1].MousePosition = silentTargetPos
                        end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        print("[SG] Silent Aim hook สำเร็จ")
    end
end

--============================================================
-- AIM PREDICTION
--============================================================
_G.SG_predictTargetPosition = function(char, part, t)
    if not CONFIG.AimPredictionEnabled or t <= 0 then
        return part.Position
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    return part.Position + hrp.AssemblyLinearVelocity * t
end

--============================================================
-- TARGET PRIORITY
--============================================================
_G.SG_findPriorityTarget = function()
    local camPos = camera.CFrame.Position
    local camLook = camera.CFrame.LookVector
    local vp = camera.ViewportSize
    local best, bestScore, bestPart = nil, math.huge, nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not isSameTeam(plr) then
            local char = plr.Character
            if char then
                local tp = char:FindFirstChild("Head")
                    or char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if tp and hum and hum.Health > 0 then
                    local dist = (tp.Position - camPos).Magnitude
                    if dist <= CONFIG.AimbotMaxDist then
                        local score
                        if CONFIG.TargetPriority == "closest" then
                            score = dist
                        elseif CONFIG.TargetPriority == "lowest_hp" then
                            score = hum.Health
                        elseif CONFIG.TargetPriority == "center" then
                            local sp, onScreen = camera:WorldToViewportPoint(tp.Position)
                            if onScreen then
                                local center = Vector2.new(vp.X/2, vp.Y/2)
                                local pt = Vector2.new(sp.X, sp.Y)
                                score = (pt - center).Magnitude
                            else
                                score = math.huge
                            end
                        else
                            score = dist
                        end
                        if score < bestScore then
                            bestScore = score
                            best = char
                            bestPart = tp
                        end
                    end
                end
            end
        end
    end
    return best, bestPart
end

--============================================================
-- ANTI-AFK
--============================================================
local antiAFKConn
_G.SG_setAntiAFK = function(state)
    CONFIG.AntiAFKEnabled = state
    if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
    if state then
        antiAFKConn = RunService.Heartbeat:Connect(function()
            if not CONFIG.AntiAFKEnabled then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

--============================================================
-- SOUND DISABLE
--============================================================
local soundBackup = {}
_G.SG_setSoundDisable = function(state)
    CONFIG.SoundDisableEnabled = state
    if state then
        for _, s in ipairs(game:GetService("SoundService"):GetDescendants()) do
            if s:IsA("Sound") then
                soundBackup[s] = s.Volume
                s.Volume = 0
            end
        end
    else
        for s, vol in pairs(soundBackup) do
            if s and s.Parent then s.Volume = vol end
        end
        table.clear(soundBackup)
    end
end

--============================================================
-- ANTI-FLING
--============================================================
RunService.Heartbeat:Connect(function()
    if not CONFIG.AntiFlingEnabled then return end
    local hrp = getHRP()
    if not hrp then return end
    if hrp.AssemblyLinearVelocity.Magnitude > 500 then
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity.Unit * 500
    end
    if hrp.AssemblyAngularVelocity.Magnitude > 100 then
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end)

--============================================================
-- ANTI-RAGDOLL
--============================================================
RunService.Heartbeat:Connect(function()
    if not CONFIG.AntiRagdollEnabled then return end
    local hum = getHum()
    if not hum then return end
    pcall(function()
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics 
            or state == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end)

--============================================================
-- ANTI-VOID
--============================================================
RunService.Heartbeat:Connect(function()
    if not CONFIG.AntiVoidEnabled then return end
    local hrp = getHRP()
    if not hrp then return end
    if hrp.Position.Y < CONFIG.AntiVoidY then
        if _G.SG_savedSpawnCFrame then
            hrp.CFrame = _G.SG_savedSpawnCFrame
        else
            hrp.CFrame = CFrame.new(0, 50, 0)
        end
        if notify then notify("⚠ Anti-Void: วาร์ปกลับ!", COL.warn) end
    end
end)

--============================================================
-- AUTO RESPAWN
--============================================================
local lastDeathTime = 0
task.spawn(function()
    while _G.SG5_P1 do
        task.wait(0.5)
        if CONFIG.AutoRespawnEnabled then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                if tick() - lastDeathTime > CONFIG.AutoRespawnDelay then
                    lastDeathTime = tick()
                    pcall(function() player:LoadCharacter() end)
                    if notify then notify("💀 Auto-Respawn แล้ว", COL.accent) end
                end
            end
        end
    end
end)

--============================================================
-- HITBOX EXPANDER
--============================================================
local hitboxBackup = {}
RunService.Heartbeat:Connect(function()
    if not CONFIG.HitboxEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not hitboxBackup[hrp] then
                        hitboxBackup[hrp] = hrp.Size
                    end
                    hrp.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                    hrp.Material = Enum.Material.Neon
                    hrp.Color = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
end)

_G.SG_restoreHitbox = function()
    for hrp, size in pairs(hitboxBackup) do
        if hrp and hrp.Parent then
            hrp.Size = size
            hrp.Transparency = 1
            hrp.CanCollide = true
        end
    end
    table.clear(hitboxBackup)
end

--============================================================
-- WALL WALK
--============================================================
RunService.Heartbeat:Connect(function()
    if not CONFIG.WallWalkEnabled then return end
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.PlatformStand = true end)
end)

--============================================================
-- SAFE MODE
--============================================================
RunService.Heartbeat:Connect(function()
    if not CONFIG.SafeModeEnabled then return end
    local hum = getHum()
    if hum then
        if hum.WalkSpeed > CONFIG.SafeModeMaxSpeed then
            hum.WalkSpeed = CONFIG.SafeModeMaxSpeed
        end
        if hum.JumpPower > 200 then
            hum.JumpPower = 200
        end
    end
end)

--============================================================
-- RGB UI
--============================================================
local rgbHue = 0
RunService.RenderStepped:Connect(function(dt)
    if not CONFIG.RGBUIEnabled then return end
    rgbHue = (rgbHue + dt * 0.3) % 1
end)

--============================================================
-- FREE CAMERA
--============================================================
local freeCamCF = CFrame.new()
_G.SG_setFreeCam = function(state)
    CONFIG.FreeCamEnabled = state
    if state then
        freeCamCF = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
    else
        camera.CameraType = Enum.CameraType.Custom
    end
end

RunService.RenderStepped:Connect(function(dt)
    if not CONFIG.FreeCamEnabled then return end
    local move = Vector3.zero
    if UserInput:IsKeyDown(Enum.KeyCode.W) then move = move + camera.CFrame.LookVector end
    if UserInput:IsKeyDown(Enum.KeyCode.S) then move = move - camera.CFrame.LookVector end
    if UserInput:IsKeyDown(Enum.KeyCode.A) then move = move - camera.CFrame.RightVector end
    if UserInput:IsKeyDown(Enum.KeyCode.D) then move = move + camera.CFrame.RightVector end
    if UserInput:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
    if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
    if move.Magnitude > 0 then
        freeCamCF = freeCamCF + move.Unit * 50 * dt
    end
    camera.CFrame = freeCamCF
end)

--============================================================
-- FOOTSTEP ESP
--============================================================
local footstepFolder = Instance.new("Folder")
footstepFolder.Name = "__Footsteps"
footstepFolder.Parent = workspace
local footstepData = {}

_G.SG_setFootstepESP = function(state)
    CONFIG.FootstepESPEnabled = state
    if not state then
        for _, f in ipairs(footstepFolder:GetChildren()) do f:Destroy() end
        table.clear(footstepData)
    end
end

RunService.Heartbeat:Connect(function()
    if not CONFIG.FootstepESPEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not isSameTeam(plr) then
            local char = plr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.MoveDirection.Magnitude > 0.1 then
                    local last = footstepData[plr] or 0
                    if tick() - last > 0.3 then
                        footstepData[plr] = tick()
                        local foot = Instance.new("Part")
                        foot.Size = Vector3.new(1, 0.1, 1)
                        foot.Position = hrp.Position - Vector3.new(0, 2.5, 0)
                        foot.Anchored = true
                        foot.CanCollide = false
                        foot.Material = Enum.Material.Neon
                        foot.Color = CONFIG.PlayerESPColor
                        foot.Transparency = 0.5
                        foot.Parent = footstepFolder
                        Tween:Create(foot, TweenInfo.new(2), { Transparency = 1 }):Play()
                        task.delay(2, function()
                            if foot and foot.Parent then foot:Destroy() end
                        end)
                    end
                end
            end
        end
    end
end)

--============================================================
-- HIT MARKER
--============================================================
local hitMarkerGui = Instance.new("ScreenGui")
hitMarkerGui.Name = "SG_HitMarker"
hitMarkerGui.ResetOnSpawn = false
hitMarkerGui.Parent = CoreGui

local hitMarkerFrame = Instance.new("Frame")
hitMarkerFrame.Size = UDim2.new(0, 30, 0, 30)
hitMarkerFrame.Position = UDim2.new(0.5, -15, 0.5, -15)
hitMarkerFrame.BackgroundTransparency = 1
hitMarkerFrame.Parent = hitMarkerGui

local hitLines = {}
for i = 1, 4 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 2, 0, 8)
    line.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0.5, 0, 0.5, 0)
    line.Rotation = (i - 1) * 45 + 45
    line.Visible = false
    line.Parent = hitMarkerFrame
    table.insert(hitLines, line)
end

_G.SG_showHitMarker = function()
    if not CONFIG.HitMarkerEnabled then return end
    for _, line in ipairs(hitLines) do
        line.Visible = true
        line.BackgroundTransparency = 0
        Tween:Create(line, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    end
end

--============================================================
-- SAVE / LOAD CONFIG
--============================================================
_G.SG_saveConfig = function()
    local data = {}
    for k, v in pairs(CONFIG) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            data[k] = v
        elseif type(v) == "table" then
            data[k] = v
        end
    end
    local json = HttpService:JSONEncode(data)
    if writefile then
        pcall(function() writefile("sigmagoon_config.json", json) end)
        if notify then notify("💾 บันทึก config แล้ว", Color3.fromRGB(0, 255, 100)) end
        return true
    end
    return false
end

_G.SG_loadConfig = function()
    if not isfile or not readfile then return false end
    if not isfile("sigmagoon_config.json") then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile("sigmagoon_config.json"))
    end)
    if ok and data then
        for k, v in pairs(data) do CONFIG[k] = v end
        if notify then notify("📂 โหลด config แล้ว", Color3.fromRGB(0, 200, 255)) end
        return true
    end
    return false
end

--============================================================
-- CUSTOM CROSSHAIR
--============================================================
CONFIG.CrosshairEnabled = false
CONFIG.CrosshairSize = 20
CONFIG.CrosshairColor = Color3.fromRGB(0, 255, 100)
CONFIG.CrosshairStyle = "cross"

local crosshairGui = nil

local function createCrosshair()
    if crosshairGui then crosshairGui:Destroy() end
    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "SG_Crosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    crosshairGui.Parent = CoreGui

    local size = CONFIG.CrosshairSize
    for i = 1, 4 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 2, 0, size)
        line.BackgroundColor3 = CONFIG.CrosshairColor
        line.BorderSizePixel = 0
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.new(0.5, 0, 0.5, 0)
        line.Rotation = (i-1) * 90
        line.Parent = crosshairGui
        local offset = size / 2 + 2
        if i == 1 then line.Position = UDim2.new(0.5, 0, 0.5, -offset)
        elseif i == 2 then line.Position = UDim2.new(0.5, offset, 0.5, 0)
        elseif i == 3 then line.Position = UDim2.new(0.5, 0, 0.5, offset)
        elseif i == 4 then line.Position = UDim2.new(0.5, -offset, 0.5, 0) end
    end
end

_G.SG_setCrosshair = function(state)
    CONFIG.CrosshairEnabled = state
    if state then createCrosshair()
    else
        if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    end
end

--============================================================
-- AUTO PLAY
--============================================================
CONFIG.AutoPlayEnabled = false
task.spawn(function()
    while _G.SG5_P1 do
        task.wait(0.5)
        if CONFIG.AutoPlayEnabled then
            local hum = getHum()
            if hum then
                local dir = Vector3.new(
                    math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)
                hum:Move(dir, false)
                task.wait(math.random(1, 3))
                hum:Move(Vector3.zero, false)
                task.wait(math.random(0.5, 1))
            end
        end
    end
end)

--============================================================
-- EMOTE
--============================================================
_G.SG_Emote = function(text)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = head
    billboard.Parent = head
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    Tween:Create(billboard, TweenInfo.new(1.5), {
        StudsOffset = Vector3.new(0, 8, 0)
    }):Play()
    task.delay(1.5, function()
        if billboard and billboard.Parent then billboard:Destroy() end
    end)
end

--============================================================
-- CHAT SPAM
--============================================================
CONFIG.ChatSpamEnabled = false
CONFIG.ChatSpamMessage = "SIGMAGOON ON TOP"
CONFIG.ChatSpamInterval = 2

task.spawn(function()
    while _G.SG5_P1 do
        task.wait(CONFIG.ChatSpamInterval)
        if CONFIG.ChatSpamEnabled then
            pcall(function()
                local chatEvent = RS:FindFirstChild("DefaultChatSystemChatEvents")
                if chatEvent then
                    local sayMsg = chatEvent:FindFirstChild("SayMessageRequest")
                    if sayMsg then
                        sayMsg:FireServer(CONFIG.ChatSpamMessage, "All")
                    end
                end
            end)
        end
    end
end)

--============================================================
-- UI — เพิ่มในหน้า Combat (Combat Extras)
--============================================================
if pageCombat then
    for _, c in ipairs(pageCombat:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then
            c:Destroy()
        end
    end

    local ctx = { y = 10 }
    local function section(text)
        local h = Instance.new("Frame")
        h.Size = UDim2.new(1, -20, 0, 24)
        h.Position = UDim2.new(0, 10, 0, ctx.y)
        h.BackgroundColor3 = COL.bg3
        h.BackgroundTransparency = 0.4
        h.BorderSizePixel = 0
        h.Parent = pageCombat
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

    local function toggle(label, get, set)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 34)
        row.Position = UDim2.new(0, 10, 0, ctx.y)
        row.BackgroundColor3 = COL.bg3
        row.BackgroundTransparency = 0.4
        row.BorderSizePixel = 0
        row.Parent = pageCombat
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
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
        sw.BackgroundColor3 = get() and COL.on or COL.off
        sw.BorderSizePixel = 0
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = row
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = get() and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = sw
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
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
        ctx.y = ctx.y + 38
    end

    local function slider(label, minV, maxV, get, set)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -20, 0, 46)
        holder.Position = UDim2.new(0, 10, 0, ctx.y)
        holder.BackgroundColor3 = COL.bg3
        holder.BackgroundTransparency = 0.4
        holder.BorderSizePixel = 0
        holder.Parent = pageCombat
        Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = COL.text        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = holder
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -20, 0, 5)
        bg.Position = UDim2.new(0, 10, 0, 28)
        bg.BackgroundColor3 = COL.off
        bg.BorderSizePixel = 0
        bg.Parent = holder
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = COL.accent
        fill.BorderSizePixel = 0
        fill.Parent = bg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = bg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local function refresh()
            local v = get()
            local rel = math.clamp((v-minV)/(maxV-minV), 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            lbl.Text = label .. ": " .. tostring(math.floor(v))
        end
        local dragging = false
        bg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        UserInput.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local rel = math.clamp((input.Position.X - bg.AbsolutePosition.X) / math.max(bg.AbsoluteSize.X, 1), 0, 1)
                set(minV + rel*(maxV-minV))
                refresh()
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
        b.Parent = pageCombat
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        if callback then b.MouseButton1Click:Connect(callback) end
        ctx.y = ctx.y + 36
    end

    section("⚡ TRIGGER BOT")
    toggle("เปิด Trigger Bot", function() return CONFIG.TriggerBotEnabled end,
        function(v) CONFIG.TriggerBotEnabled = v end)
    slider("ดีเลย์ (ms)", 10, 500, function() return CONFIG.TriggerBotDelay * 1000 end,
        function(v) CONFIG.TriggerBotDelay = v / 1000 end)
    slider("ความแม่น %", 10, 100, function() return CONFIG.TriggerBotHitChance end,
        function(v) CONFIG.TriggerBotHitChance = v end)

    section("🎯 SILENT AIM")
    toggle("เปิด Silent Aim", function() return CONFIG.SilentAimEnabled end,
        function(v) CONFIG.SilentAimEnabled = v end)
    slider("FOV", 10, 180, function() return CONFIG.SilentAimFOV end,
        function(v) CONFIG.SilentAimFOV = v end)
    toggle("ไม่ยิงทีมเดียวกัน", function() return CONFIG.SilentAimTeamCheck end,
        function(v) CONFIG.SilentAimTeamCheck = v end)

    section("📊 AIM PREDICTION")
    toggle("ทำนายตำแหน่ง", function() return CONFIG.AimPredictionEnabled end,
        function(v) CONFIG.AimPredictionEnabled = v end)
    slider("ทำนายล่วงหน้า (ms)", 0, 500, function() return CONFIG.AimPredictionAmount * 1000 end,
        function(v) CONFIG.AimPredictionAmount = v / 1000 end)

    section("🎯 TARGET PRIORITY")
    button("ใกล้สุด", CONFIG.TargetPriority == "closest" and COL.on or COL.bg3,
        function()
            CONFIG.TargetPriority = "closest"
            if notify then notify("เป้า: ใกล้สุด", COL.accent) end
        end)
    button("HP น้อยสุด", CONFIG.TargetPriority == "lowest_hp" and COL.on or COL.bg3,
        function()
            CONFIG.TargetPriority = "lowest_hp"
            if notify then notify("เป้า: HP น้อยสุด", COL.accent) end
        end)
    button("กลางจอ", CONFIG.TargetPriority == "center" and COL.on or COL.bg3,
        function()
            CONFIG.TargetPriority = "center"
            if notify then notify("เป้า: กลางจอ", COL.accent) end
        end)

    section("🔔 HIT MARKER")
    toggle("แสดง Hit Marker", function() return CONFIG.HitMarkerEnabled end,
        function(v) CONFIG.HitMarkerEnabled = v end)

    section("👣 FOOTSTEP ESP")
    toggle("แสดงรอยเท้า", function() return CONFIG.FootstepESPEnabled end,
        function(v) _G.SG_setFootstepESP(v) end)

    pageCombat.CanvasSize = UDim2.new(0, 0, 0, ctx.y + 20)
end

--============================================================
-- UI — เพิ่มในหน้า Utility
--============================================================
if pageUtility then
    for _, c in ipairs(pageUtility:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then
            c:Destroy()
        end
    end

    local ctx = { y = 10 }
    local function section(text)
        local h = Instance.new("Frame")
        h.Size = UDim2.new(1, -20, 0, 24)
        h.Position = UDim2.new(0, 10, 0, ctx.y)
        h.BackgroundColor3 = COL.bg3
        h.BackgroundTransparency = 0.4
        h.BorderSizePixel = 0
        h.Parent = pageUtility
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
    local function toggle(label, get, set)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 34)
        row.Position = UDim2.new(0, 10, 0, ctx.y)
        row.BackgroundColor3 = COL.bg3
        row.BackgroundTransparency = 0.4
        row.BorderSizePixel = 0
        row.Parent = pageUtility
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
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
        sw.BackgroundColor3 = get() and COL.on or COL.off
        sw.BorderSizePixel = 0
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = row
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = get() and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = sw
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
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
        ctx.y = ctx.y + 38
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
        b.Parent = pageUtility
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        if callback then b.MouseButton1Click:Connect(callback) end
        ctx.y = ctx.y + 36
    end

    section("🛡 DEFENSE")
    toggle("Anti-AFK", function() return CONFIG.AntiAFKEnabled end,
        function(v) _G.SG_setAntiAFK(v) end)
    toggle("ปิดเสียงทั้งหมด", function() return CONFIG.SoundDisableEnabled end,
        function(v) _G.SG_setSoundDisable(v) end)
    toggle("Anti-Fling (กันปั่น)", function() return CONFIG.AntiFlingEnabled end,
        function(v) CONFIG.AntiFlingEnabled = v end)
    toggle("Anti-Ragdoll", function() return CONFIG.AntiRagdollEnabled end,
        function(v) CONFIG.AntiRagdollEnabled = v end)
    toggle("Anti-Void (กันตก)", function() return CONFIG.AntiVoidEnabled end,
        function(v) CONFIG.AntiVoidEnabled = v end)
    toggle("Auto-Respawn", function() return CONFIG.AutoRespawnEnabled end,
        function(v) CONFIG.AutoRespawnEnabled = v end)
    toggle("Safe Mode", function() return CONFIG.SafeModeEnabled end,
        function(v) CONFIG.SafeModeEnabled = v end)

    section("🎬 VISUAL")
    toggle("RGB UI", function() return CONFIG.RGBUIEnabled end,
        function(v) CONFIG.RGBUIEnabled = v end)
    toggle("Free Camera", function() return CONFIG.FreeCamEnabled end,
        function(v) _G.SG_setFreeCam(v) end)
    toggle("Custom Crosshair", function() return CONFIG.CrosshairEnabled end,
        function(v) _G.SG_setCrosshair(v) end)
    toggle("Hitbox Expander", function() return CONFIG.HitboxEnabled end,
        function(v)
            CONFIG.HitboxEnabled = v
            if not v then _G.SG_restoreHitbox() end
        end)
    toggle("Wall Walk", function() return CONFIG.WallWalkEnabled end,
        function(v) CONFIG.WallWalkEnabled = v end)

    section("🎮 AUTO")
    toggle("Auto Play", function() return CONFIG.AutoPlayEnabled end,
        function(v) CONFIG.AutoPlayEnabled = v end)
    toggle("Chat Spam", function() return CONFIG.ChatSpamEnabled end,
        function(v) CONFIG.ChatSpamEnabled = v end)

    section("📸 TOOLS")
    button("💾 บันทึก Config", COL.on, _G.SG_saveConfig)
    button("📂 โหลด Config", COL.accent, _G.SG_loadConfig)
    button("👋 Emote ทักทาย", COL.accent, function()
        _G.SG_Emote("👋 Hello!")
    end)

    pageUtility.CanvasSize = UDim2.new(0, 0, 0, ctx.y + 20)
end

print("[SG v8.0] P3 โหลดเสร็จ — Combat Extras + Utility ครบ")
