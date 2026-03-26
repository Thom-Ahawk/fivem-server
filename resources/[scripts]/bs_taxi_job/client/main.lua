local ESX = exports['es_extended']:getSharedObject()

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
    local data = ESX.GetPlayerData()
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
    -- Generic key handling for ESX
    -- Many ESX servers use custom key scripts.
    -- We trigger a generic event that can be easily mapped.
    TriggerEvent('bs_taxi:client:giveKeys', plate, veh)
    -- Fallback for some common scripts
    SetVehicleHasBeenOwnedByPlayer(veh, true)
end

local function ensureEntityFromNetId(netId, timeoutMs)
    local waited = 0
    local step = 100
    local timeout = timeoutMs or 4000

    while waited < timeout do
        if NetworkDoesNetworkIdExist(netId) then
            local veh = NetToVeh(netId)
            if veh ~= 0 and DoesEntityExist(veh) then
                return veh
            end
        end
        Wait(step)
        waited = waited + step
    end

    return 0
end

local function refreshTablet()
    if not garageOpen then return end
    ESX.TriggerServerCallback('bs_taxi:server:getFleet', function(data)
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
    SetTimeout(500, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('bs_taxi:server:spawnVehicle', tonumber(data.id))
    SetTimeout(500, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('storeCurrentVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        ESX.ShowNotification('Tu dois être dans le véhicule à ranger.', 'error')
        cb('ok')
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local fuel = GetVehicleFuelLevel(veh)
    local engine = GetVehicleEngineHealth(veh)
    local body = GetVehicleBodyHealth(veh)

    TriggerServerEvent('bs_taxi:server:storeVehicle', netId, plate, fuel, engine, body)
    SetTimeout(500, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('recoverFleet', function(_, cb)
    TriggerServerEvent('bs_taxi:server:recoverFleet')
    SetTimeout(500, refreshTablet)
    cb('ok')
end)

RegisterNUICallback('forceRecoverVehicle', function(data, cb)
    TriggerServerEvent('bs_taxi:server:forceRecoverVehicle', tonumber(data.id))
    SetTimeout(500, refreshTablet)
    cb('ok')
end)

RegisterNetEvent('bs_taxi:client:vehicleSpawned', function(netId, fuel, plate)
    local veh = ensureEntityFromNetId(netId, 5000)
    if veh == 0 then return end

    SetVehicleDoorsLocked(veh, 1)
    SetVehicleFuelLevel(veh, fuel + 0.0)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehRadioStation(veh, 'OFF')
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

    tryGiveKeys(veh, plate)
    ESX.ShowNotification(('Clés du véhicule %s attribuées.'):format(plate), 'success')
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
    if missionPed and DoesEntityExist(missionPed) then
        DeleteEntity(missionPed)
    end
    missionPed, missionBlip, dropBlip = nil, nil, nil
    missionPickup, missionDropoff = nil, nil
    inMission = false
    hasPassenger = false
end

local function startMission()
    if inMission then
        ESX.ShowNotification('Tu as déjà une mission.', 'error')
        return
    end

    if GetGameTimer() < canStartMissionAt then
        ESX.ShowNotification('Patiente un instant avant la prochaine mission.', 'error')
        return
    end

    if not isTaxi() then
        ESX.ShowNotification('Tu dois être taxi.', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        ESX.ShowNotification('Monte dans un taxi pour démarrer.', 'error')
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

    ESX.ShowNotification('Va chercher le client PNJ.', 'info')
end

-- Main Loop for Interactions
CreateThread(function()
    createMainBlips()

    while true do
        local sleep = 1000
        if not isTaxi() then
            Wait(2000)
            goto continue
        end

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- Garage Interaction
        local garageCoords = getSafeCoord('Garage')
        local garageDist = #(pos - garageCoords)
        if garageDist < 12.0 then
            sleep = 0
            DrawMarker(1, garageCoords.x, garageCoords.y, garageCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.4, 1.4, 0.5, 255, 204, 0, 120, false, false, 2, nil, nil, false)

            if garageDist < 3.0 then
                drawTxt3D(garageCoords + vec3(0.0, 0.0, 1.0), '[E] Tablette Garage')
                if IsControlJustReleased(0, 38) and not garageOpen then
                    ESX.TriggerServerCallback('bs_taxi:server:getFleet', function(data)
                        if not data.ok then
                            ESX.ShowNotification(data.message, 'error')
                            return
                        end
                        openTablet(data)
                    end)
                end
            end
        end

        -- Mission Interaction
        local missionCoords = getSafeCoord('Mission')
        local missionDist = #(pos - missionCoords)
        if missionDist < 12.0 then
            sleep = 0
            DrawMarker(1, missionCoords.x, missionCoords.y, missionCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.4, 1.4, 0.5, 255, 204, 0, 120, false, false, 2, nil, nil, false)

            if missionDist < 3.0 then
                drawTxt3D(missionCoords + vec3(0.0, 0.0, 1.0), '[E] Mission PNJ')
                if IsControlJustReleased(0, 38) then
                    startMission()
                end
            end
        end

        ::continue::
        Wait(sleep)
    end
end)

-- Mission Thread
CreateThread(function()
    while true do
        local sleep = 1000
        if inMission and missionPed then
            sleep = 0
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)

            if not hasPassenger then
                local pickupCoords = vec3(missionPickup.x, missionPickup.y, missionPickup.z)
                local dist = #(pCoords - pickupCoords)

                if dist < 20.0 then
                    DrawMarker(2, pickupCoords.x, pickupCoords.y, pickupCoords.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 204, 0, 200, false, true, 2, nil, nil, false)
                end

                if dist < 8.0 then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                        TaskEnterVehicle(missionPed, vehicle, -1, 2, 1.0, 1, 0)

                        local timeout = 0
                        while not IsPedInVehicle(missionPed, vehicle, false) and timeout < 100 do
                            Wait(100)
                            timeout = timeout + 1
                        end

                        if IsPedInVehicle(missionPed, vehicle, false) then
                            hasPassenger = true
                            if DoesBlipExist(missionBlip) then RemoveBlip(missionBlip) end

                            dropBlip = AddBlipForCoord(missionDropoff.x, missionDropoff.y, missionDropoff.z)
                            SetBlipRoute(dropBlip, true)
                            SetBlipRouteColour(dropBlip, 5)
                            SetBlipSprite(dropBlip, 1)

                            ESX.ShowNotification('Client monté. Dépose-le à destination.', 'success')
                        end
                    end
                end
            else
                local drop = vec3(missionDropoff.x, missionDropoff.y, missionDropoff.z)
                local distDrop = #(pCoords - drop)

                if distDrop < 20.0 then
                    DrawMarker(1, drop.x, drop.y, drop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.2, 2.2, 1.0, 255, 204, 0, 120, false, false, 2, nil, nil, false)
                end

                if distDrop < 6.0 then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    TaskLeaveVehicle(missionPed, vehicle, 0)
                    Wait(1500)
                    TaskWanderStandard(missionPed, 10.0, 10)

                    local distance = #(vec3(missionPickup.x, missionPickup.y, missionPickup.z) - drop)
                    TriggerServerEvent('bs_taxi:server:finishMission', distance)

                    canStartMissionAt = GetGameTimer() + (Config.MissionCooldown * 1000)
                    clearMission()
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

-- Placeholder for future features
function OpenGarage()
    -- Logic for opening a vehicle-selection menu or similar
    -- Could use ESX.UI.Menu.Open
end

function OpenBossMenu()
    -- Logic for opening the society/boss menu
    -- Integration with esx_society or similar
    -- Example: TriggerEvent('esx_society:openBossMenu', 'taxi', function(data, menu) menu.close() end, { wash = false })
end

function StartAdvancedMission(tier)
    -- Logic for missions based on player level or vehicle type
end
