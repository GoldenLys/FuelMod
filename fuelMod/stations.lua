stationsList = {
    GroveStreet = v3(-67.300, -1761.404, 28.314),
    LindsayCircus = v3(-720.801, -934.966, 18.017),
    Davis = v3(172.266, -1563.212, 27.623),
    SandyShores = v3(2007.918, 3772.873, 30.533),
    Paleto = v3(174.811, 6601.134, 30.334),
    SenoraFreeway = v3(1702.809, 6418.350, 31.125),
    LittleSeoul = v3(-527.469, -1208.325, 16.671),
    PopularStreet = v3(821.748, -1028.274, 24.871),
    Harmony = v3(263.967, 2608.679, 44.269),
    MirrorPark = v3(1181.554, -332.793, 67.596),
    Morningwood = v3(-1430.680, -280.017, 44.627),
    Vinewood = v3(614.969, 264.504, 101.509),
    PacificBluffs = v3(-2099.512, -320.867, 11.523),
    LagoZancudo = v3(-2558.103, 2331.768, 31.558),
    SandyShoresAirfield = v3(1784.108, 3329.823, 39.769),
    --SandyShoresMotel = v3(1043.171, 2670.477, 38.046), no fuel pump
    SandyShoresLSC = v3(1209.234, 2662.301, 36.306),
    PalominoFreeway = v3(2578.465, 361.363, 106.955),
    --Grapeseed = v3(1688.766, 4929.291, 40.575), no fuel pump
    RichmanGlen = v3(-1802.732, 797.043, 137.010),
    Strawberry = v3(267.748, -1263.358, 27.640),
    ElBurroHeights = v3(1210.197, -1404.031, 33.721),
    LaPuerta = v3(-320.708, -1466.867, 29.043),
    EarlsMiniMart = v3(2676.836, 3263.114, 53.817),
    Road68MC = v3(86.27, 2777.767, 57.274),
    RonAlternates = v3(2537.963, 2594.558, 37.335),
    CascabelAvenue = v3(-93.789, 6419.835, 30.879)
}

PumpModels = { 
    [3832150195] = true,
    [2287735495] = true,
    [1339433404] = true, 
    [1694452750] = true, 
    [1933174915] = true, 
    [3825272565] = true,
    [4130089803] = true,
    --[-2007231801] = true, prop_gas_pump_1d   unused
    --[-462817101] = true,  prop_vintage_pump  unused
    --[-469694731] = true,  prop_gas_pump_old2 unused
    --[-164877493] = true   prop_gas_pump_old3 unused
}

function drawBlip(pos)
    local blip = ui.add_blip_for_coord(pos)
    ui.set_blip_sprite(blip, 361)
    ui.set_blip_colour(blip, 23)
    native.call(0xBE8BE4FE60E27B72, blip, true)
    native.call(0xF9113A30DE5C6670, "STRING")
    native.call(0x6C188BE134E074AA, "Gas Station")
    native.call(0xBC38B49BCB83BC9B, blip)
    return blip
end

fuelMod_Blips = {}
function drawFuelBlips()
    local BlipsCount = 0;
    for name, coords in pairs(stationsList) do
        fuelMod_Blips[BlipsCount] = drawBlip(coords)
        BlipsCount = BlipsCount + 1
    end
end

function drawFuelMarkers()
    for name, coords in pairs(stationsList) do
        graphics.draw_marker(1, coords, v3(0, 0, 0), v3(0, 0, 0), v3(2, 2, 2), 240, 200, 80, 200, false, true, 2, false, nil, "MarkerTypeVerticalCylinder", false)
    end
end

function clearBlips()
    if not is_table_empty(fuelMod_Blips) then
        for i = 0, #fuelMod_Blips do
            ui.remove_blip(fuelMod_Blips[i])
        end
    end
end
event.add_event_listener("exit", function()
    if not is_table_empty(fuelMod_Blips) then
        menu.notify("Clearing " .. #fuelMod_Blips .. " blips...")
        for i = 0, #fuelMod_Blips do
            ui.remove_blip(fuelMod_Blips[i])
            --menu.notify("Cleared blip " .. fuelMod_Blips[i] .. ".")
        end
    end
end)

function nearestPump(coords)
    local objects = object.get_all_objects()
    local last_distance = 1000
    local pump = {coords = {}, hash = nil}
    for object=1,#objects do
        local distance = Get_Distance_Between_Coords(player.get_player_coords(player.player_id()), entity.get_entity_coords(objects[object]))
        if objects[object] ~= nil and distance <= fuelSettings.stationsRange then 
            for hash in pairs(PumpModels) do
                if entity.get_entity_model_hash(objects[object]) == hash and distance <= distance then 
                    last_distance = distance
                    pump.hash = entity.get_entity_model_hash(objects[object])
                    pump.coords = entity.get_entity_coords(objects[object])
                end
            end
        end
    end 
    if PumpModels[pump.hash] then return pump.coords end
end