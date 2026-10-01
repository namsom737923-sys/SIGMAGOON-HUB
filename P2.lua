--============================================================
-- SIGMAGOON HUB v4.0 — P2/3 (UI + Silent Aim)
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
local isLocked = _G.SG_isLocked
local lockFeature = _G.SG_lockFeature
local unlockFeature = _G.SG_unlockFeature
local ANTI_CHECKS = _G.SG_ANTI_CHECKS

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
