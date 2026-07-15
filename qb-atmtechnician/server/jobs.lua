
QBCore = exports['qb-core']:GetCoreObject()QBCore = QBCore or exports['qb-core']:GetCoreObject()

-- Core job result processing: ties together rewards, db, police alert, logging

AddEventHandler('qb-atmtechnician:server:processRepairResult', function(source, atmId, success)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    exports['qb-atmtechnician']:ReleaseActiveRepair(atmId)

    local payout = 0

    if success then
        Database.SetATMRepaired(atmId)
        payout = Rewards.CalculatePayout(Player)
        Rewards.Give(Player, payout)
        TriggerClientEvent('QBCore:Notify', source, Functions_Locale_Server('paid', payout), 'success')

        -- sequential shift progress: unlock next ATM, or flag "return to NPC" once all done
        local citizenid = Player.PlayerData.citizenid
        local remaining, size, nextAtm, isAllDone = Shift.CompleteCurrent(citizenid, atmId)

        if isAllDone then
            TriggerClientEvent('qb-atmtechnician:client:shiftAllComplete', source, remaining, size)
        else
            TriggerClientEvent('qb-atmtechnician:client:shiftProgress', source, remaining, size, nextAtm)
        end
    else
        -- failed repair: chance to break a tool
        if math.random(1, 100) <= Config.Minigame.failPenalty.breakTool then
            for _, item in ipairs(Config.RequiredItems) do
                if item ~= 'tool_repair_kit' then -- keep tablet, break consumable tools only
                    Player.Functions.RemoveItem(item, 1)
                    TriggerClientEvent('QBCore:Notify', source, Functions_Locale_Server('tool_broke'), 'error')
                    break
                end
            end
        end
    end

    Database.LogJob(Player.PlayerData.citizenid, atmId, success, payout)
    TriggerEvent('qb-atmtechnician:server:logJob', Player.PlayerData.citizenid, atmId, success, payout)
end)

--- Small helper since server has no Locales table loaded the same way client does;
--- shared.lua/locales are shared scripts so Locales table IS available server-side too.
function Functions_Locale_Server(key, ...)
    local str = Locales[Config.Locale] and Locales[Config.Locale][key]
    if not str then return key end
    if ... then
        return string.format(str, ...)
    end
    return str
end
