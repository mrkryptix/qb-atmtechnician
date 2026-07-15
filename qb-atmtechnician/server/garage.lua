

QBCore = exports['qb-core']:GetCoreObject()-- Server-side garage bookkeeping (tracks who currently has a job vehicle out)

local vehiclesOut = {} -- source -> plate

RegisterNetEvent('qb-atmtechnician:server:vehicleStored', function()
    local source = source
    vehiclesOut[source] = nil
end)

AddEventHandler('playerDropped', function()
    local source = source
    vehiclesOut[source] = nil
end)

exports('SetVehicleOut', function(source, plate)
    vehiclesOut[source] = plate
end)

exports('IsVehicleOut', function(source)
    return vehiclesOut[source] ~= nil
end)
