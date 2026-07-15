
QBCore = exports['qb-core']:GetCoreObject()QBCore = QBCore or exports['qb-core']:GetCoreObject()

-- Sends dispatch alerts to online police jobs

RegisterNetEvent('qb-atmtechnician:server:alertPolice', function(source, message)
    AlertPolice(source, message)
end)

function AlertPolice(source, message)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local coords = GetEntityCoords(GetPlayerPed(source))
    local players = QBCore.Functions.GetQBPlayers()

    for _, Player2 in pairs(players) do
        if Player2.PlayerData.job.type == 'leo' and Player2.PlayerData.job.onduty then
            TriggerClientEvent(Config.Police.dispatchEvent, Player2.PlayerData.source, {
                coords = coords,
                message = message or Config.Police.alertMessage,
            })
        end
    end

    TriggerClientEvent('qb-atmtechnician:client:policeAlertVisual', source)
end

exports('AlertPolice', AlertPolice)
