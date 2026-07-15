

QBCore = exports['qb-core']:GetCoreObject()-- Receives periodic vehicle health/fuel sync from client (could persist to DB for real garage systems)

RegisterNetEvent('qb-atmtechnician:server:syncVehicle', function(plate, data)
    local source = source
    if Config.Debug then
        print(('[atmtechnician] vehicle sync from %s | plate: %s | engine: %.1f | body: %.1f | fuel: %.1f')
            :format(source, plate, data.engine, data.body, data.fuel))
    end
    -- Extend here: exports.oxmysql:execute('UPDATE player_vehicles SET ... WHERE plate = ?', { plate })
end)
