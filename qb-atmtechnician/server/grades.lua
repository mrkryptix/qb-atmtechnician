

QBCore = exports['qb-core']:GetCoreObject()-- Grade / XP progression system for the ATM Technician job.
-- 5 grades (0-4), each with its own per-repair payout and per-shift XP reward.
-- Progress persists in `atmtechnician_grades` (per citizenid) and is kept in sync
-- with the player's actual QBCore job grade so the label shows correctly everywhere.

Grades = {}

local cache = {} -- [citizenid] = { xp = n, grade = n }

--- Works out the correct grade (0-Config.MaxGrade) for a given XP total
local function calcGrade(xp)
    local grade = 0
    for g = 0, Config.MaxGrade do
        local info = Config.Grades[g]
        if info and xp >= info.xpNeeded then
            grade = g
        end
    end
    return grade
end

--- Pushes the resolved grade to QBCore's actual job grade (only if it differs),
--- so job labels/menus outside this resource also show the right rank.
local function syncJobGrade(Player, grade)
    if not Player then return end
    if Player.PlayerData.job.name ~= Config.Job.name then return end
    if Player.PlayerData.job.grade.level == grade then return end

    Player.Functions.SetJob(Config.Job.name, grade)
    TriggerClientEvent('QBCore:Client:OnJobUpdate', Player.PlayerData.source, Player.PlayerData.job)
end

--- Loads (or lazily creates) a citizenid's grade/XP row into the in-memory cache.
--- Safe to call repeatedly -- only hits the DB the first time per citizenid.
function Grades.Load(citizenid, cb)
    if cache[citizenid] then
        if cb then cb(cache[citizenid]) end
        return
    end

    Database.GetPlayerGrade(citizenid, function(row)
        cache[citizenid] = { xp = row.xp or 0, grade = row.grade or 0 }
        if cb then cb(cache[citizenid]) end
    end)
end

--- Synchronous read of whatever's currently cached (0/grade0 if not loaded yet -- always
--- call Grades.Load first for a citizenid you haven't touched this session).
function Grades.Get(citizenid)
    return cache[citizenid] or { xp = 0, grade = 0 }
end

--- Adds (or removes, if amount is negative) XP for a player, recalculates their grade,
--- persists it, and syncs the real QBCore job grade if it changed.
function Grades.AddXP(Player, amount)
    local citizenid = Player.PlayerData.citizenid

    Grades.Load(citizenid, function(state)
        local newXp = math.max(0, state.xp + amount)
        local newGrade = calcGrade(newXp)
        local leveledUp = newGrade > state.grade
        local demoted = newGrade < state.grade

        cache[citizenid] = { xp = newXp, grade = newGrade }
        Database.SavePlayerGrade(citizenid, newXp, newGrade)
        syncJobGrade(Player, newGrade)

        if leveledUp then
            local info = Config.Grades[newGrade]
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, ('Promoted to %s!'):format(info.name), 'success')
        elseif demoted then
            local info = Config.Grades[newGrade]
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, ('Demoted to %s'):format(info.name), 'error')
        end
    end)
end

--- Admin-only: force a player's XP to an exact value (used by /atmtechgrade).
--- Recalculates + persists + syncs grade same as AddXP.
function Grades.SetXP(Player, amount)
    local citizenid = Player.PlayerData.citizenid
    local newXp = math.max(0, math.floor(amount))
    local newGrade = calcGrade(newXp)

    cache[citizenid] = { xp = newXp, grade = newGrade }
    Database.SavePlayerGrade(citizenid, newXp, newGrade)
    syncJobGrade(Player, newGrade)

    return newXp, newGrade
end

--- $ paid per successful ATM repair at this citizenid's current grade
function Grades.GetPayout(citizenid)
    local state = Grades.Get(citizenid)
    local info = Config.Grades[state.grade]
    return (info and info.payout) or Config.FlatPayout
end

--- XP awarded for turning in a full shift at this citizenid's current grade
function Grades.GetShiftXP(citizenid)
    local state = Grades.Get(citizenid)
    local info = Config.Grades[state.grade]
    return (info and info.shiftXP) or 0
end

--- Full display payload for the tablet UI
function Grades.GetDisplayInfo(citizenid)
    local state = Grades.Get(citizenid)
    local info = Config.Grades[state.grade]

    return {
        gradeLevel = state.grade,
        gradeName = info.name,
        currentXP = state.xp,
        xpForCurrentGrade = info.xpNeeded,
        xpForNextGrade = info.nextXp,
        payoutPerATM = info.payout,
        shiftXP = info.shiftXP,
        isMaxGrade = state.grade >= Config.MaxGrade,
    }
end

exports('GetPlayerGradeState', Grades.Get)
exports('GetPlayerGradeDisplay', Grades.GetDisplayInfo)
