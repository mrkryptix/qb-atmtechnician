-- Handles putting on the job uniform on duty-on, and restoring the EXACT outfit
-- the player was wearing before, on duty-off / job quit. Self-contained (doesn't
-- depend on qb-clothing having a saved skin).

local wearingUniform = false
local skinBeforeUniform = nil

-- components we actually touch when putting on the uniform (see Config.Uniform)
local COMPONENTS = { 8, 11, 3, 4, 6 } -- undershirt, torso, arms, pants, shoes
local PROPS = { 0 } -- helmet/hat prop

local function CaptureSkin()
    local ped = PlayerPedId()
    local snapshot = { components = {}, props = {} }

    for _, compId in ipairs(COMPONENTS) do
        snapshot.components[compId] = {
            drawable = GetPedDrawableVariation(ped, compId),
            texture = GetPedTextureVariation(ped, compId),
        }
    end

    for _, propId in ipairs(PROPS) do
        snapshot.props[propId] = {
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId),
        }
    end

    return snapshot
end

local function ApplySkin(snapshot)
    if not snapshot then return end
    local ped = PlayerPedId()

    for compId, data in pairs(snapshot.components) do
        SetPedComponentVariation(ped, compId, data.drawable, data.texture, 0)
    end

    for propId, data in pairs(snapshot.props) do
        if data.drawable and data.drawable ~= -1 then
            SetPedPropIndex(ped, propId, data.drawable, data.texture, true)
        else
            ClearPedProp(ped, propId)
        end
    end
end

local function SetUniform()
    if not skinBeforeUniform then
        skinBeforeUniform = CaptureSkin()
    end

    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local gender = PlayerData.charinfo and PlayerData.charinfo.gender == 1 and 'female' or 'male'
    local outfit = Config.Uniform[gender]

    SetPedComponentVariation(ped, 8, outfit.tshirt_1, outfit.tshirt_2, 0)  -- undershirt
    SetPedComponentVariation(ped, 11, outfit.torso_1, outfit.torso_2, 0)  -- torso/jacket
    SetPedComponentVariation(ped, 3, outfit.arms, 0, 0)                  -- arms
    SetPedComponentVariation(ped, 4, outfit.pants_1, outfit.pants_2, 0)  -- pants
    SetPedComponentVariation(ped, 6, outfit.shoes_1, outfit.shoes_2, 0)  -- shoes
    if outfit.helmet_1 and outfit.helmet_1 ~= -1 then
        SetPedPropIndex(ped, 0, outfit.helmet_1, outfit.helmet_2, true)
    end

    wearingUniform = true
end

local function RemoveUniform()
    if skinBeforeUniform then
        ApplySkin(skinBeforeUniform)
        skinBeforeUniform = nil
    end
    wearingUniform = false
end

RegisterNetEvent('qb-atmtechnician:client:setUniform', function(state)
    if state then
        SetUniform()
    else
        RemoveUniform()
    end
end)

exports('IsWearingUniform', function()
    return wearingUniform
end)
