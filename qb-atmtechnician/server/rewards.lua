

QBCore = exports['qb-core']:GetCoreObject()-- Handles payout calculation and giving money to the player

Rewards = {}

function Rewards.CalculatePayout(Player)
    -- Payout now scales with the technician's current grade (Config.Grades)
    return Grades.GetPayout(Player.PlayerData.citizenid)
end

function Rewards.Give(Player, amount)
    Player.Functions.AddMoney('bank', amount, 'atmtechnician-payout')
end
