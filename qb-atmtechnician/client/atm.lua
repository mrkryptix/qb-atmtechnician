-- Handles ATM interaction zones, cooldown display, and repair flow

local activeATMBlips = {}
local busyATMs = {} -- locally tracked "in progress" atm ids
local isRepairing = false
local activeJobBlip = nil -- the single "your assigned job" blip set from the tablet's Take Job button
local assignedATMs = {} -- [atmId] = coords, only the current unlocked ATM is interactable
local awaitingTurnIn = false -- true once all shift ATMs are repaired and player must return to NPC
local npcRouteBlip = nil

local function ClearShiftBlips()
    for id, blip in pairs(activeATMBlips) do
        RemoveBlip(blip)
    end
    activeATMBlips = {}
    assignedATMs = {}

    if npcRouteBlip then
        RemoveBlip(npcRouteBlip)
        npcRouteBlip = nil
    end
end

local function CreateATMBlip(coords, id, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.ActiveATMBlip.sprite)
    SetBlipColour(blip, Config.ActiveATMBlip.color)
    SetBlipScale(blip, Config.ActiveATMBlip.scale)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, Config.ActiveATMBlip.color)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('ATM Needs Service' .. (label and (' - ' .. label) or ''))
    EndTextCommandSetBlipName(blip)
    activeATMBlips[id] = blip
end

RegisterNetEvent('qb-atmtechnician:client:clearAllATMBlips', function()
    ClearShiftBlips()
    awaitingTurnIn = false

    if activeJobBlip then
        RemoveBlip(activeJobBlip)
        activeJobBlip = nil
    end
end)

-- Received on duty-on: reveals the current/next ATM. `resumed` is true when this
-- continues a shift you already made progress on before (left the game mid-shift, went
-- off duty, etc.) rather than a brand new set of Config.Shift.size ATMs.
RegisterNetEvent('qb-atmtechnician:client:shiftAssigned', function(atm, resumed)
    ClearShiftBlips()
    awaitingTurnIn = false

    if not atm then return end

    assignedATMs[atm.id] = atm.coords
    CreateATMBlip(atm.coords, atm.id, atm.label)

    if resumed then
        Functions.Notify(('Shift resumed: %s (%d/%d ATMs remaining)'):format(atm.label or 'ATM', atm.remaining, atm.size), 'success')
    else
        Functions.Notify(('Shift started: %s (%d/%d ATMs remaining)'):format(atm.label or 'ATM', atm.remaining, atm.size), 'success')
    end
end)

-- Received after each successful repair (except the last): unlocks the next ATM
RegisterNetEvent('qb-atmtechnician:client:shiftProgress', function(remaining, size, nextAtm)
    ClearShiftBlips()

    if nextAtm then
        assignedATMs[nextAtm.id] = nextAtm.coords
        CreateATMBlip(nextAtm.coords, nextAtm.id, nextAtm.label)
        Functions.Notify(Functions.Locale('shift_remaining', remaining, size) .. ' - Next: ' .. (nextAtm.label or 'ATM'), 'primary')
    else
        Functions.Notify(Functions.Locale('shift_remaining', remaining, size), 'primary')
    end
end)

-- Received once all shift ATMs are repaired: route the player back to the job NPC to turn in
RegisterNetEvent('qb-atmtechnician:client:shiftAllComplete', function(remaining, size)
    ClearShiftBlips()
    awaitingTurnIn = true

    local npcCoords = Config.JobCenter.coords
    npcRouteBlip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)
    SetBlipSprite(npcRouteBlip, Config.JobCenter.blip.sprite)
    SetBlipColour(npcRouteBlip, Config.JobCenter.blip.color)
    SetBlipScale(npcRouteBlip, Config.JobCenter.blip.scale)
    SetBlipAsShortRange(npcRouteBlip, false)
    SetBlipRoute(npcRouteBlip, true)
    SetBlipRouteColour(npcRouteBlip, Config.JobCenter.blip.color)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Return to Technician - Turn In Shift')
    EndTextCommandSetBlipName(npcRouteBlip)

    Functions.Notify(Functions.Locale('shift_all_complete'), 'success')
end)

-- Received on manual duty-off (before finishing the shift) or a completed turn-in
RegisterNetEvent('qb-atmtechnician:client:shiftCleared', function()
    ClearShiftBlips()
    awaitingTurnIn = false
end)

exports('IsAwaitingTurnIn', function() return awaitingTurnIn end)

-- Called from the tablet's "Take Job" button: picks the nearest ATM, drops a blip + waypoint on it
RegisterNetEvent('qb-atmtechnician:client:markJobLocation', function(coords)
    if activeJobBlip then
        RemoveBlip(activeJobBlip)
        activeJobBlip = nil
    end

    activeJobBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(activeJobBlip, Config.ActiveATMBlip.sprite)
    SetBlipColour(activeJobBlip, Config.ActiveATMBlip.color)
    SetBlipScale(activeJobBlip, Config.ActiveATMBlip.scale)
    SetBlipAsShortRange(activeJobBlip, false)
    SetBlipRoute(activeJobBlip, true)
    SetBlipRouteColour(activeJobBlip, Config.ActiveATMBlip.color)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Job: ATM Repair')
    EndTextCommandSetBlipName(activeJobBlip)

    SetNewWaypoint(coords.x, coords.y)
    Functions.Notify('Job location marked on your map', 'success')
end)

-- ATM target zones only exist while the player actually holds the job: they're created as
-- soon as the job is taken, and fully removed on job quit.
--
-- IMPORTANT DESIGN NOTE: every coord in Config.ATMLocations was manually walked to and
-- captured with F6 while standing at the REAL, default GTA V ATM prop (see config.lua
-- comments). Because of that we do NOT spawn any extra prop and do NOT hide/replace the
-- vanilla ATM anymore -- the real ATM just sits there exactly like it does for every other
-- player, and this script only bolts a "Repair" interaction onto that same spot for whoever
-- currently holds the job. Simpler, no streaming/hide races, and there's nothing to restore
-- on job quit besides removing the zone itself.
local atmZoneNames = {} -- [id] = qb-target zone name (for cleanup)
local atmWorldSpawned = false

local function CreateATMZone(id, coords, heading)
    local zoneName = 'atm_' .. id
    atmZoneNames[id] = zoneName

    exports['qb-target']:AddBoxZone(zoneName, vector3(coords.x, coords.y, coords.z), 1.0, 1.0, {
        name = zoneName,
        heading = heading,
        debugPoly = Config.Debug,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 1.5,
    }, {
        options = {
            {
                type = 'client',
                event = 'qb-atmtechnician:client:startRepair',
                icon = 'fas fa-screwdriver-wrench',
                label = 'Inspect / Repair ATM',
                canInteract = function()
                    return Functions.OnDuty() and not isRepairing and assignedATMs[id] ~= nil
                end,
                coords = coords,
                atmId = id,
            },
        },
        distance = Config.ATMInteractDistance,
    })
end

local function SpawnATMProps()
    if atmWorldSpawned then return end
    atmWorldSpawned = true

    for _, entry in ipairs(Config.ATMLocations) do
        local coords = entry.coords
        local id = Shared.GetATMId(coords)
        local heading = coords.w or 0.0

        CreateATMZone(id, coords, heading)
    end
end

local function RemoveATMProps()
    if not atmWorldSpawned then return end
    atmWorldSpawned = false

    for id, zoneName in pairs(atmZoneNames) do
        exports['qb-target']:RemoveZone(zoneName)
    end
    atmZoneNames = {}
end

exports('SpawnATMProps', SpawnATMProps)
exports('RemoveATMProps', RemoveATMProps)

-- CRITICAL: without this, restarting/updating the resource while a player holds the job
-- leaves every target zone orphaned (this script instance dies with its atmZoneNames
-- table, so nothing can ever reference/remove them again). The next time SpawnATMProps()
-- runs (player loaded, job re-applied, etc.) it would try to add a zone with the SAME
-- name again, which qb-target rejects/duplicates unpredictably.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    RemoveATMProps()
end)

-- Job taken -> ATMs spawn in the world. Job quit -> ATMs (and any leftover shift blips) removed.
RegisterNetEvent('qb-atmtechnician:client:jobStateChanged', function(hasJob)
    if hasJob then
        SpawnATMProps()
    else
        RemoveATMProps()
        ClearShiftBlips()
        awaitingTurnIn = false
    end
end)

-- Draw a visible marker at any currently-assigned ATM location the player is near
CreateThread(function()
    while true do
        local sleep = 1000
        local pCoords = GetEntityCoords(PlayerPedId())
        for id, coords in pairs(assignedATMs) do
            local dist = #(pCoords - vector3(coords.x, coords.y, coords.z))
            if dist < 15.0 then
                sleep = 0
                DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 0, 180, 255, 150, false, true, 2, false, nil, nil, false)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('qb-atmtechnician:client:startRepair', function(data)
    if isRepairing then return end
    if not Functions.OnDuty() then
        Functions.Notify(Functions.Locale('need_duty'), 'error')
        return
    end

    local coords = data.coords
    local atmId = data.atmId or Shared.GetATMId(coords)

    if busyATMs[atmId] then
        Functions.Notify(Functions.Locale('atm_busy'), 'error')
        return
    end

    QBCore.Functions.TriggerCallback('qb-atmtechnician:server:canRepairATM', function(allowed, reason)
        if not allowed then
            Functions.Notify(Functions.Locale(reason or 'atm_cooldown'), 'error')
            return
        end

        -- check tools -- re-checked fresh on every repair click, so if the player was missing
        -- tools last time, picks them up, and clicks repair again on the SAME atm, this passes
        -- as soon as all 6 required items are in their inventory
        QBCore.Functions.TriggerCallback('qb-atmtechnician:server:hasTools', function(hasTools, missing)
            if not hasTools then
                TriggerServerEvent('qb-atmtechnician:server:releaseRepairLock', atmId)

                if missing and #missing > 0 then
                    Functions.Notify(Functions.Locale('need_items_specific', table.concat(missing, ', ')), 'error')
                else
                    Functions.Notify(Functions.Locale('need_items'), 'error')
                end
                return
            end

            isRepairing = true
            busyATMs[atmId] = true

            Functions.Notify(Functions.Locale('atm_repairing'), 'primary')
            Animations.PlayRepair(function()
                TriggerEvent('qb-atmtechnician:client:startMinigame', atmId, coords)
            end)
        end)
    end, atmId)
end)

RegisterNetEvent('qb-atmtechnician:client:repairFinished', function(atmId, success)
    isRepairing = false
    busyATMs[atmId] = nil

    if success then
        Functions.Notify(Functions.Locale('atm_success'), 'success')
    else
        Functions.Notify(Functions.Locale('atm_fail'), 'error')
    end

    if activeJobBlip then
        RemoveBlip(activeJobBlip)
        activeJobBlip = nil
    end

    TriggerServerEvent('qb-atmtechnician:server:finishRepair', atmId, success)
end)

exports('IsRepairing', function() return isRepairing end)

exports('GetAssignedATMCoords', function()
    local list = {}
    for id, coords in pairs(assignedATMs) do
        list[#list + 1] = coords
    end
    return list
end)
