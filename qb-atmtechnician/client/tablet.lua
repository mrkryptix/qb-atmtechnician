-- Job Tablet NUI - shows stats, active tasks, payout history

local tabletOpen = false

RegisterNetEvent('qb-atmtechnician:client:openTablet', function()
    if not Functions.HasJob() then
        Functions.Notify(Functions.Locale('not_your_job'), 'error')
        return
    end
    if tabletOpen then return end
    -- Note: tablet can be opened off duty too (e.g. during shift cooldown) so players can still shop for tools

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:getTabletData', function(data)
        tabletOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openTablet',
            data = data,
        })
        Animations.PlayTablet(2000)
        Functions.Notify(Functions.Locale('tablet_opened'), 'primary')
    end)
end)

RegisterNUICallback('closeTablet', function(_, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    local itemName = data and data.item

    if not itemName then
        cb('error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:buyShopItem', function(success, result)
        if success then
            Functions.Notify(Functions.Locale('item_purchased', result), 'success')
        else
            if result == 'not_enough_money' then
                Functions.Notify(Functions.Locale('not_enough_money'), 'error')
            else
                Functions.Notify(Functions.Locale('purchase_failed'), 'error')
            end
        end

        -- refresh tablet data (updated bank balance) regardless of outcome
        QBCore.Functions.TriggerCallback('qb-atmtechnician:server:getTabletData', function(tabletData)
            SendNUIMessage({ action = 'updateTablet', data = tabletData })
        end)

        cb(success and 'ok' or 'error')
    end, itemName)
end)

-- "Take Job" button: spawns the job vehicle (if not already out) and marks the nearest ATM on the map
RegisterNUICallback('takeJob', function(_, cb)
    if not Functions.OnDuty() then
        Functions.Notify(Functions.Locale('need_duty'), 'error')
        cb('error')
        return
    end

    -- find the nearest ATM from the player's currently assigned shift (not the full location list)
    local pCoords = GetEntityCoords(PlayerPedId())
    local shiftCoords = exports['qb-atmtechnician']:GetAssignedATMCoords()
    local nearest, _ = Functions.GetClosest(shiftCoords, pCoords)

    if not nearest then
        Functions.Notify('No active ATMs in your current shift', 'error')
        cb('error')
        return
    end

    TriggerEvent('qb-atmtechnician:client:takeVehicle')
    TriggerEvent('qb-atmtechnician:client:markJobLocation', nearest)

    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeTablet' })

    cb('ok')
end)

RegisterKeyMapping('atmtech_closetablet', 'Close ATM Tech Tablet', 'keyboard', 'ESCAPE')
RegisterCommand('atmtech_closetablet', function()
    if tabletOpen then
        tabletOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeTablet' })
    end
end, false)

-- Emergency unstuck command in case NUI focus ever gets stuck (type in chat: /fixscreen)
RegisterCommand('fixscreen', function()
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeTablet' })
    Functions.Notify('Screen unlocked', 'primary')
end, false)
