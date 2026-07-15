QBCore = exports['qb-core']:GetCoreObject()

Functions = {}

--- Load a model safely
function Functions.LoadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    return hash
end

--- Load animation dict safely
function Functions.LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
end

--- Notify wrapper (uses qb-core notify)
function Functions.Notify(msg, type, duration)
    QBCore.Functions.Notify(msg, type or 'primary', duration or 5000)
end

--- Get locale string
function Functions.Locale(key, ...)
    local str = Locales[Config.Locale] and Locales[Config.Locale][key]
    if not str then return key end
    if ... then
        return string.format(str, ...)
    end
    return str
end

--- Distance check helper
function Functions.GetClosest(coordsList, playerCoords)
    local closest, closestDist = nil, math.huge
    for i, c in ipairs(coordsList) do
        local dist = #(playerCoords - vector3(c.x, c.y, c.z))
        if dist < closestDist then
            closest = c
            closestDist = dist
        end
    end
    return closest, closestDist
end

--- Check if player has required job
function Functions.HasJob()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData.job and PlayerData.job.name == Config.Job.name
end

--- Check if player is on duty for this job
function Functions.OnDuty()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData.job and PlayerData.job.name == Config.Job.name and PlayerData.job.onduty
end
