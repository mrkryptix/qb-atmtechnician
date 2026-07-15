-- Client-side handling of police alert visuals (server actually triggers the dispatch)

RegisterNetEvent('qb-atmtechnician:client:policeAlertVisual', function()
    Functions.Notify(Functions.Locale('police_alerted'), 'error')
end)
