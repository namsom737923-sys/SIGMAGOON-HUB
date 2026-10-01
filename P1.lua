--============================================================
-- SIGMAGOON HUB v7.0 — P1 (Core Logic)
--============================================================
if _G.SG5_P1 then
    pcall(function()
        for _, g in ipairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if g.Name:find("SIGMAGOON") or g.Name:find("CamAimbot") then g:Destroy() end
        end
        for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if g.Name:find("SIGMAGOON") or g.Name:find("CamAimbot") then g:Destroy() end
        end
    end)
end
_G.SG5_P1 = true
_G.CamAimbotV2 = nil
_G.CamAimbotV3 = nil
_G.CamAimbotV4 = nil

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

print("[SG v7.0] P1 เริ่มโหลด")

local CONFIG = {
    FlyEnabled=false, FlySpeed=50,
    SpeedEnabled=false, SpeedValue=16,
    JumpEnabled=false, JumpPower=100,
    TPWalkEnabled=false, TPWalkSpeed=500,
    TPWalkAntiVoid=true, TPWalkWaterWalk=true, TPWalkWaterY=4,
    LaserEnabled=true, MaxDistance=500,
    BeamWidth0=0.15, BeamWidth1=0.05,
    GreenColor=Color3.fromRGB(0,255,80),
    RedColor=Color3.fromRGB(255,40,40),
    BlueColor=Color3.fromRGB(80,160,255),
    HitDotSize=0.35,
    HitDotColor=Color3.fromRGB(255,60,60),
    PlayerDotColor=Color3.fromRGB(80,160,255),
    MuzzleNames={"Muzzle","BarrelEnd","FirePoint","Tip","MuzzleAttachment","Barrel","GunMuzzle"},
    VehicleMuzzleNames={"VehicleMuzzle","TurretMuzzle","GunMuzzle","Muzzle","BarrelEnd"},
    FallbackToHandle=true,
    AimMode="camera", AimSmoothing=0.35,
    AimbotEnabled=false, AimbotFOV=180, AimbotMaxDist=5000,
    AimbotSmooth=0.85, AimbotWallCheck=true, AimbotTeamCheck=false,
    AimbotLockPart="Head",
    LaserPiercing=true, LaserPierceCount=6,
    NoCollideEnabled=false, NoCollideTransparency=true,
    NoCollideNames={"Grass","Leaf","Leaves","Bush","Shrub","Plant","Flower","Fern","Vine","Weed"},
    InvisibleEnabled=false,
    GodmodeEnabled=false,
    PlayerESPEnabled=false, PlayerESPColor=Color3.fromRGB(255,40,40),
    PlayerESPTeamCheck=false, PlayerESPShowName=true, PlayerESPShowDistance=true,
    BotESPEnabled=false, BotESPColor=Color3.fromRGB(255,40,40),
    BotESPShowName=true, BotESPShowHealth=true,
    VehicleESPEnabled=false, VehicleESPColor=Color3.fromRGB(255,180,40),
    VehicleESPShowName=true, VehicleESPShowHealth=true,
    ESPTextSizeMin=10, ESPTextSizeMax=20, ESPMaxDist=1000,
    AutoLowGraphics=false,
    FPSWarpEnabled=false,
    FPSMin=10, FPSMax=60,
    FPSWarpDistance=1000,
    FPSWarpCooldown=5,
    FPSWarpVerifyCount=3,
    FPSWarpReturnEnabled=true,
    FPSAntiVoidHeight=100,
    FPSPlatformSize=20,
}
_G.SG_CONFIG = CONFIG

local laserFolder = Instance.new("Folder")
laserFolder.Name = "__LSF_" .. math.random(1000,9999)
laserFolder.Parent = workspace
_G.SG_laserFolder = laserFolder

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function buildFilter()
    local f = { laserFolder }
    local c = player.Character
    if c then table.insert(f, c) end
    return f
end
local function safeFindAtt(root, names)
    if not root then return nil end
    for _, name in ipairs(names) do
        local att = root:FindFirstChild(name, true)
        if att and att:IsA("Attachment") then return att end
    end
    return nil
end
local function isSameTeam(tp)
    if not CONFIG.AimbotTeamCheck then return false end
    if not tp or tp == player then return true end
    local ok, result = pcall(function()
        if player.Team and tp.Team then return player.Team == tp.Team end
        return false
    end)
    if ok and result then return true end
    return false
end

_G.SG_getHRP = getHRP
_G.SG_getHum = getHum
_G.SG_buildFilter = buildFilter
_G.SG_safeFindAtt = safeFindAtt
_G.SG_isSameTeam = isSameTeam

-- FPS
local FPS = { value = 60, accum = 0, frames = 0 }
RunService.RenderStepped:Connect(function(dt)
    FPS.accum = FPS.accum + dt
    FPS.frames = FPS.frames + 1
    if FPS.accum >= 0.5 then
        FPS.value = math.floor(FPS.frames / FPS.accum)
        FPS.accum = 0; FPS.frames = 0
    end
end)
_G.SG_FPS = FPS

-- FLY
local flyBV, flyBG, flyConn
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    if flyConn then flyConn:Disconnect(); flyConn=nil end
end
local function startFly()
    stopFly()
    local hrp = getHRP()
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    flyBG.P = 1000; flyBG.D = 50
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.FlyEnabled then return end
        local root = getHRP()
        if not root or not flyBV or not flyBG then return end
        local moveDir = Vector3.zero
        local camCF = camera.CFrame
        local hum = getHum()
        if hum then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                moveDir = (camCF.LookVector*md.Z + camCF.RightVector*md.X).Unit
            end
        end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
        flyBV.Velocity = moveDir * CONFIG.FlySpeed
        flyBG.CFrame = camCF
    end)
end
_G.SG_startFly = startFly
_G.SG_stopFly = stopFly

-- SPEED / JUMP
RunService.Heartbeat:Connect(function()
    if CONFIG.SpeedEnabled then
        local hum = getHum()
        if hum then hum.WalkSpeed = CONFIG.SpeedValue end
    end
    if CONFIG.JumpEnabled then
        local hum = getHum()
        if hum then hum.UseJumpPower = true; hum.JumpPower = CONFIG.JumpPower end
    end
end)

-- NO-COLLIDE
local ncCache = {}
local function matchesNC(inst)
    local n = inst.Name:lower()
    for _, kw in ipairs(CONFIG.NoCollideNames) do
        if n:find(kw:lower(),1,true) then return true end
    end
    return false
end
local function processNC(inst)
    if not inst or not inst:IsA("BasePart") then return end
    if ncCache[inst] then return end
    ncCache[inst] = { CanCollide=inst.CanCollide, Transparency=inst.Transparency }
    inst.CanCollide = false
    if CONFIG.NoCollideTransparency then inst.Transparency = 0.7 end
end
local function applyNC()
    if not CONFIG.NoCollideEnabled then return end
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("BasePart") and matchesNC(inst) then processNC(inst) end
    end
end
local function revertNC()
    for inst, data in pairs(ncCache) do
        if inst and inst.Parent then
            pcall(function()
                inst.CanCollide = data.CanCollide
                inst.Transparency = data.Transparency
            end)
        end
    end
    table.clear(ncCache)
end
_G.SG_applyNC = applyNC
_G.SG_revertNC = revertNC

-- INVISIBLE / GODMODE
local invisConns = {}
local function setInvisible(state)
    for _, c in ipairs(invisConns) do c:Disconnect() end
    table.clear(invisConns)
    local function applyChar(char)
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then
                d.LocalTransparencyModifier = state and 1 or 0
            end
        end
    end
    applyChar(player.Character)
    if state then
        table.insert(invisConns, RunService.RenderStepped:Connect(function()
            applyChar(player.Character)
        end))
    end
end
local godConn
local function setGodmode(state)
    if godConn then godConn:Disconnect(); godConn=nil end
    if state then
        local hum = getHum()
        if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
        godConn = RunService.Heartbeat:Connect(function()
            local h = getHum()
            if h then h.MaxHealth = math.huge; h.Health = math.huge end
        end)
    end
end
_G.SG_setInvisible = setInvisible
_G.SG_setGodmode = setGodmode

-- TP SYSTEM
local savedSpawn, savedDeath = nil, nil
local teleportPoints = {}
local function saveCurrentSpawn() local h=getHRP(); if h then savedSpawn=h.CFrame end end
local function warpToSpawn() if savedSpawn then local h=getHRP(); if h then h.CFrame=savedSpawn end end end
local function saveDeathPoint() local h=getHRP(); if h then savedDeath=h.CFrame end end
local function warpToDeath() if savedDeath then local h=getHRP(); if h then h.CFrame=savedDeath end end end
local function clearSpawn() savedSpawn=nil; savedDeath=nil end
local function addTeleportPoint()
    local h=getHRP(); if not h then return end
    table.insert(teleportPoints, { cf=h.CFrame })
end
local function removeLastTP() if #teleportPoints>0 then table.remove(teleportPoints) end end
local function warpToTP(idx)
    local p = teleportPoints[idx]
    if p then local h=getHRP(); if h then h.CFrame=p.cf end end
end
local function reportCoords()
    local h=getHRP()
    if not h then return "N/A" end
    local p = h.Position
    return string.format("X: %.1f  Y: %.1f  Z: %.1f", p.X, p.Y, p.Z)
end
_G.SG_saveCurrentSpawn = saveCurrentSpawn
_G.SG_warpToSpawn = warpToSpawn
_G.SG_saveDeathPoint = saveDeathPoint
_G.SG_warpToDeath = warpToDeath
_G.SG_clearSpawn = clearSpawn
_G.SG_addTeleportPoint = addTeleportPoint
_G.SG_removeLastTP = removeLastTP
_G.SG_warpToTP = warpToTP
_G.SG_reportCoords = reportCoords
_G.SG_getTeleportPoints = function() return teleportPoints end

-- TP WALK
RunService.Heartbeat:Connect(function(dt)
    if not CONFIG.TPWalkEnabled or CONFIG.TPWalkSpeed<=0 then return end
    local hum = getHum()
    local hrp = getHRP()
    if not hum or not hrp or hum.Health<=0 then return end
    local md = hum.MoveDirection
    if md.Magnitude<0.01 then return end
    local step = md * CONFIG.TPWalkSpeed * dt
    local newPos = hrp.Position + step
    if CONFIG.TPWalkAntiVoid then
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.IgnoreWater = not CONFIG.TPWalkWaterWalk
        p.FilterDescendantsInstances = { player.Character or workspace, laserFolder }
        if not workspace:Raycast(newPos + Vector3.new(0,5,0), Vector3.new(0,-200,0), p) then return end
    end
    if CONFIG.TPWalkWaterWalk and newPos.Y < CONFIG.TPWalkWaterY then
        newPos = Vector3.new(newPos.X, CONFIG.TPWalkWaterY, newPos.Z)
    end
    if CONFIG.TPWalkAntiVoid and newPos.Y < -100 then return end
    hrp.CFrame = CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position)
end)

-- LASER
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.FilterDescendantsInstances = { laserFolder }

local function createLaser(startAtt)
    if not startAtt or not startAtt.Parent then return nil end
    local p0 = Instance.new("Part")
    p0.Anchored=true; p0.CanCollide=false; p0.CanQuery=false
    p0.CanTouch=false; p0.Transparency=1
    p0.Size=Vector3.new(0.1,0.1,0.1); p0.Parent=laserFolder
    local a0 = Instance.new("Attachment"); a0.Parent=p0
    local p1 = Instance.new("Part")
    p1.Anchored=true; p1.CanCollide=false; p1.CanQuery=false
    p1.CanTouch=false; p1.Transparency=1
    p1.Size=Vector3.new(0.1,0.1,0.1); p1.Parent=laserFolder
    local a1 = Instance.new("Attachment"); a1.Parent=p1
    local beam = Instance.new("Beam")
    beam.Attachment0=a0; beam.Attachment1=a1
    beam.Width0=CONFIG.BeamWidth0; beam.Width1=CONFIG.BeamWidth1
    beam.FaceCamera=true; beam.LightEmission=1; beam.LightInfluence=0
    beam.Color=ColorSequence.new(CONFIG.GreenColor)
    beam.Transparency=NumberSequence.new(0.1)
    beam.Parent=p0
    local dot = Instance.new("Part")
    dot.Shape=Enum.PartType.Ball
    dot.Size=Vector3.new(CONFIG.HitDotSize,CONFIG.HitDotSize,CONFIG.HitDotSize)
    dot.Anchored=true; dot.CanCollide=false; dot.CanQuery=false
    dot.CanTouch=false; dot.Material=Enum.Material.Neon
    dot.Color=CONFIG.HitDotColor; dot.Transparency=1; dot.Parent=laserFolder
    return { att=startAtt, p0=p0, a0=a0, p1=p1, a1=a1, beam=beam, dot=dot, smoothDir=nil, destroyed=false }
end
local function destroyLaser(l)
    if not l or l.destroyed then return end
    l.destroyed = true
    for _, o in ipairs({ l.p0, l.p1, l.dot }) do
        if o and o.Parent then o:Destroy() end
    end
end
_G.SG_createLaser = createLaser
_G.SG_destroyLaser = destroyLaser

_G.SG_statusFunc = function() end
_G.SG_gunLabel = nil

local function getAimDir(laser)
    if CONFIG.AimMode=="camera" then return camera.CFrame.LookVector end
    if CONFIG.AimMode=="character" then
        local hrp = getHRP()
        if hrp then return hrp.CFrame.LookVector end
        return camera.CFrame.LookVector
    end
    if laser.att and laser.att.Parent then return laser.att.WorldCFrame.LookVector end
    return camera.CFrame.LookVector
end

local function classifyHit(r)
    if not r then return "none", nil end
    local inst = r.Instance
    local m = inst:FindFirstAncestorOfClass("Model")
    local h = m and m:FindFirstChildOfClass("Humanoid")
    if h then
        local p = Players:GetPlayerFromCharacter(m)
        if p then return "player", p end
        return "npc", m
    end
    return "object", inst
end

local function updateLaser(laser)
    if not laser or laser.destroyed then return end
    if not laser.att or not laser.att.Parent then destroyLaser(laser); return end
    local origin = laser.att.WorldPosition
    local rawDir = getAimDir(laser)
    if not laser.smoothDir then laser.smoothDir=rawDir
    else
        local a = math.clamp(CONFIG.AimSmoothing,0,0.95)
        laser.smoothDir = laser.smoothDir:Lerp(rawDir, 1-a)
        if laser.smoothDir.Magnitude>0.001 then laser.smoothDir=laser.smoothDir.Unit
        else laser.smoothDir=rawDir end
    end
    local aimDir = laser.smoothDir
    local dir = aimDir * CONFIG.MaxDistance
    origin = origin + aimDir * 0.1

    local hits = {}
    if CONFIG.LaserPiercing then
        local co, rem = origin, dir
        local trav, maxD = 0, dir.Magnitude
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.IgnoreWater = true
        local f = buildFilter()
        p.FilterDescendantsInstances = f
        for _ = 1, CONFIG.LaserPierceCount do
            local r = workspace:Raycast(co, rem, p)
            if not r then break end
            table.insert(hits, r)
            local adv = (r.Position - co).Magnitude + 0.01
            trav = trav + adv
            if trav >= maxD then break end
            co = r.Position + rem.Unit*0.01
            rem = rem.Unit*(maxD-trav)
            table.insert(f, r.Instance)
            p.FilterDescendantsInstances = f
        end
    else
        rayParams.FilterDescendantsInstances = buildFilter()
        local s = workspace:Raycast(origin, dir, rayParams)
        hits = s and { s } or {}
    end

    local stop = nil
    if #hits>0 then
        if not CONFIG.LaserPiercing then stop = hits[1]
        else
            for _, h in ipairs(hits) do
                local m = h.Instance:FindFirstAncestorOfClass("Model")
                if m and m:FindFirstChildOfClass("Humanoid") then stop = h break end
            end
            if not stop then stop = hits[#hits] end
        end
    end

    local hitPos, isHit
    if stop then hitPos=stop.Position; isHit=true
    else hitPos=origin+dir; isHit=false end

    laser.p0.CFrame = CFrame.new(origin)
    laser.p1.CFrame = CFrame.new(hitPos)

    local ht, hT = classifyHit(stop)
    if isHit then
        if ht=="player" then
            laser.beam.Color = ColorSequence.new(CONFIG.BlueColor)
            laser.dot.Color = CONFIG.PlayerDotColor
        else
            laser.beam.Color = ColorSequence.new(CONFIG.RedColor)
            laser.dot.Color = CONFIG.HitDotColor
        end
        laser.dot.CFrame = CFrame.new(hitPos, hitPos + camera.CFrame.LookVector)
        laser.dot.Transparency = 0
    else
        laser.beam.Color = ColorSequence.new(CONFIG.GreenColor)
        laser.dot.Transparency = 1
    end
    if ht=="player" then _G.SG_statusFunc("🎯 ชนผู้เล่น: "..hT.Name, CONFIG.BlueColor)
    elseif ht=="npc" then _G.SG_statusFunc("👾 ชน NPC: "..hT.Name, CONFIG.RedColor)
    elseif ht=="object" then _G.SG_statusFunc("🧱 ชน: "..hT.Name, CONFIG.RedColor)
    else _G.SG_statusFunc(string.format("➡ ระยะไกลสุด %d", math.floor(CONFIG.MaxDistance)), CONFIG.GreenColor) end
end
_G.SG_updateLaser = updateLaser

-- CAMERA AIMBOT
local aimbotTarget, aimbotTargetPart = nil, nil

local function hasWallBetween(fromPos, targetPos, targetChar)
    if not CONFIG.AimbotWallCheck then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local filterList = {}
    local myChar = player.Character
    if myChar then table.insert(filterList, myChar) end
    if targetChar then table.insert(filterList, targetChar) end
    table.insert(filterList, camera)
    params.FilterDescendantsInstances = filterList
    local result = workspace:Raycast(fromPos, targetPos - fromPos, params)
    if not result then return false end
    if result.Instance and result.Instance:IsA("BasePart") then
        if result.Instance:FindFirstAncestorOfClass("Accessory") then return false end
        if targetChar and result.Instance:IsDescendantOf(targetChar) then return false end
        if myChar and result.Instance:IsDescendantOf(myChar) then return false end
        return true
    end
    return false
end

local function findAimbotTarget()
    local camPos = camera.CFrame.Position
    local camLook = camera.CFrame.LookVector
    local best, bestScore = nil, math.huge
    local bestPart = nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not isSameTeam(plr) then
            local char = plr.Character
            if char then
                local targetPart = char:FindFirstChild(CONFIG.AimbotLockPart)
                    or char:FindFirstChild("Head")
                    or char:FindFirstChild("HumanoidRootPart")
                    or char:FindFirstChild("Torso")
                    or char:FindFirstChild("UpperTorso")
                if targetPart then
                    local toTarget = targetPart.Position - camPos
                    local dist = toTarget.Magnitude
                    if dist <= CONFIG.AimbotMaxDist then
                        local angle = math.deg(math.acos(math.clamp(
                            toTarget.Unit:Dot(camLook), -1, 1)))
                        if angle <= CONFIG.AimbotFOV / 2 then
                            if not hasWallBetween(camPos, targetPart.Position, char) then
                                local score = angle + dist * 0.001
                                if score < bestScore then
                                    bestScore = score
                                    best = char
                                    bestPart = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestPart
end

RunService.RenderStepped:Connect(function(dt)
    if not CONFIG.AimbotEnabled then
        aimbotTarget = nil
        aimbotTargetPart = nil
        return
    end
    local target, targetPart = findAimbotTarget()
    aimbotTarget = target
    aimbotTargetPart = targetPart
    if target and targetPart then
        local camPos = camera.CFrame.Position
        local targetPos = targetPart.Position
        local desiredCF = CFrame.new(camPos, targetPos)
        local dist = (targetPos - camPos).Magnitude
        local distFactor = math.clamp(dist / CONFIG.AimbotMaxDist, 0, 1)
        local baseSmooth = CONFIG.AimbotSmooth
        local dynamicSmooth = baseSmooth * (0.7 + distFactor * 0.3)
        dynamicSmooth = math.clamp(dynamicSmooth, 0.5, 0.99)
        local alpha = 1 - math.pow(dynamicSmooth, dt * 60)
        alpha = math.clamp(alpha, 0.01, 0.5)
        camera.CFrame = camera.CFrame:Lerp(desiredCF, alpha)
    end
end)
_G.SG_getAimbotTarget = function() return aimbotTarget, aimbotTargetPart end

-- AUTO FPS WARP
local FPSWarp = {
    lastWarpTime = 0, warping = false,
    returnPoint = nil, verifyCounter = 0, onPlatform = nil,
}
_G.SG_FPSWarp = FPSWarp

local function createAntiVoidPlatform(pos)
    local existing = workspace:FindFirstChild("__SG_Platform")
    if existing then existing:Destroy() end
    local platform = Instance.new("Part")
    platform.Name = "__SG_Platform"
    platform.Size = Vector3.new(CONFIG.FPSPlatformSize, 1, CONFIG.FPSPlatformSize)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = Color3.fromRGB(0,200,255)
    platform.Transparency = 0.5
    platform.Position = Vector3.new(pos.X, pos.Y - 3, pos.Z)
    platform.Parent = workspace
    FPSWarp.onPlatform = platform
    return platform
end

local function findBestFPSPoint(radius)
    local hrp = getHRP()
    if not hrp then return nil end
    local origin = hrp.Position
    local bestPos, bestScore = nil, -math.huge
    for i = 1, 16 do
        local angle = (i/16) * math.pi * 2
        local dist = radius * (0.3 + math.random()*0.7)
        local offset = Vector3.new(math.cos(angle)*dist, 0, math.sin(angle)*dist)
        local testPos = origin + offset
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { player.Character or workspace, laserFolder }
        local hit = workspace:Raycast(testPos + Vector3.new(0,50,0), Vector3.new(0,-300,0), params)
        if hit then
            if math.abs(hit.Position.Y - origin.Y) < CONFIG.FPSAntiVoidHeight then
                local score = (hit.Position - origin).Magnitude
                if score > bestScore then bestScore = score; bestPos = hit.Position end
            end
        end
    end
    return bestPos
end

local function tryFPSWarp()
    if FPSWarp.warping then return end
    local now = tick()
    if now - FPSWarp.lastWarpTime < CONFIG.FPSWarpCooldown then return end
    local hrp = getHRP()
    if not hrp then return end
    FPSWarp.warping = true
    FPSWarp.lastWarpTime = now
    if not FPSWarp.returnPoint then FPSWarp.returnPoint = hrp.CFrame end
    local newPos = findBestFPSPoint(CONFIG.FPSWarpDistance)
    if not newPos then FPSWarp.warping = false; return end
    if math.abs(newPos.Y - hrp.Position.Y) > CONFIG.FPSAntiVoidHeight then
        createAntiVoidPlatform(newPos)
        task.wait(0.2)
    end
    hrp.CFrame = CFrame.new(newPos + Vector3.new(0,5,0))
    task.delay(2, function()
        if not CONFIG.FPSWarpEnabled then FPSWarp.warping = false; return end
        if FPS.value >= CONFIG.FPSMin then
            FPSWarp.returnPoint = nil
            FPSWarp.verifyCounter = 0
            if FPSWarp.onPlatform then FPSWarp.onPlatform:Destroy(); FPSWarp.onPlatform = nil end
        else
            FPSWarp.verifyCounter = FPSWarp.verifyCounter + 1
            if FPSWarp.verifyCounter >= CONFIG.FPSWarpVerifyCount then
                if CONFIG.FPSWarpReturnEnabled and FPSWarp.returnPoint then
                    local h = getHRP()
                    if h then h.CFrame = FPSWarp.returnPoint end
                end
                FPSWarp.returnPoint = nil
                FPSWarp.verifyCounter = 0
                if FPSWarp.onPlatform then FPSWarp.onPlatform:Destroy(); FPSWarp.onPlatform = nil end
            end
        end
        FPSWarp.warping = false
    end)
end
_G.SG_tryFPSWarp = tryFPSWarp

RunService.Heartbeat:Connect(function()
    if not CONFIG.FPSWarpEnabled then return end
    if FPSWarp.warping then return end
    if FPS.value < CONFIG.FPSMin then tryFPSWarp() end
    local hrp = getHRP()
    if hrp and CONFIG.FPSAntiVoidHeight > 0 then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { player.Character or workspace, laserFolder }
        local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -CONFIG.FPSAntiVoidHeight, 0), rp)
        if not hit and hrp.Position.Y > 50 then
            if not FPSWarp.onPlatform or not FPSWarp.onPlatform.Parent then
                createAntiVoidPlatform(hrp.Position)
            else
                FPSWarp.onPlatform.Position = Vector3.new(hrp.Position.X, FPSWarp.onPlatform.Position.Y, hrp.Position.Z)
            end
        end
    end
end)

print("[SG v7.0] P1 โหลดเสร็จ")
