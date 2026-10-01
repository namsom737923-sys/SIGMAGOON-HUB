--============================================================
-- SIGMAGOON HUB v4.0 — P1/3 (Core + Anti-Check)
--============================================================
if _G.SG_Loaded then
    pcall(function()
        for _, g in ipairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if g.Name:find("SIGMAGOON") then g:Destroy() end
        end
    end)
end
_G.SG_Loaded = true

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

print("[SG v4.0] P1/3 เริ่มโหลด")

local CONFIG = {
    FlyEnabled=false, FlySpeed=50,
    SpeedEnabled=false, SpeedValue=16,
    JumpEnabled=false, JumpPower=100,
    NoCollideEnabled=false,
    InvisibleEnabled=false,
    GodmodeEnabled=false,
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
    AimbotEnabled=false, AimbotFOV=60, AimbotMaxDist=500,
    AimbotSmooth=0.85, AimbotWallCheck=true, AimbotTeamCheck=true,
    AimbotLockPart="Head", AimbotStrength=5, AimbotPredict=0.15,
    LaserPiercing=true, LaserPierceCount=6,
    TPWalkEnabled=false, TPWalkSpeed=500,
    TPWalkAntiVoid=true, TPWalkWaterWalk=true, TPWalkWaterY=4,
    NoCollideTransparency=true,
    NoCollideNames={"Grass","Leaf","Leaves","Bush","Shrub","Plant","Flower","Fern","Vine","Weed"},
    AutoLowGraphics=false,

    -- ESP
    PlayerESPEnabled=false, PlayerESPColor=Color3.fromRGB(255,40,40),
    PlayerESPTeamCheck=true, PlayerESPShowName=true, PlayerESPShowDistance=true,
    PlayerESPShowBox=false, PlayerESPShowTracer=false,
    PlayerESPBoxColor=Color3.fromRGB(255,40,40),
    PlayerESPTracerColor=Color3.fromRGB(255,40,40),
    PlayerESPTracerOrigin="bottom",

    BotESPEnabled=false, BotESPColor=Color3.fromRGB(255,40,40),
    BotESPShowName=true, BotESPShowHealth=true,
    BotESPShowBox=false, BotESPShowTracer=false,

    VehicleESPEnabled=false, VehicleESPColor=Color3.fromRGB(255,180,40),
    VehicleESPShowName=true, VehicleESPShowHealth=true,

    ESPTextSizeMin=10, ESPTextSizeMax=20, ESPMaxDist=1000,

    -- Auto FPS Warp
    AutoFPSWarpEnabled=false,
    AutoFPSMin=10, AutoFPSMax=60,
    AutoFPSWarpDistance=1000,
    AutoFPSWarpCooldown=5,
    AutoFPSWarpVerifyCount=3,
    AutoFPSWarpReturnEnabled=true,
    AutoFPSAntiVoidHeight=100,
    AutoFPSPlatformSize=20,

    -- Silent Aim
    SilentAimEnabled=false,
    SilentAimHitPart="Head",
    SilentAimFOV=90,
    SilentAimMaxDist=1000,
    SilentAimWallCheck=true,
    SilentAimTeamCheck=true,
    SilentAimVisibilityCheck=true,
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
    if player.Team and tp.Team then return player.Team == tp.Team end
    if player.TeamColor and tp.TeamColor then return player.TeamColor == tp.TeamColor end
    return false
end

_G.SG_getHRP = getHRP
_G.SG_getHum = getHum
_G.SG_safeFindAtt = safeFindAtt
_G.SG_isSameTeam = isSameTeam
_G.SG_buildFilter = buildFilter

--============================================================
-- FLY
--============================================================
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
    flyBG.P = 1000
    flyBG.D = 50
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

--============================================================
-- SPEED / JUMP
--============================================================
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

--============================================================
-- NO-COLLIDE
--============================================================
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

--============================================================
-- INVISIBLE / GODMODE
--============================================================
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

--============================================================
-- TP SYSTEM
--============================================================
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

--============================================================
-- TP WALK
--============================================================
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

--============================================================
-- LASER
--============================================================
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

--============================================================
-- AIMBOT
--============================================================
local function hasLOS(fromP, toP, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.IgnoreWater = true
    local f = { laserFolder }
    for _, v in ipairs(ignore or {}) do table.insert(f, v) end
    p.FilterDescendantsInstances = f
    return workspace:Raycast(fromP, toP-fromP, p) == nil
end
local function predictPos(char, part, t)
    if t<=0 then return part.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    return part.Position + hrp.AssemblyLinearVelocity*t
end
local function findBestTarget(originP, aimDir, maxD)
    local best, bestS = nil, math.huge
    local camP = camera.CFrame.Position
    local camL = camera.CFrame.LookVector
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not isSameTeam(plr) then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local tp = char:FindFirstChild(CONFIG.AimbotLockPart)
                    or char:FindFirstChild("HumanoidRootPart")
                    or char:FindFirstChild("Head")
                if hum and hum.Health>0 and tp then
                    local tPos = predictPos(char, tp, CONFIG.AimbotPredict)
                    local toT = tPos - originP
                    if toT.Magnitude<=maxD then
                        local ang = math.deg(math.acos(math.clamp(toT.Unit:Dot(aimDir),-1,1)))
                        local toC = tPos - camP
                        local cAng = math.deg(math.acos(math.clamp(toC.Unit:Dot(camL),-1,1)))
                        if ang<=CONFIG.AimbotFOV/2 and cAng<=CONFIG.AimbotFOV/2 then
                            local ok = true
                            if CONFIG.AimbotWallCheck then
                                ok = hasLOS(originP, tPos, { char, player.Character })
                            end
                            if ok then
                                local s = ang + cAng*0.5
                                if s<bestS then bestS=s; best=char end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end
_G.SG_findBestTarget = findBestTarget
_G.SG_predictPos = predictPos
_G.SG_hasLOS = hasLOS

--============================================================
-- ANTI-CHECK
--============================================================
local ANTI_LOCK = {}
_G.SG_ANTI_LOCK = ANTI_LOCK
local function lockFeature(id) ANTI_LOCK[id] = true end
local function unlockFeature(id) ANTI_LOCK[id] = nil end
local function isLocked(id) return ANTI_LOCK[id] == true end
_G.SG_lockFeature = lockFeature
_G.SG_unlockFeature = unlockFeature
_G.SG_isLocked = isLocked

local ANTI_CHECKS = {
    { id="walkspeed", name="WalkSpeed", risk="ต่ำ", test=function()
        local h=getHum(); if not h then error("ไม่มี") end
        local s=h.WalkSpeed; h.WalkSpeed=s+5; task.wait(0.1); h.WalkSpeed=s
    end },
    { id="jump", name="JumpPower", risk="ต่ำ", test=function()
        local h=getHum(); if not h then error("ไม่มี") end
        local s=h.JumpPower; h.JumpPower=s+10; task.wait(0.1); h.JumpPower=s
    end },
    { id="hipheight", name="HipHeight", risk="กลาง", test=function()
        local h=getHum(); if not h then error("ไม่มี") end
        local s=h.HipHeight; h.HipHeight=s+0.1; task.wait(0.1); h.HipHeight=s
    end },
    { id="fly_bodyvel", name="BodyVelocity", risk="สูง", test=function()
        local hrp=getHRP(); if not hrp then error("ไม่มี") end
        local bv=Instance.new("BodyVelocity")
        bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1,1,1)
        bv.Parent=hrp; task.wait(0.1); bv:Destroy()
    end },
    { id="fly_bodygyro", name="BodyGyro", risk="สูง", test=function()
        local hrp=getHRP(); if not hrp then error("ไม่มี") end
        local bg=Instance.new("BodyGyro")
        bg.MaxTorque=Vector3.new(1,1,1); bg.Parent=hrp
        task.wait(0.1); bg:Destroy()
    end },
    { id="cframe_warp_small", name="CFrame Warp 5s", risk="กลาง", test=function()
        local hrp=getHRP(); if not hrp then error("ไม่มี") end
        local s=hrp.CFrame; hrp.CFrame=s+Vector3.new(0,5,0)
        task.wait(0.05); hrp.CFrame=s
    end },
    { id="cframe_warp_big", name="Warp 100 studs", risk="สูงมาก", test=function()
        local hrp=getHRP(); if not hrp then error("ไม่มี") end
        local s=hrp.CFrame; hrp.CFrame=s+Vector3.new(100,0,0)
        task.wait(0.3); if hrp.Parent then hrp.CFrame=s end
    end },
    { id="maxhealth", name="MaxHealth ∞", risk="สูง", test=function()
        local h=getHum(); if not h then error("ไม่มี") end
        local s=h.MaxHealth; h.MaxHealth=math.huge; task.wait(0.1); h.MaxHealth=s
    end },
    { id="clear_children", name="ClearAllChildren", risk="สูงมาก", test=function()
        local c=player.Character
        if not c or not c.ClearAllChildren then error("ไม่มี") end
    end },
    { id="instance_sss", name="Instance.new SSS", risk="สูง", test=function()
        local ok=pcall(function()
            local p=Instance.new("Part")
            p.Parent=game:GetService("ServerScriptService")
            p:Destroy()
        end)
        if not ok then error("block") end
    end },
    { id="remote_event", name="RemoteEvent", risk="กลาง", test=function()
        local found=false
        for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") then found=true break end
        end
        if not found then error("ไม่พบ") end
    end },
    { id="animator", name="Animator", risk="กลาง", test=function()
        local h=getHum()
        if not h then error("ไม่มี") end
        if not h:FindFirstChildOfClass("Animator") then error("ไม่มี") end
    end },
    { id="nocollide_part", name="CanCollide false", risk="ต่ำ", test=function()
        local c=player.Character; if not c then error("ไม่มี") end
        local hrp=c:FindFirstChild("HumanoidRootPart")
        if not hrp then error("ไม่มี HRP") end
        local s=hrp.CanCollide; hrp.CanCollide=false
        task.wait(0.1); hrp.CanCollide=s
    end },
    { id="transparency", name="Transparency = 1", risk="ต่ำ", test=function()
        local c=player.Character; if not c then error("ไม่มี") end
        for _,d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                local s=d.Transparency
                d.Transparency=1; task.wait(0.05); d.Transparency=s
                break
            end
        end
    end },
    { id="raycast", name="Raycast", risk="ต่ำ", test=function()
        workspace:Raycast(Vector3.new(0,100,0), Vector3.new(0,-200,0))
    end },
    { id="camera_cframe", name="Camera CFrame", risk="กลาง", test=function()
        local save=camera.CFrame
        camera.CFrame=save*CFrame.new(0,0.01,0)
        task.wait(0.05); camera.CFrame=save
    end },
}
_G.SG_ANTI_CHECKS = ANTI_CHECKS

print("[SG v4.0] P1/3 โหลดเสร็จ")
