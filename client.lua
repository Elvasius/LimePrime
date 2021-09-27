-- Variables
local smokeHandle = nil
local sprayHandle = nil
local networkedSprayHandles = {}
local networkedSmokeHandles = {}
local limeGrenadeCooldown = 3000
local limeGrenadeReady = true

-- Replace this model with an actual big lime or lime colored bowling ball
local limeModelHash = GetHashKey("prop_bowling_ball")

-- Lime grenade functions
function startLimeGrenadeAttack()
    if not limeGrenadeReady then
        return
    end
    RequestModel(limeModelHash)
    while not HasModelLoaded(limeModelHash) do
        Citizen.Wait(100)
    end
    local playerPed = GetPlayerPed( -1 )
    local vehicle = GetVehiclePedIsIn(playerPed, true)
    
    Citizen.CreateThread(function()
        local dict = "core"
        local particleName = "exp_extinguisher"
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Citizen.Wait(0)
        end

        -- Thread to reset CD of the grenade attack
        Citizen.CreateThread(function()
            Wait(limeGrenadeCooldown)
            limeGrenadeReady = true
        end)

        limeGrenadeReady = false
        -- These bones are the big exhaust on top of the vehicle
        -- Left exhausts go from 92 - 95
        -- Right exhausts go from 101 - 98
        local leftRot = GetEntityBoneRotation(vehicle, 92)
        local rightRot = GetEntityBoneRotation(vehicle, 101)

        -- First Limes
        local upperRight = createLime(vehicle, 101, rightRot)
        local upperLeft = createLime(vehicle, 92, leftRot)
        applyForceToLime(upperRight, 101, vector3(0.0, -15.0,15.0))
        applyForceToLime(upperLeft, 92, vector3(0.0, -15.0,15.0))
        
        Wait(1000)

        -- Second Limes
        local middleRight = createLime(vehicle, 100, rightRot )
        local middleLeft = createLime(vehicle, 93, leftRot )
        applyForceToLime(middleRight, 100, vector3(0.0, -15.0,15.0))
        applyForceToLime(middleLeft, 93 , vector3(0.0, -15.0,15.0))

        Wait(1000)

        -- Third Limes
        local middleTwoRight = createLime(vehicle, 99, rightRot )
        local middleTwoLeft = createLime(vehicle, 94, leftRot )
        applyForceToLime(middleTwoRight, 99, vector3(0.0, -15.0,15.0))
        applyForceToLime(middleTwoLeft, 94 , vector3(0.0, -15.0,15.0))

        Wait(1000)

        -- Start exploding all the limes
        explodeLime(upperRight, dict, particleName)
        explodeLime(upperLeft, dict, particleName)
        Wait(1000)
        explodeLime(middleRight, dict, particleName)
        explodeLime(middleLeft, dict, particleName)
        Wait(1000)
        explodeLime(middleTwoRight, dict, particleName)
        explodeLime(middleTwoLeft, dict, particleName)

        -- Cleanup (need to wait until after explosion cause the effect is attached to the ball)
        Wait(2000)
        DeleteEntity(upperRight)
        DeleteEntity(upperLeft)
        DeleteEntity(middleRight)
        DeleteEntity(middleLeft)
        DeleteEntity(middleTwoRight)
        DeleteEntity(middleTwoLeft)
    end)
end

function createLime(veh, boneId, rotation) 
    local retval  = CreateObject(
        limeModelHash, 
		GetEntityBonePosition_2(veh, boneId), 
		true --[[ boolean ]], 
		true --[[ boolean ]], 
		false --[[ boolean ]]
	)
    -- Need to set rotation to make sure the force is applied correctly
    SetEntityRotation(retval, rotation)
    return retval
end

function applyForceToLime(entity, boneId, direction)
    local forceTypes = {
        MinForce = 0,
        MaxForceRot = 1,
        MinForce2 = 2,
        MaxForceRot2 = 3,
        ForceNoRot = 4,
        ForceRotPlusForce = 5
    }
    
    local forceType = forceTypes.MaxForceRot2
    local rotation = vector3(0.0, 0.0, 0.0)
    local boneIndex = 0
    local isDirectionRel = true
    local ignoreUpVec = true
    local isForceRel = true
    local p12 = false
    local p13 = true
    
    ApplyForceToEntity(
        entity,
        forceType,
        direction,
        rotation,
        boneIndex,
        isDirectionRel,
        ignoreUpVec,
        isForceRel,
        p12,
        p13
    )
end
function explodeLime(entity, particleDict, particleName)
    -- This particle is networked, setting colour is networked as well
    UseParticleFxAssetNextCall(particleDict)
    local partRet  =StartNetworkedParticleFxNonLoopedOnEntity(
		particleName --[[ string ]], 
		entity --[[ Entity ]], 
		0.0 --[[ number ]], 
		0.0 --[[ number ]], 
		0.0 --[[ number ]], 
		0.0 --[[ number ]], 
		0.0 --[[ number ]], 
		0.0 --[[ number ]], 
		5.0 --[[ number ]], 
		false --[[ boolean ]], 
		true --[[ boolean ]], 
		true --[[ boolean ]]
	)
    -- For some reason NonLoopedColour is not rgb but gbr
    SetParticleFxNonLoopedColour(
        partRet --[[ integer ]], 
        255.0, 0.0, 0.0, 
        true --[[ boolean ]]
    )
    AddExplosion(
        GetEntityCoords(entity), 
        26 --[[ integer ]], 
        5.0 --[[ number ]], 
        false --[[ boolean ]], 
        true --[[ boolean ]], 
        1.0 --[[ number ]]
    )
    
end

-- Spray functions
function playSprayParticle(vehicle)
    local particleDict = "core"
    local particleName = "exp_sht_steam"
    return playColoredLoopedParticleOnBone(particleDict, particleName, vehicle, vector3(90.0, 0.0, 0.0), 54, 10.0, 0.0, 255.0, 0.0)
end

function spray(debug)  
    local playerPed = GetPlayerPed( -1 )
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
    TriggerServerEvent("limePrimePressedSprayServer", VehToNet(vehicle), true)
    sprayHandle = playSprayParticle(vehicle)
    local drawLocation = vector3(0.0, 0.0, 0.0)
    -- Debug draws a marker at the end of the paint raycast
    if debug then
        Citizen.CreateThread(function()
            while true do
                DrawMarker(2, drawLocation, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                Wait(1)
            end
        end)
    end
    -- Paint thread that performs a raycast
    -- The raycast uses the beginning of the barrel and the end of the barrel to calculate a vector that points where the gun is aiming at  
    -- Downside is that this is a very simple raycast so hitting multiple vehicles at the same time might be difficult
    Citizen.CreateThread(function()
        while sprayHandle ~= nil do
            local boneLoc = GetEntityBonePosition_2(vehicle, 54)
            local boneLoc2 = GetEntityBonePosition_2(vehicle, 53)
            local hitHandle =StartShapeTestCapsule(
                boneLoc2 + (boneLoc-boneLoc2)*5.0, 
                boneLoc2 + (boneLoc-boneLoc2)*20.0, 
                10.0 --[[ number ]], 
                10 --[[ integer ]], 
                vehicle --[[ Entity ]], 
                true --[[ integer ]]
            )
            local hitRet, hit, endCoords, surfaceNormal, entityHit  = GetShapeTestResult(hitHandle)
            if hit then
                SetVehicleColours(
                    entityHit --[[ Vehicle ]], 
                    92 --[[ integer ]], 
                    92 --[[ integer ]]
                )
            end
            drawLocation = boneLoc2 + (boneLoc-boneLoc2)*10.0
            Wait(100)
        end
    end)
end

function stopSpray()
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
    TriggerServerEvent("limePrimePressedSprayServer", VehToNet(vehicle), false)
    StopParticleFxLooped(sprayHandle, true)
    sprayHandle = nil
end

-- Smoke functions
function playSmokeParticle(vehicle)
    local particleDict = "scr_pm_plane_promotion"
    local particleName = "scr_stuntplane_trail"
    return playColoredLoopedParticleOnBone(particleDict, particleName, vehicle, vector3(90.0, 0.0, 0.0), 105, 10.0, 0.0, 255.0, 0.0)
end
function smoke()
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    TriggerServerEvent("limePrimePressedSmokeServer", VehToNet(vehicle), true)
    smokeHandle = playSmokeParticle(vehicle)
end

function stopSmoke()
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
    TriggerServerEvent("limePrimePressedSmokeServer", VehToNet(vehicle), false)
    StopParticleFxLooped(smokeHandle, true)
    smokeHandle = nil
end

-- Helper functions
function playColoredLoopedParticleOnBone(particleDict, particleName, vehicle, rotation, boneId, scale, r, g, b)
    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Citizen.Wait(0)
    end
    UseParticleFxAssetNextCall(particleDict)
    -- These particles seem to not sync by default so need to use an event to sync them manually
    local partRet = StartParticleFxLoopedOnEntityBone(
        particleName --[[ string ]], 
        vehicle --[[ Entity ]], 
        0.0 --[[ number ]], 
        0.0 --[[ number ]], 
        0.0 --[[ number ]], 
        rotation, 
        boneId --[[ integer ]], 
        scale --[[ number ]], 
        false --[[ boolean ]], 
        true --[[ boolean ]], 
        true --[[ boolean ]]
    )
    SetParticleFxLoopedColour(
        partRet --[[ integer ]], 
        r, g, b, 
        true --[[ boolean ]]
    )
    return partRet
end

-- Can be used to stop threads of previous vehicles, i.e. when the current one gets destroyed / put in garage etc
function stopAll()
    stopSpray()
    stopSmoke()
end

-- Simple controls to test
-- Shift = spray
-- Left alt = grenades
-- Space = smoke

-- Maybe want to add some check if player is still in vehicle or if the vehicle is still alive
RegisterCommand("listenForLimeInput", function()
    Citizen.CreateThread(function()
        stopAll()
        while true do
            if IsControlJustReleased(0--[[control type]],  19--[[control index]]) then
                startLimeGrenadeAttack()
            end
            if IsControlJustReleased(0--[[control type]],  21--[[control index]]) then
                if sprayHandle == nil then
                    spray()
                else
                    stopSpray()
                end
            end
            if IsControlJustReleased(0--[[control type]],  22--[[control index]]) then
                if smokeHandle == nil then
                    smoke()
                else
                    stopSmoke()
                end
                
            end
            Wait(1)
        end
    end)
 
  end)

-- Sync events
RegisterNetEvent("limePrimePressedSprayClient")
RegisterNetEvent("limePrimePressedSmokeClient")
AddEventHandler("limePrimePressedSprayClient", function(vehicleNetId, isActive)
    if isActive then
        networkedSprayHandles[vehicleNetId] = playSprayParticle(NetToVeh(vehicleNetId))
    else
        StopParticleFxLooped(networkedSprayHandles[vehicleNetId], true)
        networkedSprayHandles[vehicleNetId] = nil
    end
    
end)
AddEventHandler("limePrimePressedSmokeClient", function(vehicleNetId, isActive)
    if isActive then
        networkedSmokeHandles[vehicleNetId] = playSmokeParticle(NetToVeh(vehicleNetId))
    else
        StopParticleFxLooped(networkedSmokeHandles[vehicleNetId], true)
        networkedSmokeHandles[vehicleNetId] = nil
    end
    
end)
