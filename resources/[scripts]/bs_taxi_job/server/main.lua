local ESX = exports['es_extended']:getSharedObject()

local FleetTable = 'bs_taxi_fleet'
local TaxiGarageName = 'taxi'

local function normalizeStored(value)
    if value == true then return 1 end
    if value == false or value == nil then return 0 end
    if type(value) == 'string' then
        local lowered = string.lower(value)
        if lowered == 'true' then return 1 end
        if lowered == 'false' then return 0 end
    end
    return tonumber(value) or 0
end

local function isTaxi(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName, xPlayer
end

local function isBoss(xPlayer)
    if not xPlayer then return false end
    return xPlayer.job.grade_name == Config.BossGradeName or xPlayer.job.grade >= 3
end

local function formatVehicleRow(row)
    local storedValue = normalizeStored(row.stored)
    local remaining = math.floor(((row.engine_health + row.body_health) / 2.0) / 10.0)
    return {
        id = row.id,
        model = row.model,
        plate = row.plate,
        stored = storedValue == 1,
        fuel = math.floor(row.fuel + 0.5),
        engine = math.floor(row.engine_health + 0.5),
        body = math.floor(row.body_health + 0.5),
        remaining = remaining < 0 and 0 or remaining
    }
end

ESX.RegisterServerCallback('bs_taxi:server:getFleet', function(source, cb)
    local isInTaxi = select(1, isTaxi(source))
    if not isInTaxi then
        cb({ ok = false, message = 'Tu n\'es pas taxi.' })
        return
    end

    local rows = MySQL.query.await(
        'SELECT id, model, plate, fuel, engine_health, body_health, stored FROM bs_taxi_fleet ORDER BY id ASC',
        {}
    )

    local list = {}
    if rows then
        for _, row in ipairs(rows) do
            list[#list + 1] = formatVehicleRow(row)
        end
    end

    cb({ ok = true, vehicles = list, price = Config.VehiclePrice, uniqueModel = Config.UniqueGarageVehicle })
end)

RegisterNetEvent('bs_taxi:server:buyUniqueVehicle', function()
    local src = source
    local ok, xPlayer = isTaxi(src)

    if not ok then
        xPlayer.showNotification('Tu n\'es pas taxi.', 'error')
        return
    end

    if not isBoss(xPlayer) then
        xPlayer.showNotification('Seul le patron peut acheter.', 'error')
        return
    end

    local exists = MySQL.scalar.await('SELECT COUNT(1) FROM bs_taxi_fleet WHERE model = ?', { Config.UniqueGarageVehicle })
    if exists and exists > 0 then
        xPlayer.showNotification('Le véhicule unique est déjà acheté.', 'error')
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money
    if bankMoney < Config.VehiclePrice then
        xPlayer.showNotification('Fonds insuffisants en banque.', 'error')
        return
    end

    xPlayer.removeAccountMoney('bank', Config.VehiclePrice)

    local plate = ('TAXI%s'):format(math.random(111, 999))

    MySQL.insert.await(
        'INSERT INTO bs_taxi_fleet (model, plate, fuel, engine_health, body_health, stored) VALUES (?, ?, ?, ?, ?, 1)',
        { Config.UniqueGarageVehicle, plate, 100, 1000, 1000 }
    )

    xPlayer.showNotification(('Véhicule %s acheté (%s$).'):format(string.upper(Config.UniqueGarageVehicle), Config.VehiclePrice), 'success')
end)

RegisterNetEvent('bs_taxi:server:spawnVehicle', function(vehicleId)
    local src = source
    local ok, xPlayer = isTaxi(src)
    if not ok then return end

    local row = MySQL.single.await(
        'SELECT id, model, plate, fuel, engine_health, body_health, stored FROM bs_taxi_fleet WHERE id = ?',
        { vehicleId }
    )
    if not row then
        xPlayer.showNotification('Véhicule introuvable.', 'error')
        return
    end

    if normalizeStored(row.stored) == 0 then
        xPlayer.showNotification('Ce véhicule est déjà sorti.', 'error')
        return
    end

    local claimed = MySQL.update.await(
        'UPDATE bs_taxi_fleet SET stored = 0 WHERE id = ? AND stored = 1',
        { vehicleId }
    )
    if (claimed or 0) < 1 then
        xPlayer.showNotification('Ce véhicule vient d\'être sorti par quelqu\'un.', 'error')
        return
    end

    local coords = Config.GarageSpawn.coords
    local veh = CreateVehicleServerSetter(joaat(row.model), 'automobile', coords.x, coords.y, coords.z, coords.w)

    local timeout = 0
    while not DoesEntityExist(veh) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not DoesEntityExist(veh) then
        MySQL.update.await('UPDATE bs_taxi_fleet SET stored = 1 WHERE id = ?', { vehicleId })
        xPlayer.showNotification('Impossible de sortir le véhicule.', 'error')
        return
    end

    SetVehicleNumberPlateText(veh, row.plate)
    local spawnedPlate = GetVehicleNumberPlateText(veh)

    SetVehicleEngineHealth(veh, row.engine_health + 0.0)
    SetVehicleBodyHealth(veh, row.body_health + 0.0)

    local netId = NetworkGetNetworkIdFromEntity(veh)

    TriggerClientEvent('bs_taxi:client:vehicleSpawned', src, netId, row.fuel, spawnedPlate)
end)

RegisterNetEvent('bs_taxi:server:storeVehicle', function(netId, plate, fuel, engine, body)
    local src = source
    local ok, xPlayer = isTaxi(src)
    if not ok then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then
        xPlayer.showNotification('Véhicule invalide.', 'error')
        return
    end

    local cleanPlate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
    local row = MySQL.single.await('SELECT id FROM bs_taxi_fleet WHERE plate = ?', { cleanPlate })

    if not row then
        xPlayer.showNotification('Ce véhicule ne fait pas partie de la flotte taxi.', 'error')
        return
    end

    DeleteEntity(entity)

    MySQL.update.await(
        'UPDATE bs_taxi_fleet SET stored = 1, fuel = ?, engine_health = ?, body_health = ? WHERE id = ?',
        { fuel, engine, body, row.id }
    )

    xPlayer.showNotification('Véhicule rangé.', 'success')
end)

RegisterNetEvent('bs_taxi:server:recoverFleet', function()
    local src = source
    local ok, xPlayer = isTaxi(src)
    if not ok then
        xPlayer.showNotification('Tu n\'es pas taxi.', 'error')
        return
    end

    if not isBoss(xPlayer) then
        xPlayer.showNotification('Seul le patron peut forcer la récupération.', 'error')
        return
    end

    local recovered = MySQL.update.await(
        'UPDATE bs_taxi_fleet SET stored = 1 WHERE stored = 0',
        {}
    ) or 0

    xPlayer.showNotification(('Récupération flotte terminée: %s véhicule(s).'):format(recovered), 'success')
end)

RegisterNetEvent('bs_taxi:server:forceRecoverVehicle', function(vehicleId)
    local src = source
    local ok, xPlayer = isTaxi(src)
    if not ok then
        xPlayer.showNotification('Tu n\'es pas taxi.', 'error')
        return
    end

    if not isBoss(xPlayer) then
        xPlayer.showNotification('Seul le patron peut forcer le retour.', 'error')
        return
    end

    local row = MySQL.single.await('SELECT plate FROM bs_taxi_fleet WHERE id = ?', { vehicleId })
    if not row then
        xPlayer.showNotification('Véhicule introuvable.', 'error')
        return
    end

    MySQL.update.await('UPDATE bs_taxi_fleet SET stored = 1 WHERE id = ?', { vehicleId })
    xPlayer.showNotification(('Véhicule %s forcé au garage.'):format(row.plate), 'success')
end)

RegisterNetEvent('bs_taxi:server:finishMission', function(distance)
    local src = source
    local ok, xPlayer = isTaxi(src)
    if not ok then return end

    local km = math.max(0.1, distance / 1000.0)
    local reward = math.floor(Config.PaymentBase + (Config.PaymentPerKm * km))

    xPlayer.addAccountMoney('money', reward)
    xPlayer.showNotification(('Course terminée : +%s$'):format(reward), 'success')
end)

-- Future Mission Expansion Logic
-- Missions could be stored in a table and assigned to players
-- We could add a 'level' or 'experience' system for drivers
