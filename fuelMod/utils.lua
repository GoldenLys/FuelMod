Colour = {
	green = {r=5, g=245, b=50, a=255},
	white = {r=255, g=255, b=255, a=255},
	black = {r=0, g=0, b=0, a=150},
	blue = {r=137, g=196, b=244, a=255},
	orange = {r=245, g=128, b=0, a=255},
	orange2 = {r=243, g=156, b=18, a=255},
	red = {r=245, g=5, b=50, a=255}
}

function notify(msg, title, seconds, color)
    title = title or FUELMOD.NAME
    seconds = seconds or 5
    color = color or RGBAToInt(245, 128, 0, 255)
    menu.notify(msg, title, seconds, color)
    print(msg)
end

function RGBAToInt(Red, Green, Blue, Alpha)
    Alpha = Alpha or 255
    return (Red & 0xff) | (Green & 0xff) << 8 | (Blue & 0xff) << 16 | (Alpha & 0xff) << 24
end

function drawRect(x, y, width, height, colour) ui.draw_rect(x, y, width, height, colour.r, colour.g, colour.b, colour.a) end

function drawText(text, x, y, font, scale, R, G, B, center, alignRight)
	ui.set_text_color(R, G, B, 255)
	ui.set_text_font(font)
	ui.set_text_scale(scale, scale)
	ui.set_text_outline(1)
	if center then ui.set_text_centre(true)
    elseif alignRight then ui.set_text_right_justify(true) end
	ui.draw_text(tostring(text), v2(x, y))
end

function SaveSettings()
    local file = io.open(PATHS.Settings, "w")
    file:write("ShowBlips=" .. tostring(FUELMOD.feature['SHOW BLIPS'].on) .. "\n")
    for k, v in pairs(fuelSettings) do
        file:write(k .. "=" .. tostring(v) .. "\n")
    end
    
    file:close()
    notify("Saved settings", nil, nil, RGBAToInt(245, 128, 0, 255))
end

function LoadSettingsFromFile()
	if not utils.file_exists(PATHS.Settings) then return end
	for line in io.lines(PATHS.Settings) do
		local separator = line:find("=", 1, true)
		if separator then
            local key, value = line:sub(1, separator - 1), line:sub(separator + 1)
            if key == "ShowBlips" then 
                FUELMOD.feature['SHOW BLIPS'].on = (value == "true" and true) or (value == "false" and false)
            else 
                fuelSettings[tonumber(key) or key] = tonumber(value) or (value == "true" and true) or (value == "false" and false)
            end
		end
	end
    FUELMOD.SETTINGS = true
end

function UpdateMenuSettings()
    FUELMOD.feature['REFUEL POWER'].value = fuelSettings.refuel
    FUELMOD.feature['MANUAL REFUEL POWER'].value = fuelSettings.manualRefuel
    FUELMOD.feature['CONSUMPTION RATE'].value = fuelSettings.consumptionRate
    FUELMOD.feature['REFILL RANGE'].value = fuelSettings.stationsRange
    FUELMOD.feature['ICON POS X'].value = fuelSettings.posX * 1000
    FUELMOD.feature['ICON POS Y'].value = fuelSettings.posY * 1000
    FUELMOD.feature['ICON SCALE'].value = fuelSettings.scale
    FUELMOD.feature['TEXT POS X'].value = fuelSettings.textposX * 1000
    FUELMOD.feature['TEXT POS Y'].value = fuelSettings.textposY * 1000
    FUELMOD.feature['TEXT SCALE'].value = fuelSettings.textscale
    FUELMOD.feature['ORIGINAL DISPLAY MODE'].on = fuelSettings.originalDisplayMode
    FUELMOD.feature['REFUELLING REPAIRS'].on = fuelSettings.refuellingRepairs
    FUELMOD.feature['JERRY CAN FUEL'].on = fuelSettings.useJerryCanFuel
    FUELMOD.feature['MANUAL REFUEL FUEL CONSUMPTION'].value = fuelSettings.manualRefuelConsumption
end

function LoadSprites()
    for k,v in pairs(spritelist.electric) do
        fuelSprite.electric[k] = scriptdraw.register_sprite(v)
    end
    for k,v in pairs(spritelist.fuel) do
        fuelSprite.fuel[k] = scriptdraw.register_sprite(v)
    end
end

function SetFeatureValues(feature, min, max, mod)
    feature.min = min
    feature.max = max
    feature.mod = mod
end

function is_table_empty(tbl)
    for _, _ in pairs(tbl) do
        return false
    end
    return true
end

function Draw3DText(x, y, z, text)
	local onScreen,_x,_y=native.call(0x34E82F05DF2974F5,x,y,z,graphics.get_screen_width(),graphics.get_screen_height()):__tointeger() --GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(x,y,z)
	if onScreen then
        ui.set_text_scale(0.35, 0.35)
        ui.set_text_font(4)
        ui.set_text_color(255, 255, 255, 215)
        ui.set_text_centre(true)

        ui.draw_text(tostring(text), v2(_x, _y))
	end
end

function isEmpty(search)
    return search == nil or search == ''
end

function Get_Distance_Between_Coords(first, second)
    local x = second.x - first.x
    local y = second.y - first.y
    local z = second.z - first.z
    return math.sqrt(x * x + y * y + z * z)
end

function GetDistanceBetweenCoords(pos1, pos2)
    return math.abs(pos1:magnitude(pos2))
end

function IsFullyTransitionedIntoSession()
    return script.get_global_i(1574993) == 66 or native.call(0x49C32D60007AFA47, player.player_id())
 end