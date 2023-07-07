if not menu.is_trusted_mode_enabled(1 << 2) then     -- Trusted natives mode check
    menu.notify("Turn on trusted natives to use Realistic FuelMod")
    menu.exit()
end

require("fuelMod\\utils")
require("fuelMod\\stations")

FUELMOD = {
    NAME = "Realistic FuelMod",
    VERSION = "3.5.4",
    SETTINGS = false,
    parent = {},
    feature = {},
    SESSION_ACTIVE = false
}


fuelMod_threads = {
    "hud_thread",
    "loop_thread",
    "disable_vehicle_thread",
    "refuel_thread",
    "manualrefuel_thread",
    "manualrefuel_hud_thread",
    "status_thread"
}

usedVehicles = {}
PATHS = {}
PATHS.root = utils.get_appdata_path("PopstarDevs", "2Take1Menu")
PATHS.fuelMod = PATHS.root .. "\\scripts\\fuelMod"
PATHS.Settings = PATHS.fuelMod .. "\\config.cfg"
PATHS.LogFile = PATHS.fuelMod .. "\\Realistic FuelMod.log"
fuelSettings = {
    originalDisplayMode = false,
    posX = -0.67,
    posY = -0.915,
    scale = 0.15,
    textscale = 0.3,
    textposX = 0.165,
    textposY = 0.97,
    stationsRange = 3.5,
    refuel = 1,
    manualRefuel = 0.5,
    consumptionRate = 1.0,
    refuellingRepairs = true,
    useJerryCanFuel = false,
    manualRefuelConsumption = 1.0
}

current = {
    status = false,
    FuelLevel = 30,
    TankSize = 100,
    latestHash = nil
}

local FuelUsage = {
	[1.0] = 1.4,
	[0.9] = 1.2,
	[0.8] = 1.0,
	[0.7] = 0.9,
	[0.6] = 0.8,
	[0.5] = 0.7,
	[0.4] = 0.5,
	[0.3] = 0.4,
	[0.2] = 0.2,
	[0.1] = 0.1,
	[0.0] = 0.0
}

local fuelConsumption = {}
-- VEHICLE TYPE = CONSUMPTION, TANK CAPACITY
fuelConsumption[0] = {1.00, 50} -- Compacts
fuelConsumption[1] = {1.50, 90} -- Sedans
fuelConsumption[2] = {1.75, 95} -- SUVs
fuelConsumption[3] = {1.60, 70} -- Coupes
fuelConsumption[4] = {2.00, 75} -- Muscle
fuelConsumption[5] = {1.60, 65} -- Sports Classics
fuelConsumption[6] = {1.50, 70} -- Sports
fuelConsumption[7] = {2.50, 100} -- Super
fuelConsumption[8] = {0.50, 25} -- Motorcycles
fuelConsumption[9] = {1.60, 75} -- Off-road
fuelConsumption[10] = {6.00, 300} -- Industrial
fuelConsumption[11] = {2.25, 150} -- Utility
fuelConsumption[12] = {1.75, 105} -- Vans
fuelConsumption[13] = {0.00, 0} -- Cycles
fuelConsumption[14] = {0.00, 0} -- Boats
fuelConsumption[15] = {0.00, 0} -- Helicopters
fuelConsumption[16] = {0.00, 0} -- Planes
fuelConsumption[17] = {1.50, 100} -- Service
fuelConsumption[18] = {0.90, 70} -- Emergency
fuelConsumption[19] = {1.25, 150} -- Military
fuelConsumption[20] = {7.00, 350} -- Commercial
fuelConsumption[21] = {0.00, 0} -- Trains
fuelConsumption[22] = {3.00, 115} -- Open Wheel
fuelConsumption.electrics = {1.05, 100} -- Electric

spritelist = {
    electric = {
        red = "\\scripts\\fuelMod\\sprites\\electric_red.dds",
        orange = "\\scripts\\fuelMod\\sprites\\electric_orange.dds",
        green = "\\scripts\\fuelMod\\sprites\\electric_green.dds",
    },
    fuel = {
        red = "\\scripts\\fuelMod\\sprites\\fuel_red.dds",
        orange = "\\scripts\\fuelMod\\sprites\\fuel_orange.dds",
        green = "\\scripts\\fuelMod\\sprites\\fuel_green.dds",
    }
}
fuelSprite = {
    electric = {},
    fuel = {}
}

local basePrint = print
function print(...)
	local success, result = pcall(function(...)
		local currTime = os.date("*t")
		local file = io.open(PATHS.LogFile, "a")
        if not utils.file_exists(PATHS.LogFile) then file:write("") end
		
		local args = {...}
		for i=1,#args do
			file:write(string.format("[%02d-%02d-%02d %02d:%02d:%02d] ", currTime.year, currTime.month, currTime.day, currTime.hour, currTime.min, currTime.sec)..tostring(args[i]).."\n")
			basePrint(args[i])
		end
		
		file:close()
	end, ...)
	if not success then
		basePrint("Error writing log: " .. result)
	end
end

function Round(num, dp)
    local mult = 10^(dp or 0)
    return math.floor(num * mult + 0.5)/mult
end

function currentVehicle()
    return ped.get_vehicle_ped_is_using(player.get_player_ped(player.player_id()))
end

function isInSupportVehicle()
    if vehicle.get_vehicle_class(currentVehicle()) ~= 13 and vehicle.get_vehicle_class(currentVehicle()) ~= 14 and vehicle.get_vehicle_class(currentVehicle()) ~= 15 and vehicle.get_vehicle_class(currentVehicle()) ~= 16 and vehicle.get_vehicle_class(currentVehicle()) ~= 21 then return true
    else return false end
end

local function IsDriving()
	local pped = player.get_player_ped(player.player_id())
	if ped.is_ped_in_any_vehicle(pped) then
		local veh = ped.get_vehicle_ped_is_using(pped)
		if network.has_control_of_entity(veh) then
			return true
		end
	end
	return false
end

local function IS_ELECTRIC()
    local EV = false
    local evList = {"VOLTIC2", "VOLTIC", "CYCLONE2", "CYCLONE", "TEZERACT", "IWAGEN", "NEON", "RAIDEN", "AIRTUG", "CADDY3", "CADDY2", "CADDY", "IMORGON", "KHAMEL", "DILETTANTE", "SURGE", "OMNISEGT", "VIRTUE", "POWERSURGE"}

    for k,v in pairs(evList) do
        if vehicle.get_vehicle_model_label(currentVehicle()) == v then EV = true end
    end
    return EV
end

local function GetBaseFuelLevel()
    local r=math.floor(math.random() * (12 - 1)) + 1
    if r > 10 then 
        return math.floor(math.random() * (100 - 75)) + 75
    elseif r > 7 then
        return math.floor(math.random() * (75 - 50)) + 50
    else
        return math.floor(math.random() * (50 - 30)) + 30
    end
end

local function UPDATE_VEHICLE_DB()
    if isEmpty(usedVehicles[currentVehicle()]) then
        local baseFuel = GetBaseFuelLevel()
        usedVehicles[currentVehicle()] = baseFuel / 100 * fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][2]
        current.FuelLevel = baseFuel / 100 * fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][2]
    else current.FuelLevel = usedVehicles[currentVehicle()] end
end

local function fuelLevelDecreaseLevel()
        if (current.FuelLevel > 0 and entity.get_entity_speed(currentVehicle()) > 4) then
            if IS_ELECTRIC() then current.FuelLevel = usedVehicles[currentVehicle()] - (FuelUsage[Round(vehicle.get_vehicle_rpm(currentVehicle()), 1)] * (fuelConsumption.electrics[1]) * fuelSettings.consumptionRate) / 10
                --menu.notify("Battery level decreased by " .. (FuelUsage[Round(vehicle.get_vehicle_rpm(currentVehicle()), 1)] * (fuelConsumption.electrics[1]) * fuelSettings.consumptionRate) / 10)
                current.TankSize = fuelConsumption.electrics[2]
            else
                --menu.notify("Fuel level decreased by " .. (FuelUsage[Round(vehicle.get_vehicle_rpm(currentVehicle()), 1)] * (fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][1]) * fuelSettings.consumptionRate) / 15)
                current.FuelLevel = usedVehicles[currentVehicle()] - (FuelUsage[Round(vehicle.get_vehicle_rpm(currentVehicle()), 1)] * (fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][1]) * fuelSettings.consumptionRate) / 15
                current.TankSize = fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][2]
            end
        if current.FuelLevel < 0 then current.FuelLevel = 0 end
        if current.FuelLevel > current.TankSize then current.FuelLevel = current.TankSize end
        usedVehicles[currentVehicle()] = current.FuelLevel
    end
end

function CAN_REFUEL_CHECK()
    nearPump = nearestPump(player.get_player_coords(player.player_id()))
    if nearPump ~= nil and nearPump ~= -1 then
        if Get_Distance_Between_Coords(player.get_player_coords(player.player_id()), nearPump) <= fuelSettings.stationsRange then return true
        else return false end
    end
end

local function fuelLevelIncreaseLevel()
    if CAN_REFUEL_CHECK() then
        if current.FuelLevel < current.TankSize and entity.get_entity_speed(currentVehicle()) == 0 then
            current.FuelLevel = usedVehicles[currentVehicle()] + fuelSettings.refuel
            usedVehicles[currentVehicle()] = current.FuelLevel
        end
        if (current.FuelLevel > current.TankSize) then 
            current.FuelLevel = current.TankSize
            if fuelSettings.refuellingRepairs then
                vehicle.set_vehicle_fixed(currentVehicle())
			    vehicle.set_vehicle_engine_health(currentVehicle(), 1000)
            end
        end
    end
end

local function drawFuelBar()
    if not fuelSettings.originalDisplayMode then
        local posX = fuelSettings.posX
        local posY = fuelSettings.posY
        local fuelCol = RGBAToInt(255, 255, 255, 255)
        local fuelPos = v2(posX, posY)

        local fuelColor = "orange"
        if current.FuelLevel * 100 / current.TankSize <= 15 then fuelColor = "red"
        elseif current.FuelLevel * 100 / current.TankSize >= 75 then fuelColor = "green" end

        local FuelPercentage = Round(current.FuelLevel * 100 / current.TankSize, 0)
        if FuelPercentage > 100 then FuelPercentage = 100 end
        drawText(math.floor(FuelPercentage) .. "%", fuelSettings.textposX, fuelSettings.textposY, 0, fuelSettings.textscale, Colour[fuelColor].r, Colour[fuelColor].g, Colour[fuelColor].b, true, false)
        local fuelType = "fuel"
        if IS_ELECTRIC() then fuelType = "electric" end
        local sprite = fuelSprite[fuelType][fuelColor]
        scriptdraw.draw_sprite(sprite, fuelPos, fuelSettings.scale, 0, fuelCol)
    else
        local fuelType = "Fuel"
        if IS_ELECTRIC() then fuelType = "Battery" end
        if current.FuelLevel * 100 / current.TankSize <= 15 then
            drawText(string.format("Low " .. fuelType .. ": %i/%i", Round(current.FuelLevel, 0), current.TankSize), 0.5, 0.96, 0, 0.3, Colour.white.r, Colour.white.g, Colour.white.b, true, false)
            drawRect(0.5, 0.99, (current.FuelLevel * 100 / current.TankSize) / 400, 0.015, Colour.red)
        elseif current.FuelLevel * 100 / current.TankSize >= 75 then
            drawText(string.format(fuelType .. ": %i/%i", Round(current.FuelLevel, 0), current.TankSize), 0.5, 0.96, 0, 0.3, Colour.white.r, Colour.white.g, Colour.white.b, true, false)
            drawRect(0.5, 0.99, (current.FuelLevel * 100 / current.TankSize) / 400, 0.015, Colour.green)
        else
            drawRect(0.5, 0.99, (current.FuelLevel * 100 / current.TankSize) / 400, 0.015, Colour.orange)
            drawText(string.format(fuelType .. ": %i/%i", Round(current.FuelLevel, 0), current.TankSize), 0.5, 0.96, 0, 0.3, Colour.white.r, Colour.white.g, Colour.white.b, true, false)
        end
    end
end

local function CanRefuelManually()
    if usedVehicles[current.latestHash] < current.TankSize and ped.get_current_ped_weapon(player.get_player_ped(player.player_id())) == 883325847 and
    Get_Distance_Between_Coords(player.get_player_coords(player.player_id()), player.get_player_coords(player.player_id())) <= 1 then
        return true else return false end
end

local function MANUAL_REFUELLING()
    if (IsDriving() == false) then
        if (CanRefuelManually() == true) then
            local ammo = native.call(0x015A522136D7F951, player.player_ped(), 883325847):__tointeger()
            if fuelSettings.useJerryCanFuel and ammo > 0 then 
                weapon.set_ped_ammo(player.player_ped(), 883325847, ammo - (10 * fuelSettings.manualRefuelConsumption)) 
                usedVehicles[current.latestHash] = usedVehicles[current.latestHash] + fuelSettings.manualRefuel
                if (usedVehicles[current.latestHash] > current.TankSize) then usedVehicles[current.latestHash] = current.TankSize end
            elseif not fuelSettings.useJerryCanFuel then
                usedVehicles[current.latestHash] = usedVehicles[current.latestHash] + fuelSettings.manualRefuel
                if (usedVehicles[current.latestHash] > current.TankSize) then usedVehicles[current.latestHash] = current.TankSize end
            end

            local fuel_level = Round(usedVehicles[current.latestHash] * 100 / current.TankSize, 0)
            if fuelMod_threads["manualrefuel_thread"] == nil then
                fuelMod_threads["manualrefuel_thread"] = menu.create_thread(function()
                    while current.status == true do
                        MANUAL_REFUELLING()
                        system.yield(500)
                        menu.delete_thread(fuelMod_threads["manualrefuel_hud_thread"])
                        fuelMod_threads["manualrefuel_hud_thread"] = nil
                    end
                end, nil)
            end
            if fuelMod_threads["manualrefuel_hud_thread"] == nil then
                fuelMod_threads["manualrefuel_hud_thread"] = menu.create_thread(function()
                    while current.status == true do
                        drawText("Vehicle refuelled at ".. fuel_level .."%", 0.5, 0.96, 0, 0.3, Colour.white.r, Colour.white.g, Colour.white.b, true, false)
                        system.yield(0)
                    end
                end, nil)
            end
        else
            if fuelMod_threads["manualrefuel_thread"] ~= nil then 
                menu.delete_thread(fuelMod_threads["manualrefuel_thread"])
                fuelMod_threads["manualrefuel_thread"] = nil 
            end
            if fuelMod_threads["manualrefuel_hud_thread"] ~= nil then 
                menu.delete_thread(fuelMod_threads["manualrefuel_hud_thread"])
                fuelMod_threads["manualrefuel_hud_thread"] = nil
            end
        end
    end
end

local function fuelMod()
    if (IsDriving() and isInSupportVehicle()) then
        if IS_ELECTRIC() then current.TankSize = fuelConsumption.electrics[2]
        else current.TankSize = fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][2] end
        UPDATE_VEHICLE_DB()
        fuelLevelDecreaseLevel()
        current.latestHash = currentVehicle()
    end
end

FUELMOD.parent['MAIN'] = menu.add_feature("#FF007FF5#Realistic FuelMod v" .. FUELMOD.VERSION, "parent", 0).id

FUELMOD.feature['REALISTIC FUELMOD'] = menu.add_feature("Realistic FuelMod", "toggle", FUELMOD.parent['MAIN'], function(f)
    if (f.on) then
        current.status = true
        if fuelMod_threads["loop_thread"] == nil then
            fuelMod_threads["loop_thread"] = menu.create_thread(function()
                while f.on do
                    fuelMod()
                    system.yield(1500)
                end
            end, nil)
        end
        if fuelMod_threads["disable_vehicle_thread"] == nil then
            fuelMod_threads["disable_vehicle_thread"] = menu.create_thread(function()
                while f.on do
                    if IsDriving() and isInSupportVehicle() and current.FuelLevel <= 0 then vehicle.set_vehicle_engine_on(currentVehicle(), false, true, true) end
                    system.yield(0)
                end
            end, nil)
        end
        if fuelMod_threads["refuel_thread"] == nil then
            fuelMod_threads["refuel_thread"] = menu.create_thread(function()
                while f.on do
                    if IsDriving() and isInSupportVehicle() then
                        UPDATE_VEHICLE_DB()
                        fuelLevelIncreaseLevel()
                    else
                        if not isEmpty(current.latestHash) then MANUAL_REFUELLING() else 
                            if fuelMod_threads["manualrefuel_thread"] ~= nil then 
                                menu.delete_thread(fuelMod_threads["manualrefuel_thread"])
                                fuelMod_threads["manualrefuel_thread"] = nil 
                            end
                            if fuelMod_threads["manualrefuel_hud_thread"] ~= nil then 
                                menu.delete_thread(fuelMod_threads["manualrefuel_hud_thread"])
                                fuelMod_threads["manualrefuel_hud_thread"] = nil
                            end
                        end
                    end
                    system.yield(250)
                end
            end, nil)
        end
        if fuelMod_threads["hud_thread"] == nil then
            fuelMod_threads["hud_thread"] = menu.create_thread(function()
                while f.on do
                    if IsDriving() and isInSupportVehicle() and fuelConsumption[vehicle.get_vehicle_class(currentVehicle())][1] > 0 then
                        drawFuelBar()
                        --drawFuelMarkers()
                    end
                    system.yield(0)
                end
            end, nil)
        end
        system.wait(0)
    end
    if not f.on then
        current.status = false
        if fuelMod_threads["loop_thread"] ~= nil then 
            menu.delete_thread(fuelMod_threads["loop_thread"])
            fuelMod_threads["loop_thread"] = nil
        end
        if fuelMod_threads["disable_vehicle_thread"] ~= nil then 
            menu.delete_thread(fuelMod_threads["disable_vehicle_thread"])
            fuelMod_threads["disable_vehicle_thread"] = nil
        end
        if fuelMod_threads["refuel_thread"] ~= nil then 
            menu.delete_thread( fuelMod_threads["refuel_thread"])
            fuelMod_threads["refuel_thread"] = nil
        end
        if fuelMod_threads["hud_thread"] ~= nil then 
            menu.delete_thread(fuelMod_threads["hud_thread"])
            fuelMod_threads["hud_thread"] = nil
        end
    end
    return HANDLER_CONTINUE
end)

FUELMOD.parent['SETTINGS'] = menu.add_feature("UI settings", "parent", FUELMOD.parent['MAIN']).id

-- DISPLAY MODE
FUELMOD.feature['ORIGINAL DISPLAY MODE'] = menu.add_feature("Original display mode", "toggle", FUELMOD.parent['SETTINGS'], function(f)
    if f.on then fuelSettings.originalDisplayMode = true
    else fuelSettings.originalDisplayMode = false end
end)
FUELMOD.feature['ORIGINAL DISPLAY MODE'].hint = "The design of the orginal display mode is not editable."

-- UI POSITION
FUELMOD.feature['ICON POS X'] = menu.add_feature("Position X", "autoaction_value_i", FUELMOD.parent['SETTINGS'], function(f)
    fuelSettings.posX = f.value / 1000
end)
SetFeatureValues(FUELMOD.feature['ICON POS X'], -1000, 1000, 5)

FUELMOD.feature['ICON POS Y'] = menu.add_feature("Position Y", "autoaction_value_i", FUELMOD.parent['SETTINGS'], function(f)
    fuelSettings.posY = f.value / 1000
end)
SetFeatureValues(FUELMOD.feature['ICON POS Y'], -1000, 1000, 5)

-- UI SCALE
FUELMOD.feature['ICON SCALE'] = menu.add_feature("Icon scale", "autoaction_slider", FUELMOD.parent['SETTINGS'], function(f)
    fuelSettings.scale = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['ICON SCALE'], 0, 2, 0.05)

-- TEXT POSITION
FUELMOD.feature['TEXT POS X'] = menu.add_feature("Text position X", "autoaction_value_i", FUELMOD.parent['SETTINGS'], function(f)
    fuelSettings.textposX = f.value / 1000
end)
SetFeatureValues(FUELMOD.feature['TEXT POS X'], 0, 1000, 5)

FUELMOD.feature['TEXT POS Y']  = menu.add_feature("Text position Y", "autoaction_value_i", FUELMOD.parent['SETTINGS'], function(f)
    fuelSettings.textposY = f.value / 1000
end)
SetFeatureValues(FUELMOD.feature['TEXT POS Y'] , 0, 1000, 5)

-- TEXT SCALE
FUELMOD.feature['TEXT SCALE'] = menu.add_feature("Text scale", "autoaction_slider", FUELMOD.parent['SETTINGS'], function(f)
    fuelSettings.textscale = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['TEXT SCALE'], 0, 2, 0.05)

-- REFILL RANGE
FUELMOD.feature['REFILL RANGE'] = menu.add_feature("Refill range in stations", "autoaction_slider", FUELMOD.parent['MAIN'], function(f)
    fuelSettings.stationsRange = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['REFILL RANGE'], 2.5, 10, 0.5)

-- REFUEL POWER
FUELMOD.feature['REFUEL POWER'] = menu.add_feature("Refuelling power", "autoaction_value_f", FUELMOD.parent['MAIN'], function(f)
    fuelSettings.refuel = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['REFUEL POWER'], 0.05, 2.50, 0.05)

-- MANUAL REFUEL POWER
FUELMOD.feature['MANUAL REFUEL POWER'] = menu.add_feature("Manual refuelling power", "autoaction_value_f", FUELMOD.parent['MAIN'], function(f)
    fuelSettings.manualRefuel = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['MANUAL REFUEL POWER'], 0.05, 2.50, 0.05)

-- MANUAL REFUEL FUEL CONSUMPTION
FUELMOD.feature['MANUAL REFUEL FUEL CONSUMPTION'] = menu.add_feature("Manual refuel fuel consumption", "autoaction_value_f", FUELMOD.parent['MAIN'], function(f)
    fuelSettings.manualRefuelConsumption = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['MANUAL REFUEL FUEL CONSUMPTION'], 0.05, 2.50, 0.05)

-- CONSUMPTION RATE
FUELMOD.feature['CONSUMPTION RATE'] = menu.add_feature("Fuel consumption rate", "autoaction_value_f", FUELMOD.parent['MAIN'], function(f)
    fuelSettings.consumptionRate = Round(f.value, 2)
end)
SetFeatureValues(FUELMOD.feature['CONSUMPTION RATE'], 0.1, 2.5, 0.1)

FUELMOD.feature['SHOW BLIPS'] = menu.add_feature("Show Blips", "toggle", FUELMOD.parent['MAIN'], function(f)
    if f.on then 
        if fuelMod_threads["status_thread"] == nil then
            fuelMod_threads["status_thread"] = menu.create_thread(function()
                while f.on do
                    if IsFullyTransitionedIntoSession() and not FUELMOD.SESSION_ACTIVE then FUELMOD.SESSION_ACTIVE = true
                    elseif not IsFullyTransitionedIntoSession() and FUELMOD.SESSION_ACTIVE then
                        FUELMOD.SESSION_ACTIVE = false
                        print("Detected session switch, disabling blips")
                    else FUELMOD.SESSION_ACTIVE = false end

                    if FUELMOD.SESSION_ACTIVE then
                        clearBlips() 
                        drawFuelBlips()
                    end
                    system.yield(5000)
                end
            end, nil)
        end

    else
        if fuelMod_Blips ~= nil then clearBlips() end
        if fuelMod_threads["status_thread"] ~= nil then 
            menu.delete_thread(fuelMod_threads["status_thread"])
            fuelMod_threads["status_thread"] = nil
        end
    end
end)

FUELMOD.feature['REFUELLING REPAIRS'] = menu.add_feature("Repairs in stations", "toggle", FUELMOD.parent['MAIN'], function(f)
    if f.on then fuelSettings.refuellingRepairs = true
    else fuelSettings.refuellingRepairs = false end
end)

FUELMOD.feature['JERRY CAN FUEL'] = menu.add_feature("Use jerry can fuel", "toggle", FUELMOD.parent['MAIN'], function(f)
    if f.on then fuelSettings.useJerryCanFuel = true
    else fuelSettings.useJerryCanFuel = false end
end)

FUELMOD.feature['SAVE SETTINGS'] = menu.add_feature("Save settings", "action", FUELMOD.parent['MAIN'], SaveSettings)

require("fuelMod\\debug")
menu.create_thread(function()
    system.yield(10)
    FUELMOD.feature['SHOW BLIPS'].on = true
    FUELMOD.feature['REFUELLING REPAIRS'].on = true
	FUELMOD.feature['REALISTIC FUELMOD'].on = true
    local LOADED_SETTINGS = ""
    LoadSprites()
    LoadSettingsFromFile()
    UpdateMenuSettings()
    if FUELMOD.SETTINGS then LOADED_SETTINGS = " with saved settings" end
    notify(" Successfully loaded" ..  LOADED_SETTINGS .. ".", "#FF007FF5#" .. FUELMOD.NAME .. "#FFFFFFFF# v" .. FUELMOD.VERSION, nil, RGBAToInt(245, 128, 0, 255))
end, nil)