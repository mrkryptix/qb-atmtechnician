-- Keeps job vehicle fuel/damage optionally synced to server (works with qb-fuel / LegacyFuel if present)

CreateThread(function()
    while true do
        Wait(60000)
        local veh = exports['qb-atmtechnician']:GetCurrentJobVehicle()
        if veh and DoesEntityExist(veh) then
            local plate = QBCore.Functions.GetPlate(veh)
            local engineHealth = GetVehicleEngineHealth(veh)
            local bodyHealth = GetVehicleBodyHealth(veh)
            local fuel = GetVehicleFuelLevel and GetVehicleFuelLevel(veh) or 100.0

            TriggerServerEvent('qb-atmtechnician:server:syncVehicle', plate, {
                engine = engineHealth,
                body = bodyHealth,
                fuel = fuel,
            })
        end
    end
end)

-- Prevent job vehicle from being sold / stored in other garages accidentally
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local veh = exports['qb-atmtechnician']:GetCurrentJobVehicle()
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
end)
