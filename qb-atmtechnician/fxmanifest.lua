fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ATM Technician Job '
author 'Delipkumar Developer'
description 'QBCore ATM Technician Job - Repair, Refill & Maintain ATMs'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/ta.lua',
    'config.lua',
    'shared.lua',
}

client_scripts {
    'client/functions.lua',
    'client/animations.lua',
    'client/npc.lua',
    'client/duty.lua',
    'client/uniform.lua',
    'client/garage.lua',
    'client/target.lua',
    'client/atm.lua',
    'client/minigames.lua',
    'client/vehicle_sync.lua',
    'client/tablet.lua',
    'client/police.lua',
    'client/main.lua',
}

server_scripts {
    'license.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
    'server/grades.lua',
    'server/items.lua',
    'server/shift.lua',
    'server/idcard.lua',
    'server/callbacks.lua',
    'server/security.lua',
    'server/logs.lua',
    'server/rewards.lua',
    'server/garage.lua',
    'server/vehicle_sync.lua',
    'server/police.lua',
    'server/jobs.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/*.png',
    'html/sounds/*.ogg',
}

dependencies {
    'qb-core',
    'oxmysql',
    'qb-target',
    'PolyZone',
}

escrow_ignore {
    'config.lua',
    'shared.lua',
    'client/*.lua',
    'server/*.lua',
    'html/*.html',
    'html/*.css',
    'html/*.js',
    'locales/*.lua',
}
