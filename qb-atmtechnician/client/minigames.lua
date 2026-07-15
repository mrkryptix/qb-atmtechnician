-- Simple native-UI skillcheck minigame (no external dependency needed)
-- Sequence of directional key presses shown on screen; player must press matching key in time

local minigameActive = false

local function ShowKeyPrompt(key, timeLeft)
    local keyMap = {
        w = 'W (UP)', a = 'A (LEFT)', s = 'S (DOWN)', d = 'D (RIGHT)'
    }
    SetTextFont(4)
    SetTextScale(0.6, 0.6)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(('~y~PRESS: ~w~%s   ~r~%.1fs'):format(keyMap[key] or key, timeLeft))
    DrawText(0.5, 0.80)
end

local keyControls = {
    w = 32, -- INPUT_MOVE_UP_ONLY / W
    a = 34, -- A
    s = 33, -- S
    d = 35, -- D
}

--- Runs one stage of the skillcheck. Returns true/false via callback
local function RunStage(cb)
    local keys = Config.Minigame.keys
    local key = keys[math.random(#keys)]
    local timeLimit = Config.Minigame.timeout / 1000.0
    local start = GetGameTimer()
    local success = false

    CreateThread(function()
        while true do
            local elapsed = (GetGameTimer() - start) / 1000.0
            local timeLeft = timeLimit - elapsed
            if timeLeft <= 0 then
                break
            end

            ShowKeyPrompt(key, timeLeft)
            DisableControlAction(0, keyControls[key], true)

            if IsDisabledControlJustPressed(0, keyControls[key]) then
                success = true
                break
            end

            -- fail if a wrong key among w/a/s/d is pressed
            for k, control in pairs(keyControls) do
                if k ~= key and IsDisabledControlJustPressed(0, control) then
                    success = false
                    cb(false)
                    return
                end
            end

            Wait(0)
        end
        cb(success)
    end)
end

RegisterNetEvent('qb-atmtechnician:client:startMinigame', function(atmId, coords)
    if minigameActive then return end
    minigameActive = true

    local stages = Config.Minigame.difficulty
    local currentStage = 1
    local overallSuccess = true

    local function nextStage()
        if currentStage > #stages then
            minigameActive = false
            TriggerEvent('qb-atmtechnician:client:repairFinished', atmId, overallSuccess)
            return
        end

        RunStage(function(success)
            if not success then
                overallSuccess = false
                minigameActive = false
                TriggerEvent('qb-atmtechnician:client:repairFinished', atmId, false)
                return
            end
            currentStage = currentStage + 1
            nextStage()
        end)
    end

    nextStage()
end)

exports('IsMinigameActive', function() return minigameActive end)
