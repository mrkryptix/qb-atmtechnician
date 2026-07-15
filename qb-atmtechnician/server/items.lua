
QBCore = exports['qb-core']:GetCoreObject()QBCore = QBCore or exports['qb-core']:GetCoreObject()

-- Registers useable items (add these to qb-core/shared/items.lua as well - see README)
-- This file wires up server-side item use callbacks

QBCore.Functions.CreateUseableItem('tool_repair_kit', function(source, item)
    if not _G.LICENSE_VERIFIED then return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.name ~= Config.Job.name then return end

    TriggerClientEvent('qb-atmtechnician:client:openTablet', source)
end)

QBCore.Functions.CreateUseableItem('provision_key_bank_safe', function(source, item)
    if not _G.LICENSE_VERIFIED then return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    -- Master key = illegal bypass tool, always alerts police if enabled
    if Config.Police.alertOnMasterkeyUse then
        TriggerEvent('qb-atmtechnician:server:alertPolice', source, 'ATM tampering detected (unauthorized key use)')
    end

    TriggerClientEvent('QBCore:Notify', source, 'You used the master key to bypass the ATM lock', 'primary')
end)
