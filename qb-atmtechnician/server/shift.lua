
QBCore = exports['qb-core']:GetCoreObject()-- Manages the sequential-5-ATM shift system: one ATM revealed at a time,
-- turn-in at the NPC once all are done, and post-shift cooldown.
-- Keyed by citizenid so it survives a relog within the same server session.

Shift = {}

-- [citizenid] = { queue = {id,...}, atmsById = {[id]={coords,label}}, index = 1, progress = 0,
--                  cooldownUntil = nil, awaitingTurnIn = false, readyToQuit = true, quitCooldownUntil = nil }
local state = {}

local function getState(citizenid)
    if not state[citizenid] then
        state[citizenid] = {
            queue = {}, atmsById = {}, index = 1, progress = 0,
            cooldownUntil = nil, awaitingTurnIn = false,
            readyToQuit = true,      -- false while a shift has been started but not yet turned in
            quitCooldownUntil = nil, -- real-world cooldown before re-applying, set once the player quits
        }
    end
    return state[citizenid]
end

--- Returns remaining cooldown in minutes (0 if none / expired)
function Shift.GetCooldownRemaining(citizenid)
    local s = getState(citizenid)
    if not s.cooldownUntil then return 0 end

    local remaining = math.ceil((s.cooldownUntil - os.time()) / 60)
    if remaining <= 0 then
        s.cooldownUntil = nil
        return 0
    end
    return remaining
end

--- Returns true if the player is allowed to quit the job right now, i.e. they are not
--- mid-shift and any shift they started has been properly turned in at the NPC.
function Shift.IsReadyToQuit(citizenid)
    local s = getState(citizenid)
    return s.readyToQuit
end

--- Returns remaining quit-cooldown in minutes (0 if none / expired)
function Shift.GetQuitCooldownRemaining(citizenid)
    local s = getState(citizenid)
    if not s.quitCooldownUntil then return 0 end

    local remaining = math.ceil((s.quitCooldownUntil - os.time()) / 60)
    if remaining <= 0 then
        s.quitCooldownUntil = nil
        return 0
    end
    return remaining
end

--- Starts the real-world cooldown before the player can re-apply for the job after quitting.
function Shift.SetQuitCooldown(citizenid)
    local s = getState(citizenid)
    s.quitCooldownUntil = os.time() + (Config.Shift.quitCooldownMinutes * 60)
end

--- Starts a fresh shift: picks Config.Shift.size random ATMs and reveals only the first one.
--- Returns { id, coords, label, remaining, size } for the first ATM.
function Shift.StartShift(citizenid)
    local s = getState(citizenid)
    s.queue = {}
    s.atmsById = {}
    s.index = 1
    s.progress = 0
    s.cooldownUntil = nil
    s.awaitingTurnIn = false
    s.readyToQuit = false -- can't quit again until this shift is fully turned in

    local picked = Shared.PickRandomN(Config.ATMLocations, Config.Shift.size)
    for _, entry in ipairs(picked) do
        local id = Shared.GetATMId(entry.coords)
        s.queue[#s.queue + 1] = id
        s.atmsById[id] = { coords = entry.coords, label = entry.label }
    end

    local firstId = s.queue[1]
    local first = s.atmsById[firstId]
    return {
        id = firstId,
        coords = first.coords,
        label = first.label,
        remaining = Config.Shift.size,
        size = Config.Shift.size,
    }
end

--- Returns the currently-unlocked ATM { id, coords, label } for this player, or nil if none active
function Shift.GetCurrent(citizenid)
    local s = getState(citizenid)
    local currentId = s.queue[s.index]
    if not currentId then return nil end
    local atm = s.atmsById[currentId]
    return { id = currentId, coords = atm.coords, label = atm.label }
end

--- Returns true if atmId is the player's currently-unlocked ATM
function Shift.IsCurrentATM(citizenid, atmId)
    local current = Shift.GetCurrent(citizenid)
    return current ~= nil and current.id == atmId
end

--- Returns true if the player has finished all assigned ATMs and needs to turn in at the NPC
function Shift.IsAwaitingTurnIn(citizenid)
    local s = getState(citizenid)
    return s.awaitingTurnIn
end

--- Call when a repair succeeds on the current ATM.
--- Returns (remaining, size, nextAtmOrNil, isAllDone)
function Shift.CompleteCurrent(citizenid, atmId)
    local s = getState(citizenid)
    if not Shift.IsCurrentATM(citizenid, atmId) then
        local remaining = Config.Shift.size - s.progress
        return remaining, Config.Shift.size, nil, false
    end

    s.progress = s.progress + 1
    s.index = s.index + 1

    local remaining = Config.Shift.size - s.progress
    local nextId = s.queue[s.index]

    if nextId then
        local nextAtm = s.atmsById[nextId]
        return remaining, Config.Shift.size, { id = nextId, coords = nextAtm.coords, label = nextAtm.label }, false
    else
        s.awaitingTurnIn = true
        return remaining, Config.Shift.size, nil, true
    end
end

--- Finalizes the shift at NPC turn-in: clears state and starts the cooldown timer.
function Shift.TurnIn(citizenid)
    local s = getState(citizenid)
    s.queue = {}
    s.atmsById = {}
    s.index = 1
    s.progress = 0
    s.awaitingTurnIn = false
    s.cooldownUntil = os.time() + (Config.Shift.cooldownMinutes * 60)
    s.readyToQuit = true -- only a full 5/5 turn-in clears the quit block
end

--- Returns true if the player currently has ATMs still queued/in-progress this shift
--- (started but not yet finished+turned in). False once turned in or never started.
function Shift.HasActiveShift(citizenid)
    local s = getState(citizenid)
    return #s.queue > 0 and s.index <= #s.queue
end

--- Starts a shift, but RESUMES an unfinished one instead of picking a fresh random set
--- if the player already has ATMs left over from before (e.g. they went off duty, left
--- the game / disconnected, or re-applied for the job mid-shift). This is what makes
--- progress survive: repair 2/5, log off, come back later -> still only 3/5 left, not
--- a brand new 5.
---
--- Returns three values:
---   atm              -- { id, coords, label, remaining, size } for the ATM to reveal, or nil
---   isAwaitingTurnIn -- true if the player already finished all ATMs and just needs to
---                       go turn the shift in at the NPC (atm will be nil in this case)
---   resumed          -- true if this continued an existing shift instead of starting fresh
function Shift.StartOrResume(citizenid)
    local s = getState(citizenid)

    -- All ATMs already repaired, just never turned in at the NPC yet (e.g. disconnected
    -- right after the last repair) -- leave the state untouched, they just need to go turn it in.
    if s.awaitingTurnIn then
        return nil, true, false
    end

    -- Unfinished shift left over from before -- resume at the current ATM, don't touch progress.
    if Shift.HasActiveShift(citizenid) then
        local current = Shift.GetCurrent(citizenid)
        local remaining = Config.Shift.size - s.progress
        return {
            id = current.id,
            coords = current.coords,
            label = current.label,
            remaining = remaining,
            size = Config.Shift.size,
        }, false, true
    end

    -- Nothing left over: start a completely fresh shift.
    return Shift.StartShift(citizenid), false, false
end

exports('GetCooldownRemaining', Shift.GetCooldownRemaining)
exports('StartOrResume', Shift.StartOrResume)
exports('IsReadyToQuit', Shift.IsReadyToQuit)
exports('GetQuitCooldownRemaining', Shift.GetQuitCooldownRemaining)
exports('HasActiveShift', Shift.HasActiveShift)
