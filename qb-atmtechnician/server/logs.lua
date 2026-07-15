

QBCore = exports['qb-core']:GetCoreObject()-- Discord webhook / qb-log integration

Logs = {}

function Logs.Send(title, message, color)
    -- Uses qb-log resource if present, falls back to print
    local ok = pcall(function()
        TriggerEvent('qb-log:server:CreateLog', 'atmtechnician', title, color or 'blue', message)
    end)
    if not ok and Config.Debug then
        print(('[atmtechnician LOG] %s: %s'):format(title, message))
    end
end

RegisterNetEvent('qb-atmtechnician:server:logJob', function(citizenid, atmId, success, payout)
    Logs.Send(
        success and 'ATM Repaired' or 'ATM Repair Failed',
        ('Citizen **%s** %s ATM `%s` %s'):format(
            citizenid, success and 'successfully repaired' or 'failed to repair', atmId,
            success and ('for **$%s**'):format(payout) or ''
        ),
        success and 'green' or 'red'
    )
end)
