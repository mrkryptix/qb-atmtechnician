QBCore = exports['qb-core']:GetCoreObject()
QBCore = QBCore or exports['qb-core']:GetCoreObject()

-- All QBCore server callbacks used by the client

local activeRepairs = {} -- atmId -> true while a repair is happening (server-wide, prevents 2 techs racing same atm)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:applyJob', function(source, cb)
    if not _G.LICENSE_VERIFIED then cb(false, { reason = 'license_invalid' }) return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end

    if Player.PlayerData.job.name == Config.Job.name then
        cb(false)
        return
    end

    -- real-world cooldown after quitting the job
    local citizenid = Player.PlayerData.citizenid
    local quitRemaining = Shift.GetQuitCooldownRemaining(citizenid)
    if quitRemaining > 0 then
        cb(false, { reason = 'quit_cooldown', cooldown = quitRemaining })
        return
    end

    -- Optional slot cap for public servers (0 = unlimited)
    if Config.Job.maxSlots and Config.Job.maxSlots > 0 then
        local currentCount = 0
        for _, p in pairs(QBCore.Functions.GetQBPlayers()) do
            if p.PlayerData.job.name == Config.Job.name then
                currentCount = currentCount + 1
            end
        end
        if currentCount >= Config.Job.maxSlots then
            cb(false)
            return
        end
    end

    Grades.Load(citizenid, function(state)
        Player.Functions.SetJob(Config.Job.name, state.grade) -- restores previously-earned grade, not always 0
        Player.Functions.SetJobDuty(true) -- auto clock-in on apply

        IDCard.Give(Player)

        TriggerClientEvent('QBCore:Client:OnJobUpdate', source, Player.PlayerData.job)
        TriggerClientEvent('qb-atmtechnician:client:jobApplied', source) -- direct, race-proof trigger for uniform + ATM spawn

        -- resume leftover progress (e.g. left the game mid-shift last time) instead of
        -- always handing out a fresh set of 5 ATMs
        local atm, isAwaitingTurnIn, resumed = Shift.StartOrResume(citizenid)
        if isAwaitingTurnIn then
            TriggerClientEvent('qb-atmtechnician:client:shiftAllComplete', source, 0, Config.Shift.size)
        else
            TriggerClientEvent('qb-atmtechnician:client:shiftAssigned', source, atm, resumed)
        end

        Logs.Send('New ATM Technician', ('**%s** applied and joined the ATM Technician job'):format(citizenid), 'green')
        cb(true)
    end)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:quitJob', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, 'no_player') return end
    if Player.PlayerData.job.name ~= Config.Job.name then cb(false, 'not_your_job') return end

    local citizenid = Player.PlayerData.citizenid

    -- must be off duty first (turning in a shift automatically clocks the player off duty)
    if Player.PlayerData.job.onduty then
        cb(false, 'cannot_quit_onduty')
        return
    end

    -- must not be sitting on an abandoned/incomplete shift (e.g. manually clocked off mid-shift
    -- without finishing all 5 ATMs and turning them in at the NPC)
    if not Shift.IsReadyToQuit(citizenid) then
        cb(false, 'cannot_quit_incomplete')
        return
    end

    Player.Functions.SetJob('unemployed', 0)
    TriggerClientEvent('QBCore:Client:OnJobUpdate', source, Player.PlayerData.job)

    Shift.SetQuitCooldown(citizenid)

    Logs.Send('ATM Technician Quit', ('**%s** left the ATM Technician job'):format(citizenid), 'orange')

    cb(true, Config.Shift.quitCooldownMinutes)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:toggleDuty', function(source, cb)
    if not _G.LICENSE_VERIFIED then cb(false, { reason = 'license_invalid' }) return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    if Player.PlayerData.job.name ~= Config.Job.name then cb(false) return end

    local citizenid = Player.PlayerData.citizenid
    local goingOnDuty = not Player.PlayerData.job.onduty

    if goingOnDuty then
        Grades.Load(citizenid) -- safety: make sure XP/grade cache is populated before any repairs happen
        local remaining = Shift.GetCooldownRemaining(citizenid)
        if remaining > 0 then
            cb(false, { cooldown = remaining })
            return
        end
    end

    if not goingOnDuty and Shift.IsAwaitingTurnIn(citizenid) then
        -- all 5 ATMs are done but the player hasn't turned the shift in at the NPC yet --
        -- block duty-off entirely, they must use the "Turn In Shift" option first
        cb(false, { mustTurnIn = true })
        return
    end

    Player.Functions.SetJobDuty(goingOnDuty)
    TriggerClientEvent('QBCore:Client:OnJobUpdate', source, Player.PlayerData.job)

    if goingOnDuty then
        IDCard.Give(Player)

        -- resume leftover progress (repaired 2/5, went off duty/left the game, now back on
        -- duty) instead of always handing out a fresh set of 5 ATMs
        local atm, isAwaitingTurnIn, resumed = Shift.StartOrResume(citizenid)
        if isAwaitingTurnIn then
            TriggerClientEvent('qb-atmtechnician:client:shiftAllComplete', source, 0, Config.Shift.size)
        else
            TriggerClientEvent('qb-atmtechnician:client:shiftAssigned', source, atm, resumed)
        end
        cb(true, { atm = atm })
    else
        IDCard.Remove(Player)
        if Shift.HasActiveShift(citizenid) then
            -- manual duty-off before finishing the shift: PAUSE it, don't wipe progress.
            -- No cooldown penalty either way -- going back on duty (or re-taking the job)
            -- will resume at the exact same ATM with the same remaining count.
            TriggerClientEvent('qb-atmtechnician:client:shiftCleared', source)
        end
        -- else: shift was already turned in (or never started) -- leave Shift.TurnIn's
        -- cooldown/readyToQuit state alone, this is just a plain clock-off
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:canTakeVehicle', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, nil, 'no_player') return end
    if Player.PlayerData.job.name ~= Config.Job.name then cb(false, nil, 'not_your_job') return end
    if not Player.PlayerData.job.onduty then cb(false, nil, 'need_duty') return end

    local plate = Config.Garage.plateprefix .. tostring(math.random(1000, 9999))
    cb(true, plate)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:hasTools', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, {}) return end

    -- checks ALL 6 required tools every single time this is called (i.e. every repair attempt,
    -- including retries on the same ATM) -- nothing is cached, so picking up a missing tool
    -- and clicking repair again will pass as soon as all 6 are actually in the inventory.
    local missing = {}
    for _, item in ipairs(Config.RequiredItems) do
        local hasItem = Player.Functions.GetItemByName(item)
        if not hasItem then
            local itemLabel = (QBCore.Shared.Items[item] and QBCore.Shared.Items[item].label) or item
            missing[#missing + 1] = itemLabel
        end
    end

    if #missing > 0 then
        cb(false, missing)
        return
    end

    cb(true, {})
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:canRepairATM', function(source, cb, atmId)
    if not _G.LICENSE_VERIFIED then cb(false, 'license_invalid') return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job.name or not Player.PlayerData.job.onduty then
        cb(false, 'need_duty')
        return
    end

    if activeRepairs[atmId] then
        cb(false, 'atm_busy')
        return
    end

    if not Shift.IsCurrentATM(Player.PlayerData.citizenid, atmId) then
        cb(false, 'atm_not_assigned')
        return
    end

    Database.GetATMCooldown(atmId, function(lastRepaired)
        local lastTime = Shared.MySQLTimeToUnix(lastRepaired)
        if lastTime then
            local diffMinutes = os.difftime(os.time(), lastTime) / 60
            if diffMinutes < Config.ATMCooldown then
                cb(false, 'atm_cooldown')
                return
            end
        end

        activeRepairs[atmId] = source
        cb(true)
    end)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:getTabletData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end

    local citizenid = Player.PlayerData.citizenid

    Database.GetPlayerStats(citizenid, function(stats)
        Database.GetRecentJobs(citizenid, 10, function(recent)
            -- map raw atm_id -> friendly label for display
            for _, job in ipairs(recent) do
                job.label = Shared.ATMLabelByID[job.atm_id] or job.atm_id
            end

            local atmLocations = {}
            for _, entry in ipairs(Config.ATMLocations) do
                atmLocations[#atmLocations + 1] = { label = entry.label }
            end

            Grades.Load(citizenid, function()
                local gradeInfo = Grades.GetDisplayInfo(citizenid)

                cb({
                    name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    grade = Player.PlayerData.job.grade.name,
                    onDuty = Player.PlayerData.job.onduty,
                    totalJobs = stats.total_jobs or 0,
                    successfulJobs = stats.successful_jobs or 0,
                    totalEarned = stats.total_earned or 0,
                    recentJobs = recent,
                    atmLocations = atmLocations,
                    shopItems = Config.ShopItems,
                    bankMoney = Player.PlayerData.money and Player.PlayerData.money.bank or 0,
                    shiftCooldown = Shift.GetCooldownRemaining(citizenid),
                    gradeInfo = gradeInfo,
                })
            end)
        end)
    end)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:buyShopItem', function(source, cb, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, 'no_player') return end

    local shopItem = nil
    for _, entry in ipairs(Config.ShopItems) do
        if entry.item == itemName then
            shopItem = entry
            break
        end
    end

    if not shopItem then cb(false, 'invalid_item') return end

    if (Player.PlayerData.money.bank or 0) < shopItem.price then
        cb(false, 'not_enough_money')
        return
    end

    if not Player.Functions.RemoveMoney('bank', shopItem.price, 'atmtechnician-shop-purchase') then
        cb(false, 'not_enough_money')
        return
    end

    Player.Functions.AddItem(shopItem.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[shopItem.item], 'add')

    Logs.Send('ATM Tool Purchase', ('**%s** bought **%s** for $%s'):format(Player.PlayerData.citizenid, shopItem.item, shopItem.price), 'blue')

    cb(true, shopItem.label)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:turnInShift', function(source, cb)
    if not _G.LICENSE_VERIFIED then cb(false, 'license_invalid') return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    if Player.PlayerData.job.name ~= Config.Job.name then cb(false) return end

    local citizenid = Player.PlayerData.citizenid

    if not Shift.IsAwaitingTurnIn(citizenid) then
        cb(false, 'nothing_to_turn_in')
        return
    end

    Shift.TurnIn(citizenid)

    -- award XP for completing this shift, at the technician's current grade rate
    local shiftXP = Grades.GetShiftXP(citizenid)
    Grades.AddXP(Player, shiftXP)
    TriggerClientEvent('QBCore:Notify', source, ('+%s XP'):format(shiftXP), 'success')

    -- auto-remove all required repair tools once the shift is turned in
    for _, item in ipairs(Config.RequiredItems) do
        local hasItem = Player.Functions.GetItemByName(item)
        while hasItem do
            Player.Functions.RemoveItem(item, 1, hasItem.slot)
            hasItem = Player.Functions.GetItemByName(item)
        end
    end

    TriggerClientEvent('qb-atmtechnician:client:shiftCleared', source)

    Logs.Send('ATM Shift Turned In', ('**%s** finished a full ATM shift'):format(citizenid), 'green')

    cb(true, Config.Shift.cooldownMinutes)
end)

QBCore.Functions.CreateCallback('qb-atmtechnician:server:useVanRepairKit', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end

    local kit = Player.Functions.GetItemByName(Config.VanRepair.item)
    if not kit then
        cb(false, 'no_repair_kit')
        return
    end

    Player.Functions.RemoveItem(Config.VanRepair.item, 1, kit.slot)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.VanRepair.item], 'remove')

    cb(true)
end)

exports('ReleaseActiveRepair', function(atmId)
    activeRepairs[atmId] = nil
end)

RegisterNetEvent('qb-atmtechnician:server:releaseRepairLock', function(atmId)
    -- only the player currently holding the lock on this ATM can release it
    if activeRepairs[atmId] == source then
        activeRepairs[atmId] = nil
    end
end)

exports('GetActiveRepairs', function()
    return activeRepairs
end)
