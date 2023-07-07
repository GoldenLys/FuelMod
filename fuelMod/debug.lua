--FUELMOD.parent['DEBUG'] = menu.add_feature("Debug", "parent", FUELMOD.parent['MAIN']).id


--menu.add_feature("Force refuel", "action", FUELMOD.parent['DEBUG'], function() 
--    usedVehicles[ped.get_vehicle_ped_is_using(player.get_player_ped(player.player_id()))] = current.TankSize
--    current.FuelLevel = current.TankSize
--end)

---menu.add_feature("Force empty tank ", "action", FUELMOD.parent['DEBUG'], function() 
--    usedVehicles[ped.get_vehicle_ped_is_using(player.get_player_ped(player.player_id()))] = 0
--    current.FuelLevel = 0
--end)

--menu.add_feature("Can refuel ?", "action", FUELMOD.parent['DEBUG'], function() 
--    notify("Can refuel : " .. tostring(CAN_REFUEL_CHECK()), nil, nil, RGBAToInt(245, 128, 0, 255))
--end)

--menu.add_feature("Get nearest pump", "action", FUELMOD.parent['DEBUG'], function() 
--    nearPump = nearestPump(player.get_player_coords(player.player_id()))
--    if nearPump ~= nil then notify(Round(Get_Distance_Between_Coords(player.get_player_coords(player.player_id()), nearestPump(player.get_player_coords(player.player_id()))), 1) .. "m away from a pump", nil, nil, RGBAToInt(245, 128, 0, 255))
--    else notify("You are too far away from any pump.", nil, nil, RGBAToInt(245, 128, 0, 255)) end
--end)
