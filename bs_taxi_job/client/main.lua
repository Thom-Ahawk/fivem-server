local QBCore = exports['qb-core']:GetCoreObject()

local inMission = false
local missionPed = nil
local missionBlip = nil
local dropBlip = nil
local missionPickup = nil
local missionDropoff = nil
local hasPassenger = false
local missionStartTime = 0
local canStartMissionAt = 0

local garageOpen = false
local warnedInvalidCoords = {}

local fallbackCoords = {
    Garage = vec3(900.1, -179.2, 73.9),
    Mission = vec3(908.7, -163.4, 74.1)
}

local function getSafeCoord(key)
    local cfg = Config.Blips and Config.Blips[key] and Config.Blips[key].coords
    if cfg and cfg.x and cfg.y and cfg.z then
        return cfg
    end

    if not warnedInvalidCoords[key] then
        warnedInvalidCoords[key] = true
        print(('[bs_taxi_job] Coordonnées invalides pour %s, fallback par défaut utilisé.'):format(key))
    end

    return fallbackCoords[key]
end

local function drawTxt3D(coords, text)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)
    local factor = #text / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function isTaxi()
    local data = QBCore.Functions.GetPlayerData()
    return data.job and data.job.name == Config.JobName
end

local function createMainBlips()
    if type(Config.Blips) ~= 'table' then
        print('[bs_taxi_job] Config.Blips invalide, blips non créés.')
        return
    end

    for _, b in pairs(Config.Blips) do
        if not b.coords then
            goto continue
        end
        local blip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
        SetBlipSprite(blip, b.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, b.scale)
        SetBlipColour(blip, b.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(b.label)
        EndTextCommandSetBlipName(blip)
        ::continue::
    end
end

local function openTablet(data)
    local vehicles = {}
    if type(data.vehicles) == 'table' then
        vehicles = data.vehicles
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        payload = {
            vehicles = vehicles,
            price = data.price,
            uniqueModel = data.uniqueModel,
            theme = Config.TabletTheme
        }
    })
    garageOpen = true
end

local function tryGiveKeys(veh, plate)
    local detectedPlate = plate
    if not detectedPlate or detectedPlate == '' then
        detectedPlate = QBCore.Functions.GetPlate(veh)
    end
    local finalPlate = string.gsub((detectedPlate or ''), '^%s*(.-)%s*$', '%1')
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
            -- qb-vehiclekeys attendu: acquisition serveur + fallback compat ancien event
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', variant)
            TriggerEvent('vehiclekeys:client:SetOwner', variant)
            TriggerEvent('qb-vehiclekeys:client:AddKeys', variant)
        end
    end
end

local function syncKeysFromServer()
    QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:GetVehicleKeys', function(keysList)
        if type(keysList) ~= 'table' then return end
        for k, _ in pairs(keysList) do
            TriggerEvent('qb-vehiclekeys:client:AddKeys', k)
        end
    end)
end

local function ensureEntityFromNetId(netId, timeoutMs)
    local waited = 0
    local step = 100
    local timeout = timeoutMs or 4000

    while waited < timeout do
        local veh = NetToVeh(netId)
        if veh ~= 0 and DoesEntityExist(veh) then
            return veh
        end
        Wait(step)
        waited = waited + step
    end

    return 0
end

local function refreshTablet()
    if not garageOpen then return end
    QBCore.Functions.TriggerCallback('bs_taxi:server:getFleet', function(data)
        if not data or not data.ok then return end
        openTablet(data)
    end)
end

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    garageOpen = false
    cb('ok')
end)

RegisterNUICallback('buyUniqueVehicle', function(_, cb)
    TriggerServerEvent('bs_taxi:server:buyUniqueVehicle')
    SetTimeout(250, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('bs_taxi:server:spawnVehicle', tonumber(data.id))
    SetTimeout(250, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('storeCurrentVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        QBCore.Functions.Notify('Tu dois être dans le véhicule à ranger.', 'error')
        cb('ok')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local fuel = Entity(veh).state.fuel or 100.0
    local engine = GetVehicleEngineHealth(veh)
    local body = GetVehicleBodyHealth(veh)
    TriggerServerEvent('bs_taxi:server:storeVehicle', netId, fuel, engine, body)
    SetTimeout(250, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('recoverFleet', function(_, cb)
    TriggerServerEvent('bs_taxi:server:recoverFleet')
    SetTimeout(250, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('forceRecoverVehicle', function(data, cb)
    TriggerServerEvent('bs_taxi:server:forceRecoverVehicle', tonumber(data.id))
    SetTimeout(250, refreshTablet)
    cb('ok')
end)

RegisterNetEvent('bs_taxi:client:vehicleSpawned', function(netId, fuel, plate)
    local veh = ensureEntityFromNetId(netId, 4000)
    if veh == 0 then return end

    SetVehicleDoorsLocked(veh, 1)
    SetVehicleDoorsLockedForAllPlayers(veh, false)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleFuelLevel(veh, fuel)
    Entity(veh).state.fuel = fuel
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehRadioStation(veh, 'OFF')
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

    local finalPlate = QBCore.Functions.GetPlate(veh)
    if not finalPlate or finalPlate == '' then
        finalPlate = plate or GetVehicleNumberPlateText(veh)
    end
    finalPlate = string.gsub(finalPlate or '', '^%s*(.-)%s*$', '%1')
    TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', netId, 1)
    tryGiveKeys(veh, finalPlate)

    -- Retry anti-race (qb-vehiclekeys peut init en retard au spawn réseau)
    for i = 1, 5 do
        SetTimeout(i * 400, function()
            if DoesEntityExist(veh) then
                tryGiveKeys(veh, finalPlate)
            end
        end)
    end
    SetTimeout(1200, syncKeysFromServer)

    QBCore.Functions.Notify(('Clés du véhicule %s attribuées.'):format(finalPlate), 'success')
end)

RegisterNetEvent('bs_taxi:client:grantSpawnedVehicleKeys', function(plate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    tryGiveKeys(veh, plate)
    for i = 1, 5 do
        SetTimeout(i * 400, function()
            tryGiveKeys(veh, plate)
        end)
    end
    SetTimeout(1200, syncKeysFromServer)
end)

local function choosePickupDropoff()
    local pickup = Config.PickupLocations[math.random(#Config.PickupLocations)]
    local dropoff = Config.DropoffLocations[math.random(#Config.DropoffLocations)]

    while #(vec3(pickup.x, pickup.y, pickup.z) - vec3(dropoff.x, dropoff.y, dropoff.z)) < Config.MinMissionDistance do
        dropoff = Config.DropoffLocations[math.random(#Config.DropoffLocations)]
    end

    return pickup, dropoff
end

local function clearMission()
    if DoesBlipExist(missionBlip) then RemoveBlip(missionBlip) end
    if DoesBlipExist(dropBlip) then RemoveBlip(dropBlip) end
    if missionPed and DoesEntityExist(missionPed) then DeleteEntity(missionPed) end
    missionPed, missionBlip, dropBlip = nil, nil, nil
    missionPickup, missionDropoff = nil, nil
    inMission = false
    hasPassenger = false
end

local function startMission()
    if inMission then
        QBCore.Functions.Notify('Tu as déjà une mission.', 'error')
        return
    end

    if GetGameTimer() < canStartMissionAt then
        QBCore.Functions.Notify('Patiente un instant avant la prochaine mission.', 'error')
        return
    end

    if not isTaxi() then
        QBCore.Functions.Notify('Tu dois être taxi.', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        QBCore.Functions.Notify('Monte dans un taxi pour démarrer.', 'error')
        return
    end

    local pickup, dropoff = choosePickupDropoff()
    missionPickup = pickup
    missionDropoff = dropoff
    inMission = true
    missionStartTime = GetGameTimer()

    local model = joaat(Config.PedModels[math.random(#Config.PedModels)])
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    missionPed = CreatePed(4, model, pickup.x, pickup.y, pickup.z - 1.0, pickup.w, true, true)
    SetEntityInvincible(missionPed, true)
    SetBlockingOfNonTemporaryEvents(missionPed, true)

    missionBlip = AddBlipForCoord(pickup.x, pickup.y, pickup.z)
    SetBlipRoute(missionBlip, true)
    SetBlipRouteColour(missionBlip, 5)
    SetBlipSprite(missionBlip, 280)

    QBCore.Functions.Notify('Va chercher le client PNJ.', 'primary')
end

CreateThread(function()
    createMainBlips()

    while true do
        local sleep = 1200
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        local garageCoords = getSafeCoord('Garage')
        local garageDist = #(pos - garageCoords)
        if garageDist < 12.0 then
            sleep = 0
            DrawMarker(1, garageCoords.x, garageCoords.y, garageCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.4, 1.4, 0.5, 255, 204, 0, 120, false, false, 2, nil, nil, false)
        end
        if garageDist < 3.0 then
            sleep = 0
            drawTxt3D(garageCoords + vec3(0.0, 0.0, 1.0), '[E] Ouvrir tablette garage')
            if IsControlJustReleased(0, 38) and not garageOpen then
                QBCore.Functions.TriggerCallback('bs_taxi:server:getFleet', function(data)
                    if not data.ok then
                        QBCore.Functions.Notify(data.message, 'error')
                        return
                    end
                    openTablet(data)
                end)
            end
        end

        local missionCoords = getSafeCoord('Mission')
        local missionDist = #(pos - missionCoords)
        if missionDist < 12.0 then
            sleep = 0
            DrawMarker(1, missionCoords.x, missionCoords.y, missionCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.4, 1.4, 0.5, 255, 204, 0, 120, false, false, 2, nil, nil, false)
        end
        if missionDist < 3.0 then
            sleep = 0
            drawTxt3D(missionCoords + vec3(0.0, 0.0, 1.0), '[E] Lancer mission taxi PNJ')
            if IsControlJustReleased(0, 38) then
                startMission()
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if inMission and missionPed then
            local pCoords = GetEntityCoords(PlayerPedId())

            if not hasPassenger then
                local pickupCoords = vec3(missionPickup.x, missionPickup.y, missionPickup.z)
                local dist = #(pCoords - pickupCoords)

                if dist < 24.0 then
                    DrawMarker(2, pickupCoords.x, pickupCoords.y, pickupCoords.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18, 0.18, 0.18, 255, 204, 0, 200, false, true, 2, nil, nil, false)
                end

                if dist < 8.0 then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 then
                        TaskEnterVehicle(missionPed, vehicle, -1, 2, 1.0, 1, 0)
                        Wait(1500)
                        hasPassenger = true

                        if DoesBlipExist(missionBlip) then RemoveBlip(missionBlip) end
                        dropBlip = AddBlipForCoord(missionDropoff.x, missionDropoff.y, missionDropoff.z)
                        SetBlipRoute(dropBlip, true)
                        SetBlipRouteColour(dropBlip, 5)
                        SetBlipSprite(dropBlip, 1)

                        QBCore.Functions.Notify('Client monté. Dépose-le à destination.', 'success')
                    end
                end
            else
                local drop = vec3(missionDropoff.x, missionDropoff.y, missionDropoff.z)
                local distDrop = #(pCoords - drop)

                if distDrop < 20.0 then
                    DrawMarker(1, drop.x, drop.y, drop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.2, 2.2, 1.0, 255, 204, 0, 120, false, false, 2, nil, nil, false)
                end

                if distDrop < 6.0 then
                    TaskLeaveVehicle(missionPed, GetVehiclePedIsIn(PlayerPedId(), false), 0)
                    Wait(1000)
                    TaskWanderStandard(missionPed, 10.0, 10)

                    local distance = #(vec3(missionPickup.x, missionPickup.y, missionPickup.z) - drop)
                    TriggerServerEvent('bs_taxi:server:finishMission', distance)

                    canStartMissionAt = GetGameTimer() + (Config.MissionCooldown * 1000)
                    clearMission()
                end
            end
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    clearMission()
end)