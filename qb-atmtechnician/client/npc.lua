-- Spawns the job center NPC (clock in/out point)

local npcEntity = nil
local jobBlip = nil

local function CreateJobCenterBlip()
    jobBlip = AddBlipForCoord(Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z)
    SetBlipSprite(jobBlip, Config.JobCenter.blip.sprite)
    SetBlipColour(jobBlip, Config.JobCenter.blip.color)
    SetBlipScale(jobBlip, Config.JobCenter.blip.scale)
    SetBlipAsShortRange(jobBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.JobCenter.blip.label)
    EndTextCommandSetBlipName(jobBlip)
end

local function SpawnNPC()
    local coords = Config.JobCenter.coords
    local hash = Functions.LoadModel(Config.JobCenter.pedModel)

    -- Make sure the collision for this area is loaded before we ground-check it
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local colTimeout = 0
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and colTimeout < 2000 do
        Wait(10)
        colTimeout = colTimeout + 10
    end

    -- Find the real ground height at this X/Y instead of trusting the configured Z value
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
    local spawnZ = foundGround and groundZ or coords.z

    npcEntity = CreatePed(4, hash, coords.x, coords.y, spawnZ, coords.w, false, true)
    SetEntityCoordsNoOffset(npcEntity, coords.x, coords.y, spawnZ, false, false, false)

    -- CRITICAL: mp_* ped models (this one included) spawn with no outfit textures loaded
    -- until this is called -- without it the ped exists but renders invisible/broken, even
    -- though its collision/marker are fine. Standard (non-mp_) ped models don't need this,
    -- but it's harmless to call on any model, so it's safe to always include.
    SetPedDefaultComponentVariation(npcEntity)

    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)
    SetPedCanRagdoll(npcEntity, false)
    SetModelAsNoLongerNeeded(hash)

    TriggerEvent('qb-atmtechnician:client:npcSpawned', npcEntity)
end

CreateThread(function()
    CreateJobCenterBlip()
    SpawnNPC()
end)

-- Draw a visible glowing marker at the NPC's feet so players can spot it in the world
CreateThread(function()
    local coords = Config.JobCenter.coords
    while true do
        local sleep = 1000
        local pCoords = GetEntityCoords(PlayerPedId())
        local dist = #(pCoords - vector3(coords.x, coords.y, coords.z))
        if dist < 25.0 then
            sleep = 0
            DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 0.5, 255, 255, 255, 150, false, true, 2, false, nil, nil, false)
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if npcEntity and DoesEntityExist(npcEntity) then
        DeleteEntity(npcEntity)
    end
    if jobBlip then RemoveBlip(jobBlip) end
end)

exports('GetJobNPC', function()
    return npcEntity
end)
