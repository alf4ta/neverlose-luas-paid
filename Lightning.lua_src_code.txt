local ffi = require("ffi")
ffi.cdef[[
    typedef int(__fastcall* clantag_t)(const char*, const char*);

    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);
    typedef struct 
    {
        float x;
        float y;
        float z;
    } Vector_t;

    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;

    void* GetProcAddress(void* hModule, const char* lpProcName);
    void* GetModuleHandleA(const char* lpModuleName);
    
    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;

    typedef void (*console_color_print)(const color_struct_t&, const char*, ...);
]]

local got_edgeyaw = false

local ENTITY_LIST_POINTER = ffi.cast("void***", utils.CreateInterface("client.dll", "VClientEntityList003")) or error("Failed to find VClientEntityList003!")
local GET_CLIENT_ENTITY_FN = ffi.cast("GetClientEntity_4242425_t", ENTITY_LIST_POINTER[0][3])

local ffi_helpers = {
    get_entity_address = function(entity_index)
        local addr = GET_CLIENT_ENTITY_FN(ENTITY_LIST_POINTER, entity_index)
        return addr
    end
}

local ffi_helpers1 = {
    color_print_fn = ffi.cast("console_color_print", ffi.C.GetProcAddress(ffi.C.GetModuleHandleA("tier0.dll"), "?ConColorMsg@@YAXABVColor@@PBDZZ")),
    color_print = function(self, text, color)
        local col = ffi.new("color_struct_t")

        col.g = color:g() * 255
        col.b = color:b() * 255
        col.a = color:a() * 255

        self.color_print_fn(col, text)
    end 
}

local function coloredPrint(color, text)
	ffi_helpers.color_print(ffi_helpers, text, color)
end

local indicators = {
	doubletap = false,
	hideshots = false,
	quickpeek = false,
	fakeduck = false,
	bodyaim = false,
	safepoints = false,
	minimum_dmg = false,
	edgeyaw = false,
	manual_aa = false,
	minimum_dmg_value = 0,
}

local set_clantag = ffi.cast("clantag_t", utils.PatternScan("engine.dll", "53 56 57 8B DA 8B F9 FF 15", 0))

local tag = {
    "L",
    "Li",
    "Lig",
    "Ligh",
    "Light",
    "Lightn",
    "Lightni",
    "Lightnin",
    "Lightning",
    "Lightning",
    "ϟLightningϟ",
    "Lightning",
    "ϟLightningϟ",
    "Lightning",
    "ϟLightningϟ",
    "Lightning",
    "Lightnin",
    "Lightni",
    "Lightn",
    "Light",
    "Ligh",
    "Lig",
    "Li",
    "L",
    ""
}

local dt_stuff = {
	cached_fakelag = false,
	cached_fakelag_amount = 0,
	cache_fakelag_randomize = 0,
	should_cache = true,
}


local globals = {
    visuals = {
        indicators = { "Arrows", "Double Tap", "Hide Shots", "Fake Duck", "Min Damage", "Body Aim", "Safe Points", "Auto Peek" },
        font = g_Render:InitFont("", 14),
        brand_font = g_Render:InitFont("000webfont", 16),
        font_selection = { "Lightning", "Arial Bold", "Verdana", "Arial", "Tahoma", "Custom" }
    }
}

local username = cheat.GetCheatUserName()

menu.Text("Lightning.lua", "Hello " .. username .. "!")
menu.Text("Lightning.lua", "discord.gg/dangeroustechnology")
menu.Text("Lightning.lua", "Join discord and create a ticket to get your roles")
menu.Text("Lightning.lua", "Owner : Domcsy#6982")
menu.Text("Lightning.lua", "Website: dangeroustechnology.pro")
menu.Text("Dangerous.Technology", "Enhance your game by purchasing Dangerous.Technology Lua")
menu.Text("Dangerous.Technology", "Please join our discord to receive further support")
local up2date = ""
if script_version == version then up2date = "Your version is up-to-date - Join our discord if you encounter any issues regarding the lua" else up2date = "Your version is outdated - Contact Domcsy#6982" end
if up2date then menu.Text("Lightning Informations - Lua Status", up2date) else menu.Text("Lightning Informations - Lua Status", "ERROR") end

cheat.AddNotify("Lightning.lua", "Welcome, " .. username .. " ")


--Don't call it in an local function, so it's only getting called 1time if you load the lua.
local w1 = ("           WELCOME TO LIGHTNING.LUA!")
local w2 = ("MAKE SURE TO JOIN OUR DISCORD FOR THE BEST SETTINGS")
local w2 = ("discord.gg/dangeroustechnology")
local username = cheat.GetCheatUserName():upper()
cheat.AddNotify("Lightning.lua", "Welcome back " .. username .. " Build version: [LIVE]" )

g_EngineClient:ExecuteClientCmd("clear")


--Antiaim
local antiaim_enable = menu.Switch("Lightning | Anti-Aimbot Angles", "Enable Anti-Aimbot Angles", false, "Main switch for Anti Aims")
local antiaim_modes = menu.Combo("Lightning | Anti-Aimbot Angles", "Anti-Aim Modes", {"Default", "Aggressive", "Defensive"}, 0, "")
local antiaim_antibrute = menu.Combo("Lightning | Anti-Aimbot Angles", "Anti Bruteforce", {"Off", "Normal", "3 Modes"}, 0, "")
local legitaa = menu.Switch("Lightning | Anti-Aimbot Angles", "Legit AA", false, "Legit AA while you hold E")
local edgeyaw = menu.Switch("Lightning | Anti-Aimbot Angles", "Edge-Yaw", false, "Looks at the nearest wall")
local avoidknife = menu.Switch("Lightning | Anti-Aimbot Angles", "Avoid Backstab", false)
	
	
local is_scout = false
	
--antiaim refs
local freestand_desync = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Freestanding Desync")
local fake_option = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Fake Options")
local LBY_mode = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "LBY Mode")
local desync_onshot = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Desync On Shot")

--Doubletap
local doubletap_enable = menu.Switch("Lightning | Doubletap Manager", "Enable Doubletap Manager", false, "Main switch for Doubletap")
local doubletap_modes = menu.Combo("Lightning | Doubletap Manager", "Doubletap Modes", {"Instant", "Fast", "Default"}, 0, "Instant is recommended")
local doubletap_halfhp = menu.MultiCombo("Lightning | Doubletap Manager", "Force Lethal DMG", { "Auto", "Deagle" }, 0, "Halfs enemy hp and sets as min dmg when DT enabled")
local doubletap_dynamic_tele = menu.Switch("Lightning | Doubletap Manager", "Dynamic DT Teleport", false, "The ideal teleport for your DT")
	
local aimbot = {
	enable = menu.Switch("Lightning | Ragebot Optimizer", "Enable Ragebot Optimizer", false, "Enables ragebot features"),
	mode = menu.Combo("Lightning | Ragebot Optimizer", "Mode", {"Prefer", "Force"}, 0,  ""),
	prefer_head = menu.MultiCombo("Lightning | Ragebot Optimizer", "Prefer head", {"Standing", "Slowwalk", "Running", "In Air", "Holding E"}, 0, "Example: Prefers head on if enemy is running"),
	prefer_body = menu.MultiCombo("Lightning | Ragebot Optimizer", "Prefer body", {"Standing", "Slowwalk", "Running", "In Air", "Lethal", "Ducking", "Holding E"}, 0, "Example: Prefers body on if enemy is standing"),
	force_head = menu.MultiCombo("Lightning | Ragebot Optimizer", "Force head", {"Standing", "Slowwalk", "Running", "In Air", "Holding E"}, 0, "Example: Prefers head on if enemy is running"),
	force_body = menu.MultiCombo("Lightning | Ragebot Optimizer", "Force body", {"Standing", "Slowwalk", "Running", "In Air", "Lethal", "Ducking", "Holding E"}, 0, "Example: Prefers body on if enemy is standing"),	
}
	
--Visuals
local visuals_enable = menu.Switch("Lightning | Visual Adjustments", "Enable Visual Adjustments", false, "Main switch for Visuals")
local var_clantag = menu.Switch("Lightning | Visual Adjustments", "Clantag", false, "ϟLightningϟ")
local c_indicators_style = menu.Combo("Lightning | Visual Adjustments", "Indicator Style", { "IDEAL YAW", "Lightning V2", "Invictus" }, 1)
local mc_indicators = menu.MultiCombo("Lightning | Visual Adjustments", "Indicators", globals.visuals.indicators, 0)
local i_indicators_base = menu.SliderInt("Lightning | Visual Adjustments", "Indicator Base", 15, 0, 100, "Y Axis")
local i_indicators_size = menu.SliderInt("Lightning | Visual Adjustments", "Indicator Size", 12, 8, 24, "Font Size")
local i_indicators_font = menu.ComboColor("Lightning | Visual Adjustments", "Font", globals.visuals.font_selection, 0, Color.new(0.1, 0.5, 0.8, 1.0))
local i_indicators_custom_font = menu.TextBox("Lightning | Visual Adjustments", "Custom Font", 255, "")
local i_arrow_base = menu.SliderInt("Lightning | Visual Adjustments", "Arrow Base", 16, 10, 50, "X Axis")
local i_arrow_size = menu.SliderInt("Lightning | Visual Adjustments", "Arrow Size", 30, 20, 50, "Font Size")
local b_indicators_update_font = menu.Button("Lightning | Visual Adjustments", "Update", "Updates Indicator size, font and more")
local display_mindmg = menu.Switch("Lightning | Visual Adjustments", "Min Dmg", false, "Min Dmg")
local desync_clr = menu.ColorEdit("Lightning | Visual Adjustments", "Desync colour primary", Color.new(1.0, 1.0, 1.0, 1.0), "asd")
local desync_clr2 = menu.ColorEdit("Lightning | Visual Adjustments", "Desync colour secondary", Color.new(1.0, 1.0, 1.0, 1.0), "asd")
local watermark_clr = menu.SwitchColor("Lightning | Visual Adjustments", "Watermark", false, Color.new( 255/255,255/255,255/255 ) )
local watermark_options = menu.MultiCombo("Lightning | Visual Adjustments", "Watermark display", {"IP", "Ping", "Tick", "Fps"}, 0, "Tooltip")

--Misc
local misc_enable = menu.Switch("Lightning | Miscellaneous", "Enable Miscellaneous", false, "Main switch for Misc")
local c_menu_kill_say = menu.Switch("Lightning | Miscellaneous", "Kill Say", false, "Types in chat Automatically upon killing someone")
local c_menu_kill_say_words = menu.TextBox("Lightning | Miscellaneous", "Kill Say Text", 64, "Type here..", "Types in chat Automatically upon killing someone")
local c_leg_fucker = menu.Switch("Lightning | Miscellaneous", "Feet Yaw Breaker", false, "Leg Fucker")

local font = g_Render:InitFont("Verdana",12)
	
-- INDICATORS FUNCTION
local indicators = {
    list = {},
    binds = {},

    _add = function(self, indicator)
        if not self:_check(indicator) then
            table.insert(self.list, indicator)
        end
    end,

    _check = function(self, indicator)
        local index = 0

        for k, v in pairs(self.list) do
            if v.name == indicator.name then
                index = k
                return index
            end
        end

        return false
    end,

    _check_binds = function(self, name)

        local index = 0

        for k, v in pairs(self.binds) do
            if v:GetName() == name then
                index = k
                return index
            end
        end

        return false

    end,

    _remove = function(self, indicator, pos)
        if pos == nil then
            local highest_index = 0

            for k, v in pairs(self.list) do
                if v.name == indicator.name then
                    highest_index = k
                end
            end

            if highest_index > 0 then
                table.remove(self.list, highest_index)
            end

        else
            table.remove(self.list, pos)
        end
    end,

    _add_or_remove = function(self)
        for i = 1, #globals.visuals.indicators do
            local name = globals.visuals.indicators[i]
            local cheatvar = mc_indicators:GetBool(i - 1)
    
            local indicator = {
                name = name
            }
    
            if cheatvar then self:_add(indicator)
            else self:_remove(indicator) end
        end
    end,

    _add_or_remove_bind = function(self)

    end
}
-- INDICATORS FUNCTION END 

local mathemathics = {
    _deg2rad = function(self, x)
        return x * (math.pi / 180.0)
    end,

    _rotated_position = function(self, start, rotation, distance)
        local rad = self:_deg2rad(rotation)
        local new_start = Vector.new(start.x, start.y, start.z)
        new_start.x = new_start.x + math.cos(rad) * distance
        new_start.y = new_start.y + math.sin(rad) * distance

        return new_start
    end,

    _color_truncate = function(self, value)
        if value < 0 then return 0 end
        if value > 255 then return 255 end
    
        return value
    end,

    _contrast = function(self, color, contrast)
        local factor = (259 * (contrast + 255)) / (255 * (259 - contrast))
        
        return Color.new(self:_color_truncate((factor * ((color:r() * 255) - 128) + 128)) / 255,
                        self:_color_truncate((factor * ((color:g() * 255) - 128) + 128)) / 255,
                        self:_color_truncate((factor * ((color:b() * 255) - 128) + 128)) / 255,
                        color:a())
    end,
}

var_clantag:RegisterCallback(function()

    if not var_clantag:GetBool() then
        set_clantag("", "")
        var_clantag:SetTooltip("ϟLightningϟ")
    end

end)


local i_indicators_font_callback = function()
    i_indicators_custom_font:SetVisible(i_indicators_font:GetInt() == #globals.visuals.font_selection - 1)
end
i_indicators_font:RegisterCallback(i_indicators_font_callback)
i_indicators_font_callback()

b_indicators_update_font_callback = function()

    local size = i_indicators_size:GetInt()
    
    if i_indicators_font:GetInt() == #globals.visuals.font_selection - 1 then
        globals.visuals.font = g_Render:InitFont(i_indicators_custom_font:GetString(), size)
        globals.visuals.brand_font = g_Render:InitFont(i_indicators_custom_font:GetString(), size + 2)
    else
        if i_indicators_font:GetInt() == 0 then
            globals.visuals.font = g_Render:InitFont("000webfont", size)
            globals.visuals.brand_font = g_Render:InitFont("000webfont", size + 2)
        else
            globals.visuals.font = g_Render:InitFont(globals.visuals.font_selection[i_indicators_font:GetInt() + 1], size)
            globals.visuals.brand_font = g_Render:InitFont(globals.visuals.font_selection[i_indicators_font:GetInt() + 1], size + 2)
        end
    end
end
b_indicators_update_font:RegisterCallback(b_indicators_update_font_callback)
b_indicators_update_font_callback()

local var = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base")
local var36 = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Pitch")
local last_pitch = var36:GetInt()
local last_yaw = var:GetInt()

local was_in_use = false

local function legit_aa(cmd)
    if bit.band(cmd.buttons, bit.lshift(1,5)) ~= 0 and legitaa:GetBool() then
        cmd.buttons = bit.band(cmd.buttons, bit.bnot(bit.lshift(1,5)))
        was_in_use = true
    else
        was_in_use = false
    end
end

local wasinattack6 = 0

local antiaim_stuff = {
	limit = 0,
	yaw = 0,
	lby = 0,
	jitter = false,
}
	
local function get_velocity(player)
	x = player:GetProp("DT_BasePlayer", "m_vecVelocity[0]")
	y = player:GetProp("DT_BasePlayer", "m_vecVelocity[1]")
	z = player:GetProp("DT_BasePlayer", "m_vecVelocity[2]")
	if x == nil then return end
	return math.sqrt(x*x + y*y + z*z)
end

local function condition(entity)
	local speed = math.floor(get_velocity(entity))
	local duck_amount = entity:GetProp("DT_BasePlayer", "m_flDuckAmount")
	local m_fFlags = entity:GetProp("DT_BasePlayer", "m_fFlags")
	--standing
	if (speed <= 2) then
		return 1
	end
	--slowwalking
	if speed <= 100 and speed > 2 then
		return 2
	end
	--running
	if speed > 100 then
		return 3
	end
	--ducking
	if duck_amount == 1 then
		return 4
	end
	return false
end
	
local checkhitbox = {0,11,12,13,14}

local function canseeentity(localplayer, entity)
    if not entity or not localplayer then return false end
    local canhit = false
    for k,v in pairs(checkhitbox) do
        local data = cheat.FireBullet(localplayer, localplayer:GetEyePosition(), entity:GetPlayer():GetHitboxCenter(v))
        if data.damage > 0 then 
            canhit = true
            break 
        end
    end
    return canhit
end

local in_bomb_site = false

cheat.RegisterCallback("events", function(event)
    if event:GetName() == "enter_bombzone" and event:GetInt("userid") == g_EngineClient:GetPlayerInfo(g_EngineClient:GetLocalPlayer()).userId then
        in_bomb_site = true
    end

    if event:GetName() == "exit_bombzone" and event:GetInt("userid") == g_EngineClient:GetPlayerInfo(g_EngineClient:GetLocalPlayer()).userId then
        in_bomb_site = false
    end
end)

--anti brute

--ANTIAIM
local function vec_distance(vec_one, vec_two)

    local delta_x, delta_y, delta_z = vec_one.x - vec_two.x, vec_one.y - vec_two.y

    return math.sqrt(delta_x * delta_x + delta_y * delta_y)

end

local function get_closest_enemy()
    local best_dist = 380.0
    local best_enemy = nil
    local local_player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
    local local_origin = local_player:GetProp("DT_BaseEntity", "m_vecOrigin")
    local local_screen_orig = g_Render:ScreenPosition(local_origin)
    local screen = g_EngineClient:GetScreenSize()

    for idx = 1, g_GlobalVars.maxClients + 1 do
        local ent = g_EntityList:GetClientEntity(idx)
        if ent and ent:IsPlayer() then
            local player = ent:GetPlayer()
            local health = player:GetProp("DT_BasePlayer", "m_iHealth")

            if not player:IsTeamMate() and health > 0 and not player:IsDormant() then
                local origin = ent:GetProp("DT_BaseEntity", "m_vecOrigin")
                local screen_orig = g_Render:ScreenPosition(origin)
                local temp_dist = vec_distance(Vector2.new(screen.x / 2, screen.y / 2), screen_orig)

                if(temp_dist < best_dist) then
                    best_dist = temp_dist
                    best_enemy = ent
                end
            end
        end
    end

    return best_enemy
end


local lines = {}
local results = {}

local function impacts_events(event)
    if event:GetName() == "bullet_impact" and event:GetInt("userid") == g_EngineClient:GetPlayerInfo(g_EngineClient:GetLocalPlayer()).userId then
        local localplayer = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        if localplayer then localplayer = localplayer:GetPlayer() else return end
        local position = localplayer:GetEyePosition()
        local destination = Vector.new(event:GetFloat("x"), event:GetFloat("y"), event:GetFloat("z"))
        table.insert(lines, {pos = position, destination = destination, time = 250, curtime = g_GlobalVars.curtime})
    end

    if event:GetName() == "player_hurt" then
        if event:GetInt("attacker") == g_EngineClient:GetPlayerInfo(g_EngineClient:GetLocalPlayer()).userId then
            for k,v in pairs(lines) do
                if v.curtime == g_GlobalVars.curtime then
                    table.insert(results, lines[k])
                    table.remove(lines, k)
                end
            end
        end
    end
end

local miss_counter = 0
local shot_time = 0

local function antibrute(e)

      if e:GetName() == "weapon_fire" and antiaim_antibrute:GetInt() ~= 0 and antiaim_enable:GetBool() then --Weapon Fire event later we run FOV check so we can make sure the bullet is on our direction!
        local user_id = e:GetInt("userid", -1)
        local user = g_EntityList:GetClientEntity(g_EngineClient:GetPlayerForUserId(user_id)) --Get Enemy Entity
        local local_player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()) --Get Local Entity
        local player = local_player:GetPlayer()
        local health = player:GetProp("DT_BasePlayer", "m_iHealth")
       
        if(health > 0) then -- if our local player is alive we run the AntiBrute Logic!
          	
            local closest_enemy = get_closest_enemy() --Get Closest enemy based on distance 
            if(closest_enemy ~= nil and user:EntIndex() == closest_enemy:EntIndex()) then 
              miss_counter = miss_counter + 1 --Basic so we calculate missed shots of enemy also some checks so if we get hit don't run the code!
			  shot_time = g_GlobalVars.curtime
            end
        end
    end
end
--ANTIAIM

local lastlegfucker = 0
local wasinattack = 0
local fuck_doubletap = false

--Let's do the antiaim stuff
local function on_createmove(cmd)

    local localplayer = g_EntityList:GetLocalPlayer()
    local getplayer = localplayer:GetPlayer()
    local active_weapon = getplayer:GetActiveWeapon()
    if not active_weapon then return end
    got_edgeyaw = false
    --connected check
    if not g_EngineClient:IsConnected() then
        return
    end

    --ingame check
    if not g_EngineClient:IsInGame() then
        return
    end

    --Shortif
    function shortif ( cond , T , F )
        if cond then return T else return F end
    end

    --You can modifie these menu valus by calling them	
    --g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Add"):SetInt(8) --For example

    --You can change you're fake limit over
    --g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Left Limit"):SetInt(60) 
    --g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Right Limit"):SetInt(60) 

    --Or if you want 2 do it like me:
    --antiaim.OverrideLimit(60.0)

    --You can also do that with yaw, pitch, lowerbody yaw etc
    --https://docs.neverlose.cc/developers/tables/antiaim#overridelimit
		
if antiaim_enable:GetBool() then	
	
    if was_in_use then
        if not fakelag.Choking() then
            var:SetInt(0)
            var36:SetInt(0)         
        end

        return
    end	
		
	local localPlayer = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
		if localPlayer == nil then return end
	
		local aa_type = antiaim_modes:GetInt()
		
		local local_m_lifeState = localPlayer:GetProp("DT_BasePlayer", "m_lifeState")
		if local_m_lifestate then return end
			local cond = condition(localPlayer)                   --check condition for local.
			local inverter = antiaim.GetInverterState()
			if shot_time + 2 > g_GlobalVars.curtime then
				if antiaim_antibrute:GetInt() == 1 then
					 if (miss_counter % 2 == 0) then --Logic 1
						antiaim.OverrideLimit(60.0)
						antiaim.OverrideYawOffset(4.0)
						antiaim.OverrideInverter(true)
		
					else if (miss_counter % 2 == 1) then --Logic 2 
						antiaim.OverrideInverter(false)
						antiaim.OverrideLimit(45.0)
					end
				end
				end
				if antiaim_antibrute:GetInt() == 2 then
					 if (miss_counter % 3 == 0) then --Logic 1
						antiaim.OverrideLimit(45.0)
						antiaim.OverrideInverter(false)
		
					else if (miss_counter % 3 == 1) then --Logic 2 
						antiaim.OverrideLimit(15.0)
						antiaim.OverrideInverter(false)
						antiaim.OverrideYawOffset(8.0)
		
					else if (miss_counter % 3 == 2) then --Logic 3
						antiaim.OverrideLimit(60.0)
						antiaim.OverrideInverter(true)
						antiaim.OverrideYawOffset(8.0)
						end
					end
				end
			end
			else
			
				if cond == 1 then
					
				--standing
					if inverter then --invert: true
						if aa_type == 1 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end
                     elseif aa_type == 2 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end						
					end
					end
			
					if inverter == false then         --invert: false
						if aa_type == 1 then
                          if antiaim_stuff.jitter then
								    antiaim_stuff.limit = 60
								    antiaim_stuff.yaw = 15
								    antiaim_stuff.lby = -33
                                else 
		    						antiaim_stuff.limit = 15
								    antiaim_stuff.yaw = 0
	                        end
						elseif aa_type == 2 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end				
							end
						end
					end
		
				if cond == 2 then
				--slowwalking
				--standing
					if inverter then --invert: true
						if aa_type == 1 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end
                     elseif aa_type == 2 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end					
					end
					end
	
					if inverter == false then         --invert: false
						if aa_type == 1 then
                          if antiaim_stuff.jitter then
								    antiaim_stuff.limit = 60
								    antiaim_stuff.yaw = 15
								    antiaim_stuff.lby = -33
                                else 
		    						antiaim_stuff.limit = 15
								    antiaim_stuff.yaw = 0
	                        end
						elseif aa_type == 2 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end			
							end
						end
					end

				if cond == 3 then
				--running
					if inverter then --invert: true
						if aa_type == 1 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = -8
						    antiaim_stuff.lby = 8
                        else 
    						antiaim_stuff.limit = 28
						    antiaim_stuff.yaw = 0
                        end
                     elseif aa_type == 2 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = -8
						    antiaim_stuff.lby = 8
                        else 
    						antiaim_stuff.limit = 28
						    antiaim_stuff.yaw = 0
                        end						
					end
					end
					if inverter == false then         --invert: false
						if aa_type == 1 then
                          if antiaim_stuff.jitter then
								    antiaim_stuff.limit = 60
								    antiaim_stuff.yaw = 15
								    antiaim_stuff.lby = -33
                                else 
		    						antiaim_stuff.limit = 15
								    antiaim_stuff.yaw = 0
	                        end
						elseif aa_type == 2 then
                          if antiaim_stuff.jitter then
						    antiaim_stuff.limit = 60
						    antiaim_stuff.yaw = 15
						    antiaim_stuff.lby = -33
                        else 
    						antiaim_stuff.limit = 15
						    antiaim_stuff.yaw = 0
                        end
						end
					end
				end
			antiaim.OverrideLimit(antiaim_stuff.limit)
			antiaim.OverrideYawOffset(antiaim_stuff.yaw)
			antiaim.OverrideLBYOffset(antiaim_stuff.lby)
	end
end
		
    --If you want to add in air antiaim, you can do ghetto shit by checking is_keydown, or you can call it over events
    --For Running antiaim add a velocity check



    --if exploits.GetCharge() ~= 0 then --Check if exploits is charged/enabled

    --if you only want to check if doubletap is enabled you can do that over

    --local dtcheck = g_Config:FindVar("Aimbot", "Ragebot", "Exploits", "Double Tap") --Call it
    --If dtcheck:GetBool() then | You're check if dt is enabled


    --If you want an accurate dt you can do a check for weapons, and after that check which weapon you have in hands & do that with doubletap stuff and then change youre min dmg/hitchance depends on if dt is charged or not


    --You can do much stuff over:
    --exploits.ForceCharge()
    --exploits.ForceTeleport()
    --exploits.AllowCharge(false)
    --https://docs.neverlose.cc/developers/tables/exploits#forcecharge everything explained there


    if c_leg_fucker:GetBool() then
        if g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Enable Fake Lag"):GetBool() and exploits.GetCharge() == 0 then
            local var3 = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
            lastlegfucker = lastlegfucker + 1
            var3:SetInt(lastlegfucker > 2 and 2 or 1)
            if lastlegfucker >= 3 then lastlegfucker = 0 end
        else
            local var3 = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
            lastlegfucker = lastlegfucker + 1
            var3:SetInt(lastlegfucker > 1 and 2 or 1)
            if lastlegfucker >= 2 then lastlegfucker = 0 end
        end
    end
    
    --DT

	if doubletap_enable:GetBool() then
    
    local Instant = 15
    local Fast = 14
    local Default = 13
	
	local doubletap = g_Config:FindVar("Aimbot", "Ragebot", "Exploits", "Double Tap"):GetBool()
    
	if not doubletap and dt_stuff.should_cache == false then
		g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Enable Fake Lag"):SetBool(dt_stuff.cached_fakelag)
		g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Limit"):SetInt(dt_stuff.cached_fakelag_amount)
		dt_stuff.should_cache = true
	end	
	
	if not doubletap and dt_stuff.should_cache then
		dt_stuff.cached_fakelag = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Enable Fake Lag"):GetBool()
		dt_stuff.cached_fakelag_amount = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Limit"):GetInt()
		dt_stuff.cached_randomize = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Randomization"):GetInt()
	end


	if active_weapon:GetProp("m_iItemDefinitionIndex") == 40 and doubletap then
		if doubletap_dynamic_tele:GetBool() then
			is_scout = true
			exploits.OverrideDoubleTapSpeed(Default)
		end
	else
		is_scout = false
    if doubletap_modes:GetInt() == 0 then --Instant
        exploits.OverrideDoubleTapSpeed(Instant)
        g_CVar:FindVar("cl_clock_correction"):SetInt(0) -- causes untrusted
        g_CVar:FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(250)
        if active_weapon:GetProp("m_iItemDefinitionIndex") == 38 or active_weapon:GetProp("m_iItemDefinitionIndex") == 11 then
			if doubletap and dt_stuff.should_cache then
				g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Enable Fake Lag"):SetBool(true)
				g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Limit"):SetInt(14)
				g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Randomization"):SetInt(0)
				dt_stuff.should_cache = false
			end
        end
    elseif doubletap_modes:GetInt() == 1 then --Fast
        exploits.OverrideDoubleTapSpeed(Fast)
    
    elseif doubletap_modes:GetInt() == 2 then --Default
        exploits.OverrideDoubleTapSpeed(Default)
    end
	end
	end


	 if antiaim_enable:GetBool() then
			indicators.edgeyaw = false
    if bit.band(cmd.buttons, bit.lshift(1,11)) ~= 0 then wasinattack = 15 return end
    if bit.band(cmd.buttons, bit.lshift(1,0)) ~= 0 then wasinattack = 15 return elseif wasinattack > 0 then wasinattack = wasinattack - 1 return end
    
    if bit.band(localplayer:GetPlayer():GetProp("m_fFlags"), bit.lshift(1,0)) == 0 then return end
    localplayer = localplayer:GetPlayer()
if wasinattack == 0 and edgeyaw:GetBool() then
    local M_PI = 3.14159265358979323846
    local origin = localplayer:GetEyePosition()
    local closest_distance = 30
    local radius = 200
    local nopemen = M_PI / 8
    local predict_ticks = 10
    local velocity = Vector.new(localplayer:GetProp("m_vecVelocity[0]"), localplayer:GetProp("m_vecVelocity[1]"), localplayer:GetProp("m_vecVelocity[2]"))
    local start_pos = Vector.new(origin.x + velocity.x * g_GlobalVars.interval_per_tick * predict_ticks, origin.y + velocity.y * g_GlobalVars.interval_per_tick * predict_ticks, origin.z + velocity.z * g_GlobalVars.interval_per_tick * predict_ticks)

    local should_stop = false
    local testhit = {0, 3, 2, 11, 12}
    for i = 1,64 do
        local player = EntityList.GetClientEntity(i)
        if player and player:EntIndex() ~= localplayer:EntIndex() and not player:GetPlayer():IsTeamMate() and not player:GetPlayer():IsDormant() and player:GetPlayer():GetProp("m_iHealth") > 0 then
            for k,v in pairs(testhit) do
                if cheat.FireBullet(localplayer, localplayer:GetEyePosition(), player:GetPlayer():GetHitboxCenter(v)).damage > 0 then
                    should_stop = true
                end
            end
        end
    end

    if not should_stop then
        local a=0
        while (a<(M_PI*2)) do
            a = a+nopemen
            local location = Vector.new(radius * math.cos(a)+start_pos.x, radius*math.sin(a)+start_pos.y, start_pos.z)
            local traced = EngineTrace.TraceRay(start_pos, location, EntityList.GetClientEntity(EngineClient.GetLocalPlayer()), 0x4600400B)
            local distance = traced.endpos:DistTo(start_pos)
            if distance < closest_distance then
                closest_distance = distance
                if not fakelag.Choking() then
					indicators.edgeyaw = true
                    var:SetInt(0)
                    cmd.viewangles.yaw = a * (360 / (M_PI*2))
                    cmd.viewangles.pitch = 89
                    got_edgeyaw = true
                end
            end
        end
    end
end
end
end

--DT END 



cheat.RegisterCallback("prediction", on_createmove) 


--Misc
local function kill_say_function(event)

    local words_kill = c_menu_kill_say_words:GetString()
    
        if event:GetName() == "player_death" and misc_enable:GetBool() then
    
            local victim = g_EngineClient:GetPlayerForUserId(event:GetInt("userid"))
            local attacker = g_EngineClient:GetPlayerForUserId( event:GetInt("attacker"))
    
            if victim ~= attacker and attacker == g_EngineClient:GetLocalPlayer() and c_menu_kill_say:GetBool() then
                g_EngineClient:ExecuteClientCmd('say ' .. words_kill)
            end
        end
    end

mc_indicators:RegisterCallback(function()
    indicators:_add_or_remove()

end)
indicators:_add_or_remove()


local i_indicators_font_callback = function()
    i_indicators_custom_font:SetVisible(i_indicators_font:GetInt() == #globals.visuals.font_selection - 1)
end
i_indicators_font:RegisterCallback(i_indicators_font_callback)
i_indicators_font_callback()

b_indicators_update_font_callback = function()

    local size = i_indicators_size:GetInt()
    
    if i_indicators_font:GetInt() == #globals.visuals.font_selection - 1 then
        globals.visuals.font = g_Render:InitFont(i_indicators_custom_font:GetString(), size)
        globals.visuals.brand_font = g_Render:InitFont(i_indicators_custom_font:GetString(), size + 2)
    else
        if i_indicators_font:GetInt() == 0 then
            globals.visuals.font = g_Render:InitFont("000webfont", size)
            globals.visuals.brand_font = g_Render:InitFont("000webfont", size + 2)
        else
            globals.visuals.font = g_Render:InitFont(globals.visuals.font_selection[i_indicators_font:GetInt() + 1], size)
            globals.visuals.brand_font = g_Render:InitFont(globals.visuals.font_selection[i_indicators_font:GetInt() + 1], size + 2)
        end
    end
end
b_indicators_update_font:RegisterCallback(b_indicators_update_font_callback)
b_indicators_update_font_callback()

--Misc END

--retarded stuff for ragebot
local function ragebot_head(ent, state)
ragebot.EnableHitbox(ent, 0, state)
ragebot.EnableMultipoints(ent, 0, state)
ragebot.EnableHitbox(ent, 1, state)
ragebot.EnableMultipoints(ent, 1, state)
end

local function ragebot_baim(ent, state)
ragebot.EnableHitbox(ent, 2, state)
ragebot.EnableMultipoints(ent, 2, state)
ragebot.EnableHitbox(ent, 3, state)
ragebot.EnableMultipoints(ent, 3, state)
ragebot.EnableHitbox(ent, 4, state)
ragebot.EnableMultipoints(ent, 4, state)
ragebot.EnableHitbox(ent, 5, state)
ragebot.EnableMultipoints(ent, 5, state)
ragebot.EnableHitbox(ent, 6, state)
ragebot.EnableMultipoints(ent, 6, state)
end

local function ragebot_legs(ent, state)
ragebot.EnableHitbox(ent, 7, state)
ragebot.EnableMultipoints(ent, 7, state)
ragebot.EnableHitbox(ent, 8, state)
ragebot.EnableMultipoints(ent, 8, state)
ragebot.EnableHitbox(ent, 9, state)
ragebot.EnableMultipoints(ent, 9, state)
ragebot.EnableHitbox(ent, 10, state)
ragebot.EnableMultipoints(ent, 10, state)
ragebot.EnableHitbox(ent, 11, state)
ragebot.EnableMultipoints(ent, 11, state)
ragebot.EnableHitbox(ent, 12, state)
ragebot.EnableMultipoints(ent, 12, state)
end

local function ragebot_arms(ent, state)
ragebot.EnableHitbox(ent, 13, state)
ragebot.EnableMultipoints(ent, 13, state)
ragebot.EnableHitbox(ent, 14, state)
ragebot.EnableMultipoints(ent, 14, state)
ragebot.EnableHitbox(ent, 15, state)
ragebot.EnableMultipoints(ent, 15, state)
ragebot.EnableHitbox(ent, 16, state)
ragebot.EnableMultipoints(ent, 16, state)
ragebot.EnableHitbox(ent, 17, state)
ragebot.EnableMultipoints(ent, 17, state)
ragebot.EnableHitbox(ent, 18, state)
ragebot.EnableMultipoints(ent, 18, state)
end

local function handle_aimbot()
if aimbot.enable:GetBool() then
for idx = 1, g_GlobalVars.maxClients + 1 do
	local ent = g_EntityList:GetClientEntity(idx)
		if ent and ent:IsPlayer() then
			local player = ent:GetPlayer()
			local view_angles = player:GetRenderAngles()
			local is_teammate = player:IsTeamMate()
			local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
			if me == nil then
			return
			end
			local localPlayer = me:GetPlayer()
			local enemy_pos = ent:GetProp("DT_BaseEntity", "m_vecOrigin")
			local my_pos = localPlayer:GetProp("DT_BaseEntity", "m_vecOrigin")
			local dist = my_pos:DistTo(enemy_pos)
			local health = player:GetProp("DT_BasePlayer", "m_iHealth")
			local distance_int = math.floor(dist)
				if not player:IsTeamMate() and health > 0 then
				local speed = math.floor(get_velocity(player))
				local duck_amount = player:GetProp("DT_BasePlayer", "m_flDuckAmount")
				local new_dist = distance_int / 8
				local m_fFlags = player:GetProp("DT_BasePlayer", "m_fFlags")
				
			--prefer body
			if aimbot.prefer_body:GetBool(0) then
                if (speed <= 2) then
					ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
					ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
                end
			end
				if aimbot.prefer_body:GetBool(1) then
					if speed <= 100 and speed > 2 then
						ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
						ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
					end
				end
				if aimbot.prefer_body:GetBool(2) then
               		if speed > 100 then
						ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
						ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
				end
    		  end
				if aimbot.prefer_body:GetBool(3) then
					if bit.band(m_fFlags, bit.lshift(1, 0)) == 0 then
						ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
						ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
					end
				end
			--prefer baim if lethal
				if aimbot.prefer_body:GetBool(4) then
				local weapon = localPlayer:GetActiveWeapon()
    
				if weapon == nil then
				return
				end

				local weapon_damage = weapon:GetWeaponDamage()

				if (health > 0 and health < weapon_damage) then
						ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
						ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
			end
		end
				if aimbot.prefer_body:GetBool(5) then
               		if duck_amount == 1 then
						ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
						ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
					end
    		  end
				if aimbot.prefer_body:GetBool(6) then
					if view_angles.pitch >= 0 and view_angles.pitch <= 50 or view_angles.pitch >= 329 and view_angles.pitch <= 360 then
						ragebot.SetHitboxPriority(ent:EntIndex(), 3, 1000)
						ragebot.ForceHitboxSafety(ent:EntIndex(), 3)
						ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
				end
				end
			--force body
			if aimbot.force_body:GetBool(0) then
                if (speed <= 2) then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
                end
			end
				if aimbot.force_body:GetBool(1) then
					if speed <= 100 and speed > 2 then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
					end
				end
				if aimbot.force_body:GetBool(2) then
               		if speed > 100 then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
				end
    		  end
				if aimbot.force_body:GetBool(3) then
					if bit.band(m_fFlags, bit.lshift(1, 0)) == 0 then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
					end
				end
			--force baim if lethal
				if aimbot.force_body:GetBool(4) then
				local weapon = localPlayer:GetActiveWeapon()
    
				if weapon == nil then
				return
				end

				local weapon_damage = weapon:GetWeaponDamage()

				if (health > 0 and health < weapon_damage) then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
			end
		end
				if aimbot.force_body:GetBool(5) then
               		if duck_amount == 1 then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
					end
    		  end
				if aimbot.force_body:GetBool(6) then
					if view_angles.pitch >= 0 and view_angles.pitch <= 50 or view_angles.pitch >= 329 and view_angles.pitch <= 360 then
					ragebot_baim(ent:EntIndex(), true)
					ragebot_head(ent:EntIndex(), false)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
				end
				end				


			--prefer head
			if aimbot.prefer_head:GetBool(0) then
                if (speed <= 2) then
				    ragebot.SetHitboxPriority(ent:EntIndex(), 0, 1000)
                	end
				end
				if aimbot.prefer_head:GetBool(1) then
					if speed <= 100 and speed > 2 then
						ragebot.SetHitboxPriority(idx, 0, 1000)
					end
				end
				if aimbot.prefer_head:GetBool(2) then
               	if speed > 100 then
					ragebot.SetHitboxPriority(idx, 0, 1000)
              	end
    		  end
				if aimbot.prefer_head:GetBool(3) then
               		if bit.band(m_fFlags, bit.lshift(1, 0)) == 0 then
						ragebot.SetHitboxPriority(idx, 0, 1000)
             	 end
    		  end
				if aimbot.prefer_head:GetBool(4) then
					if view_angles.pitch >= 0 and view_angles.pitch <= 50 or view_angles.pitch >= 329 and view_angles.pitch <= 360 then
						ragebot.SetHitboxPriority(idx, 0, 1000)
					end
				end
			--prefer baim if lethal
				if aimbot.prefer_head:GetBool(4) then
				local weapon = localPlayer:GetActiveWeapon()
    
				if weapon == nil then
				return
				end

				local weapon_damage = weapon:GetWeaponDamage()

				if (health > 0 and health < weapon_damage) then
					ragebot.SetHitboxPriority(ent:EntIndex(), 3, 2)
					ragebot.SetHitboxPriority(ent:EntIndex(), 2, 1)
					ragebot.SetHitboxPriority(ent:EntIndex(), 4, 10)
			end
		end
			--force head
			if aimbot.force_head:GetBool(0) then
                if (speed <= 2) then
					ragebot_baim(ent:EntIndex(), false)
					ragebot_head(ent:EntIndex(), true)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
                	end
				end
				if aimbot.force_head:GetBool(1) then
					if speed <= 100 and speed > 2 then
						ragebot_baim(ent:EntIndex(), false)
						ragebot_head(ent:EntIndex(), true)
						ragebot_legs(ent:EntIndex(), false)
						ragebot_arms(ent:EntIndex(), false)
					end
				end
				if aimbot.force_head:GetBool(2) then
               	if speed > 100 then
					ragebot_baim(ent:EntIndex(), false)
					ragebot_head(ent:EntIndex(), true)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
              	end
    		  end
				if aimbot.force_head:GetBool(3) then
               		if bit.band(m_fFlags, bit.lshift(1, 0)) == 0 then
						ragebot_baim(ent:EntIndex(), false)
						ragebot_head(ent:EntIndex(), true)
						ragebot_legs(ent:EntIndex(), false)
						ragebot_arms(ent:EntIndex(), false)
             	 end
    		  end
				if aimbot.force_head:GetBool(4) then
					if view_angles.pitch >= 0 and view_angles.pitch <= 50 or view_angles.pitch >= 329 and view_angles.pitch <= 360 then
						ragebot_baim(ent:EntIndex(), false)
						ragebot_head(ent:EntIndex(), true)
						ragebot_legs(ent:EntIndex(), false)
						ragebot_arms(ent:EntIndex(), false)
					end
				end
			--prefer baim if lethal
				if aimbot.force_head:GetBool(4) then
				local weapon = localPlayer:GetActiveWeapon()
    
				if weapon == nil then
				return
				end

				local weapon_damage = weapon:GetWeaponDamage()

				if (health > 0 and health < weapon_damage) then
					ragebot_baim(ent:EntIndex(), false)
					ragebot_head(ent:EntIndex(), true)
					ragebot_legs(ent:EntIndex(), false)
					ragebot_arms(ent:EntIndex(), false)
			end
		end

		end
	end
end
end
end

--end

--Indicators

local screen = g_EngineClient:GetScreenSize() 
local function on_paint()

    --If we are connected
    if not g_EngineClient:IsConnected() then
        return
    end

    -- if we are not ingame.
    if not g_EngineClient:IsInGame() then
        return
    end

    --localplayer check
    local localplayer = g_EntityList:GetLocalPlayer()
    local player = localplayer:GetPlayer()

    if not localplayer then return end

antiaim_stuff.jitter = not antiaim_stuff.jitter

     -- clantag function
    if visuals_enable:GetBool() then
     if var_clantag:GetBool() == true then
        if g_EngineClient:IsConnected() then
            local netchann_info = g_EngineClient:GetNetChannelInfo()
            if netchann_info == nil then 
                return
            end
        
            local raw_latency = netchann_info:GetLatency(0)
            local latency = raw_latency / g_GlobalVars.interval_per_tick
            local tickcount_pred = g_GlobalVars.tickcount + latency
            local iter = math.floor(math.fmod(tickcount_pred / 25, #tag))
            if iter ~= last_tag_iter then 
                set_clantag(tag[iter], tag[iter])
                if (tag[iter] ~= nil) then
                    var_clantag:SetTooltip(tag[iter])
                else
                    var_clantag:SetTooltip("")
                end
                last_tag_iter = iter
            end
        end
    end
	end
    -- clantag function end 

	if visuals_enable:GetBool() then
    if #indicators.list > 0 then

        local lifestate = localplayer:GetProp("m_lifeState") == false
        local indicators_color = i_indicators_font:GetColor()

        if lifestate then

            local screen = g_EngineClient:GetScreenSize()
            local center = screen / Vector2.new(2, 2)

            local binds = cheat:GetBinds()

            indicators.binds = cheat:GetBinds()

            local printed = 0

            if c_indicators_style:GetInt() == 1 then
                local origin = localplayer:GetRenderOrigin()

                local real = antiaim.GetCurrentRealRotation()
                local fake = antiaim.GetFakeRotation()

                local real_screen = g_Render:ScreenPosition(mathemathics:_rotated_position(origin, real, 50))
                local fake_screen = g_Render:ScreenPosition(mathemathics:_rotated_position(origin, fake, 50))
				
                local left_color = Color.new(1.0, 1.0, 1.0, 1.0)
                local right_color = Color.new(1.0, 1.0, 1.0, 1.0)

                if fake_screen.x > real_screen.x then
                    left_color = indicators_color
                elseif fake_screen.x < real_screen.x then
                    right_color = indicators_color
                end

                local left_size = g_Render:CalcTextSize("light", i_indicators_size:GetInt(), globals.visuals.font)
                local right_size = g_Render:CalcTextSize("ning", i_indicators_size:GetInt(), globals.visuals.font)

                g_Render:Text("light", Vector2.new(screen.x / 2 - left_size.x / 2 - right_size.x / 2, screen.y / 2 + left_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), left_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                g_Render:Text("ning", Vector2.new(screen.x / 2 + left_size.x / 2 - right_size.x / 2, screen.y / 2 + left_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), right_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                printed = printed + 1.2

                local font_fix = 0
                if i_indicators_font:GetInt() == 0 then
                    font_fix = 4
                end

                local t_l = indicators_color
                local t_r = Color.new(0.6, 0.6, 0.6, 0.7)
                local b_l = indicators_color
                local b_r = Color.new(0.6, 0.6, 0.6, 0.7)

                g_Render:GradientBoxFilled(
                        Vector2.new(screen.x / 2 - (left_size.x + right_size.x + font_fix) / 1.5,
                            screen.y / 2 + left_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)),
                        Vector2.new(screen.x / 2,
                            screen.y / 2 + math.floor(left_size.y / 1.5) + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)),
                        t_l, t_r, b_l, b_r)
                        g_Render:BoxFilled(
                            Vector2.new(screen.x / 2,
                                screen.y / 2 + left_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)),
                            Vector2.new(screen.x / 2 + (left_size.x + right_size.x) / 1.5,
                                screen.y / 2 + math.floor(left_size.y / 1.5) + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)),
                            t_r)

                printed = printed + 0.3
            end

            for k, v in pairs(indicators.list) do

                if v.name == "Arrows" then

					if c_indicators_style:GetInt() == 1 then
                
                        local viewangles = g_EngineClient:GetViewAngles()
                        local radius = 45
                
                        local origin = localplayer:GetRenderOrigin()

                        local real = antiaim.GetCurrentRealRotation()
                        local fake = antiaim.GetFakeRotation()

                        local real_screen = g_Render:ScreenPosition(mathemathics:_rotated_position(origin, real, 50))
                        local fake_screen = g_Render:ScreenPosition(mathemathics:_rotated_position(origin, fake, 50))

                        local real_rot = mathemathics:_deg2rad(viewangles.yaw - antiaim.GetCurrentRealRotation() - 90);
                        local fake_rot = mathemathics:_deg2rad(viewangles.yaw - antiaim.GetFakeRotation() - 90);

                        local left_color = Color.new(1.0, 1.0, 1.0, 1.0)
                        local right_color = Color.new(1.0, 1.0, 1.0, 1.0)

                        left_color = mathemathics:_contrast(indicators_color, -50)
                        right_color = mathemathics:_contrast(indicators_color, -50)

                        g_Render:PolyFilled(left_color,
                            Vector2.new(center.x + math.cos(real_rot) * radius,
                                        center.y + math.sin(real_rot) * radius),
                            Vector2.new(center.x + math.cos(real_rot + mathemathics:_deg2rad(20)) * (radius - 15),
                                        center.y + math.sin(real_rot + mathemathics:_deg2rad(20)) * (radius - 15)),
                            Vector2.new(center.x + math.cos(real_rot) * (radius - 13),
                                        center.y + math.sin(real_rot) * (radius - 13))
                        )

                        g_Render:PolyFilled(right_color,
                            Vector2.new(center.x + math.cos(real_rot) * radius,
                                        center.y + math.sin(real_rot) * radius),
                            Vector2.new(center.x + math.cos(real_rot - mathemathics:_deg2rad(20)) * (radius - 15),
                                        center.y + math.sin(real_rot - mathemathics:_deg2rad(20)) * (radius - 15)),
                            Vector2.new(center.x + math.cos(real_rot) * (radius - 13),
                                        center.y + math.sin(real_rot) * (radius - 13))
                        )
                    end

                elseif v.name == "Double Tap" then

                    local feature = nil
                    local current_charge = exploits.GetCharge()

                    if c_indicators_style:GetInt() == 1 then
                        feature = indicators.doubletap

                        local feature_size = g_Render:CalcTextSize("double tap", i_indicators_size:GetInt(), globals.visuals.font)

                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            if current_charge == 1 then
                                feature_color = Color.new(0, 1, 0, 0.8)
                            else
                                feature_color = Color.new(1, 0, 0, 0.8)
                            end
                        end

                        g_Render:Text("double tap", Vector2.new(screen.x / 2 - feature_size.x / 2, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), feature_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end

                elseif v.name == "Hide Shots" then
                    local feature = nil

                    if c_indicators_style:GetInt() == 1 then
                        feature = indicators.hideshots

                        local feature_size = g_Render:CalcTextSize("hide shots", i_indicators_size:GetInt(), globals.visuals.font)
                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            feature_color = indicators_color
                        end

                        g_Render:Text("hide shots", Vector2.new(screen.x / 2 - feature_size.x / 2, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), feature_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end

                elseif v.name == "Fake Duck" then
                    local feature = nil

                    if c_indicators_style:GetInt() == 1 then
                        feature = indicators.fakeduck

                        local feature_size = g_Render:CalcTextSize("fake duck", i_indicators_size:GetInt(), globals.visuals.font)
                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            feature_color = indicators_color
                        end

                        g_Render:Text("fake duck", Vector2.new(screen.x / 2 - feature_size.x / 2, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), feature_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end

                elseif v.name == "Min Damage" then
                    local feature = nil

                    if c_indicators_style:GetInt() == 1 then
                        feature = g_Config:FindVar("Aimbot", "Ragebot", "Accuracy", "Minimum Damage"):GetInt()

                        local feature_size = g_Render:CalcTextSize("MD", i_indicators_size:GetInt(), globals.visuals.font)
                        local dmg_size = g_Render:CalcTextSize(tostring(feature), i_indicators_size:GetInt(), globals.visuals.font)
                        
                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            feature_color = indicators_color
                        end

                        g_Render:Text("min", Vector2.new(screen.x / 2 - feature_size.x / 2 - dmg_size.x / 2 - 3, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), Color.new(1.0, 1.0, 1.0, 1.0), i_indicators_size:GetInt(), globals.visuals.font, true)

                        g_Render:Text(tostring(feature), Vector2.new(screen.x / 2 + feature_size.x / 2 - dmg_size.x / 2 + 3, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), indicators_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end

                elseif v.name == "Body Aim" then
                    local feature = nil

                    if c_indicators_style:GetInt() == 1 then
                        feature = g_Config:FindVar("Aimbot", "Ragebot", "Misc", "Body Aim"):GetInt()

                        local feature_text = ""

                        if feature == 1 then
                            feature_text = "prefer baim"
                        elseif feature == 2 then
                            feature_text = "force baim"
                        else
                            goto continue
                        end

                        local feature_size = g_Render:CalcTextSize(feature_text, i_indicators_size:GetInt(), globals.visuals.font)
                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            feature_color = indicators_color
                        end

                        g_Render:Text(feature_text, Vector2.new(screen.x / 2 - feature_size.x / 2, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), feature_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end

                elseif v.name == "Safe Points" then
                    local feature = nil

                    if c_indicators_style:GetInt() == 1 then
                        feature = g_Config:FindVar("Aimbot", "Ragebot", "Misc", "Safe Points"):GetInt()

                        local feature_text = ""

                        if feature == 1 then
                            feature_text = "prefer safe"
                        elseif feature == 2 then
                            feature_text = "force safe"
                        else
                            goto continue
                        end

                        local feature_size = g_Render:CalcTextSize(feature_text, i_indicators_size:GetInt(), globals.visuals.font)
                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            feature_color = indicators_color
                        end

                        g_Render:Text(feature_text, Vector2.new(screen.x / 2 - feature_size.x / 2, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), feature_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end

                elseif v.name == "Auto Peek" then
                    local feature = nil

                    if c_indicators_style:GetInt() == 1 then
                        feature = indicators.quickpeek

                        local feature_size = g_Render:CalcTextSize("auto peek", i_indicators_size:GetInt(), globals.visuals.font)
                        local feature_color = Color.new(0.8, 0.8, 0.8, 1.0)
                        if feature then
                            feature_color = indicators_color
                        end

                        g_Render:Text("auto peek", Vector2.new(screen.x / 2 - feature_size.x / 2, screen.y / 2 + feature_size.y / 2 + i_indicators_base:GetInt() + (i_indicators_size:GetInt() * printed)), feature_color, i_indicators_size:GetInt(), globals.visuals.font, true)

                        printed = printed + 1
                    end
                end
                ::continue::
            end
        end
    end
end
end
-- colors
local function NewColor(r, g, b, a)
    return Color.new(r / 255, g / 255, b / 255, a / 255)
end

local function ideal_yaw()

    --If we are connected
    if not g_EngineClient:IsConnected() then
        return
    end

    -- if we are not ingame.
    if not g_EngineClient:IsInGame() then
        return
    end

    --localplayer check
    local localplayer = g_EntityList:GetLocalPlayer()
    local player = localplayer:GetPlayer()

    if not localplayer then return end

   	local lifestate = localplayer:GetProp("m_lifeState") == false


	local yOffset = 0
	local charge = exploits.GetCharge()

	ideal_txt = "IDEAL YAW"
	ideal_color = NewColor(215, 114, 44, 255)

	if lifestate then

	if c_indicators_style:GetInt() == 0 then
		if indicators.edgeyaw then
      		ideal_txt = "IDEAL YAW+"
		end
		if indicators.manual_aa then
			ideal_txt = "FAKE YAW"
			ideal_color = NewColor(177, 151, 255, 255)
		end

		g_Render:Text(ideal_txt, Vector2.new(screen.x / 2, screen.y / 2 + i_indicators_base:GetInt() + yOffset), ideal_color, 12, true)
	 	yOffset = yOffset + 12

		local pitch = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base"):GetInt()

		if pitch == 4 then
			pitch_txt = "DYNAMIC"
			pitch_color =  NewColor(196, 132, 215, 255)
		else
			pitch_txt = "DEFAULT"
			pitch_color =  NewColor(215, 0, 0, 255)
		end

     	 g_Render:Text(pitch_txt, Vector2.new(screen.x / 2, screen.y / 2 + i_indicators_base:GetInt() + yOffset), pitch_color, 12, true)

	if indicators.doubletap then
		if charge == 1 then
			dtcolor = Color.new(0, 1, 0, 1)
		else
			dtcolor = Color.new(1, 0, 0, 1)
		end
	
		yOffset = yOffset + 12
	     g_Render:Text("DT", Vector2.new(screen.x / 2, screen.y / 2 + i_indicators_base:GetInt() + yOffset), dtcolor, 12, true)
	end

	if indicators.hideshots then
		yOffset = yOffset + 12
	     g_Render:Text("AA", Vector2.new(screen.x / 2, screen.y / 2 + i_indicators_base:GetInt() + yOffset), NewColor(196, 132, 215, 255), 12, true)
	end
end
end
end

local screen = g_EngineClient:GetScreenSize()

-- delta angle
local real_rotation = 0
local fake_fraction = 0
local function delta_angle(angle)
    local angle = math.fmod(angle, 360.0)

    if angle > 180.0 then
        angle = angle - 360.0
    end

    if angle < -180.0 then
        angle = angle + 360.0
    end

    return angle
end

local function createmovecalc()
    if g_ClientState.m_choked_commands == 0 then
        real_rotation = antiaim.GetCurrentRealRotation()
    end

    local max_delta = antiaim.GetMaxDesyncDelta() + math.abs(antiaim.GetMinDesyncDelta())
    local delta = math.abs(delta_angle(real_rotation - antiaim.GetFakeRotation())) / max_delta

    if delta > 1.0 then
        delta = 1.0
    end

    fake_fraction = delta
end

local function ragebot()

if visuals_enable:GetBool() then
 --If we are connected
    if not g_EngineClient:IsConnected() then
        return
    end

    -- if we are not ingame.
    if not g_EngineClient:IsInGame() then
        return
    end

    --localplayer check
    local localplayer = g_EntityList:GetLocalPlayer()
    local player = localplayer:GetPlayer()

    if not localplayer then return end

       local lifestate = localplayer:GetProp("m_lifeState") == false

if lifestate then
local min_dmg = g_Config:FindVar("Aimbot", "Ragebot", "Accuracy", "Minimum Damage"):GetInt()

    if display_mindmg:GetBool() then
        g_Render:Text(tostring(min_dmg), Vector2.new(screen.x/2 + 18, screen.y/2 - 25), Color.new(1, 1, 1, 1), 11)
    end
end
end
end

local function invictus()
	if visuals_enable:GetBool() then

    --If we are connected
    if not g_EngineClient:IsConnected() then
        return
    end

    -- if we are not ingame.
    if not g_EngineClient:IsInGame() then
        return
    end

    --localplayer check
    local localplayer = g_EntityList:GetLocalPlayer()
    local player = localplayer:GetPlayer()

    if not localplayer then return end

  local lifestate = localplayer:GetProp("m_lifeState") == false


	if lifestate then
    local fake = math.ceil(fake_fraction * 58)


    local color_primary_dsy = desync_clr:GetColor()
    local color_secondary_dsy = desync_clr2:GetColor()
    local inverterr = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Inverter") --Check for inverter
    local arrow_size = g_Render:CalcTextSize(">", i_arrow_size:GetInt())
	
    if c_indicators_style:GetInt() == 2 then
        -- lightning 
        g_Render:Text("Lightning", Vector2.new(screen.x/2 - g_Render:CalcTextSize("Lightning", 11).x / 2, screen.y/2+25), Color.new(1, 1, 1, 1), 11)

        -- fake
        g_Render:Text(tostring(fake) .. "°", Vector2.new(screen.x / 2 + 2 - g_Render:CalcTextSize(tostring(fake) .. "°", 11).x / 2, screen.y / 2 +8), Color.new(1, 1, 1, 1), 11)
     
        if inverterr:GetBool() then
            
            g_Render:Text(">", Vector2.new(screen.x / 2 - 1 + i_arrow_base:GetInt(), screen.y / 2 - 1 - arrow_size.y / 2), Color.new(1, 1, 1), i_arrow_size:GetInt()) --0.1,0.5,0.8
            g_Render:Text("<", Vector2.new(screen.x / 2 - arrow_size.x - i_arrow_base:GetInt(), screen.y / 2 - 1 - arrow_size.y / 2), color_secondary_dsy, i_arrow_size:GetInt())

        else 
            
            g_Render:Text(">", Vector2.new(screen.x / 2 - 1 + i_arrow_base:GetInt(), screen.y / 2 - 1 - arrow_size.y / 2), color_secondary_dsy, i_arrow_size:GetInt())
            g_Render:Text("<", Vector2.new(screen.x / 2 - arrow_size.x - i_arrow_base:GetInt(), screen.y / 2 - 1 - arrow_size.y / 2), Color.new(1, 1, 1), i_arrow_size:GetInt())

        end

    
        -- desync bar
        g_Render:GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+21), Vector2.new(screen.x/2+(math.abs(fake) - 15), screen.y/2+23), color_secondary_dsy, color_primary_dsy, color_secondary_dsy, color_primary_dsy)
        g_Render:GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+21), Vector2.new(screen.x/2+(-math.abs(fake) + 15), screen.y/2+23), color_secondary_dsy, color_primary_dsy, color_secondary_dsy, color_primary_dsy)
    end
end
end
end

local frame_rate = 0.0
local function get_abs_fps()
frame_rate = 0.9 * frame_rate + (1.0 - 0.9) * g_GlobalVars.absoluteframetime
return math.floor((1.0 / frame_rate) + 0.5)
end

local function get_latency()
local netchann_info = g_EngineClient:GetNetChannelInfo()
if netchann_info == nil then return "0" end
local latency = netchann_info:GetLatency(0)
return string.format("%1.f", math.max(0.0, latency) * 1000.0)
end

local textSize = 0

local function watermark()
if visuals_enable:GetBool() then
if watermark_clr:GetBool() then
local screen = g_EngineClient:GetScreenSize()
local fps = get_abs_fps()
local ping = get_latency()
local ticks = math.floor(1.0 / g_GlobalVars.interval_per_tick)

local rightPadding = 25
local var = screen.x - textSize - rightPadding

local x = var - 10
local y = 9
local w = textSize + 20
local h = 17

g_Render:BoxFilled(Vector2.new(x,y+2),Vector2.new(x+textSize+20,h * 1.5 + 2), Color.new(17/255,17/255,17/255,100/255))

g_Render:BoxFilled(Vector2.new(x,y),Vector2.new(x+textSize+20,h-6),  watermark_clr:GetColor())

local nexttext = "Lightning.lua"

g_Render:Text(nexttext, Vector2.new(var,12), Color.new(255,255,255), 12, font)
local wide = g_Render:CalcTextSize(nexttext, 12, font)
var = var + wide.x

local username = string.lower(cheat.GetCheatUserName())
nexttext = " | " .. username
g_Render:Text(nexttext, Vector2.new(var,12), Color.new(255,255,255), 12,font)

wide = g_Render:CalcTextSize(nexttext, 12,font)
var = var + wide.x	
if watermark_options:GetBool(0) then
	if g_EngineClient:GetNetChannelInfo() == nil then
		ip = "local"
	else
		ip =  g_EngineClient:GetNetChannelInfo():GetAddress()
	end
nexttext = " | " .. ip
g_Render:Text(nexttext, Vector2.new(var,13), Color.new(255,255,255), 12, font)
		
wide = g_Render:CalcTextSize(nexttext, 12,font)
var = var + wide.x		
end

if watermark_options:GetBool(1) then
nexttext = " | delay: ".. ping .."ms"

g_Render:Text(nexttext, Vector2.new(var,12), Color.new(255,255,255), 12,font)

wide = g_Render:CalcTextSize(nexttext, 12,font)
var = var + wide.x
end

if watermark_options:GetBool(2) then
nexttext = " | " .. ticks .. "tick"

g_Render:Text(nexttext, Vector2.new(var,12), Color.new(255,255,255), 12,font)

wide = g_Render:CalcTextSize(nexttext, 12,font)
var = var + wide.x
end
	
if watermark_options:GetBool(3) then
nexttext = " | " .. fps .." fps"

g_Render:Text(nexttext, Vector2.new(var,13), Color.new(255,255,255), 12, font)

wide = g_Render:CalcTextSize(nexttext, 10)
var = var + wide.x
		
textSize = var + 15 - (screen.x - textSize - rightPadding)	
	else
textSize = var - (screen.x - textSize - rightPadding)		
end
end
end
end

local function handle_binds()
local binds = cheat.GetBinds()
for i = 1, #binds do
	if binds[i]:GetName() == "Minimum Damage" and binds[i]:IsActive() then
	indicators.minimum_dmg = true 
	indicators.minimum_dmg_value = binds[i]:GetValue()
	end
	if binds[i]:GetName() == "Minimum Damage" and not binds[i]:IsActive() then
	indicators.minimum_dmg = false
	end

	if binds[i]:GetName() == "Double Tap" and binds[i]:IsActive() then
	indicators.doubletap = true 
	end
	if binds[i]:GetName() == "Double Tap" and not binds[i]:IsActive() then
	indicators.doubletap = false
	end

	if binds[i]:GetName() == "Hide Shots" and binds[i]:IsActive() then
	indicators.hideshots = true 
	end
	if binds[i]:GetName() == "Hide Shots" and not binds[i]:IsActive() then
	indicators.hideshots = false
	end

	if binds[i]:GetName() == "Auto Peek" and binds[i]:IsActive() then
	indicators.quickpeek = true 
	end
	if binds[i]:GetName() == "Auto Peek" and not binds[i]:IsActive() then
	indicators.quickpeek = false
	end

	if binds[i]:GetName() == "Fake Duck" and binds[i]:IsActive() then
	indicators.fakeduck = true 
	end
	if binds[i]:GetName() == "Fake Duck" and not binds[i]:IsActive() then
	indicators.fakeduck = false
	end

	if binds[i]:GetName() == "Yaw Base" and binds[i]:IsActive() then
	indicators.manual_aa = true
	end
	if binds[i]:GetName() == "Yaw Base" and not binds[i]:IsActive() then
	indicators.manual_aa = false
	end

end


end

cheat.RegisterCallback("pre_prediction", function(cmd)

	handle_aimbot()
	legit_aa(cmd)
end)


cheat.RegisterCallback("draw", function()
    on_paint()
	ideal_yaw()
	handle_binds()
	watermark()
    invictus()
    ragebot()
end)

cheat.RegisterCallback("destroy", function()
    set_clantag("", "")
    var_clantag:SetTooltip("ϟLightningϟ")
end)

cheat.RegisterCallback("ragebot_shot", function()

	if is_scout then
		exploits.ForceTeleport()
	end

end)

cheat.RegisterCallback("createmove", function(cmd)
    local localplayer = g_EntityList:GetLocalPlayer()
    local weap = localplayer:GetPlayer():GetActiveWeapon()
    if not weap then return end
    if was_in_use then
        if not in_bomb_site then
            cmd.buttons = bit.bor(cmd.buttons, bit.lshift(1,5))
        end
        was_in_use = false
        var:SetInt(last_yaw)
        var36:SetInt(last_pitch)
    elseif not got_edgeyaw then
        last_pitch = var36:GetInt()
        last_yaw = var:GetInt()
    elseif got_edgeyaw then
        var:SetInt(last_yaw)
    end

    createmovecalc()

end)

local function events(e)
    
    kill_say_function(e)
	antibrute(e)
    impacts_events(e)

end

cheat.RegisterCallback("events", events)


local ui_lightning = function()
		
local visuals_switch = visuals_enable:GetBool()
local antiaim_switch = antiaim_enable:GetBool()
local doubletap_switch = doubletap_enable:GetBool()
local ragebot_switch = aimbot.enable:GetBool()
local misc_switch = misc_enable:GetBool()
		
antiaim_modes:SetVisible(antiaim_switch)
antiaim_antibrute:SetVisible(antiaim_switch)
legitaa:SetVisible(antiaim_switch)
edgeyaw:SetVisible(antiaim_switch)		
avoidknife:SetVisible(antiaim_switch)
	
doubletap_modes:SetVisible(doubletap_switch)
doubletap_halfhp:SetVisible(doubletap_switch)
doubletap_dynamic_tele:SetVisible(doubletap_switch)

if ragebot_switch then
	aimbot.mode:SetVisible(true)
	if aimbot.mode:GetInt() == 0 then
		aimbot.prefer_head:SetVisible(true)
		aimbot.prefer_body:SetVisible(true)
		aimbot.force_head:SetVisible(false)
		aimbot.force_body:SetVisible(false)
	elseif aimbot.mode:GetInt() == 1 then
		aimbot.prefer_head:SetVisible(false)
		aimbot.prefer_body:SetVisible(false)
		aimbot.force_head:SetVisible(true)
		aimbot.force_body:SetVisible(true)
end
end

if ragebot_switch == false then
		aimbot.mode:SetVisible(false)
		aimbot.prefer_head:SetVisible(false)
		aimbot.prefer_body:SetVisible(false)
		aimbot.force_head:SetVisible(false)
		aimbot.force_body:SetVisible(false)	
end
var_clantag:SetVisible(visuals_switch)

c_indicators_style:SetVisible(visuals_switch)

	watermark_clr:SetVisible(visuals_switch)
if visuals_switch then
	if c_indicators_style:GetInt() == 0 then
		mc_indicators:SetVisible(false)
		i_indicators_base:SetVisible(true)
		i_indicators_size:SetVisible(false)
		i_indicators_font:SetVisible(false)
		i_arrow_size:SetVisible(false)		
		b_indicators_update_font:SetVisible(false)
        i_arrow_size:SetVisible(false)
        i_arrow_base:SetVisible(false)
        desync_clr2:SetVisible(false)
        desync_clr:SetVisible(false)
        display_mindmg:SetVisible(false)
    elseif c_indicators_style:GetInt() == 1 then
		mc_indicators:SetVisible(true)
		i_indicators_base:SetVisible(true)
		i_indicators_size:SetVisible(true)
		i_indicators_font:SetVisible(true)
		i_arrow_size:SetVisible(true)		
		b_indicators_update_font:SetVisible(true)
        i_arrow_size:SetVisible(false)
        i_arrow_base:SetVisible(false)
        desync_clr2:SetVisible(false)
        desync_clr:SetVisible(false)
        display_mindmg:SetVisible(false)
    else
        mc_indicators:SetVisible(false)
		i_indicators_base:SetVisible(false)
		i_indicators_size:SetVisible(false)
		i_indicators_font:SetVisible(false)
        display_mindmg:SetVisible(true)
        i_arrow_size:SetVisible(true)
        i_arrow_base:SetVisible(true)
        desync_clr2:SetVisible(true)
        desync_clr:SetVisible(true)		
		b_indicators_update_font:SetVisible(false)
    end
else
		c_indicators_style:SetVisible(false)
		mc_indicators:SetVisible(false)
		i_indicators_base:SetVisible(false)
		i_indicators_size:SetVisible(false)
		i_indicators_font:SetVisible(false)
		i_arrow_size:SetVisible(false)		
		b_indicators_update_font:SetVisible(false)
        i_arrow_size:SetVisible(false)
        i_arrow_base:SetVisible(false)
        desync_clr2:SetVisible(false)
        desync_clr:SetVisible(false)
        display_mindmg:SetVisible(false)
end


c_menu_kill_say:SetVisible(misc_switch)
c_menu_kill_say_words:SetVisible(misc_switch)
c_leg_fucker:SetVisible(misc_switch)

if visuals_switch and mc_indicators:GetBool(0) and c_indicators_style:GetInt() == 1 then
	i_arrow_base:SetVisible(true)
	i_arrow_size:SetVisible(true)
else
	i_arrow_base:SetVisible(false)
	i_arrow_size:SetVisible(false)
end

if watermark_clr:GetBool() and visuals_switch then
	watermark_options:SetVisible(true)
else
	watermark_options:SetVisible(false)
end

if c_indicators_style:GetInt() == 2 and visuals_switch then
        i_arrow_size:SetVisible(true)
        i_arrow_base:SetVisible(true)
else
	        i_arrow_size:SetVisible(false)
        i_arrow_base:SetVisible(false)
end

end
		
ui_lightning()

watermark_clr:RegisterCallback(ui_lightning)
c_indicators_style:RegisterCallback(ui_lightning)
mc_indicators:RegisterCallback(ui_lightning)
misc_enable:RegisterCallback(ui_lightning)
visuals_enable:RegisterCallback(ui_lightning)
aimbot.mode:RegisterCallback(ui_lightning)
aimbot.enable:RegisterCallback(ui_lightning)
antiaim_enable:RegisterCallback(ui_lightning)
doubletap_enable:RegisterCallback(ui_lightning)
