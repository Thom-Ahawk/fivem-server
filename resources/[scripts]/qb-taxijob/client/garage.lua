local QBCore = exports['qb-core']:GetCoreObject()

local garage = vector3(906.45, -184.85, 74.06)
local spawn = vector4(910.0, -180.0, 75.0, 40.0)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - garage)

        if dist < 10.0 then
            DrawMarker(2, garage.x, garage.y, garage.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 150, false, false, false, true)

            if dist < 2.0 then
                DrawText3D(garage.x, garage.y, garage.z + 0.3, "[E] Garage Taxi")

                if IsControlJustPressed(0, 38) then
                    OpenTaxiGarage()
                end
            end
        end
    end
end)

function OpenTaxiGarage()
    print("OPEN GARAGE")

    QBCore.Functions.TriggerCallback('taxi:getVehicles', function(vehicles)

        print("VEHICLES:", json.encode(vehicles))

        local menu = {
            { header = "🚖 Garage Taxi", isMenuHeader = true }
        }

        if vehicles and #vehicles > 0 then
            for _, v in pairs(vehicles) do
                menu[#menu+1] = {
                    header = v.vehicle.." | "..v.plate,
                    txt = "🔧 "..math.floor(v.engine or 1000).." | ⛽ "..math.floor(v.fuel or 100),
                    params = {
                        event = "taxi:spawnVehicle",
                        args = v
                    }
                }
            end
        else
            menu[#menu+1] = {
                header = "❌ Aucun véhicule",
                txt = "Ajoute un taxi en base"
            }
        end

        exports['qb-menu']:openMenu(menu)

    end)
end

-- 🚗 SPAWN
RegisterNetEvent('taxi:spawnVehicle', function(data)
    local model = GetHashKey(data.vehicle)
RequestModel(model)

while not HasModelLoaded(model) do Wait(0) end

local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)

    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleEngineHealth(veh, data.engine + 0.0)
    SetVehicleBodyHealth(veh, data.body + 0.0)

    exports['LegacyFuel']:SetFuel(veh, data.fuel)

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

    TriggerServerEvent('taxi:updateState', data.plate, 0)
end)

-- 📦 RANGEMENT
RegisterNetEvent('taxi:storeVehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)

    if veh ~= 0 then
        local plate = QBCore.Functions.GetPlate(veh)

        local fuel = exports['LegacyFuel']:GetFuel(veh)
        local engine = GetVehicleEngineHealth(veh)
        local body = GetVehicleBodyHealth(veh)

        TriggerServerEvent('taxi:updateVehicle', plate, fuel, engine, body)

        DeleteVehicle(veh)

        QBCore.Functions.Notify("Véhicule rangé", "success")
    end
end)

local QBCore = exports['qb-core']:GetCoreObject()

