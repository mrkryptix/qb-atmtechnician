-- Job vehicle spawn / store

local currentVehicle = nil
local garageBlip = nil

local function CreateGarageBlip()
    local c = Config.Garage.spawnCoords
    garageBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(garageBlip, 357)
    SetBlipColour(garageBlip, 3)
    SetBlipScale(garageBlip, 0.7)
    SetBlipAsShortRange(garageBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('ATM Tech Garage')
    EndTextCommandSetBlipName(garageBlip)
end

CreateThread(function()
    CreateGarageBlip()
end)


local function SpawnVehicle()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        Functions.Notify(Functions.Locale('vehicle_out'), 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:canTakeVehicle', function(allowed, plate, reason)
        if not allowed then
            if reason == 'need_duty' then
                Functions.Notify(Functions.Locale('need_duty'), 'error')
            elseif reason == 'not_your_job' then
                Functions.Notify(Functions.Locale('not_your_job'), 'error')
            else
                Functions.Notify('Could not take the job vehicle right now', 'error')
            end
            return
        end

        local c = Config.Garage.spawnCoords
        local hash = Functions.LoadModel(Config.Garage.vehicle)
        currentVehicle = CreateVehicle(hash, c.x, c.y, c.z, c.w, true, false)
        SetVehicleNumberPlateText(currentVehicle, plate)
        SetEntityAsMissionEntity(currentVehicle, true, true)
        SetVehicleEngineOn(currentVehicle, true, true, false)
        SetModelAsNoLongerNeeded(hash)

        exports['qb-core']:GetVehicleProperties(currentVehicle)
        TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(currentVehicle))

        TaskWarpPedIntoVehicle(PlayerPedId(), currentVehicle, -1)

        -- "Repair Van" target option on the job vehicle itself (needs a Van Repair Kit, bought from the NPC shop)
        exports['qb-target']:AddTargetEntity(currentVehicle, {
            options = {
                {
                    type = 'client',
                    event = 'qb-atmtechnician:client:repairVan',
                    icon = 'fas fa-wrench',
                    label = 'Repair Van (uses Van Repair Kit)',
                    canInteract = function()
                        return currentVehicle and DoesEntityExist(currentVehicle)
                    end,
                },
            },
            distance = 3.0,
        })
    end)
end

local function StoreVehicle()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    local pc = Config.Garage.parkCoords
    local dist = #(GetEntityCoords(PlayerPedId()) - vector3(pc.x, pc.y, pc.z))
    if dist > 15.0 then
        Functions.Notify(Functions.Locale('no_vehicle_nearby'), 'error')
        return
    end

    exports['qb-target']:RemoveTargetEntity(currentVehicle)
    DeleteEntity(currentVehicle)
    currentVehicle = nil
    TriggerServerEvent('qb-atmtechnician:server:vehicleStored')
    Functions.Notify(Functions.Locale('vehicle_stored'), 'success')
end

RegisterNetEvent('qb-atmtechnician:client:takeVehicle', SpawnVehicle)
RegisterNetEvent('qb-atmtechnician:client:storeVehicle', StoreVehicle)

RegisterNetEvent('qb-atmtechnician:client:repairVan', function()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        Functions.Notify('No job van to repair', 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:useVanRepairKit', function(success, reason)
        if not success then
            if reason == 'no_repair_kit' then
                Functions.Notify('You need a Van Repair Kit to do this', 'error')
            else
                Functions.Notify('Could not repair the van', 'error')
            end
            return
        end

        SetVehicleFixed(currentVehicle)
        SetVehicleDeformationFixed(currentVehicle)
        SetVehicleEngineHealth(currentVehicle, 1000.0)
        SetVehicleBodyHealth(currentVehicle, 1000.0)
        Functions.Notify('Van repaired!', 'success')
    end)
end)

RegisterNetEvent('qb-atmtechnician:client:forceStoreVehicle', function()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        exports['qb-target']:RemoveTargetEntity(currentVehicle)
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end
end)

exports('GetCurrentJobVehicle', function()
    return currentVehicle
end)
