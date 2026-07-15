
QBCore = exports['qb-core']:GetCoreObject()QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    if Config.Debug then
        print('^2[qb-atmtechnician]^7 server loaded')
    end
end)

-- Make sure players are set off duty on resource restart to avoid stuck states
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(2000)
        local players = QBCore.Functions.GetQBPlayers()
        for _, Player in pairs(players) do
            if Player.PlayerData.job.name == Config.Job.name then
                Grades.Load(Player.PlayerData.citizenid)
                if Player.PlayerData.job.onduty then
                    Player.Functions.SetJobDuty(false)
                    TriggerClientEvent('QBCore:Client:OnJobUpdate', Player.PlayerData.source, Player.PlayerData.job)
                end
            end
        end
    end)
end)

-- Pre-load grade/XP into cache as soon as an existing technician logs in
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if Player.PlayerData.job.name == Config.Job.name then
        Grades.Load(Player.PlayerData.citizenid)
    end
end)

QBCore.Commands.Add('atmtechadmin', 'Set ATM Technician job (Admin Only)', {
    { name = 'id', help = 'Player ID' },
    { name = 'grade', help = 'Grade (0-4)' },
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local grade = math.max(0, math.min(Config.MaxGrade, tonumber(args[2]) or 0))
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then return end

    Player.Functions.SetJob(Config.Job.name, grade)
    TriggerClientEvent('QBCore:Notify', targetId, 'You have been set as an ATM Technician', 'success')
end, 'admin')

-- Admin-only: view / increase / decrease / set a technician's XP + grade directly.
-- Usage:
--   /atmtechgrade <id>                -> show their current grade + XP
--   /atmtechgrade <id> add <amount>   -> add XP (negative amount removes XP)
--   /atmtechgrade <id> set <amount>   -> set XP to an exact value
QBCore.Commands.Add('atmtechgrade', 'View or change an ATM Technician\'s grade/XP (Admin Only)', {
    { name = 'id', help = 'Player ID' },
    { name = 'action', help = 'view / add / set' },
    { name = 'amount', help = 'XP amount (blank for view)' },
}, false, function(source, args)
    local targetId = tonumber(args[1])
    local action = string.lower(args[2] or 'view')
    local Player = QBCore.Functions.GetPlayer(targetId)

    if not Player then
        TriggerClientEvent('QBCore:Notify', source, 'Player not online', 'error')
        return
    end

    if Player.PlayerData.job.name ~= Config.Job.name then
        TriggerClientEvent('QBCore:Notify', source, 'That player is not an ATM Technician', 'error')
        return
    end

    local citizenid = Player.PlayerData.citizenid

    Grades.Load(citizenid, function(state)
        if action == 'view' then
            local info = Config.Grades[state.grade]
            TriggerClientEvent('QBCore:Notify', source, ('%s -- %s -- %s / %s XP'):format(
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                info.name, state.xp, info.nextXp
            ), 'primary')
            return
        end

        local amount = tonumber(args[3])
        if not amount then
            TriggerClientEvent('QBCore:Notify', source, 'You must provide an XP amount', 'error')
            return
        end

        if action == 'add' then
            Grades.AddXP(Player, amount)
            TriggerClientEvent('QBCore:Notify', source, ('Added %s XP to %s'):format(amount, citizenid), 'success')
        elseif action == 'set' then
            local newXp, newGrade = Grades.SetXP(Player, amount)
            TriggerClientEvent('QBCore:Notify', source, ('Set %s to %s XP (%s)'):format(citizenid, newXp, Config.Grades[newGrade].name), 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'Unknown action, use: view / add / set', 'error')
        end
    end)
end, 'admin')
