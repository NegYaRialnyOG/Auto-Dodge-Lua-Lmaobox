--[[  Movement assist for  Lmaobox  ]]--
--[[       Added support demo       ]]--
--[[   Errors in console is normal  ]]--
--[[           --Author--           ]]--
--[[           Terminator           ]]--
--[[  (github.com/titaniummachine1  ]]--
---@alias AimTarget { entity : Entity, angles : EulerAngles, factor : number }

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.995, "lnxLib version is too old, please update it!")
UnloadLib() 

local Math, Conversion = lnxLib.Utils.Math, lnxLib.Utils.Conversion
local WPlayer, WWeapon = lnxLib.TF2.WPlayer, lnxLib.TF2.WWeapon
local Helpers = lnxLib.TF2.Helpers
local Prediction = lnxLib.TF2.Prediction
local Fonts = lnxLib.UI.Fonts

local pLocal = entities.GetLocalPlayer()
local projectiles = {}

local function NormalizeVector(vector)
    local length = math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    if length == 0 then
        return Vector3(0, 0, 0)
    else
        return Vector3(vector.x / length, vector.y / length, vector.z / length)
    end
end

local destination
local function OnCreateMove(userCmd)
    pLocal = entities.GetLocalPlayer()
    projectiles = entities.FindByClass("CTFProjectile_Rocket") 
    local grenades = entities.FindByClass("CTFGrenadePipebombProjectile") 
    for _, grenade in pairs(grenades) do
        table.insert(projectiles, grenade) 
    end

    local closestProjectile = nil
    local closestDistance = 500

    for _, projectile in pairs(projectiles) do
        local owner = projectile:GetOwner()
        if owner and owner:GetTeamNumber() ~= pLocal:GetTeamNumber() then
            local projectilePos = projectile:GetAbsOrigin()
            local distance = (pLocal:GetAbsOrigin() - projectilePos):Length()

            if distance < closestDistance then
                closestDistance = distance
                closestProjectile = projectile
            end
        end
    end

    if closestProjectile ~= nil then
        local projectilePos = closestProjectile:GetAbsOrigin()
        local projectileVel = closestProjectile:EstimateAbsVelocity()
        local hitPos = projectilePos + projectileVel * (closestDistance / (projectileVel:Length() * 2))

        destination = -hitPos
        if (destination - projectilePos):Length() < 50 then
            destination = -destination
        end
        if math.abs((pLocal:GetAbsOrigin() - hitPos):Length()) < 250 then
            Helpers.WalkTo(userCmd, pLocal, destination)
        end
    end
end

local function doDraw()
    projectiles = entities.FindByClass("CTFProjectile_Rocket") 
    local grenades = entities.FindByClass("CTFGrenadePipebombProjectile") 
    for _, grenade in pairs(grenades) do
        table.insert(projectiles, grenade) 
    end

    for _, projectile in pairs(projectiles) do
        local projectilePos = projectile:GetAbsOrigin()

        local distance = (pLocal:GetAbsOrigin() - projectilePos):Length()
        local projectileVel = NormalizeVector(projectile:EstimateAbsVelocity())

        local target = projectilePos + (projectileVel * distance)

        local startpos = client.WorldToScreen(projectilePos)
        local projectileTrace = engine.TraceLine(projectilePos, target, MASK_SHOT_HULL)
        local endpos = client.WorldToScreen(projectileTrace.endpos)

        if startpos ~= nil and endpos ~= nil then
            draw.Color(255, 255, 255, 255)
            draw.Line(startpos[1], startpos[2], endpos[1], endpos[2])
        end

        local walkto = client.WorldToScreen(destination)
        local ppos = client.WorldToScreen(pLocal:GetAbsOrigin())
        if walkto ~= nil and ppos ~= nil then
            draw.Color(0, 255, 0, 255)
            draw.Line(ppos[1], ppos[2], walkto[1], walkto[2])
        end
    end
end

local function OnUnload()
    UnloadLib() 
    client.Command('play "ui/buttonclickrelease"', true) 
end

callbacks.Unregister("CreateMove", "AMAT_CreateMove")
callbacks.Unregister("Unload", "AMAT_Unload")
callbacks.Unregister("Draw", "AMAT_Draw")

callbacks.Register("CreateMove", "AMAT_CreateMove", OnCreateMove)
callbacks.Register("Unload", "AMAT_Unload", OnUnload)
callbacks.Register("Draw", "AMAT_Draw", doDraw)

client.Command('play "ui/buttonclick"', true)
