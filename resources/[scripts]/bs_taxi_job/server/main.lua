local QBCore = exports['qb-core']:GetCoreObject()

local FleetTable = 'bs_taxi_fleet'
local TaxiGarageName = 'taxi'
local TaxiOwnerId = 'taxi_shared'

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
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.job and player.PlayerData.job.name == Config.JobName, player
end

local function isBoss(player)
    if not player then return false end
    local grade = player.PlayerData.job.grade
    if not grade then return false end
    return grade.name == Config.BossGradeName or grade.level >= 4
end

local function grantKeysToPlayer(src, plate)
    local finalPlate = string.gsub((plate or ''), '^%s*(.-)%s*$', '%1')
    if finalPlate == '' then return end

    local variants = {
        finalPlate,
        string.upper(finalPlate),
        string.lower(finalPlate)
    }

    local sent = {}
    for _, variant in ipairs(variants) do
        if variant ~= '' and not sent[variant] then
            sent[variant] = true
            if GetResourceState('qb-vehiclekeys') == 'started' then
                pcall(function()
                    exports['qb-vehiclekeys']:GiveKeys(src, variant)
                end)
            end
            TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, variant)
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, variant)
        end
    end

    TriggerClientEvent('bs_taxi:client:grantSpawnedVehicleKeys', src, finalPlate)
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

QBCore.Functions.CreateCallback('bs_taxi:server:getFleet', function(source, cb)
    local isInTaxi = select(1, isTaxi(source))
    if not isInTaxi then
        cb({ ok = false, message = 'Tu n\'es pas taxi.' })
        return
    end

    local rows = MySQL.query.await(
        ('SELECT id, model, plate, fuel, engine_health, body_health, stored FROM %s WHERE garage = ? ORDER BY id ASC'):format(FleetTable),
        { TaxiGarageName }
    )
    if rows == nil then
        cb({ ok = false, message = 'Erreur BDD: table bs_taxi_fleet absente ?' })
        return
    end

    local list = {}
    for _, row in ipairs(rows or {}) do
        list[#list + 1] = formatVehicleRow(row)
    end

    cb({ ok = true, vehicles = list, price = Config.VehiclePrice, uniqueModel = Config.UniqueGarageVehicle })
end)

RegisterNetEvent('bs_taxi:server:buyUniqueVehicle', function()
    local src = source
    local ok, player = isTaxi(src)

    if not ok then
        TriggerClientEvent('QBCore:Notify', src, 'Tu n\'es pas taxi.', 'error')
        return
    end

    if not isBoss(player) then
        TriggerClientEvent('QBCore:Notify', src, 'Seul le patron peut acheter.', 'error')
        return
    end

    local exists = MySQL.scalar.await(('SELECT COUNT(1) FROM %s WHERE model = ? AND garage = ?'):format(FleetTable), { Config.UniqueGarageVehicle, TaxiGarageName })
    if exists and exists > 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Le véhicule unique est déjà acheté.', 'error')
        return
    end

    if not player.Functions.RemoveMoney('bank', Config.VehiclePrice, 'taxi-company-vehicle') then
        TriggerClientEvent('QBCore:Notify', src, 'Fonds insuffisants en banque.', 'error')
        return
    end

    local plate = ('TAXI%s'):format(math.random(111, 999))

    MySQL.insert.await(
        ('INSERT INTO %s (model, plate, garage, fuel, engine_health, body_health, stored, hash, mods) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)'):format(FleetTable),
        { Config.UniqueGarageVehicle, plate, TaxiGarageName, 100, 1000, 1000, joaat(Config.UniqueGarageVehicle), '{}' }
    )

    TriggerClientEvent('QBCore:Notify', src, ('Véhicule %s acheté (%s$).'):format(string.upper(Config.UniqueGarageVehicle), Config.VehiclePrice), 'success')
end)

RegisterNetEvent('bs_taxi:server:spawnVehicle', function(vehicleId)
    local src = source
    local ok = select(1, isTaxi(src))
    if not ok then return end

    local row = MySQL.single.await(
        ('SELECT id, model, plate, fuel, engine_health, body_health, stored FROM %s WHERE id = ? AND garage = ?'):format(FleetTable),
        { vehicleId, TaxiGarageName }
    )
    if not row then
        TriggerClientEvent('QBCore:Notify', src, 'Véhicule introuvable.', 'error')
        return
    end

    if normalizeStored(row.stored) == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Ce véhicule est déjà sorti.', 'error')
        return
    end

    local claimed = MySQL.update.await(
        ('UPDATE %s SET stored = 0 WHERE id = ? AND stored = 1'):format(FleetTable),
        { vehicleId }
    )
    if (claimed or 0) < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Ce véhicule vient d\'être sorti par quelqu\'un.', 'error')
        return
    end

    local coords = Config.GarageSpawn.coords
    local veh = 0
    local plateToMatch = string.gsub(row.plate or '', '^%s*(.-)%s*$', '%1'):upper()

    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        local p = string.gsub(GetVehicleNumberPlateText(v) or '', '^%s*(.-)%s*$', '%1'):upper()
        if p == plateToMatch then
            veh = v
            SetEntityCoords(veh, coords.x, coords.y, coords.z)
            SetEntityHeading(veh, coords.w)
            break
        end
    end

    if veh == 0 then
        veh = CreateVehicleServerSetter(joaat(row.model), 'automobile', coords.x, coords.y, coords.z, coords.w)
        if veh == 0 then
            MySQL.update.await(('UPDATE %s SET stored = 1 WHERE id = ?'):format(FleetTable), { vehicleId })
            TriggerClientEvent('QBCore:Notify', src, 'Impossible de sortir le véhicule.', 'error')
            return
        end
        while not DoesEntityExist(veh) do Wait(10) end
        SetVehicleNumberPlateText(veh, row.plate)
    end
    local spawnedPlate = string.gsub(GetVehicleNumberPlateText(veh) or row.plate or '', '^%s*(.-)%s*$', '%1')
    if spawnedPlate == '' then spawnedPlate = row.plate end
    SetVehicleEngineHealth(veh, row.engine_health)
    SetVehicleBodyHealth(veh, row.body_health)
    Entity(veh).state.fuel = row.fuel

    local netId = NetworkGetNetworkIdFromEntity(veh)

    MySQL.update.await(('UPDATE %s SET stored = 0, plate = ? WHERE id = ?'):format(FleetTable), { spawnedPlate, vehicleId })
    TriggerEvent('qb-vehiclekeys:server:setVehLockState', netId, 2)
    TriggerClientEvent('bs_taxi:client:vehicleSpawned', src, netId, row.fuel, spawnedPlate)
    grantKeysToPlayer(src, spawnedPlate)
end)

RegisterNetEvent('bs_taxi:server:storeVehicle', function(netId, fuel, engine, body)
    local src = source
    local ok = select(1, isTaxi(src))
    if not ok then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Véhicule invalide.', 'error')
        return
    end

    local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1')

    local row = MySQL.single.await(('SELECT id FROM %s WHERE plate = ? AND garage = ?'):format(FleetTable), { plate, TaxiGarageName })
    if not row then
        TriggerClientEvent('QBCore:Notify', src, 'Ce véhicule ne fait pas partie de la flotte taxi.', 'error')
        return
    end

    TriggerEvent('qb-vehiclekeys:server:setVehLockState', netId, 2)

    MySQL.update.await(
        ('UPDATE %s SET stored = 1, fuel = ?, engine_health = ?, body_health = ?, garage = ? WHERE id = ?'):format(FleetTable),
        { fuel, engine, body, TaxiGarageName, row.id }
    )

    TriggerClientEvent('QBCore:Notify', src, 'Véhicule rangé.', 'success')
end)

RegisterNetEvent('bs_taxi:server:recoverFleet', function()
    local src = source
    local ok, player = isTaxi(src)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, 'Tu n\'es pas taxi.', 'error')
        return
    end

    if not isBoss(player) then
        TriggerClientEvent('QBCore:Notify', src, 'Seul le patron peut forcer la récupération.', 'error')
        return
    end

    local recovered = MySQL.update.await(
        ('UPDATE %s SET stored = 1 WHERE garage = ? AND stored = 0'):format(FleetTable),
        { TaxiGarageName }
    ) or 0

    TriggerClientEvent('QBCore:Notify', src, ('Récupération flotte terminée: %s véhicule(s).'):format(recovered), 'success')
end)

RegisterNetEvent('bs_taxi:server:forceRecoverVehicle', function(vehicleId)
    local src = source
    local ok, player = isTaxi(src)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, 'Tu n\'es pas taxi.', 'error')
        return
    end

    if not isBoss(player) then
        TriggerClientEvent('QBCore:Notify', src, 'Seul le patron peut forcer le retour.', 'error')
        return
    end

    local row = MySQL.single.await(('SELECT * FROM %s WHERE id = ?'):format(FleetTable), { vehicleId })
    if not row then
        TriggerClientEvent('QBCore:Notify', src, 'Véhicule introuvable.', 'error')
        return
    end

    MySQL.update.await(('UPDATE %s SET stored = 1 WHERE id = ? AND garage = ?'):format(FleetTable), { vehicleId, TaxiGarageName })
    TriggerClientEvent('QBCore:Notify', src, ('Véhicule %s forcé au garage.'):format(row.plate), 'success')
end)

RegisterNetEvent('bs_taxi:server:finishMission', function(distance)
    local src = source
    local ok, player = isTaxi(src)
    if not ok then return end

    local km = math.max(0.1, distance / 1000.0)
    local reward = math.floor(Config.PaymentBase + (Config.PaymentPerKm * km))
    player.Functions.AddMoney('cash', reward, 'taxi-npc-mission')

    TriggerClientEvent('QBCore:Notify', src, ('Course terminée : +%s$'):format(reward), 'success')
end)
