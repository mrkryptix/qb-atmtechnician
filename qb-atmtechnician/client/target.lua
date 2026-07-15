-- Sets up qb-target zones for NPC, garage and ATMs

CreateThread(function()
    -- Wait for NPC to spawn
    local npc = nil
    while not npc do
        npc = exports['qb-atmtechnician']:GetJobNPC()
        Wait(200)
    end

    exports['qb-target']:AddTargetEntity(npc, {
        options = {
            {
                type = 'client',
                event = 'qb-atmtechnician:client:applyJob',
                icon = 'fas fa-file-signature',
                label = 'Apply for ATM Technician Job',
                canInteract = function()
                    return not Functions.HasJob()
                end,
            },
            {
                type = 'client',
                event = 'qb-atmtechnician:client:quitJob',
                icon = 'fas fa-right-from-bracket',
                label = 'Quit ATM Technician Job',
                canInteract = function()
                    return Functions.HasJob() and not Functions.OnDuty()
                end,
            },
            {
                type = 'client',
                event = 'qb-atmtechnician:client:toggleDuty',
                icon = 'fas fa-toolbox',
                label = 'Clock In / Out (ATM Technician)',
                canInteract = function()
                    return Functions.HasJob()
                end,
            },
            {
                type = 'client',
                event = 'qb-atmtechnician:client:openTablet',
                icon = 'fas fa-tablet-alt',
                label = 'Open Job Tablet / Tool Shop',
                canInteract = function()
                    return Functions.HasJob()
                end,
            },
            {
                type = 'client',
                event = 'qb-atmtechnician:client:turnInShift',
                icon = 'fas fa-clipboard-check',
                label = 'Turn In Completed Shift',
                canInteract = function()
                    return Functions.HasJob() and exports['qb-atmtechnician']:IsAwaitingTurnIn()
                end,
            },
        },
        distance = 2.5,
    })

    -- Garage box zone
    exports['qb-target']:AddBoxZone('atmtech_garage', vector3(Config.Garage.spawnCoords.x, Config.Garage.spawnCoords.y, Config.Garage.spawnCoords.z), 2.0, 2.0, {
        name = 'atmtech_garage',
        heading = Config.Garage.spawnCoords.w,
        debugPoly = Config.Debug,
        minZ = Config.Garage.spawnCoords.z - 1.0,
        maxZ = Config.Garage.spawnCoords.z + 1.5,
    }, {
        options = {
            {
                type = 'client',
                event = 'qb-atmtechnician:client:takeVehicle',
                icon = 'fas fa-car',
                label = 'Take Job Vehicle',
                canInteract = function() return Functions.OnDuty() end,
            },
            {
                type = 'client',
                event = 'qb-atmtechnician:client:storeVehicle',
                icon = 'fas fa-warehouse',
                label = 'Store Job Vehicle',
                canInteract = function() return Functions.OnDuty() end,
            },
        },
        distance = 2.5,
    })
end)

-- ATM zones are added dynamically in atm.lua (since there can be many, we use box zones per location)
