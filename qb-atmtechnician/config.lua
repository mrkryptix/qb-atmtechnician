Config = {}

Config.Debug = false
Config.Locale = 'en' -- 'en' or 'ta'

-------------------------------------------------
-- JOB SETTINGS
-------------------------------------------------
Config.Job = {
    name = 'atmtechnician',       -- must match qb-core job name in qb-core/shared/jobs.lua
    onDutyBlipColor = 2,
    payPerATM = { min = 80, max = 150 },
    payPerJewelry = { min = 0, max = 0 }, -- not used, placeholder
    requireDuty = true,
    minGrade = 0, -- minimum job grade to start work
    maxSlots = 0, -- 0 = unlimited, set a number to cap how many players can hold this job at once
}

-------------------------------------------------
-- NPC JOB CENTER (where players clock in/out & get job vehicle)
-------------------------------------------------
Config.JobCenter = {
    coords = vector4(-1221.08, -329.16, 37.56, 21.95),
    pedModel = 'mp_m_waremech_01',
    blip = {
        sprite = 478,
        color = 2,
        scale = 0.8,
        label = 'ATM Technician HQ',
    },
}

-------------------------------------------------
-- GARAGE (spawn / store job vehicle)
-------------------------------------------------
Config.Garage = {
    spawnCoords = vector4(-1204.91, -372.13, 37.29, 201.72),
    parkCoords  = vector4(-1204.91, -372.13, 37.29, 201.72),
    vehicle = 'speedo', -- job van model
    plateprefix = 'ATM',
}

-------------------------------------------------
-- ATM REPAIR LOCATIONS
-- vector4 = x, y, z, heading -- these coords were walked to and captured standing
-- at the REAL, default GTA V vanilla ATM prop, so no custom prop is spawned here --
-- client/atm.lua just bolts a qb-target interaction zone onto the existing map ATM.
-- 5 of these 20 are picked at random for each shift (see Config.Shift.size below).
--
-- NOTE: the 8 labels marked "(confirm name)" are locations that didn't match any of
-- the old 15 entries, so the label is a placeholder -- rename to the real landmark
-- once you've confirmed it in-game (this is purely cosmetic, shown in blips/tablet/logs).
-------------------------------------------------
Config.ATMLocations = {
    { coords = vector4(-3044.07, 594.6, 7.74, 203.66),     label = 'Del Perro Highway Store Outside' },
    { coords = vector4(-97.21, 6455.5, 31.47, 54.58),      label = 'Paleto Bank Outside' },
    { coords = vector4(-95.5, 6457.2, 31.46, 48.04),       label = 'Paleto Bank Outside 2' },
    { coords = vector4(1701.28, 6426.61, 32.76, 78.58),    label = 'Rockford Bank Outside' },
    { coords = vector4(1172.63, 2702.57, 38.17, 6.61),     label = 'Route 68 Fleeca Outside' },
    { coords = vector4(1171.54, 2702.53, 38.18, 18.19),    label = 'Route 68 Fleeca Outside 2' },
    { coords = vector4(-2959.23, 487.88, 15.46, 186.61),   label = 'Great Ocean Bank Outside' },
    { coords = vector4(-2956.91, 487.7, 15.46, 187.66),    label = 'Great Ocean Bank Outside 2' },
    { coords = vector4(-3241.19, 997.46, 12.55, 41.42),    label = 'ATM Site 9 (confirm name)' },
    { coords = vector4(-2072.36, -317.21, 13.32, 264.68),  label = 'LTD Store Outside' },
    { coords = vector4(-1409.74, -100.46, 52.39, 117.91),  label = 'Pacific Bank Front' },
    { coords = vector4(-1410.24, -98.79, 52.43, 109.78),   label = 'Pacific Bank Front 2' },
    { coords = vector4(-1570.19, -546.64, 34.96, 209.97),  label = 'Rockford Plaza' },
    { coords = vector4(-1009.86, -2746.33, 13.76, 146.87), label = 'LSIA Terminal Entrance' },
    { coords = vector4(1077.78, -776.44, 58.24, 184.55),   label = 'Mirror Park Shopping Area' },
    { coords = vector4(1166.91, -456.15, 66.8, 355.42),    label = 'Mirror Park Bank' },
    { coords = vector4(296.38, -894.17, 29.23, 252.1),     label = 'Pillbox Bank North' },
    { coords = vector4(295.7, -896.08, 29.22, 257.77),     label = 'Pillbox Bank South' },
    { coords = vector4(5.22, -919.81, 29.56, 246.55),      label = 'Downtown Legion ATM' },
    { coords = vector4(-660.7, -854.07, 24.49, 178.51),    label = 'Alta Street Financial District' },
}

Config.ATMInteractDistance = 1.5
Config.ATMCooldown = 15 -- minutes before same ATM can be repaired again (server tracked)
Config.MaxSimultaneousATMs = 3 -- how many ATMs can be "active" (blipped) at once per technician

-------------------------------------------------
-- SHIFT SYSTEM (random ATMs per duty session)
-------------------------------------------------
Config.Shift = {
    size = 5,             -- how many random ATMs are assigned per shift
    cooldownMinutes = 30, -- cooldown before the player can go on duty again after finishing a shift
    quitCooldownMinutes = 30, -- real-world cooldown before the player can re-apply for the job after quitting
}

-- Flat payout per successful ATM repair -- DEPRECATED, kept only as a fallback if a
-- player's grade can't be resolved for some reason. Real payout now comes from Config.Grades.
Config.FlatPayout = 1000

-------------------------------------------------
-- GRADE / XP SYSTEM
-------------------------------------------------
-- xpNeeded = total XP required to REACH this grade (the "current" number in the progress bar)
-- nextXp   = total XP required to reach the NEXT grade (the "target" number in the progress bar)
--            for the last grade this is just an informational cap, it does not unlock anything further
-- payout   = $ paid per successful ATM repair while at this grade
-- shiftXP  = XP awarded once a full shift (Config.Shift.size ATMs) is completed and turned in at this grade
Config.Grades = {
    [0] = { name = 'Trainee Technician', xpNeeded = 0,      nextXp = 50000,  payout = 4500,  shiftXP = 2500 },
    [1] = { name = 'Junior Technician',  xpNeeded = 50000,  nextXp = 150000, payout = 9500,  shiftXP = 3500 },
    [2] = { name = 'ATM Technician',     xpNeeded = 150000, nextXp = 275000, payout = 19000, shiftXP = 4500 },
    [3] = { name = 'Senior Technician',  xpNeeded = 275000, nextXp = 400000, payout = 25000, shiftXP = 5500 },
    [4] = { name = 'Chief ATM Engineer', xpNeeded = 400000, nextXp = 500000, payout = 40000, shiftXP = 6500 },
}
Config.MaxGrade = 4 -- highest key in Config.Grades -- grade never goes above this

-------------------------------------------------
-- ID CARD (auto given on duty-on, auto removed on duty-off)
-------------------------------------------------
Config.IDCard = {
    item = 'id_card', -- must be added to qb-core/shared/items.lua
    label = 'ATM Technician',
}

-------------------------------------------------
-- VAN REPAIR (fixes job vehicle damage using an item bought from the NPC shop)
-------------------------------------------------
Config.VanRepair = {
    item = 'repairkit2', -- must be added to qb-core/shared/items.lua + Config.ShopItems
}

-------------------------------------------------
-- TOOL SHOP (buy from the job NPC, paid from bank)
-------------------------------------------------
Config.ShopItems = {
    { item = 'toolbox',                  label = 'ATM Toolbox',        price = 500 },
    { item = 'tool_repair_kit',          label = 'Repair Tablet',      price = 750 },
    { item = 'tool_screwdriver',         label = 'Screwdriver',        price = 100 },
    { item = 'boltcutter',               label = 'Wire Cutter',        price = 100 },
    { item = 'radioscanner',             label = 'Diagnostic Scanner', price = 300 },
    { item = 'provision_key_bank_safe',  label = 'ATM Masterkey',      price = 1500 },
    { item = 'repairkit2',               label = 'Van Repair Kit',     price = 400 },
}

-------------------------------------------------
-- REQUIRED TOOLS (ALL of these must be in inventory to repair an ATM)
-------------------------------------------------
Config.RequiredItems = {
    'toolbox',
    'tool_repair_kit',
    'tool_screwdriver',
    'boltcutter',
    'radioscanner',
    'provision_key_bank_safe',
}

Config.ConsumableChance = { -- chance tool takes "wear" damage per job (server side, cosmetic/future use)
    tool_screwdriver = 10,
    boltcutter = 10,
}

-------------------------------------------------
-- UNIFORM
-------------------------------------------------
Config.Uniform = {
    male = {
        ['tshirt_1'] = 15, ['tshirt_2'] = 0,
        ['torso_1'] = 248, ['torso_2'] = 6,
        ['arms'] = 0,
        ['pants_1'] = 34, ['pants_2'] = 0,
        ['shoes_1'] = 12, ['shoes_2'] = 6,
        ['helmet_1'] = 142, ['helmet_2'] = 0,
    },
    female = {
        ['tshirt_1'] = 1, ['tshirt_2'] = 0,
        ['torso_1'] = 66, ['torso_2'] = 0,
        ['arms'] = 0,
        ['pants_1'] = 6, ['pants_2'] = 0,
        ['shoes_1'] = 6, ['shoes_2'] = 2,
        ['helmet_1'] = -1, ['helmet_2'] = 0, -- no hat for the female uniform
    },
}

-------------------------------------------------
-- MINIGAME SETTINGS
-------------------------------------------------
Config.Minigame = {
    type = 'skillcheck', -- 'skillcheck' or 'circle'
    difficulty = { 'easy', 'easy', 'medium', 'hard' }, -- sequence stages
    keys = { 'w', 'a', 's', 'd' },
    timeout = 15000, -- ms
    failPenalty = { breakTool = 5 }, -- 5% chance to break a tool on fail
}

-------------------------------------------------
-- POLICE ALERT SETTINGS
-------------------------------------------------
Config.Police = {
    alertOnMasterkeyUse = false, -- alert if using provision_key_bank_safe (illegal bypass) - true for robbery variant
    dispatchEvent = 'police:client:policeAlert', -- change if using ps-dispatch / cd_dispatch etc.
    alertMessage = 'Suspicious activity reported near an ATM',
}
-- (Repair failure no longer alerts police -- only Config.Police.alertOnMasterkeyUse can trigger an alert now)

-------------------------------------------------
-- ANIMATIONS
-------------------------------------------------
Config.Animations = {
    repair = {
        dict = 'mini@repair',
        anim = 'fixing_a_ped',
        flag = 1,
        duration = 20000, -- 20 seconds (repairing time) -- minigame should pop up within 2s after this ends
    },
    tablet = {
        dict = 'amb@world_human_seat_wall_tablet@female@base',
        anim = 'base',
        flag = 49,
    },
}

-------------------------------------------------
-- BLIP SETTINGS FOR ACTIVE ATM WORK
-------------------------------------------------
Config.ActiveATMBlip = {
    sprite = 500,
    color = 3,
    scale = 0.7,
}
