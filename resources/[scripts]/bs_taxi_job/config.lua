Config = {}

Config.JobName = 'taxi'
Config.BossGradeName = 'boss' -- Job grade name for the boss
Config.UniqueGarageVehicle = 'taxi'
Config.VehiclePrice = 15000
Config.MissionCooldown = 8 -- seconds between rides
Config.MinMissionDistance = 700.0
Config.MaxMissionDistance = 2200.0
Config.PaymentPerKm = 110
Config.PaymentBase = 180

Config.Blips = {
    Garage = {coords = vec3(900.1, -179.2, 73.9), sprite = 198, color = 5, scale = 0.8, label = 'Garage Taxi'},
    Boss = {coords = vec3(903.2, -171.5, 74.1), sprite = 475, color = 46, scale = 0.8, label = 'Patron Taxi'},
    Mission = {coords = vec3(908.7, -163.4, 74.1), sprite = 280, color = 5, scale = 0.75, label = 'Missions Taxi'}
}

Config.GarageSpawn = {
    coords = vec4(913.2, -163.5, 74.2, 99.0)
}

Config.TabletTheme = {
    primary = '#ffcc00',
    secondary = '#f7d84b',
    dark = '#121212'
}

Config.PedModels = {
    'a_m_m_business_01',
    'a_f_y_business_02',
    'a_m_m_beach_01',
    'a_f_y_tourist_01',
    'u_m_m_streetart_01'
}

Config.PickupLocations = {
    vec4(214.9, -862.2, 30.4, 341.0),
    vec4(-536.8, -220.0, 37.6, 203.0),
    vec4(-1206.6, -880.6, 13.0, 211.0),
    vec4(-71.8, -2003.2, 18.0, 351.0),
    vec4(1692.7, 3786.8, 34.7, 216.0),
    vec4(1247.5, -329.9, 69.0, 82.0),
    vec4(-314.0, -1038.0, 30.4, 250.0)
}

Config.DropoffLocations = {
    vec3(-245.2, -987.1, 29.3),
    vec3(-1182.2, -1520.9, 4.4),
    vec3(-1473.2, -668.5, 29.0),
    vec3(255.8, -373.2, 44.1),
    vec3(1120.5, -983.0, 45.4),
    vec3(1729.0, 6416.6, 35.0),
    vec3(-37.2, -1101.8, 26.4)
}
