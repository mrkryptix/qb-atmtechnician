# qb-atmtechnician

QBCore ATM Technician Job — Repair, refill & maintain ATMs across the map. Includes duty system, job NPC, target interactions, job vehicle garage, skillcheck minigame, tablet NUI, rewards, police alerts, and full DB logging.

---

## 📦 Dependencies (install these FIRST, in this order)

1. **[qb-core](https://github.com/qbcore-framework/qb-core)** — the base framework.
2. **[oxmysql](https://github.com/overextended/oxmysql)** — database library used for all SQL queries.
3. **[qb-target](https://github.com/qbcore-framework/qb-target)** — interaction system (used for NPC, garage, and ATM zones).
4. **[PolyZone](https://github.com/mkafrin/PolyZone)** — required by qb-target for zone creation.
5. *(Optional but recommended)* **qb-clothing** — used to restore the player's real outfit after removing the uniform (`qb-clothing:client:loadPlayerSkin`). If you don't use qb-clothing, the uniform removal will fall back silently — you can wire your own clothing resource in `client/uniform.lua`.
6. *(Optional)* **qb-log** — for Discord webhook logging (`server/logs.lua` calls `qb-log:server:CreateLog`). If not installed, logs just print to console when `Config.Debug = true`.
7. *(Optional)* **qb-fuel / LegacyFuel** — for real fuel tracking in `client/vehicle_sync.lua`.
8. *(Optional)* **ps-dispatch / cd_dispatch / your dispatch script** — change `Config.Police.dispatchEvent` in `config.lua` to match your dispatch resource's client event name.

---

## 🛠 Installation Steps

1. Drop the `qb-atmtechnician` folder into your server's `resources` directory.
2. Import `sql/atmtechnician.sql` into your database (phpMyAdmin / HeidiSQL / any MySQL client).
3. Open **`qb-core/shared/jobs.lua`** and add the job (see snippet below).
4. Open **`qb-core/shared/items.lua`** and add the items (see snippet below).
5. Add ped/prop models used (`mp_m_waremech_01`, `prop_screwdriver_01`) — these are default GTA V models, no extra download needed.
6. *(Optional)* Add your own job vehicle stream files into `stream/vehicles/` and uniform clothing into `stream/uniforms/` if you want custom assets instead of the default `speedo` van and default ped components.
7. Add the following line to your **`server.cfg`**:
   ```
   ensure qb-core
   ensure oxmysql
   ensure PolyZone
   ensure qb-target
   ensure qb-atmtechnician
   ```
8. Adjust `config.lua` — especially `Config.ATMLocations` (add/remove ATM coords to match your map/MLOs), `Config.Garage`, and `Config.JobCenter` coordinates.
9. Restart your server / start the resource: `restart qb-atmtechnician`

---

## 📋 Add to `qb-core/shared/jobs.lua`

```lua
['atmtechnician'] = {
    label = 'ATM Technician',
    defaultDuty = false,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Trainee Technician', payment = 50 },
        ['1'] = { name = 'Technician', payment = 75 },
        ['2'] = { name = 'Senior Technician', payment = 100 },
        ['3'] = { name = 'Field Supervisor', payment = 125, isboss = true },
    },
},
```

---

## 🎒 Add to `qb-core/shared/items.lua`

```lua
['toolbox'] = { name = 'toolbox', label = 'toolbox', weight = 500, type = 'item', image = 'toolbox.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'toolbox' },

['tool_repair_kit'] = { name = 'tool_repair_kit', label = 'tool_repair_Kit', weight = 500, type = 'item', image = 'tool_repair_kit.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'tool_repair_Kit' },

['tool_screwdriver'] = { name = 'tool_screwdriver', label = 'tool_screwdriver', weight = 500, type = 'item', image = 'tool_screwdriver.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'tool_screwdriver' },

['boltcutter'] = { name = 'boltcutter', label = 'boltcutter', weight = 500, type = 'item', image = 'boltcutter.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'boltcutter' },

['radioscanner'] = { name = 'radioscanner', label = 'radioscanner', weight = 500, type = 'item', image = 'radioscanner.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'radioscanner' },

['provision_key_bank_safe'] = { name = 'provision_key_bank_safe', label = 'provision_key_bank_safe', weight = 500, type = 'item', image = 'provision_key_bank_safe.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'provision_key_bank_safe' },
['id_card'] = { name = 'id_card', label = 'id_card', weight = 500, type = 'item', image = 'id_card.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'id_card' },
['repairkit2'] = { name = 'repairkit2', label = 'repairkit2', weight = 500, type = 'item', image = 'repairkit2.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'repairkit2' },
```

Copy the item images from the `images/` folder in this resource into your inventory resource's image folder (e.g. `qb-inventory/html/images/`).

---

## ⚙️ Giving a player the job (in-game)

As admin:
```
/atmtechadmin [playerid] [grade]
```
Example: `/atmtechadmin 5 2` → sets player ID 5 as a Senior Technician.

Or via qb-core's built-in command:
```
/setjob [playerid] atmtechnician [grade]
```

---

## 🗂 File Overview

| File | Purpose |
|---|---|
| `config.lua` | All tunable settings — job center, garage, ATM coords, payouts, minigame, police |
| `shared.lua` | Shared helper functions used by both client & server |
| `client/npc.lua` | Spawns job center ped + blip |
| `client/target.lua` | qb-target zones for NPC / garage |
| `client/atm.lua` | ATM zones, repair flow trigger |
| `client/minigames.lua` | Directional key skillcheck minigame |
| `client/garage.lua` | Job vehicle spawn/store |
| `client/uniform.lua` | Puts on/removes job uniform |
| `client/tablet.lua` | Opens job tablet NUI |
| `server/callbacks.lua` | Duty toggle, tool checks, cooldown checks, tablet data |
| `server/jobs.lua` | Ties together payout, DB log, police alert on repair result |
| `server/rewards.lua` | Payout calculation |
| `server/police.lua` | Sends dispatch alert to on-duty LEO |
| `server/security.lua` | Rate limiting / anti-exploit checks |
| `sql/atmtechnician.sql` | Required database tables |

---

## 🔧 Customization Notes

- **ATM Locations**: `Config.ATMLocations` in `config.lua` only has a handful of default vanilla ATM coords — add more to match every ATM on your map (or the ones you want enabled).
- **Minigame**: swap in `ox_lib`'s skill check (`lib.skillCheck`) inside `client/minigames.lua` if you use ox_lib — the current version is a dependency-free native implementation.
- **Police dispatch**: update `Config.Police.dispatchEvent` to match your dispatch script's client event.
- **Uniform**: update `Config.Uniform` component IDs to match your server's clothing pack.

---

## ❗ Troubleshooting

- **NPC not showing / target not working** → make sure `qb-target` and `PolyZone` started *before* this resource in `server.cfg`.
- **Tools check always fails** → confirm you added `toolbox` and `tool_repair_kit` items to `qb-core/shared/items.lua` exactly as named in `Config.RequiredItems`.
- **SQL errors on start** → make sure `sql/atmtechnician.sql` was imported before starting the resource.
- **No payout received** → check `Player.Functions.AddMoney` — some older qb-core versions use `Player.Functions.AddMoney('bank', amount, reason)`, confirm your qb-core version matches.
