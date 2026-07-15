Shared = {}

-- Shared helper: generate a unique ATM id from its coords (used as DB key)
function Shared.GetATMId(coords)
    return string.format('%.1f_%.1f_%.1f', coords.x, coords.y, coords.z)
end

-- Built once at resource start: [atmId] = label, so anything (recent job logs, tablet UI)
-- that only has the coords-derived id can still show a friendly location name.
Shared.ATMLabelByID = {}
for _, entry in ipairs(Config.ATMLocations) do
    Shared.ATMLabelByID[Shared.GetATMId(entry.coords)] = entry.label
end

-- Shared table of job grades (mirrors what you should add to qb-core/shared/jobs.lua)
-- job = 'atmtechnician'  -- IMPORTANT: this MUST have grades 0-4 defined in qb-core, or
-- Player.Functions.SetJob(Config.Job.name, grade) used by the XP/grade system will fail
-- to apply grades above whatever qb-core currently has configured for this job.
-- grades:
--   0 = Trainee Technician   (payment 50)
--   1 = Junior Technician    (payment 75)
--   2 = ATM Technician       (payment 100)
--   3 = Senior Technician    (payment 125)
--   4 = Chief ATM Engineer   (payment 150, isboss = true)
Shared.JobGradesReference = {
    [0] = { name = 'Trainee Technician', payment = 50 },
    [1] = { name = 'Junior Technician', payment = 75 },
    [2] = { name = 'ATM Technician', payment = 100 },
    [3] = { name = 'Senior Technician', payment = 125 },
    [4] = { name = 'Chief ATM Engineer', payment = 150, isboss = true },
}

-- Picks `n` unique random entries from `list` (or all of them if list is smaller than n)
function Shared.PickRandomN(list, n)
    local pool = {}
    for i, v in ipairs(list) do
        pool[i] = v
    end

    local picked = {}
    local count = math.min(n, #pool)
    for i = 1, count do
        local idx = math.random(1, #pool)
        picked[#picked + 1] = pool[idx]
        table.remove(pool, idx)
    end
    return picked
end

-- Converts whatever oxmysql hands back for a DATETIME column into a unix timestamp (seconds).
-- Different oxmysql / mysql2 versions return this differently depending on config:
--   * a 'YYYY-MM-DD HH:MM:SS' string (dateStrings enabled)
--   * an ISO string like 'YYYY-MM-DDTHH:MM:SS.000Z'
--   * a raw JS Date turned into a number: epoch MILLISECONDS (dateStrings disabled)
-- Returns nil (treated as "no cooldown on record") if the value can't be parsed, instead of erroring.
function Shared.MySQLTimeToUnix(value)
    if value == nil then return nil end

    if type(value) == 'number' then
        -- epoch ms vs epoch seconds: anything above this is almost certainly milliseconds
        if value > 9999999999 then
            return math.floor(value / 1000)
        end
        return math.floor(value)
    end

    if type(value) == 'string' then
        local y, mo, d, h, mi, s = value:match('(%d%d%d%d)%-(%d%d)%-(%d%d)[T ](%d%d):(%d%d):(%d%d)')
        if y then
            return os.time({
                year = tonumber(y), month = tonumber(mo), day = tonumber(d),
                hour = tonumber(h), min = tonumber(mi), sec = tonumber(s),
            })
        end
    end

    return nil
end
