-- Handles duty toggle logic (triggered from target interaction on job NPC)

RegisterNetEvent('qb-atmtechnician:client:applyJob', function()
    if Functions.HasJob() then
        Functions.Notify('You already work here', 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:applyJob', function(success, extra)
        if success then
            Functions.Notify('Congratulations, you are now an ATM Technician!', 'success')
        elseif extra and extra.reason == 'quit_cooldown' then
            Functions.Notify(Functions.Locale('quit_cooldown', extra.cooldown), 'error')
        else
            Functions.Notify('Could not apply for this job right now', 'error')
        end
    end)
end)

RegisterNetEvent('qb-atmtechnician:client:quitJob', function()
    if not Functions.HasJob() then
        Functions.Notify(Functions.Locale('not_your_job'), 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:quitJob', function(success, extra)
        if success then
            Functions.Notify(Functions.Locale('job_quit_success', extra), 'primary')
            TriggerEvent('qb-atmtechnician:client:setUniform', false)       -- restore the exact outfit worn before applying
            TriggerEvent('qb-atmtechnician:client:forceStoreVehicle')       -- remove the job van
            TriggerEvent('qb-atmtechnician:client:clearAllATMBlips')
            TriggerEvent('qb-atmtechnician:client:jobStateChanged', false)  -- despawn ATM props/zones
        elseif extra == 'cannot_quit_onduty' then
            Functions.Notify(Functions.Locale('cannot_quit_onduty'), 'error')
        elseif extra == 'cannot_quit_incomplete' then
            Functions.Notify(Functions.Locale('cannot_quit_incomplete'), 'error')
        else
            Functions.Notify('Could not quit the job right now', 'error')
        end
    end)
end)

RegisterNetEvent('qb-atmtechnician:client:toggleDuty', function()
    if not Functions.HasJob() then
        Functions.Notify(Functions.Locale('not_your_job'), 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:toggleDuty', function(onDuty, extra)
        if onDuty then
            Functions.Notify(Functions.Locale('duty_on'), 'success')
            -- shift ATMs arrive separately via 'qb-atmtechnician:client:shiftAssigned'
        else
            if extra and extra.mustTurnIn then
                -- shift is fully done (5/5) but not turned in yet -- duty-off was blocked server-side
                Functions.Notify(Functions.Locale('must_turn_in_shift'), 'error')
            elseif extra and extra.cooldown then
                Functions.Notify(Functions.Locale('shift_cooldown', extra.cooldown), 'error')
            else
                Functions.Notify(Functions.Locale('duty_off'), 'error')
                -- if going off duty manually, force store vehicle & clear active atm blips
                TriggerEvent('qb-atmtechnician:client:forceStoreVehicle')
                TriggerEvent('qb-atmtechnician:client:clearAllATMBlips')
            end
        end
    end)
end)

-- Fired when the player interacts with the NPC's "Turn In Shift" option after finishing all ATMs
RegisterNetEvent('qb-atmtechnician:client:turnInShift', function()
    local isAwaiting = exports['qb-atmtechnician']:IsAwaitingTurnIn()
    if not isAwaiting then
        Functions.Notify('You have no completed shift to turn in', 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:turnInShift', function(success, cooldownMinutes)
        if success then
            Functions.Notify(Functions.Locale('shift_turned_in', cooldownMinutes), 'success')
            TriggerEvent('qb-atmtechnician:client:forceStoreVehicle')
        else
            Functions.Notify('Could not turn in your shift right now', 'error')
        end
    end)
end)

-- Keep local PlayerData job state fresh
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    if JobInfo.name == Config.Job.name then
        if Config.Debug then print('[atmtechnician] job updated, onduty: ' .. tostring(JobInfo.onduty)) end
    end
end)
