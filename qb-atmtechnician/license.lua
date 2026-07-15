_G.LICENSE_VERIFIED = false

local LICENSE_SERVER_URL = "https://license-console.onrender.com"
local PRODUCT_NAME = "qb-atmtechnician"
local RECHECK_INTERVAL_MINUTES = 30

local resource = GetCurrentResourceName()

local function stop(reason)
    _G.LICENSE_VERIFIED = false -- flip immediately, before StopResource even takes effect
    print("^1[LICENSE] " .. reason .. "^0")
    StopResource(resource)
end

local function verify(cb)
    PerformHttpRequest(LICENSE_SERVER_URL .. "/api/license/verify", function(code, body)
        if code ~= 200 then
            cb(false)
            return
        end

        local ok, data = pcall(json.decode, body)
        cb(ok and data and data.valid == true)
    end, "POST", json.encode({
        license_key = GetConvar("atm_license_key", ""),
        cfx_license = GetConvar("sv_licenseKey", ""),
        product = PRODUCT_NAME
    }), {
        ["Content-Type"] = "application/json"
    })
end

CreateThread(function()
    -- IMPORTANT: this thread runs before any other server_script's top-level code
    -- gets a chance to register callbacks/events, because it's first in fxmanifest.lua
    -- and we do NOT yield with an artificial Wait() here -- every tick we spend
    -- idling is a tick where the rest of the resource could already be loading.
    verify(function(ok)
        if ok then
            _G.LICENSE_VERIFIED = true
            print("^2[LICENSE] Verified^0")
        else
            stop("License Invalid")
        end
    end)

    while true do
        Wait(RECHECK_INTERVAL_MINUTES * 60 * 1000)
        verify(function(ok)
            if ok then
                _G.LICENSE_VERIFIED = true
                print("^2[LICENSE] Re-verified^0")
            else
                stop("License Invalid (recheck)")
            end
        end)
    end
end)
