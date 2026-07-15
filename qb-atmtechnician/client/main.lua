-- Entry point / misc client logic

CreateThread(function()
    if Config.Debug then
        print('^2[qb-atmtechnician]^7 client loaded')
    end
end)

-- The uniform and ATM props are tied to HOLDING the job, not to duty state:
-- apply job -> dress changes + ATMs spawn (and stay, even through duty off/on)
-- quit job  -> dress restores + ATMs despawn
local hadJob = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    hadJob = Functions.HasJob()
    if hadJob then
        TriggerEvent('qb-atmtechnician:client:setUniform', true)
        TriggerEvent('qb-atmtechnician:client:jobStateChanged', true)
    end
end)

-- Direct, race-proof trigger fired by the server right after SetJob/SetJobDuty on apply.
-- (We don't rely solely on QBCore:Client:OnJobUpdate here -- on some QBCore builds
-- Player.PlayerData.job isn't refreshed yet at the exact moment the server sends that
-- broadcast, so the uniform would silently fail to apply on Apply and only "catch up"
-- later on the next duty toggle -- that was the "uniform only shows after clicking
-- off-duty" bug.)
RegisterNetEvent('qb-atmtechnician:client:jobApplied', function()
    if hadJob then return end
    hadJob = true
    TriggerEvent('qb-atmtechnician:client:setUniform', true)
    TriggerEvent('qb-atmtechnician:client:jobStateChanged', true)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    local hasJobNow = JobInfo.name == Config.Job.name

    if hasJobNow and not hadJob then
        -- just applied for the job
        hadJob = true
        TriggerEvent('qb-atmtechnician:client:setUniform', true)
        TriggerEvent('qb-atmtechnician:client:jobStateChanged', true)
    elseif not hasJobNow and hadJob then
        -- just quit the job
        hadJob = false
        TriggerEvent('qb-atmtechnician:client:setUniform', false)
        TriggerEvent('qb-atmtechnician:client:jobStateChanged', false)
    end
    -- onduty toggling on its own (clock in/out, turn in shift) intentionally does NOT
    -- touch the uniform or ATM props anymore -- that was the bug being fixed.
end)

-- Cleanup on logout
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    TriggerEvent('qb-atmtechnician:client:forceStoreVehicle')
    TriggerEvent('qb-atmtechnician:client:clearAllATMBlips')
end)
