
events.mouse_input:set(function()
    return not (ui.get_alpha() > 0)
end)
local render_circle, render_shadow, ui_create, ui_get_icon, ui_sidebar ,entity_get, entity_get_local_player, ffi_cast, ffi_cdef, ffi_new, ffi_typeof, math_floor, fn, math_modf, render_blur, render_circle_outline, render_line, render_rect_outline, render_screen_size, render_text, render_world_to_screen, ui_find, utils_create_interface, utils_get_netvar_offset, vector, color = render.circle, render.shadow, ui.create, ui.get_icon, ui.sidebar, entity.get, entity.get_local_player, ffi.cast, ffi.cdef, ffi.new, ffi.typeof, math.floor, fn, math.modf, render.blur, render_circle_outline, render.line, render.rect_outline, render.screen_size, render.text, render.world_to_screen, ui.find, utils.create_interface, utils.get_netvar_offset, vector, color
local ffi = require("ffi")
ffi.cdef[[ 

    typedef struct
    {
        float x;
        float y;
        float z;
    } Vector_t;
    
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);

    typedef struct
    {
        char    pad0[0x60]; // 0x00
        void* pEntity; // 0x60
        void* pActiveWeapon; // 0x64
        void* pLastActiveWeapon; // 0x68
        float        flLastUpdateTime; // 0x6C
        int            iLastUpdateFrame; // 0x70
        float        flLastUpdateIncrement; // 0x74
        float        flEyeYaw; // 0x78
        float        flEyePitch; // 0x7C
        float        flGoalFeetYaw; // 0x80
        float        flLastFeetYaw; // 0x84
        float        flMoveYaw; // 0x88
        float        flLastMoveYaw; // 0x8C // changes when moving/jumping/hitting ground
        float        flLeanAmount; // 0x90
        char         pad1[0x4]; // 0x94
        float        flFeetCycle; // 0x98 0 to 1
        float        flMoveWeight; // 0x9C 0 to 1
        float        flMoveWeightSmoothed; // 0xA0
        float        flDuckAmount; // 0xA4
        float        flHitGroundCycle; // 0xA8
        float        flRecrouchWeight; // 0xAC
        Vector_t        vecOrigin; // 0xB0
        Vector_t        vecLastOrigin;// 0xBC
        Vector_t        vecVelocity; // 0xC8
        Vector_t        vecVelocityNormalized; // 0xD4
        Vector_t        vecVelocityNormalizedNonZero; // 0xE0
        float        flVelocityLenght2D; // 0xEC
        float        flJumpFallVelocity; // 0xF0
        float        flSpeedNormalized; // 0xF4 // clamped velocity from 0 to 1
        float        flRunningSpeed; // 0xF8
        float        flDuckingSpeed; // 0xFC
        float        flDurationMoving; // 0x100
        float        flDurationStill; // 0x104
        bool        bOnGround; // 0x108
        bool        bHitGroundAnimation; // 0x109
        char    pad2[0x2]; // 0x10A
        float        flNextLowerBodyYawUpdateTime; // 0x10C
        float        flDurationInAir; // 0x110
        float        flLeftGroundHeight; // 0x114
        float        flHitGroundWeight; // 0x118 // from 0 to 1, is 1 when standing
        float        flWalkToRunTransition; // 0x11C // from 0 to 1, doesnt change when walking or crouching, only running
        char    pad3[0x4]; // 0x120
        float        flAffectedFraction; // 0x124 // affected while jumping and running, or when just jumping, 0 to 1
        char    pad4[0x208]; // 0x128
        float        flMinBodyYaw; // 0x330
        float        flMaxBodyYaw; // 0x334
        float        flMinPitch; //0x338
        float        flMaxPitch; // 0x33C
        int            iAnimsetVersion; // 0x340
    } CCSGOPlayerAnimationState_534535_t;

	typedef struct {
	} SYSTEMTIME, *LPSYSTEMTIME;
	void GetSystemTime(LPSYSTEMTIME lpSystemTime);
	void GetLocalTime(LPSYSTEMTIME lpSystemTime);
	
	typedef struct {
		float x;
		float y;
		float z;
	} vec3_struct;
	
	typedef void*(__thiscall* c_entity_list_get_client_entity_t)(void*, int);
	typedef void*(__thiscall* c_entity_list_get_client_entity_from_handle_t)(void*, uintptr_t);
	typedef int(__thiscall* c_weapon_get_muzzle_attachment_index_first_person_t)(void*, void*);
	typedef bool(__thiscall* c_entity_get_attachment_t)(void*, int, vec3_struct*);
	
	bool DeleteUrlCacheEntryA(const char* lpszUrlName);
	void* __stdcall URLDownloadToFileA(void* LPUNKNOWN, const char* LPCSTR, const char* LPCSTR2, int a, int LPBINDSTATUSCALLBACK);
]]

local ffi_handler = {}
local muzzle = {}
Luaname_upper = "INVERSE"
Luaname_normal = "inverse"
Luaname = "Inverse"

local lerp = function (a, b, percentage) return math_floor(a + (b - a) * percentage) end

ffi_handler.bind_argument = function(fn, arg)
return function(...)
return fn(arg, ...)
end
end

ffi_handler.interface_type = ffi_typeof("uintptr_t**")

ffi_handler.i_client_entity_list = ffi_cast(ffi_handler.interface_type, utils_create_interface("client.dll", "VClientEntityList003"))
ffi_handler.get_client_entity = ffi_handler.bind_argument(ffi_cast("c_entity_list_get_client_entity_t", ffi_handler.i_client_entity_list[0][3]), ffi_handler.i_client_entity_list)

muzzle.pos = vector(0, 0, 0)

muzzle.get = function()

local me = entity_get_local_player()
if not me or entity_get_local_player().m_iHealth < 1 then return end

local my_address = ffi_handler.get_client_entity(me:get_index())
if not my_address then return end

local my_weapon_handle = me.m_hActiveWeapon
local my_weapon = entity.get(my_weapon_handle)
if not my_weapon then return end

local my_weapon_address = ffi_handler.get_client_entity(my_weapon:get_index())
if not my_weapon_address then return end

local my_viewmodel_handle = me.m_hViewModel[0]
local my_viewmodel = entity.get(my_viewmodel_handle)
if not my_viewmodel then return end

local my_viewmodel_addres = ffi_handler.get_client_entity(my_viewmodel:get_index())
if not my_viewmodel_addres then return end

local viewmodel_vtbl = ffi.cast(ffi_handler.interface_type, my_viewmodel_addres)[0]
local weapon_vtbl = ffi.cast(ffi_handler.interface_type, my_weapon_address)[0]

local get_viewmodel_attachment_fn = ffi.cast("c_entity_get_attachment_t", viewmodel_vtbl[84])
local get_muzzle_attachment_index_fn = ffi.cast("c_weapon_get_muzzle_attachment_index_first_person_t", weapon_vtbl[468])
local muzzle_attachment_index = get_muzzle_attachment_index_fn(my_weapon_address, my_viewmodel_addres)
local ret = ffi.new("vec3_struct[1]")
local state = get_viewmodel_attachment_fn(my_viewmodel_addres, muzzle_attachment_index, ret)

local final_pos = vector(ret[0].x, ret[0].y, ret[0].z)
return {state = state,pos = final_pos} end


local MTools = require("neverlose/mtools")
local gradient = require("neverlose/gradient")
local better_json = require("neverlose/better_json")
local anti_aim = require("neverlose/anti_aim")
local drag_system = require("neverlose/drag_system")
local base64 = require("neverlose/base64")
local clipboard = require("neverlose/clipboard")
local vmt_hook = require("neverlose/vmt_hook")

screen_size = render.screen_size()
username, screen_center = common.get_username(), screen_size * 0.5
events.render:set(function()
	local_player = entity.get_local_player()
	if local_player == nil then return end
end)

local Mainmenunick = gradient.text_animate(username, -3, {
    color(80, 80, 110), 
    color(150, 150, 215)
})
local Lastupdate = gradient.text_animate("22.01.2023", -3, {
    color(80, 80, 110), 
    color(150, 150, 215)
})
local Sidebarcolor = gradient.text_animate("KITAXE~"..Luaname_upper, -3, {
    color(80, 80, 110), 
    color(150, 150, 215)
})
local INVERSE = gradient.text_animate(Luaname_upper, -3, {
    color(80, 80, 110), 
    color(150, 150, 215)
})
ui.sidebar(Sidebarcolor:get_animated_text(), 'paw')

-- MAIN
HomeMenu = ui.create(ui.get_icon("paw").." Home", ui.get_icon("star").." Informations")
HomeLinks = ui.create(ui.get_icon("paw").." Home", ui.get_icon("wifi").." Reference")
HomeMenu:label("Welcome, "..Mainmenunick:get_animated_text())
HomeMenu:label("Currect build: "..INVERSE:get_animated_text())
HomeMenu:label("Last update: "..Lastupdate:get_animated_text())
HomeMenu:label("»  Stay pasted » Stay kitaxe")
HomeMenu:label("»  Report bugs on discord")
HomeMenu:label("»  Giveaways, support only on discord server")
local Discordbutton = HomeLinks:button(ui.get_icon("link").."						  Discord Link     						", function() 
	panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/og4leaks")
end)
local Configbutton = HomeLinks:button(ui.get_icon("star").."				          Best cfgs/luas leak here     				 		", function() 
	panorama.SteamOverlayAPI.OpenExternalBrowserURL("discord.gg/og4leaks")
end)

-- REFS
local refs = {
	dmg = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
	pa = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),
	hs = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
	dt = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
	sw = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
	fd = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
	fl = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
	fs = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
	fs2 = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Disable Yaw Modifiers"),
	fs3 = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Body Freestanding"),
	avoidbackstab = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
	Pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
	Yawbase = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
	Yawoffset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
	Yawmodifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
	YawmodifierOffset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
	DesyncLeft = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left limit"),
	DesyncRight = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right limit"),
	Options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
	Options2 = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
	Freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
	leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement"),
	defensive = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
	dtlimit = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Fake Lag Limit"),
}

-- ANTIAIM
MainAntiaim = ui.create(ui.get_icon("star").." Anti-Aim", ui.get_icon("star").." Anti-Aim")
BuilderAntiaim = ui.create(ui.get_icon("star").." Anti-Aim", ui.get_icon("hammer").." Anti-Aim Builder")

AntiAimarray = {}
BodyYawarray = {}
local var = {
    player_states = {"Standing", "Moving", "Jumping", "Jumping-Duck", "Crouching", "Slowwalk"},
	player_states_idx = {["Standing"] = 1, ["Moving"] = 2, ["Jumping"] = 3, ["Jumping-Duck"] = 4, ["Crouching"] = 5, ["Slowwalk"] = 6},
    p_state = 0
}

AntiAimarray[0] = {
    Condition = BuilderAntiaim:combo("Condition: ", var.player_states)
}

for i = 1,6 do 
	AntiAimarray[i] ={
		Yawmode = BuilderAntiaim:combo("Yaw Mode", "L&R", "3-Way", "5-Way"),
		YawL = BuilderAntiaim:slider("Yaw Left", -180, 180, 0),
		YawR = BuilderAntiaim:slider("Yaw Right", -180, 180, 0),
		TWay1 = BuilderAntiaim:slider("3-Way offset 1", -180, 180, 0),
		TWay2 = BuilderAntiaim:slider("3-Way offset 2", -180, 180, 0),
		TWay3 = BuilderAntiaim:slider("3-Way offset 3", -180, 180, 0),
		FWay1 = BuilderAntiaim:slider("5-Way offset 1", -180, 180, 0),
		FWay2 = BuilderAntiaim:slider("5-Way offset 2", -180, 180, 0),
		FWay3 = BuilderAntiaim:slider("5-Way offset 3", -180, 180, 0),
		FWay4 = BuilderAntiaim:slider("5-Way offset 4", -180, 180, 0),
		FWay5 = BuilderAntiaim:slider("5-Way offset 5", -180, 180, 0),
		YawModifier = BuilderAntiaim:combo("Jitter Modifier", "Disabled", "Center", "Offset", "Random", "Spin"),
		JitterOffset = BuilderAntiaim:slider("Jitter Offset", -180, 180, 0),
		BodyYaw = BuilderAntiaim:switch("Body Yaw")
	}
end

for i = 1,6 do 
	bodyyawoptions = AntiAimarray[i].BodyYaw:create()

	BodyYawarray[i] ={
		LeftLimit = bodyyawoptions:slider("Left Limit", 0, 60, 58),
		RightLimit = bodyyawoptions:slider("Right Limit", 0, 60, 58),
		BodyYaw = bodyyawoptions:selectable("Options", "Avoid Overlap", "Jitter", "Randomize Jitter"),
		Freestanding = bodyyawoptions:combo("Freestanding", "Off", "Peek Real", "Peek Fake"),

	}
end


local Antiaim = {
	mode = MainAntiaim:combo("Mode", "Custom"),
	Yawbase = MainAntiaim:combo("Yaw Base", "At-Targets", "Local View"),
	avoidbackstab = MainAntiaim:switch("Avoid Backstab"),
	freestand = MainAntiaim:switch("Freestanding"),
	forcedefensive = MainAntiaim:switch("Adaptive Force-Defensive"),
	PitchExploit = MainAntiaim:switch("\a97DB99FFDefensive-Pitch Exploit"),
	animbreaker = MainAntiaim:selectable("\aFFB9B9C8Anim. Breakers", {'Static legs in air', 'Moonwalk'}, 0)
}

sim_time_dt = 0
to_draw = "no"
to_up = "no"
to_draw_ticks = 0
go_ = "no"

local var_table = {}
local prev_simulation_time = 0

local function time_to_ticks(t)
    return math.floor(0.5 + (t / globals.tickinterval))
end
local diff_sim = 0
function var_table:sim_diff() 
	local_player = entity.get_local_player()
	if local_player == nil then return end
    local current_simulation_time = time_to_ticks(local_player["m_flSimulationTime"])
    local diff = current_simulation_time - prev_simulation_time
    prev_simulation_time = current_simulation_time
    diff_sim = diff
    return diff_sim
end

function defensive_indicator()
	local_player = entity.get_local_player()
	if local_player == nil then return end
    local diff_mmeme = var_table.sim_diff()
    if diff_mmeme <= -1 then
        to_draw = "yes"
        to_up = "yes"
        go_ = "yes"
     
    end
end 

function defensive_indicator_paint()
    if to_draw == "yes" and refs.dt:get() then

        draw_art = to_draw_ticks * 100 / 57

        to_draw_ticks = to_draw_ticks + 1

        if to_draw_ticks == 12 then
            to_draw_ticks = 0
            to_draw = "no"
            to_up = "no"
        end
    end
end

up_abuse = function()
	refs.Pitch:set("Down")
    if not Antiaim.PitchExploit:get() then return end
	refs.Pitch:set("Down")
    if to_up == "yes" then
		refs.Pitch:set("Fake Up")
        if not refs.dt:get() or not refs.dt:get() then
            to_up = "no"
        end
    end
end


local function AntiAimshow()
	active_i = var.player_states_idx[AntiAimarray[0].Condition:get()]
	for i = 1,6 do 
		AntiAimarray[0].Condition:visibility(AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way")
		AntiAimarray[i].Yawmode:visibility(active_i == i)
		AntiAimarray[i].YawL:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R"))
		AntiAimarray[i].YawR:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R"))
		AntiAimarray[i].TWay1:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "3-Way"))
		AntiAimarray[i].TWay2:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "3-Way"))
		AntiAimarray[i].TWay3:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "3-Way"))
		AntiAimarray[i].FWay1:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "5-Way"))
		AntiAimarray[i].FWay2:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "5-Way"))
		AntiAimarray[i].FWay3:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "5-Way"))
		AntiAimarray[i].FWay4:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "5-Way"))
		AntiAimarray[i].FWay5:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "5-Way"))
		AntiAimarray[i].YawModifier:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
		AntiAimarray[i].JitterOffset:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
		AntiAimarray[i].BodyYaw:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
		BodyYawarray[i].LeftLimit:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
		BodyYawarray[i].RightLimit:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
		BodyYawarray[i].BodyYaw:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
		BodyYawarray[i].Freestanding:visibility(active_i == i and (AntiAimarray[i].Yawmode:get() == "L&R" or AntiAimarray[i].Yawmode:get() == "5-Way" or AntiAimarray[i].Yawmode:get() == "3-Way"))
	end
end

local function choking(cmd)
    local Choke = false

    if cmd.send_packet == false or globals.choked_commands > 1 then
        Choke = true
    else
        Choke = false
    end

    return Choke
end

local function choking(cmd)
    local Choke = false

    if cmd.send_packet == false or globals.choked_commands > 1 then
        Choke = true
    else
        Choke = false
    end

    return Choke
end

local current_stage = 1
local currect_mode = 1
local function Antiaimworking(cmd)
local player_inverter = local_player.m_flPoseParameter[11] * 120 - 60 <= 0 and true or false
local on_ground = local_player.m_fFlags == bit.bor(local_player.m_fFlags, bit.lshift(1, 0))
local on_crouch = local_player.m_fFlags == bit.bor(local_player.m_fFlags, bit.lshift(1, 2))
local velocity = local_player.m_vecVelocity
local speed = velocity:length()
if speed <= 2 then
	var.p_state = 1
end
if speed >= 3 and refs.sw:get() == false then
	var.p_state = 2
end
if on_ground == false and on_crouch == false then
	var.p_state = 3
end
if on_ground == false and on_crouch == true then
	var.p_state = 4
end
if on_crouch == true and on_ground == true then
	var.p_state = 5
end
if refs.sw:get() == true then
	var.p_state = 6
end
if Antiaim.forcedefensive:get() then
	refs.defensive:set("Always On")
	refs.dtlimit:set(1)
else
	refs.defensive:set("On Peek")
	refs.dtlimit:set(1)
end
	if AntiAimarray[var.p_state].Yawmode:get() == "L&R" then
		if player_inverter == true then
			refs.Yawoffset:set(AntiAimarray[var.p_state].YawR:get())
		else
			refs.Yawoffset:set(AntiAimarray[var.p_state].YawL:get())
		end
		refs.Yawmodifier:set(AntiAimarray[var.p_state].YawModifier:get())
		refs.YawmodifierOffset:set(AntiAimarray[var.p_state].JitterOffset:get())
		if AntiAimarray[var.p_state].BodyYaw:get() then
			refs.Options2:set(true)
			refs.DesyncLeft:set(BodyYawarray[var.p_state].LeftLimit:get())
			refs.DesyncRight:set(BodyYawarray[var.p_state].RightLimit:get())
			refs.Options:set(BodyYawarray[var.p_state].BodyYaw:get())
			refs.Freestanding:set(BodyYawarray[var.p_state].Freestanding:get())
		end
		if Antiaim.Yawbase:get() == "At-Targets" then
			refs.Yawbase:set("At Target")
		else
			refs.Yawbase:set(Antiaim.Yawbase:get())
		end
	end
	if (AntiAimarray[var.p_state].Yawmode:get() == "5-Way" or AntiAimarray[var.p_state].Yawmode:get() == "3-Way") then
		local three_ways = {AntiAimarray[var.p_state].TWay1:get() ,AntiAimarray[var.p_state].TWay1:get(), AntiAimarray[var.p_state].TWay2:get(), AntiAimarray[var.p_state].TWay3:get(), AntiAimarray[var.p_state].TWay3:get()}
		local five_ways = {AntiAimarray[var.p_state].FWay1:get(), AntiAimarray[var.p_state].FWay2:get(), AntiAimarray[var.p_state].FWay3:get(), AntiAimarray[var.p_state].FWay4:get(), AntiAimarray[var.p_state].FWay5:get()}
		if cmd.command_number % 4 > 1 and choking(cmd) == false then
			current_stage = current_stage + 1
		end
		if current_stage == 6 and AntiAimarray[var.p_state].Yawmode:get() == "3-Way" then
			current_stage = 1
		end

		if current_stage == 6 and AntiAimarray[var.p_state].Yawmode:get() == "5-Way" then
			current_stage = 1
		end

		refs.Yawoffset:set(AntiAimarray[var.p_state].Yawmode:get() == "5-Way" and five_ways[current_stage] or AntiAimarray[var.p_state].Yawmode:get() == "3-Way" and three_ways[current_stage])
		refs.Yawmodifier:set(AntiAimarray[var.p_state].YawModifier:get())
		refs.YawmodifierOffset:set(AntiAimarray[var.p_state].JitterOffset:get())
		if AntiAimarray[var.p_state].BodyYaw:get() then
			refs.Options2:set(true)
			refs.DesyncLeft:set(BodyYawarray[var.p_state].LeftLimit:get())
			refs.DesyncRight:set(BodyYawarray[var.p_state].RightLimit:get())
			refs.Options:set(BodyYawarray[var.p_state].BodyYaw:get())
			refs.Freestanding:set(BodyYawarray[var.p_state].Freestanding:get())
		end
	end
end

local function antibackstab()
	
	
	if Antiaim.avoidbackstab:get() then
		refs.avoidbackstab:set(true)
	else
		refs.avoidbackstab:set(false)
	end
end

local function freeestandingg()
	
	
	if Antiaim.freestand:get() then
		refs.fs:set(true)
		refs.fs2:set(true)
		refs.fs3:set(true)
	else
		refs.fs:set(false)
		refs.fs2:set(false)
		refs.fs3:set(false)
	end
end


local function in_air()
    local b = entity.get_local_player()
        if b == nil then
            return
        end
    local flags = localplayer["m_fFlags"]
    
    if bit.band(flags, 1) == 0 then
        return true
    end
    
    return false
end

entity_list_pointer = ffi.cast('void***', utils.create_interface('client.dll', 'VClientEntityList003'))
get_client_entity_fn = ffi.cast('GetClientEntity_4242425_t', entity_list_pointer[0][3])
function get_entity_address(ent_index)
	local addr = get_client_entity_fn(entity_list_pointer, ent_index)
	return addr
end

hook_helper = {
	copy = function(dst, src, len)
	return ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
	end,

	virtual_protect = function(lpAddress, dwSize, flNewProtect, lpflOldProtect)
	return ffi.C.VirtualProtect(ffi.cast('void*', lpAddress), dwSize, flNewProtect, lpflOldProtect)
	end,

	virtual_alloc = function(lpAddress, dwSize, flAllocationType, flProtect, blFree)
	local alloc = ffi.C.VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
	if blFree then
		table.insert(buff.free, function()
		ffi.C.VirtualFree(alloc, 0, 0x8000)
		end)
	end
	return ffi.cast('intptr_t', alloc)
end
}

buff = {free = {}}
vmt_hook = {hooks = {}}

function vmt_hook.new(vt)
    local new_hook = {}
    local org_func = {}
    local old_prot = ffi.new('unsigned long[1]')
    local virtual_table = ffi.cast('intptr_t**', vt)[0]

    new_hook.this = virtual_table
    new_hook.hookMethod = function(cast, func, method)
    org_func[method] = virtual_table[method]
    hook_helper.virtual_protect(virtual_table + method, 4, 0x4, old_prot)

    virtual_table[method] = ffi.cast('intptr_t', ffi.cast(cast, func))
    hook_helper.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)

    return ffi.cast(cast, org_func[method])
end

new_hook.unHookMethod = function(method)
    hook_helper.virtual_protect(virtual_table + method, 4, 0x4, old_prot)
    local alloc_addr = hook_helper.virtual_alloc(nil, 5, 0x1000, 0x40, false)
    local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)

    trampoline_bytes[0] = 0xE9
    ffi.cast('int32_t*', trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5

    hook_helper.copy(alloc_addr, trampoline_bytes, 5)
    virtual_table[method] = ffi.cast('intptr_t', alloc_addr)

    hook_helper.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)
    org_func[method] = nil
end

new_hook.unHookAll = function()
    for method, func in pairs(org_func) do
        new_hook.unHookMethod(method)
    end
end

table.insert(vmt_hook.hooks, new_hook.unHookAll) 
    return new_hook
end

events.shutdown:set(function()
    for _, reset_function in ipairs(vmt_hook.hooks) do
        reset_function()
    end
end)

hooked_function = nil
ground_ticks, end_time = 1, 0
function updateCSA_hk(thisptr, edx)
    if entity.get_local_player() == nil or ffi.cast('uintptr_t', thisptr) == nil then return end
    hooked_function(thisptr, edx)
	if Antiaim.animbreaker:get("Moonwalk") then
        ffi.cast('float*', ffi.cast('uintptr_t', thisptr) + 10104)[7] = 0
        refs.leg_movement:set('Walking')
    end
    if Antiaim.animbreaker:get("Static legs in air") then
        ffi.cast('float*', ffi.cast('uintptr_t', thisptr) + 10104)[6] = 1
    end
end


function anim_state_hook()
    local local_player_ptr = get_entity_address(local_player:get_index())
    if not local_player_ptr or hooked_function then return end
    local C_CSPLAYER = vmt_hook.new(local_player_ptr)
    hooked_function = C_CSPLAYER.hookMethod('void(__fastcall*)(void*, void*)', updateCSA_hk, 224)
end

-- VISUALS
create = MTools.FileSystem.CreateDir("nl\\KITAXE V2");
MTools.Network.Download(
    "https://fonts.cdnfonts.com/s/55266/smallest_pixel-7.ttf", 
    "nl\\KITAXE V2\\pixel.ttf", 
    true,
    97
);
MTools.Network.Download(
    "https://cdn.discordapp.com/attachments/609330493565042688/1066331134813802566/cYMjlkf.png", 
    "nl\\KITAXE V2\\LGBT.png", 
    true,
    97
);
MTools.Network.Download(
    "https://cdn.discordapp.com/attachments/609330493565042688/1066331138060189820/3LHBPEC.png", 
    "nl\\KITAXE V2\\LGBT+.png", 
    true,
    97
);

local font = {
	pixel = render.load_font("nl\\KITAXE V2\\pixel.ttf", 10, "o"),
    verdana = render.load_font("Verdana", 12, "d"),
}

VisualsFeatures = ui.create(ui.get_icon("cogs").." Features", ui.get_icon("paint-brush").." Visuals")
local Visuals = {
    Indicators = VisualsFeatures:switch("Crosshair Indicator"),
	Widgets = VisualsFeatures:switch("Widgets"),
	Logs = VisualsFeatures:switch("Hitlogs"),
    Infopanel = VisualsFeatures:switch("Infopanel"),
	Muzzleindicators = VisualsFeatures:switch("Muzzle Indicators"),
	MinDMG = VisualsFeatures:switch("Minimum Damage Indicator")
}

Indicatorsgroup = Visuals.Indicators:create()
Widgetsgroup = Visuals.Widgets:create()
Logsgroup = Visuals.Logs:create()
Infopanelgroup = Visuals.Infopanel:create()
Muzzlegroup = Visuals.Muzzleindicators:create()
Mindmggroup = Visuals.MinDMG:create()

local VisualsCogs = {
	Bindstoshow = Indicatorsgroup:selectable("Display Indicators", "Minimum DMG", "Double Tap", "Hide Shoot", "Safe Points", "Hit Chance", "Freestanding"),
	Indicatorsglow = Indicatorsgroup:color_picker("Glow color", color(200, 200, 230, 255)),
    Indicatorscolor = Indicatorsgroup:color_picker("First color", color(80, 80, 110, 255)),
	Indicatorscolortwo = Indicatorsgroup:color_picker("Second color", color(150, 150, 215, 255)),
	accent_col = Widgetsgroup:color_picker("Text color", color(150,170,215,255)),
    accent_colglow = Widgetsgroup:color_picker("Glow color", color()),
	solus_widgets = Widgetsgroup:selectable("Widgets", {"Watermark", "Keybinds", "Spectator list"}),
	solus_combo = Widgetsgroup:combo("Style", {"Modern"}),
	solus_combo2 = Widgetsgroup:combo("Cheat name", {"Neverlose", "Gamesense"}),
	hitlogsvalue = Logsgroup:slider("Hitlogs max", 1, 10, 3, 1, ""),
	hitlogs = Logsgroup:selectable("Hitlogs type	", "Console", "Event Logs", "Under Crosshair", "Sidelogs"),
	hitlogsfont = Logsgroup:combo("Hitlogs font	", "Pixel-7", "Kibit"),
	hitlogstext = Logsgroup:color_picker("Hit color", color(165,190,215,255)),
	hitlogstext2 = Logsgroup:color_picker("Miss color", color(215,175,115,255)),
	dmgfont = Mindmggroup:combo("Font", {"Pixel", "Kibit"}),
    Infopanelcolor = Infopanelgroup:color_picker("First color", color(50, 50, 80, 255)),
    Infopanelcolortwo = Infopanelgroup:color_picker("Second color", color(180, 180, 220, 255)),
    Infopanelflag = Infopanelgroup:combo("Flag", {"Disable", "LGBT", "LGBT TRANS"}),
	Muzzlecolor = Muzzlegroup:color_picker("Color", color(135, 150, 210, 255)),
	Bindstoshow2 = Muzzlegroup:selectable("Display Indicators", "Fake Ping", "Double Tap", "Hide Shoot", "Freestanding", "Peek Assist"),
}

local holo_x, holo_y = 0, 0
local Gradientmuzzle = render.load_font("Calibri", vector(19,20.5), "adb")
local function Muzzleindicatorss()
	if not Visuals.Muzzleindicators:get() then return end
	local active_binds = ui.get_binds()
	local muzzle_temp = muzzle.get()

	muzzlespacing = -10

	MTools.Animation:Register("MTools");
	MTools.Animation:Update("MTools", 6);

	if VisualsCogs.Bindstoshow2:get(1) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Fake Latency" then
				if active_binds[i].active then
					muzzleping = MTools.Animation:Lerp("MTools", "muzzleping", (active_binds[i].active), vector(0, muzzlespacing), vector(0, muzzlespacing + 20), 10);
					muzzlespacing = muzzlespacing + 28
				end
			end
		end
	end
	if refs.dt:get() and VisualsCogs.Bindstoshow2:get(2) then
		muzzledt = MTools.Animation:Lerp("MTools", "muzzledt", (refs.dt:get()), vector(0, muzzlespacing), vector(0, muzzlespacing + 20), 10);
		muzzlespacing = muzzlespacing + 28
	end
	if refs.hs:get() and VisualsCogs.Bindstoshow2:get(3) then
		muzzlehs = MTools.Animation:Lerp("MTools", "muzzlehs", (refs.hs:get()), vector(0, muzzlespacing), vector(0, muzzlespacing + 20), 10);
		muzzlespacing = muzzlespacing + 28
	end
	if refs.fs:get() and VisualsCogs.Bindstoshow2:get(4) then
		muzzlefs = MTools.Animation:Lerp("MTools", "muzzlefs", (refs.fs:get()), vector(0, muzzlespacing), vector(0, muzzlespacing + 20), 10);
		muzzlespacing = muzzlespacing + 28
	end
	if refs.pa:get() and VisualsCogs.Bindstoshow2:get(5) then
		muzzlepa = MTools.Animation:Lerp("MTools", "muzzlepa", (refs.pa:get()), vector(0, muzzlespacing), vector(0, muzzlespacing + 20),10);
		muzzlespacing = muzzlespacing + 28
	end

	if muzzle_temp then
	muzzle.pos = muzzle_temp.pos
	end
	if not entity.get_local_player() then return end
	if not entity.get_local_player():is_alive() then return end
	local active_weapon = entity.get_local_player():get_player_weapon()
	if not active_weapon then return end
	local weapon_id = active_weapon:get_classname()
	local knife = weapon_id == "CKnife"
	if knife then return end
	if weapon_id == ("CIncendiaryGrenade") then return end
	if weapon_id == ("CMolotovGrenade") then return end
	if weapon_id == ("CHEGrenade") then return end
	if weapon_id == ("CSmokeGrenade") then return end
	if weapon_id == ("CDecoyGrenade") then return end
	if weapon_id == ("CFlashbang") then return end
	if weapon_id == ("CC4") then return end
	if weapon_id == ("CItem_Healthshot") then return end
	if weapon_id == ("CWeaponElite") then return end
	if weapon_id == ("CWeaponSawedoff") then return end
	local hitbox = entity_get_local_player():get_hitbox_position(3)
	local world_stand = render_world_to_screen(hitbox)
	local firth = render_world_to_screen(muzzle.pos)


	if not ui_find("Visuals", "World", "Main", "Force Thirdperson"):get() then
		if active_weapon == nil then return end
		if entity.get_local_player().m_bIsScoped then return end
		if firth.x ~= nil and firth.y ~= nil then
	
			local screensize = render.screen_size()
			lp = entity.get_local_player()
			if lp == nil then return end
			local Gradientmuzzle2 = render.measure_text(Gradientmuzzle, "c", "DT")
			local Gradientmuzzle_x = 0
			if refs.dt:get() and VisualsCogs.Bindstoshow2:get(2) then
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzledt.y), vector(holo_x-147-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzledt.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzledt.y), vector(holo_x-147-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzledt.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 150, firth.y - 12+muzzledt.y), VisualsCogs.Muzzlecolor:get(), "с", "DT")
			end
			if refs.hs:get() and VisualsCogs.Bindstoshow2:get(3) then
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlehs.y), vector(holo_x-147-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlehs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlehs.y), vector(holo_x-147-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlehs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 150, firth.y - 12 + muzzlehs.y), VisualsCogs.Muzzlecolor:get(), "с", "HS")
			end
			if refs.fs:get() and VisualsCogs.Bindstoshow2:get(4) then
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlefs.y), vector(holo_x-147-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlefs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlefs.y), vector(holo_x-147-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlefs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 150, firth.y - 12 + muzzlefs.y), VisualsCogs.Muzzlecolor:get(), "с", "FS")
			end
			if VisualsCogs.Bindstoshow2:get(1) then
				for i in pairs(active_binds) do
					if active_binds[i].name == "Fake Latency" then
						if active_binds[i].active then
							render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzleping.y), vector(holo_x-147-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzleping.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
							render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzleping.y), vector(holo_x-147-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzleping.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
							render.text(Gradientmuzzle, vector(holo_x - 150, firth.y - 12 + muzzleping.y), VisualsCogs.Muzzlecolor:get(), "с", "PING")
						end
					end
				end
			end
			if refs.pa:get() and VisualsCogs.Bindstoshow2:get(5) then
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlepa.y), vector(holo_x-147-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlepa.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-168+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlepa.y), vector(holo_x-147-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlepa.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 150, firth.y - 12 + muzzlepa.y), VisualsCogs.Muzzlecolor:get(), "с", "PEEK")
			end

	
		local lerpx = lerp(holo_x, firth.x + 100, globals.frametime * 50)
		local lerpy = lerp(holo_y, firth.y - 90, globals.frametime * 8)
		if lerpx >= 0 and lerpx <= 2000 and lerpy >= 0 and lerpy <= 1500 then
			holo_x = lerp(holo_x, firth.x + 100, globals.frametime * 50)
			holo_y = lerp(holo_y, firth.y - 100, globals.frametime * 8)
		else
			holo_x = firth.x + 10
			holo_y = firth.y - 90
				end
			end
		end
		if ui_find("Visuals", "World", "Main", "Force Thirdperson"):get() then
		if world_stand.x ~= nil and world_stand.y ~= nil then
			local screensize = render.screen_size()
			lp = entity.get_local_player()
			if lp == nil then return end
			local Gradientmuzzle2 = render.measure_text(Gradientmuzzle, "c", "DT")
			local Gradientmuzzle_x = 0

			if refs.dt:get() and VisualsCogs.Bindstoshow2:get(2) then
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzledt.y), vector(holo_x-297-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzledt.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzledt.y), vector(holo_x-297-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzledt.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 300, firth.y - 12+muzzledt.y), VisualsCogs.Muzzlecolor:get(), "с", "DT")
			end
			if refs.hs:get() and VisualsCogs.Bindstoshow2:get(3) then
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlehs.y), vector(holo_x-297-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlehs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlehs.y), vector(holo_x-297-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlehs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 300, firth.y - 12 + muzzlehs.y), VisualsCogs.Muzzlecolor:get(), "с", "HS")
			end
			if refs.fs:get() and VisualsCogs.Bindstoshow2:get(4) then
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlefs.y), vector(holo_x-297-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlefs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlefs.y), vector(holo_x-297-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlefs.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 300, firth.y - 12 + muzzlefs.y), VisualsCogs.Muzzlecolor:get(), "с", "FS")
			end
			if VisualsCogs.Bindstoshow2:get(1) then
				for i in pairs(active_binds) do
					if active_binds[i].name == "Fake Latency" then
						if active_binds[i].active then
							render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzleping.y), vector(holo_x-297-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzleping.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
							render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzleping.y), vector(holo_x-297-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzleping.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
							render.text(Gradientmuzzle, vector(holo_x - 300, firth.y - 12+muzzleping.y), VisualsCogs.Muzzlecolor:get(), "с", "PING")
						end
					end
				end
			end
			if refs.pa:get() and VisualsCogs.Bindstoshow2:get(5) then
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlepa.y), vector(holo_x-297-Gradientmuzzle2.x+10,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlepa.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.gradient(vector(holo_x-318+Gradientmuzzle2.x,screensize.y/1.75+firth.y-630-2+muzzlepa.y), vector(holo_x-297-Gradientmuzzle2.x+50,screensize.y/1.75+firth.y+Gradientmuzzle2.y-630+muzzlepa.y), color(0, 0, 0, 60), color(0, 0, 0, 5), color(0, 0, 0, 50), color(0, 0, 0, 5))
				render.text(Gradientmuzzle, vector(holo_x - 300, firth.y - 12 + muzzlepa.y), VisualsCogs.Muzzlecolor:get(), "с", "PEEK")
			end

	
			local lerpx = lerp(holo_x, world_stand.x + 100, globals.frametime * 8)
			local lerpy = lerp(holo_y, world_stand.y - 90, globals.frametime * 8)
			if lerpx >= 0 and lerpx <= 2000 and lerpy >= 0 and lerpy <= 1500 then
				holo_x = lerp(holo_x, world_stand.x + 100, globals.frametime * 8)
				holo_y = lerp(holo_y, world_stand.y - 100, globals.frametime * 8)
			else
				holo_x = world_stand.x + 10
				holo_y = world_stand.y - 90
				end
			end
		end
	end


-- Infopanel
infopanel_x = Mindmggroup:slider("x", 1, screen_size.x, screen_center.x - 950)
infopanel_y = Mindmggroup:slider("y", 1, screen_size.y, screen_center.y + 10)
infopanel_x:visibility(false)
infopanel_y:visibility(false)


fnay = render.load_image(network.get("https://avatars.cloudflare.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_medium.jpg"), vector(50, 50))
getflag = render.load_image_from_file(("nl\\KITAXE V2\\LGBT.png"), vector(805,920))
getflag2 = render.load_image_from_file(("nl\\KITAXE V2\\LGBT+.png"), vector(805,920))
Infopaneltext = "kitaxe.dev ~ "..Luaname_normal.." {     }"
Infopanelvalue = 0
local Infopanel = drag_system.register({infopanel_x, infopanel_y}, vector(160, 20), "Infopanel", function(self)
    if VisualsCogs.Infopanelflag:get() == "LGBT" or VisualsCogs.Infopanelflag:get() == "LGBT TRANS" then
        Infopaneltext = "kitaxe.dev ~ "..Luaname_normal.." {     }"
    else
        Infopaneltext = "{ kitaxe.dev ~ "..Luaname_normal.." }"
    end
	local infopanelgradient = gradient.text_animate(Infopaneltext, -3, {
		VisualsCogs.Infopanelcolor:get(), 
		VisualsCogs.Infopanelcolortwo:get()
	})

	if ui.get_alpha() == 1 then
		render.rect_outline(vector(self.position.x, self.position.y), vector(self.position.x + self.size.x, self.position.y + self.size.y), color())
    end

	render.text(font.verdana, vector(self.position.x + 78, self.position.y + 8), color(), "c", infopanelgradient:get_animated_text())
    infopanelgradient:animate()
    
    if VisualsCogs.Infopanelflag:get() == "LGBT TRANS" then
        render.texture(getflag2, vector(self.position.x + 130, self.position.y + 5.5), vector(15,8), color(), f)
    elseif VisualsCogs.Infopanelflag:get() == "LGBT" then
        render.texture(getflag, vector(self.position.x + 130, self.position.y + 5.5), vector(15,8), color(), f)
    elseif VisualsCogs.Infopanelflag:get() == "Disable" then return end

end)

-- Infopanel


-- Mindmg

dmg_x = Mindmggroup:slider("x", 1, screen_size.x, screen_center.x + 10)
dmg_y = Mindmggroup:slider("y", 1, screen_size.y, screen_center.y - 25)
dmg_x:visibility(false)
dmg_y:visibility(false)
local Minimumdamage = drag_system.register({dmg_x, dmg_y}, vector(20, 20), "Mindmg", function(self)
	if VisualsCogs.dmgfont:get() == "Pixel" then
		render.text(font.pixel, vector(self.position.x + 11, self.position.y + 10), color(), "c", refs.dmg:get())
	else
		render.text(12, vector(self.position.x + 11, self.position.y + 10), color(), "c", refs.dmg:get())
	end

	if ui.get_alpha() == 1 then
		render.rect_outline(vector(self.position.x, self.position.y), vector(self.position.x + self.size.x, self.position.y + self.size.y), color())
    end
end)

-- Mindmg


--hitlogs

local screen = render.screen_size()
local hitgroup_str = {[0] = 'generic','head', 'chest', 'stomach','left arm', 'right arm','left leg', 'right leg','neck', 'generic', 'gear'}

local hitlog = {}
local sidelogs = {}
local id = 1
events.aim_ack:set(function(event)
	local me = entity.get_local_player()
	if not me then return end
	local result = event.state
	local target = entity.get(event.target)
	local text = "%"
	if target == nil then return end
    local health = target["m_iHealth"]
    local state_1 = ""
	target = entity.get(event.target)
	if target == nil then return end
	enemyavatar = target:get_steam_avatar()
	if (enemyavatar == nil or enemyavatar.width <= 5) then enemyavatar = fnay end
	
    if Visuals.Logs:get() then
		if event.state == "spread" then state_1 = "spread" end
	    if event.state == "prediction error" then state_1 = "prediction error" end
        if event.state == "correction" then state_1 = "correction" end
        if event.state == "misprediction" then state_1 = "misprediction" end
	    if event.state == "jitter correction" then state_1 = "jitter correction" end
	    if event.state == "correction" then state_1 = "resolver" end
	    if event.state == "lagcomp failure" then state_1 = "fake lag correction" end
		if event.state == "unregistered shot" then state_1 = "unregistered shot" end
		if event.state == "player death" then state_1 = "player death" end
        if event.state == "death" then state_1 = "death" end
		if result == nil then
			if VisualsCogs.hitlogs:get('Under crosshair') then
				hitlog[#hitlog+1] = {("\aD6D6D6FFHit \a%s%s \aD6D6D6FFin \a%s%s \aD6D6D6FFfor \a%s%s \aD6D6D6FFdamage | Health remaining \a%s%s"):format(VisualsCogs.hitlogstext:get():to_hex(), event.target:get_name(), VisualsCogs.hitlogstext:get():to_hex(), hitgroup_str[event.hitgroup], VisualsCogs.hitlogstext:get():to_hex(), event.damage, VisualsCogs.hitlogstext:get():to_hex(), health), globals.tickcount + 250, 0}
			end
			if VisualsCogs.hitlogs:get('Sidelogs') then
				sidelogs[#sidelogs+1] = {("\aD6D6D6FFTarget: \a%s%s \n\aD6D6D6FFDamage: \a%s%s \n\aD6D6D6FFHitbox: \a%s%s"):format(VisualsCogs.hitlogstext:get():to_hex(), event.target:get_name(), VisualsCogs.hitlogstext:get():to_hex(), event.damage, VisualsCogs.hitlogstext:get():to_hex(), hitgroup_str[event.hitgroup]), globals.tickcount + 250, 0}
			end
			if VisualsCogs.hitlogs:get("Console") then
				print_raw(("\a4562FF[kitaxe] \aD5D5D5[%s] Registered shot at %s's %s(%s%s) for %s (aimed: %s for %s, health remain: %s) backtrack: %s"):format(id, event.target:get_name(), hitgroup_str[event.hitgroup], event.hitchance, text, event.damage, hitgroup_str[event.wanted_hitgroup], event.wanted_damage, health, event.backtrack))
			end
			if VisualsCogs.hitlogs:get("Event Logs") then
				print_dev(("[%s] Registered shot at %s's %s(%s%s) for %s (aimed: %s for %s, health remain: %s) backtrack: %s"):format(id, event.target:get_name(), hitgroup_str[event.hitgroup], event.hitchance, text, event.damage, hitgroup_str[event.wanted_hitgroup], event.wanted_damage, health, event.backtrack))           
			end
		else
			if VisualsCogs.hitlogs:get('Under crosshair') then
				hitlog[#hitlog+1] = {("\aD6D6D6FFMissed \a%s%s \aD6D6D6FFin the \a%s%s \aD6D6D6FFdue \aD6D6D6FFto \a%s%s\aD6D6D6FF | Wanted backtrack \a%s%s"):format(VisualsCogs.hitlogstext2:get():to_hex(),event.target:get_name(), VisualsCogs.hitlogstext2:get():to_hex(),hitgroup_str[event.wanted_hitgroup], VisualsCogs.hitlogstext2:get():to_hex(),state_1, VisualsCogs.hitlogstext2:get():to_hex(),event.backtrack), globals.tickcount + 250, 0}
			end
			if VisualsCogs.hitlogs:get('Sidelogs') then
				sidelogs[#sidelogs+1] = {("\aD6D6D6FFTarget: \a%s%s \n\aD6D6D6FFHitbox: \a%s%s \n\aD6D6D6FFReason: \a%s%s"):format(VisualsCogs.hitlogstext2:get():to_hex(),event.target:get_name(), VisualsCogs.hitlogstext2:get():to_hex(),hitgroup_str[event.wanted_hitgroup], VisualsCogs.hitlogstext2:get():to_hex(),state_1), globals.tickcount + 250, 0}
			end
			if VisualsCogs.hitlogs:get("Console") then
				print_raw(("\a4562FF[kitaxe] \aD5D5D5[%s] Missed %s %s (dmg:%s, %s%s) due to %s\aD5D5D5 | backtrack: %s"):format(id, event.target:get_name(), hitgroup_str[event.wanted_hitgroup], event.wanted_damage, event.hitchance, text, state_1, event.backtrack))
			end
			if VisualsCogs.hitlogs:get("Event Logs") then
				print_dev(("[%s] Missed %s %s (dmg:%s, %s%s) due to %s | backtrack: %s"):format(id, event.target:get_name(), hitgroup_str[event.wanted_hitgroup], event.wanted_damage, event.hitchance, text, state_1, event.backtrack))           
			end
		end
		id = id == 999 and 1 or id + 1 
	end
end)

function hit_event(event)
	local me = entity.get_local_player()
	if not me then return end
    local attacker = entity.get(event.attacker, true)
    local weapon = event.weapon
    local hit_type = ""
    if Visuals.Logs:get() then
    	if weapon == 'hegrenade' then 
	        hit_type = 'Exploded'
	    end

	    if weapon == 'inferno' then
	        hit_type = 'Burned'
	    end

	    if weapon == 'knife' then 
	        hit_type = 'Hit from Knife'
	    end

	    if weapon == 'hegrenade' or weapon == 'inferno' or weapon == 'knife' then
		    if me == attacker then
		        local user = entity.get(event.userid, true)
				if VisualsCogs.hitlogs:get('Under crosshair') then
		        	hitlog[#hitlog+1] = {(hit_type..' \a%s%s \aD6D6D6FFfor \a%s%d \aD6D6D6FFdamage ( \a%s%s\aD6D6D6FF health remaining )'):format(VisualsCogs.hitlogstext:get():to_hex(), user:get_name(), VisualsCogs.hitlogstext:get():to_hex(), event.dmg_health, VisualsCogs.hitlogstext:get():to_hex(), event.health), globals.tickcount + 250, 0}
				end
				if VisualsCogs.hitlogs:get('Sidelogs') then
		        	sidelogs[#sidelogs+1] = {('Type: \a%s'..hit_type..' \aD6D6D6FF\nTarget: \a%s%s \n\aD6D6D6FFdamage \a%s%d'):format(VisualsCogs.hitlogstext:get():to_hex(), VisualsCogs.hitlogstext:get():to_hex(), user:get_name(), VisualsCogs.hitlogstext:get():to_hex(), event.dmg_health), globals.tickcount + 250, 0}
				end
				if VisualsCogs.hitlogs:get("Console") then
		        	print_raw(('\a4562FF[kitaxe] \aD5D5D5[%s] '..hit_type..' %s for %d damage (%d health remaining)'):format(id, user:get_name(), event.dmg_health, event.health))
				end
				if VisualsCogs.hitlogs:get("Event Logs") then
		        	print_dev(("[%s] " .. hit_type..' %s for %d damage (%d health remaining)'):format(id, user:get_name(), event.dmg_health, event.health))
				end
		    end
		    id = id == 999 and 1 or id + 1 
	    end
	end
end

fontcheck = 0
events.render:set(function()
	if VisualsCogs.hitlogsfont:get() == "Pixel-7" then
		fontcheck = font.pixel
	else
		fontcheck = 1
	end
    if #hitlog > 0 then
        if globals.tickcount >= hitlog[1][2] then
            if hitlog[1][3] > 0 then
                hitlog[1][3] = hitlog[1][3] - 20
            elseif hitlog[1][3] <= 0 then
                table.remove(hitlog, 1)
            end
        end
        if #hitlog > VisualsCogs.hitlogsvalue:get() then
            table.remove(hitlog, 1)
        end
        if globals.is_connected == false then
            table.remove(hitlog, #hitlog)
        end
        for i = 1, #hitlog do
			text_size = render.measure_text(1, nil, hitlog[i][1]).x
            if hitlog[i][3] < 255 then 
                hitlog[i][3] = hitlog[i][3] + 10 
            end
            if VisualsCogs.hitlogs:get('Under crosshair') then
				render.text(fontcheck, vector(screen.x/2 - text_size/2 + (hitlog[i][3]/35), screen.y/1.4 + 20 * i), color(255, 255, 255, hitlog[i][3]), nil, hitlog[i][1])
            end
        end
    end
	if VisualsCogs.hitlogs:get('Under crosshair') then
		VisualsCogs.hitlogsfont:visibility(true)
	else
		VisualsCogs.hitlogsfont:visibility(false)
	end
	if VisualsCogs.hitlogs:get('Under crosshair') or VisualsCogs.hitlogs:get('Sidelogs') then
		VisualsCogs.hitlogstext:visibility(true)
		VisualsCogs.hitlogstext2:visibility(true)
	else
		VisualsCogs.hitlogstext:visibility(false)
		VisualsCogs.hitlogstext2:visibility(false)
	end
end)
events.render:set(function()
	if #sidelogs > 0 then
		if globals.tickcount >= sidelogs[1][2] then
			if sidelogs[1][3] > 0 then
				sidelogs[1][3] = sidelogs[1][3] - 20
			elseif sidelogs[1][3] <= 0 then
				table.remove(sidelogs, 1)
			end
		end
		if #sidelogs > VisualsCogs.hitlogsvalue:get() then
			table.remove(sidelogs, 1)
		end
		if globals.is_connected == false then
			table.remove(sidelogs, #sidelogs)
		end
		for i = 1, #sidelogs do
			text_size = render.measure_text(1, nil, sidelogs[i][1]).x
			if sidelogs[i][3] < 255 then 
				sidelogs[i][3] = sidelogs[i][3] + 10
			end
			if VisualsCogs.hitlogs:get('Sidelogs') then
				render.rect(vector(screen.x/2 - 1084 + (sidelogs[i][3]/2), screen.y/2.8 + 40 * i), vector(screen.x/2 - 1030 + text_size + (sidelogs[i][3]/2), screen.y/2.58 + 40 * i), color(20,20,20,255), 3)
				render.text(font.pixel, vector(screen.x/155 - 40 + (sidelogs[i][3]/3), screen.y/2.8 + 40 * i), color(255, 255, 255, 255), nil, sidelogs[i][1])
				render.texture(enemyavatar, vector(screen.x/155 - 90 + (sidelogs[i][3]/3), screen.y/2.79 + 40 * i), vector(33,28), color(), f, 0)
		end
	end
end
end)

--hitlogs

-- Widgets
function lerpx(time,a,b) return a * (1-time) + b * time end
function window(x, y, w, h, name, alpha) 
	local name_size = render.measure_text(1, "", name) 
	local r, g, b = VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b
    local r2, g2, b2 = VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b

    if VisualsCogs.solus_combo:get() == 'Modern' then
		if VisualsCogs.solus_combo2:get() == "Neverlose" then
        	render.rect_outline(vector(x - 7, y), vector(x - 21 + w + 4, y + h + 1), color(25,25,25,alpha), 1, 0)
        	render.rect(vector(x - 7, y), vector(x - 21 + w + 4, y + h + 1), color(25,25,25,alpha), 0)
        	render.shadow(vector(x - 7, y), vector(x - 21 + w + 4, y + h + 1), color(VisualsCogs.accent_colglow:get().r, VisualsCogs.accent_colglow:get().g, VisualsCogs.accent_colglow:get().b, alpha), 15, 0, 0)
			render.text(font.pixel, vector(x-3 + w / 2 + 1 - name_size.x / 2,	y + h / 2 -  name_size.y/2), color(VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b, alpha), "", ""..name)
		else
			render.rect_outline(vector(x - 7, y), vector(x - 25 + w + 4, y + h + 1), color(25,25,25,alpha), 1, 0)
        	render.rect(vector(x - 7, y), vector(x - 25 + w + 4, y + h + 1), color(25,25,25,alpha), 0)
        	render.shadow(vector(x - 7, y), vector(x - 25 + w + 4, y + h + 1), color(VisualsCogs.accent_colglow:get().r, VisualsCogs.accent_colglow:get().g, VisualsCogs.accent_colglow:get().b, alpha), 15, 0, 0)
			render.text(font.pixel, vector(x - 10 + w / 2 + 1 - name_size.x / 2,	y + h / 2 -  name_size.y/2), color(VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b, alpha), "", ""..name)
		end
    end
end

function window2(x, y, w, h, name, alpha) 
	local name_size = render.measure_text(1, "", name) 
	local r, g, b = VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b
    local r2, g2, b2 = VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b

    if VisualsCogs.solus_combo:get() == 'Modern' then
        render.rect_outline(vector(x - 7, y), vector(x - 20 + w + 4, y + h + 1), color(25,25,25,alpha), 1, 0)
        render.rect(vector(x - 7, y), vector(x - 20 + w + 4, y + h + 1), color(25,25,25,alpha), 0)
        render.shadow(vector(x - 7, y), vector(x - 20 + w + 4, y + h + 1), color(VisualsCogs.accent_colglow:get().r, VisualsCogs.accent_colglow:get().g, VisualsCogs.accent_colglow:get().b, alpha), 15, 0, 0)
		render.text(font.pixel, vector(x-10 + w / 2 + 1 - name_size.x / 2,	y + h / 2 -  name_size.y/2), color(VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b, alpha), "", ""..name)
    end
end

local x, y, alphabinds, alpha_k, width_k, width_ka, data_k, width_spec = render.screen_size().x, render.screen_size().y, 0, 1, 0, 0, { [''] = {alpha_k = 0}}, 1

local pos_x = Widgetsgroup:slider("posx", 0, x, 150)
local pos_y = Widgetsgroup:slider("posy", 0, y, 150)
local pos_x1 = Widgetsgroup:slider("posx1", 0, x, 250)
local pos_y1 = Widgetsgroup:slider("posy1", 0, y, 250)

--@: sowus - watermark
events.render:set(function()
    local me = entity.get_local_player()
    if me == nil then return end
    if VisualsCogs.solus_widgets:get('Watermark') then
    local ticks = math.floor(1.0 / globals.tickinterval)
    local user_name = common.get_username()

    function get_ping()
        local netchannel = utils.net_channel()
    
        if netchannel == nil then
            return 0
        end
    
        return math.floor(netchannel.latency[1] * 1000)
    end
    
    local actual_time = ""
    local latency_text = ""
    local nexttext = ""

    actual_time = common.get_date("%H:%M")

    if not globals.is_in_game then
        latency_text = ''
    else
        latency_text = ' | '..get_ping().."ms"
    end

    solushex = color(VisualsCogs.accent_col:get().r, VisualsCogs.accent_col:get().g, VisualsCogs.accent_col:get().b, 255):to_hex()
    if VisualsCogs.solus_combo2:get() == "Neverlose" then
	local nexttext = ('  never\a'..solushex..'lose \aFFFFFFFF| '.."KITAXE~"..Luaname_upper..""..latency_text.." | "..actual_time)
    local text_size = render.measure_text(1, "", nexttext).x
    window(x - text_size + 25, 10, 210, 16, nexttext, 255)
        end
    if VisualsCogs.solus_combo2:get() == "Gamesense" then
        local nexttext = ('     game\a'..solushex..'sense \aFFFFFFFF| '.."KITAXE~"..Luaname_upper..""..latency_text.." | "..actual_time)
        local text_size = render.measure_text(1, "", nexttext).x
        window(x - text_size + 40, 10, 210, 16, nexttext, 255)
        end
    end
end)

--@: sowus - keybinds
local new_drag_object = drag_system.register({pos_x, pos_y}, vector(120, 60), "Test", function(self)
    if VisualsCogs.solus_widgets:get('Keybinds') and Visuals.Widgets:get() == true then
    local max_width = 0
    local frametime = globals.frametime * 16
    local add_y = 0
    local total_width = 66
    local active_binds = {}

    local binds = ui.get_binds()
    for i = 1, #binds do
            local bind = binds[i]
            local get_mode = binds[i].mode == 1 and 'holding' or (binds[i].mode == 2 and 'toggled') or '[?]'
            local get_value = binds[i].value

            local c_name = binds[i].name
            if c_name == 'Peek Assist' then c_name = 'Quick peek assist' end
            if c_name == 'Edge Jump' then c_name = 'Jump at edge' end
            if c_name == 'Hide Shots' then c_name = 'On shot anti-aim' end
            if c_name == 'Minimum Damage' then c_name = 'Minimum damage' end
            if c_name == 'Fake Latency' then c_name = 'Ping spike' end
            if c_name == 'Fake Duck' then c_name = 'Duck peek assist' end
            if c_name == 'Safe Points' then c_name = 'Safe point' end
            if c_name == 'Body Aim' then c_name = 'Body aim' end
            if c_name == 'Double Tap' then c_name = 'Double tap' end
            if c_name == 'Yaw Base' then c_name = 'Manual override' end
            if c_name == 'Slow Walk' then c_name = 'Slow motion' end


            local bind_state_size = render.measure_text(1, "", get_mode)
            local bind_name_size = render.measure_text(1, "", c_name)
            if data_k[bind.name] == nil then data_k[bind.name] = {alpha_k = 0} end
            data_k[bind.name].alpha_k = lerpx(frametime, data_k[bind.name].alpha_k, (bind.active and 255 or 0))

            if VisualsCogs.solus_combo:get() == 'Modern' then
                render.text(font.pixel, vector(self.position.x+3, self.position.y + 19 + add_y), color(255, data_k[bind.name].alpha_k), '', c_name)

                if c_name == 'Minimum damage' or c_name == 'Ping spike' then
                    render.text(font.pixel, vector(self.position.x - 8 + (width_ka - bind_state_size.x) - render.measure_text(1, nil, get_value).x + 28, self.position.y + 19 + add_y), color(255, data_k[bind.name].alpha_k), '',  '['..get_value..']')
                else
                    render.text(font.pixel, vector(self.position.x - 8 + (width_ka - bind_state_size.x - 8), self.position.y + 19 + add_y), color(255, data_k[bind.name].alpha_k), '',  '['..get_mode..']')
                end
            end
            
            add_y = add_y + 16 * data_k[bind.name].alpha_k/255

            --drag
            local width_k = bind_state_size.x + bind_name_size.x + 18
            if width_k > 130-11 then
                if width_k > max_width then
                    max_width = width_k
                end
            end

            if binds.active then
                    table.insert(active_binds, binds)
                end
            end

            alpha_k = lerpx(frametime, alpha_k, (ui.get_alpha() > 0 or add_y > 0) and 1 or 0)
            width_ka = lerpx(frametime,width_ka, math.max(max_width, 130-11))
            if ui.get_alpha()>0 or add_y > 6 then alphabinds = lerpx(frametime, alphabinds, math.max(ui.get_alpha()*255, (add_y > 1 and 255 or 0)))
            elseif add_y < 15.99 and ui.get_alpha() == 0 then alphabinds = lerpx(frametime, alphabinds, 0) end
            if ui.get_alpha() or #active_binds > 0 then
            window2(self.position.x + 7, self.position.y, width_ka, 16, 'keybinds', alphabinds)
            end
    end
end)

local fnay = render.load_image(network.get("https://avatars.cloudflare.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_medium.jpg"), vector(50, 50))

local new_drag_object1 = drag_system.register({pos_x1, pos_y1}, vector(120, 60), "Test2", function(self)
if Visuals.Widgets:get() == true then
    if VisualsCogs.solus_widgets:get('Spectator list') then
        local width_spec = 120
        if width_spec > 160-11 then
            if width_spec > max_width then
                max_width = width_spec
            end
        end

        if ui.get_alpha() > 0.3 or (ui.get_alpha() > 0.3 and not globals.is_in_game) then window2(self.position.x, self.position.y, width_spec, 16, 'spectators', 255) end

        local me = entity.get_local_player()
        if me == nil then return end

        local speclist = me:get_spectators()

        if me.m_hObserverTarget and (me.m_iObserverMode == 4 or me.m_iObserverMode == 5) then
            me = me.m_hObserverTarget
        end

        local speclist = me:get_spectators()
        if speclist == nil then return end
        for idx,player_ptr in pairs(speclist) do
            local name = player_ptr:get_name()
            local tx = render.measure_text(1, '', name).x
            name_sub = string.len(name) > 14 and string.sub(name, 0, 14) .. "..." or name;
            local avatar = player_ptr:get_steam_avatar()
            if (avatar == nil or avatar.width <= 5) then avatar = fnay end

            if player_ptr:is_bot() and not player_ptr:is_player() then goto skip end
            render.text(font.pixel, vector(self.position.x + 17, self.position.y + 5 + (idx*15)), color(), 'u', name_sub)
            render.texture(avatar, vector(self.position.x - 3, self.position.y + 5 + (idx*15)), vector(12, 12), color(), 'f', 0)
            ::skip::
        end
    
        if #me:get_spectators() > 0 or (me.m_iObserverMode == 4 or me.m_iObserverMode == 5) then
            window2(self.position.x, self.position.y, width_spec, 16, 'spectators', 255)
        end
        
        end
    end
end)

events.mouse_input:set(function()
        if ui.get_alpha() > 0.3 then return false end
end)

-- Widgets


p_stateindicators = 0
local function indicatorsrender()
	indicator_spacing = -20
	local is_scoped = local_player.m_bIsScoped
	local active_binds = ui.get_binds()
	local DTRecharge = rage.exploit:get(refs.dt)

	MTools.Animation:Register("Indicators");
	MTools.Animation:Update("Indicators", 6);

	if VisualsCogs.Bindstoshow:get(1) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Minimum Damage" then
				if active_binds[i].active then
					DMGBIND = MTools.Animation:Lerp("Indicators", "dmgbind", (active_binds[i].active), vector(screen_center.x, screen_center.y + indicator_spacing), vector(screen_center.x, screen_center.y + indicator_spacing + 10), 15);
					indicator_spacing = indicator_spacing + 10
				end
			end
		end
	end
	if refs.dt:get() and VisualsCogs.Bindstoshow:get(2) then
		DTBIND = MTools.Animation:Lerp("Indicators", "dtbind", (refs.dt:get()), vector(screen_center.x, screen_center.y + indicator_spacing), vector(screen_center.x, screen_center.y + indicator_spacing + 10), 15);
		indicator_spacing = indicator_spacing + 10
	end
	if refs.hs:get() and VisualsCogs.Bindstoshow:get(3) then
		HSBIND = MTools.Animation:Lerp("Indicators", "hsbind", (refs.hs:get()), vector(screen_center.x, screen_center.y + indicator_spacing), vector(screen_center.x, screen_center.y + indicator_spacing + 10), 15);
		indicator_spacing = indicator_spacing + 10
	end
	if refs.fs:get() and VisualsCogs.Bindstoshow:get(6) then
		FSBIND = MTools.Animation:Lerp("Indicators", "fsbind", (refs.fs:get()), vector(screen_center.x, screen_center.y + indicator_spacing), vector(screen_center.x, screen_center.y + indicator_spacing + 10), 15);
		indicator_spacing = indicator_spacing + 10
	end
	if VisualsCogs.Bindstoshow:get(4) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Safe Points" then
				if active_binds[i].active then
					SPBIND = MTools.Animation:Lerp("Indicators", "spbind", (active_binds[i].active), vector(screen_center.x, screen_center.y + indicator_spacing), vector(screen_center.x, screen_center.y + indicator_spacing + 10), 15);
					indicator_spacing = indicator_spacing + 10
				end
			end
		end
	end
	if VisualsCogs.Bindstoshow:get(5) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Hit Chance" then
				if active_binds[i].active then
					HITBIND = MTools.Animation:Lerp("Indicators", "hitbind", (active_binds[i].active), vector(screen_center.x, screen_center.y + indicator_spacing), vector(screen_center.x, screen_center.y + indicator_spacing + 10), 15);
					indicator_spacing = indicator_spacing + 10
				end
			end
		end
	end

	KITAXE_TEXT = MTools.Animation:Lerp("Indicators", "KITAXEDEV", (is_scoped), vector(screen_center.x, screen_center.y), vector(screen_center.x + 40, screen_center.y), 15);
	
	local player_inverter = local_player.m_flPoseParameter[11] * 120 - 60 <= 0 and true or false
	local on_ground = local_player.m_fFlags == bit.bor(local_player.m_fFlags, bit.lshift(1, 0))
	local on_crouch = local_player.m_fFlags == bit.bor(local_player.m_fFlags, bit.lshift(1, 2))
	local velocity = local_player.m_vecVelocity
	local speed = velocity:length()
	if speed <= 2 then
		p_stateindicators = "Stand"
	end
	if speed >= 3 and refs.sw:get() == false then
		p_stateindicators = "Walk"
	end
	if on_ground == false and on_crouch == false then
		p_stateindicators = "Air"
	end
	if on_ground == false and on_crouch == true then
		p_stateindicators = "Air~C"
	end
	if on_crouch == true and on_ground == true then
		p_stateindicators = "Crouch"
	end
	if refs.sw:get() == true then
		p_stateindicators = "Slow"
	end
	if refs.fd:get() == true then
		p_stateindicators = "FAKE-DUCK"
	end

	local KITAXEDEV = gradient.text_animate("KITAXE~"..Luaname_upper, -3, {
		VisualsCogs.Indicatorscolor:get(), 
		VisualsCogs.Indicatorscolortwo:get()
	})
	
	render.shadow(vector(KITAXE_TEXT.x - 26, screen_center.y + 30), vector(KITAXE_TEXT.x + 26, screen_center.y + 30), VisualsCogs.Indicatorsglow:get(), 20, 0, 5)
	render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y + 30), color(255,0,255), "c", KITAXEDEV:get_animated_text())
	render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y + 40), color(), "c", "* "..p_stateindicators.." *")
	if VisualsCogs.Bindstoshow:get(1) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Minimum Damage" then
				if active_binds[i].active then
					render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + DMGBIND.y), color(), "c", "DMG")
				end
			end
		end
	end
	if refs.dt:get() and VisualsCogs.Bindstoshow:get(2) and DTRecharge <= 0.99 then
		render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + DTBIND.y), color(255,DTRecharge*255,DTRecharge*255,255), "c", "DT")
	end
	if refs.dt:get() and VisualsCogs.Bindstoshow:get(2) and DTRecharge == 1 then
		render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + DTBIND.y), color(255,DTRecharge*255,DTRecharge*255,255), "c", "DT")
	end
	if refs.hs:get() and VisualsCogs.Bindstoshow:get(3) then
		render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + HSBIND.y), color(), "c", "HS")
	end
	if refs.fs:get() and VisualsCogs.Bindstoshow:get(6) then
		render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + FSBIND.y), color(), "c", "FS")
	end
	if VisualsCogs.Bindstoshow:get(4) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Safe Points" then
				if active_binds[i].active then
					render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + SPBIND.y), color(), "c", "SP")
				end
			end
		end
	end
	if VisualsCogs.Bindstoshow:get(5) then
		for i in pairs(active_binds) do
			if active_binds[i].name == "Hit Chance" then
				if active_binds[i].active then
					render.text(font.pixel, vector(KITAXE_TEXT.x, screen_center.y * 0.11 + HITBIND.y), color(), "c", "HC")
				end
			end
		end
	end

	KITAXEDEV:animate()
end


-- MISC

MiscFeatures = ui.create(ui.get_icon("cogs").." Features", ui.get_icon("wrench").." Miscellaneous")
local Misc = {

    Aspectratio = MiscFeatures:switch("Override Aspect Ratio"),
	Viewmodel = MiscFeatures:switch("View Model"),
	Customscope = MiscFeatures:switch("Scope Lines"),
	Clantag = MiscFeatures:switch("Clantag Spammer"),
	Fastledder = MiscFeatures:switch("Fast Ladder")

}

Aspectratiogroup = Misc.Aspectratio:create()
Viewmodel = Misc.Viewmodel:create()
Customscope = Misc.Customscope:create()


local MiscCogs = {
	Aspectvalue = Aspectratiogroup:slider("Value", 10, 30, 1.4, 0.1, ""),
	viewmodel_fov = Viewmodel:slider("FOV", -100, 100, 68),
	viewmodel_x = Viewmodel:slider("X", -10, 10, 2.5),
	viewmodel_y = Viewmodel:slider("Y", -10, 10, 0),
	viewmodel_z = Viewmodel:slider("Z", -10, 10, -1.5),
	scopeGap = Customscope:slider("Scope Gap", 0, 300, 15),
	scopeLength = Customscope:slider("Scope Length", 0, 300, 150),
	scopeColor = Customscope:color_picker("Scope Color", color(255, 255, 255, 255))
}

-- Viewmodel

events.createmove:set(function()
    if Misc.Viewmodel:get() then
        cvar.viewmodel_fov:int(MiscCogs.viewmodel_fov:get(), true)
		cvar.viewmodel_offset_x:float(MiscCogs.viewmodel_x:get(), true)
		cvar.viewmodel_offset_y:float(MiscCogs.viewmodel_y:get(), true)
		cvar.viewmodel_offset_z:float(MiscCogs.viewmodel_z:get(), true)
    end
end)

events.shutdown:set(function()
    cvar.viewmodel_fov:int(68)
    cvar.viewmodel_offset_x:float(2.5)
    cvar.viewmodel_offset_y:float(0)
    cvar.viewmodel_offset_z:float(-1.5)
end)

-- Viewmodel

local lerp = function(time,a,b)
    return a * (1-time) + b * time
end
length = 0
gap = 0
local function customscope()
    if Misc.Customscope:get() then
        local x = render.screen_size().x
        local y = render.screen_size().y
        local localplayer = entity.get_local_player()
        ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"):set("Remove All")
        if localplayer == nil then return end
        if localplayer.m_iHealth < 1 then return end
		length = lerp(0.2, length, localplayer.m_bIsScoped and MiscCogs.scopeLength:get() or 0) 
		gap = lerp(0.2, gap, localplayer.m_bIsScoped and MiscCogs.scopeGap:get() or 0) 
		local scopeColor_x = color(MiscCogs.scopeColor:get().r, MiscCogs.scopeColor:get().g, MiscCogs.scopeColor:get().b, MiscCogs.scopeColor:get().a)
		local scopeColor_y = color(MiscCogs.scopeColor:get().r, MiscCogs.scopeColor:get().g, MiscCogs.scopeColor:get().b, 0)
		render.gradient(vector(x / 2 - gap, y / 2), vector(x / 2 - gap - length, y / 2 + 1), scopeColor_x, scopeColor_y, scopeColor_x, scopeColor_y)
		render.gradient(vector(x / 2 + gap, y / 2), vector(x / 2 + gap + length, y / 2 + 1), scopeColor_x, scopeColor_y, scopeColor_x, scopeColor_y)
		render.gradient(vector(x / 2, y / 2 + gap), vector(x / 2 + 1, y / 2 + gap + length), scopeColor_x, scopeColor_x, scopeColor_y, scopeColor_y)
		render.gradient(vector(x / 2, y / 2 - gap), vector(x / 2 + 1, y / 2 - gap - length), scopeColor_x, scopeColor_x, scopeColor_y, scopeColor_y)
	else
		ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"):set("Remove Overlay")
	end
end


gamesense_anim = function(text, indices) if not globals.is_connected then return end local text_anim = '               ' .. text .. '                      '  local tickinterval = globals.tickinterval local tickcount = globals.tickcount + math.floor(utils.net_channel().avg_latency[0]+0.22 / globals.tickinterval + 0.5) local i = tickcount / math.floor(0.3 / globals.tickinterval + 0.5) i = math.floor(i % #indices) i = indices[i+1]+1 return string.sub(text_anim, i, i+15) end
set_clantag = ffi.cast('int(__fastcall*)(const char*, const char*)', utils.opcode_scan('engine.dll', '53 56 57 8B DA 8B F9 FF 15'))
set_clantag('\0', '\0')
clantag = function()
	if not globals.is_connected then return end
	if Misc.Clantag:get() then
		if local_player ~= nil and globals.is_connected and globals.choked_commands then
			clan_tag = gamesense_anim('kitaxe ~ dev', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 , 22, 23, 24})
			if entity.get_game_rules()['m_gamePhase'] == 5 or entity.get_game_rules()['m_gamePhase'] == 4 then
				clan_tag = gamesense_anim('kitaxe ~ dev', {12})
				set_clantag(clan_tag, clan_tag)
			elseif clan_tag ~= clan_tag_prev then
				set_clantag(clan_tag, clan_tag)
			end
			clan_tag_prev = clan_tag
		end
		enabled_prev = false
	elseif not Misc.Clantag:get() and enabled_prev == false then
        set_clantag('\0', '\0')
        enabled_prev = true
	end
end


local function aspectratio()
	if Misc.Aspectratio:get() == true then
        cvar.r_aspectratio:float(MiscCogs.Aspectvalue:get()/10)
	else
		cvar.r_aspectratio:float(0)
    end
end

local function fastladder(cmd)
		if not Misc.Fastledder:get() then return end
		local pitch = render.camera_angles()
		if local_player["m_MoveType"] == 9 then
			if cmd.forwardmove > 0 then
			if pitch.x < 45 then
				cmd.view_angles.x = 89
				cmd.view_angles.y = cmd.view_angles.y + 89
				cmd.in_moveright = 1
				cmd.in_moveleft = 0
				cmd.in_forward = 0
				cmd.in_back = 1
				if cmd.sidemove == 0 then
					cmd.move_yaw = cmd.move_yaw + 90
				end
				if cmd.sidemove < 0 then
					cmd.move_yaw = cmd.move_yaw + 150
				end
				if cmd.sidemove > 0 then
					cmd.move_yaw = cmd.move_yaw + 30
				end
			end
		end
		
		if cmd.forwardmove < 0 then
			cmd.view_angles.x = 89
			cmd.view_angles.y = cmd.view_angles.y + 89
			cmd.in_moveright = 1
			cmd.in_moveleft = 0
			cmd.in_forward = 1
			cmd.in_back = 0
			if cmd.sidemove == 0 then
				cmd.move_yaw = cmd.move_yaw + 90
			end
			if cmd.sidemove > 0 then
				cmd.move_yaw = cmd.move_yaw + 150
			end
			if cmd.sidemove < 0 then
				cmd.move_yaw = cmd.move_yaw + 30
			end
		end
	end
end

-- Configsystem
local data = {
	bools = {},
	tables = {},
	ints = {},
	numbers = {},
}

function pairsort(t)  
	local a = {}  
	for n in pairs(t) do    
		a[#a+1] = n  
	end  
	table.sort(a)  
	local i = 0  
	return function()  
		i = i + 1  
		return a[i], t[a[i]]  
	end  
end 

for i, v in pairsort(var.player_states) do
	for _, v in pairsort(BodyYawarray[i]) do
		if type(v:get()) == "boolean" then
			table.insert(data.bools,v)
		elseif type(v:get()) == "table" then
			table.insert(data.tables,v)
		elseif type(v:get()) == "string" then
			table.insert(data.ints,v)
		else
			table.insert(data.numbers,v)
		end
	end
end
for i, v in pairsort(var.player_states) do
	for _, v in pairsort(AntiAimarray[i]) do
		if type(v:get()) == "boolean" then
			table.insert(data.bools,v)
		elseif type(v:get()) == "table" then
			table.insert(data.tables,v)
		elseif type(v:get()) == "string" then
			table.insert(data.ints,v)
		else
			table.insert(data.numbers,v)
		end
	end
end
for _, v in pairsort(Antiaim) do
	if type(v:get()) == "boolean" then
		table.insert(data.bools,v)
	elseif type(v:get()) == "table" then
		table.insert(data.tables,v)
	elseif type(v:get()) == "string" then
		table.insert(data.ints,v)
	else
		table.insert(data.numbers,v)
	end
end
for _, v in pairsort(Visuals) do
	if type(v:get()) == "boolean" then
		table.insert(data.bools,v)
	elseif type(v:get()) == "table" then
		table.insert(data.tables,v)
	elseif type(v:get()) == "string" then
		table.insert(data.ints,v)
	else
		table.insert(data.numbers,v)
	end
end
for _, v in pairsort(VisualsCogs) do
	if type(v:get()) == "boolean" then
		table.insert(data.bools,v)
	elseif type(v:get()) == "table" then
		table.insert(data.tables,v)
	elseif type(v:get()) == "string" then
		table.insert(data.ints,v)
	else
		table.insert(data.numbers,v)
	end
end
for _, v in pairsort(MiscCogs) do
	if type(v:get()) == "boolean" then
		table.insert(data.bools,v)
	elseif type(v:get()) == "table" then
		table.insert(data.tables,v)
	elseif type(v:get()) == "string" then
		table.insert(data.ints,v)
	else
		table.insert(data.numbers,v)
	end
end
for _, v in pairsort(Misc) do
	if type(v:get()) == "boolean" then
		table.insert(data.bools,v)
	elseif type(v:get()) == "table" then
		table.insert(data.tables,v)
	elseif type(v:get()) == "string" then
		table.insert(data.ints,v)
	else
		table.insert(data.numbers,v)
	end
end


local function export()    
	common.add_notify("Config System", "Config Exported!")
	utils.console_exec("playvol  buttons/bell1.wav 1")  
	local Code = {{},{},{},{},{},{}}
		for _, bools in pairs(data.bools) do
			table.insert(Code[1], bools:get())
		end
		
		for _, tables in pairs(data.tables) do
			table.insert(Code[2], tables:get())
		end
		
		for _, ints in pairs(data.ints) do
			table.insert(Code[3], ints:get())
		end
		
		for _, numbers in pairs(data.numbers) do
			table.insert(Code[4], numbers:get())
		end
		
		clipboard.set("<kitaxe>_"..base64.encode(json.stringify(Code)))
		
end

local function import()
	common.add_notify("Config System", "Config has been loaded")
	utils.console_exec("playvol  buttons/bell1.wav 1")
	local removekitaxe = clipboard.get():gsub("<kitaxe>_", "")
	for k, v in pairs(json.parse(base64.decode(removekitaxe))) do
		k = ({[1] = "bools", [2] = "tables",[3] = "ints",[4] = "numbers"})[k]
		for k2, v2 in pairs(v) do
			if (k == "bools") then
				data[k][k2]:set(v2)
			end
	
			if (k == "tables") then
				data[k][k2]:set(v2)
			end
	
			if (k == "ints") then
				data[k][k2]:set(v2)
			end
				
			if (k == "numbers") then
				data[k][k2]:set(v2)
			end

		end
	end
end
local function defaultcfg()
	common.add_notify("Config System", "Config has been loaded")
	utils.console_exec("playvol  buttons/bell1.wav 1")
	for k, v in pairs(json.parse(base64.decode("W1t0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSxmYWxzZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsZmFsc2UsZmFsc2UsdHJ1ZV0sW1siSml0dGVyIl0sWyJKaXR0ZXIiXSxbIkppdHRlciJdLFsiSml0dGVyIl0sWyJKaXR0ZXIiXSxbIkppdHRlciJdLFsiU3RhdGljIGxlZ3MgaW4gYWlyIiwiTW9vbndhbGsiXSxbIk1pbmltdW0gRE1HIiwiRG91YmxlIFRhcCIsIkhpZGUgU2hvb3QiLCJTYWZlIFBvaW50cyIsIkhpdCBDaGFuY2UiLCJGcmVlc3RhbmRpbmciXSxbIkZha2UgUGluZyIsIkRvdWJsZSBUYXAiLCJIaWRlIFNob290IiwiRnJlZXN0YW5kaW5nIiwiUGVlayBBc3Npc3QiXSxbIkNvbnNvbGUiLCJFdmVudCBMb2dzIiwiVW5kZXIgQ3Jvc3NoYWlyIiwiU2lkZWxvZ3MiXSxbIldhdGVybWFyayIsIktleWJpbmRzIiwiU3BlY3RhdG9yIGxpc3QiXV0sWyJPZmYiLCJPcHBvc2l0ZSIsIk9wcG9zaXRlIiwiT2ZmIiwiT3Bwb3NpdGUiLCJPcHBvc2l0ZSIsIk9mZiIsIk9wcG9zaXRlIiwiT3Bwb3NpdGUiLCJPZmYiLCJPcHBvc2l0ZSIsIk9wcG9zaXRlIiwiT2ZmIiwiT3Bwb3NpdGUiLCJPcHBvc2l0ZSIsIk9mZiIsIk9wcG9zaXRlIiwiT3Bwb3NpdGUiLCJDZW50ZXIiLCIzLVdheSIsIkNlbnRlciIsIkwmUiIsIkNlbnRlciIsIjMtV2F5IiwiQ2VudGVyIiwiNS1XYXkiLCJDZW50ZXIiLCJMJlIiLCJDZW50ZXIiLCJMJlIiLCJBdC1UYXJnZXRzIiwiQ3VzdG9tIiwiRGlzYWJsZSIsIlBpeGVsIiwiUGl4ZWwtNyIsIk1vZGVybiIsIk5ldmVybG9zZSJdLFs1OC4wLDU4LjAsNjAuMCw2MC4wLDYwLjAsNjAuMCw1OC4wLDU4LjAsNTguMCw1OC4wLDU4LjAsNTguMCwwLjAsMC4wLDAuMCwwLjAsMC4wLC01MC4wLDE3LjAsMy4wLC0yMy4wLDAuMCwwLjAsMjguMCwxMS4wLDAuMCwtMTMuMCwtMzcuMCwtNDUuMCwyNS4wLDUuMCwtMTguMCwtMTQuMCwxOC4wLDAuMCwwLjAsMC4wLDAuMCwwLjAsLTY1LjAsMTguMCwwLjAsLTIzLjAsMC4wLDAuMCwyMS4wLDEyLjAsMC4wLC0xNy4wLC0yOC4wLC03NC4wLDAuMCwwLjAsMC4wLDAuMCwwLjAsMC4wLDAuMCwwLjAsMC4wLDAuMCwtNDAuMCwwLjAsMC4wLDAuMCwtMTQuMCwxOC4wLDAuMCwwLjAsMC4wLDAuMCwwLjAsLTYwLjAsLTE0LjAsOS4wLDI4LjAsLTkuMCw5LjAsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCwzLjAsMTcuMCxudWxsLDE1LjAsMTUwLjAsNDIuMCwtMC4wLDAuMCwtMi4wXSxbXSxbXV0="))) do
		k = ({[1] = "bools", [2] = "tables",[3] = "ints",[4] = "numbers"})[k]
		for k2, v2 in pairs(v) do
			if (k == "bools") then
				data[k][k2]:set(v2)
			end
	
			if (k == "tables") then
				data[k][k2]:set(v2)
			end
	
			if (k == "ints") then
				data[k][k2]:set(v2)
			end
				
			if (k == "numbers") then
				data[k][k2]:set(v2)
			end


		end
	end
end
local export = HomeLinks:button(ui.get_icon('upload').."               	     Export settings   	   	            ",export)
local import = HomeLinks:button(ui.get_icon('download').."             	       Import settings    		             ",import)
local defaultcfg = HomeLinks:button(ui.get_icon('cloud').."             	      Default settings    		            ",defaultcfg)

events.render:set(function(cmd)
	defensive_indicator()
end)

events.render:set(function()
	pos_x:visibility(false)
    pos_y:visibility(false)
    pos_x1:visibility(false)
    pos_y1:visibility(false)

    new_drag_object:update()
    new_drag_object1:update()

    clantag()
	AntiAimshow()
	if local_player == nil then return end
	if not local_player:is_alive() then return end

    VisualsCogs.accent_col:visibility(VisualsCogs.solus_widgets:get('Watermark') or VisualsCogs.solus_widgets:get('Keybinds') or VisualsCogs.solus_widgets:get('Spectator list'))
    VisualsCogs.solus_combo:visibility(VisualsCogs.solus_widgets:get('Watermark') or VisualsCogs.solus_widgets:get('Keybinds') or VisualsCogs.solus_widgets:get('Spectator list'))
    if Visuals.Infopanel:get() then
        Infopanel:update()
    end
    if Visuals.Indicators:get() then
		indicatorsrender()
	end
	if Visuals.MinDMG:get() then
		Minimumdamage:update()
	end
	
	defensive_indicator_paint()
	antibackstab()
	freeestandingg()
	customscope()
	Muzzleindicatorss()
end)
events.createmove:set(function(cmd)
	aspectratio()
	fastladder(cmd)
	Antiaimworking(cmd)
	up_abuse()
end)
events.createmove_run:set(function()
	anim_state_hook()
end)
events.player_hurt:set(function(event)
    hit_event(event)
end)
