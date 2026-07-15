-- Handles playing / stopping repair & tablet animations

Animations = {}

function Animations.PlayRepair(cb)
    local ped = PlayerPedId()
    local cfg = Config.Animations.repair
    Functions.LoadAnimDict(cfg.dict)
    TaskPlayAnim(ped, cfg.dict, cfg.anim, 8.0, -8.0, cfg.duration, cfg.flag, 0, false, false, false)

    -- attach a prop (screwdriver) to hand for visual flair
    local propModel = Functions.LoadModel(`prop_screwdriver_01`)
    local bone = GetPedBoneIndex(ped, 28422)
    local prop = CreateObject(propModel, GetEntityCoords(ped), true, true, true)
    AttachEntityToEntity(prop, ped, bone, 0.12, 0.02, 0.0, -80.0, 0.0, 0.0, true, true, false, true, 1, true)

    CreateThread(function()
        Wait(cfg.duration)
        ClearPedTasks(ped)
        DeleteObject(prop)
        SetModelAsNoLongerNeeded(propModel)
        if cb then cb() end
    end)
end

function Animations.PlayTablet(duration, cb)
    local ped = PlayerPedId()
    local cfg = Config.Animations.tablet
    Functions.LoadAnimDict(cfg.dict)
    TaskPlayAnim(ped, cfg.dict, cfg.anim, 8.0, -8.0, duration or 3000, cfg.flag, 0, false, false, false)
    CreateThread(function()
        Wait(duration or 3000)
        ClearPedTasks(ped)
        if cb then cb() end
    end)
end

