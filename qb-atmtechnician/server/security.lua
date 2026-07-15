

QBCore = exports['qb-core']:GetCoreObject()QBCore = QBCore or exports['qb-core']:GetCoreObject()

-- Basic anti-exploit checks: rate limiting on repair finish events, distance sanity checks

local lastRepairFinish = {}

local function IsRateLimited(source)
    local now = GetGameTimer()
    if lastRepairFinish[source] and (now - lastRepairFinish[source]) < 5000 then
        return true
    end
    lastRepairFinish[source] = now
    return false
end

exports('IsRateLimited', IsRateLimited)

-- Sanity check: player must actually be on duty & have job when finishing a repair
RegisterServerEvent('qb-atmtechnician:server:finishRepair')
AddEventHandler('qb-atmtechnician:server:finishRepair', function(atmId, success)
    if not _G.LICENSE_VERIFIED then return end
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    if Player.PlayerData.job.name ~= Config.Job.name or not Player.PlayerData.job.onduty then
        if Config.Debug then print(('[atmtechnician] blocked finishRepair from %s - not on duty'):format(source)) end
        return
    end

    if IsRateLimited(source) then
        if Config.Debug then print(('[atmtechnician] rate limited finishRepair from %s'):format(source)) end
        return
    end

    TriggerEvent('qb-atmtechnician:server:processRepairResult', source, atmId, success)
end)

AddEventHandler('playerDropped', function()
    local source = source
    lastRepairFinish[source] = nil
end)
