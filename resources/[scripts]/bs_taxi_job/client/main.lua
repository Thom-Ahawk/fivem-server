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
        local coords = GetEntityCoords(ped)
        veh = QBCore.Functions.GetClosestVehicle(coords)
        if veh == 0 or #(coords - GetEntityCoords(veh)) > 8.0 then
            QBCore.Functions.Notify('Aucun véhicule taxi à proximité.', 'error')
            cb('ok')
            return
        end
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local fuel = Entity(veh).state.fuel or GetVehicleFuelLevel(veh) or 100.0
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

    SetVehicleDoorsLocked(veh, 2) -- Sortie verrouillée
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
    TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', netId, 2)
    tryGiveKeys(veh, finalPlate)

    for i = 1, 5 do
        SetTimeout(i * 400, function()
            if DoesEntityExist(veh) then
                tryGiveKeys(veh, finalPlate)
            end
        end)
    end
    SetTimeout(1200, syncKeysFromServer)

    QBCore.Functions.Notify(('Clés du véhicule %s attribuées. Il est verrouillé.'):format(finalPlate), 'success')
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

RegisterNetEvent('bs_taxi:client:forceExitVehicle', function(netId)
    local veh = NetToVeh(netId)
    if veh ~= 0 and DoesEntityExist(veh) then
        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) == veh then
            TaskLeaveVehicle(ped, veh, 0)
        end
    end
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

    exports['qb-target']:AddBoxZone("TaxiGarage", Config.Blips.Garage.coords, 25.0, 25.0, { -- Zone élargie
        name = "TaxiGarage",
        heading = 0,
        debugPoly = false,
        minZ = Config.Blips.Garage.coords.z - 2.0,
        maxZ = Config.Blips.Garage.coords.z + 5.0,
    }, {
        options = {
            {
                type = "client",
                event = "bs_taxi:client:openGarage",
                icon = "fas fa-warehouse",
                label = "Garage Taxi",
                job = Config.JobName,
            },
            {
                type = "client",
                event = "bs_taxi:client:storeVehicle",
                icon = "fas fa-car",
                label = "Enregistrer véhicule (reste dehors)",
                job = Config.JobName,
            },
        },
        distance = 15.0
    })

    exports['qb-target']:AddBoxZone("TaxiMissions", Config.Blips.Mission.coords, 2.0, 2.0, {
        name = "TaxiMissions",
        heading = 0,
        debugPoly = false,
        minZ = Config.Blips.Mission.coords.z - 1.0,
        maxZ = Config.Blips.Mission.coords.z + 1.0,
    }, {
        options = {
            {
                type = "client",
                event = "bs_taxi:client:startMission",
                icon = "fas fa-taxi",
                label = "Missions Taxi",
                job = Config.JobName,
            },
        },
        distance = 2.5
    })
end)

RegisterNetEvent('bs_taxi:client:openGarage', function()
    QBCore.Functions.TriggerCallback('bs_taxi:server:getFleet', function(data)
        if not data.ok then
            QBCore.Functions.Notify(data.message, 'error')
            return
        end
        openTablet(data)
    end)
end)

RegisterNetEvent('bs_taxi:client:storeVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = QBCore.Functions.GetClosestVehicle(coords)
        if veh == 0 or #(coords - GetEntityCoords(veh)) > 8.0 then
            QBCore.Functions.Notify('Aucun véhicule taxi à proximité.', 'error')
            return
        end
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local fuel = Entity(veh).state.fuel or GetVehicleFuelLevel(veh) or 100.0
    local engine = GetVehicleEngineHealth(veh)
    local body = GetVehicleBodyHealth(veh)
    TriggerServerEvent('bs_taxi:server:storeVehicle', netId, fuel, engine, body)
end)

RegisterNetEvent('bs_taxi:client:startMission', function()
    startMission()
end)

CreateThread(function()
    while true do
        local sleep = 500
        if inMission and missionPed then
            local pCoords = GetEntityCoords(PlayerPedId())

            if not hasPassenger then
                local pickupCoords = vec3(missionPickup.x, missionPickup.y, missionPickup.z)
                local dist = #(pCoords - pickupCoords)

                if dist < 50.0 then
                    sleep = 0
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
                end
            else
                local drop = vec3(missionDropoff.x, missionDropoff.y, missionDropoff.z)
                local distDrop = #(pCoords - drop)

                if distDrop < 50.0 then
                    sleep = 0
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
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    clearMission()
end)
