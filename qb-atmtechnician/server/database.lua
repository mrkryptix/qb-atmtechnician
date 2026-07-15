
QBCore = exports['qb-core']:GetCoreObject()-- Handles DB reads/writes for ATM cooldowns and job stats

Database = {}

function Database.GetATMCooldown(atmId, cb)
    exports.oxmysql:scalar('SELECT last_repaired FROM atmtechnician_cooldowns WHERE atm_id = ?', { atmId }, function(result)
        cb(result)
    end)
end

function Database.SetATMRepaired(atmId)
    exports.oxmysql:execute([[
        INSERT INTO atmtechnician_cooldowns (atm_id, last_repaired)
        VALUES (?, NOW())
        ON DUPLICATE KEY UPDATE last_repaired = NOW()
    ]], { atmId })
end

function Database.LogJob(citizenid, atmId, success, payout)
    exports.oxmysql:insert([[
        INSERT INTO atmtechnician_logs (citizenid, atm_id, success, payout, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { citizenid, atmId, success and 1 or 0, payout })
end

function Database.GetPlayerStats(citizenid, cb)
    exports.oxmysql:execute([[
        SELECT
            COUNT(*) as total_jobs,
            SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_jobs,
            SUM(payout) as total_earned
        FROM atmtechnician_logs
        WHERE citizenid = ?
    ]], { citizenid }, function(result)
        cb(result and result[1] or { total_jobs = 0, successful_jobs = 0, total_earned = 0 })
    end)
end

function Database.GetRecentJobs(citizenid, limit, cb)
    exports.oxmysql:execute([[
        SELECT atm_id, success, payout, created_at
        FROM atmtechnician_logs
        WHERE citizenid = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], { citizenid, limit or 10 }, function(result)
        cb(result or {})
    end)
end

function Database.GetPlayerGrade(citizenid, cb)
    exports.oxmysql:execute('SELECT xp, grade FROM atmtechnician_grades WHERE citizenid = ?', { citizenid }, function(result)
        if result and result[1] then
            cb(result[1])
        else
            exports.oxmysql:insert('INSERT INTO atmtechnician_grades (citizenid, xp, grade) VALUES (?, 0, 0)', { citizenid })
            cb({ xp = 0, grade = 0 })
        end
    end)
end

function Database.SavePlayerGrade(citizenid, xp, grade)
    exports.oxmysql:execute([[
        INSERT INTO atmtechnician_grades (citizenid, xp, grade)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE xp = ?, grade = ?
    ]], { citizenid, xp, grade, xp, grade })
end
