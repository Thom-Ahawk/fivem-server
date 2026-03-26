local cooldowns = {}

-- Initialize ESX
ESX = exports["es_extended"]:getSharedObject()

-- Register the /heal command
ESX.RegisterCommand('heal', 'user', function(xPlayer, args, showError)
    local source = xPlayer.source
    local currentTime = os.time()

    -- Check if player is on cooldown
    if cooldowns[source] and (currentTime - cooldowns[source]) < 60 then
        local remainingTime = 60 - (currentTime - cooldowns[source])
        xPlayer.showNotification("You must wait " .. remainingTime .. " seconds before using /heal again.")
        return
    end

    -- Update cooldown
    cooldowns[source] = currentTime

    -- Trigger client event to heal the player
    TriggerClientEvent('heal:playerHeal', source)

    xPlayer.showNotification("You have been healed!")
end, false, {help = "Heal yourself", arguments = {}})

-- Cleanup cooldowns when player drops
AddEventHandler('playerDropped', function(reason)
    local source = source
    if cooldowns[source] then
        cooldowns[source] = nil
    end
end)
