

QBCore = exports['qb-core']:GetCoreObject()-- Auto-gives an ATM Technician ID card to inventory on duty-on, removes it on duty-off.
-- The card's metadata (info table) carries the character's name, age, gender and job title,
-- which qb-inventory shows in the item tooltip automatically.

IDCard = {}

local function calculateAge(birthdate)
    -- QBCore charinfo.birthdate is usually 'YYYY-MM-DD'
    if not birthdate then return 0 end

    local year = tonumber(string.match(birthdate, '^(%d+)'))
    if not year then return 0 end

    local currentYear = tonumber(os.date('%Y'))
    return math.max(currentYear - year, 0)
end

local function genderLabel(gender)
    if gender == 0 or tostring(gender):lower() == 'male' or tostring(gender):lower() == 'm' then
        return 'Male'
    end
    return 'Female'
end

function IDCard.Give(Player)
    if not Player then return end

    local charinfo = Player.PlayerData.charinfo

    -- clear out any stray duplicate first (safety, e.g. leftover from a crash)
    IDCard.Remove(Player)

    local info = {
        name = ('%s %s'):format(charinfo.firstname, charinfo.lastname),
        age = calculateAge(charinfo.birthdate),
        gender = genderLabel(charinfo.gender),
        job = Config.IDCard.label,
        issued = os.date('%d/%m/%Y'),
    }

    Player.Functions.AddItem(Config.IDCard.item, 1, false, info)
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[Config.IDCard.item], 'add')
end

function IDCard.Remove(Player)
    if not Player then return end

    -- remove every copy just in case more than one ever ended up in inventory
    for i = 1, 5 do
        local item = Player.Functions.GetItemByName(Config.IDCard.item)
        if not item then break end
        Player.Functions.RemoveItem(Config.IDCard.item, 1, item.slot)
    end
end
