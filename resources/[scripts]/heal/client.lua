-- Register the event to heal the player
RegisterNetEvent('heal:playerHeal')
AddEventHandler('heal:playerHeal', function()
    local ped = PlayerPedId()

    -- Set health to maximum
    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    -- Clear blood effects
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)

    -- Optional: Feedback message (could also be handled via ESX.ShowNotification if preferred)
    -- In this implementation, the server already sends a notification.
end)
