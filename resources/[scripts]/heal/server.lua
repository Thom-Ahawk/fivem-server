local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}

-- Register the /heal command
QBCore.Commands.Add('heal', 'Heal yourself', {}, false, function(source, args)
    local currentTime = os.time()

    -- Check if player is on cooldown
    if cooldowns[source] and (currentTime - cooldowns[source]) < 60 then
        local remainingTime = 60 - (currentTime - cooldowns[source])
        TriggerClientEvent('QBCore:Notify', source, "You must wait " .. remainingTime .. " seconds before using /heal again.", "error")
        return
    end

    -- Update cooldown
    cooldowns[source] = currentTime

    -- Trigger client event to heal the player
    TriggerClientEvent('heal:playerHeal', source)

    TriggerClientEvent('QBCore:Notify', source, "You have been healed!", "success")
end, 'user')

-- Cleanup cooldowns when player drops
AddEventHandler('playerDropped', function(reason)
    local source = source
    if cooldowns[source] then
        cooldowns[source] = nil
    end
end)
