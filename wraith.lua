
local user, build = "Jordan", "alpha"
local elements, config = {}, {}

ffi.cdef [[
    typedef int(__thiscall* get_clipboard_text_length)(void*);
    typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
    typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
]]

local VGUI_System = ffi.cast(ffi.typeof("void***"), client.create_interface("vgui2.dll", "VGUI_System010"))
local get_clipboard_text_length = ffi.cast("get_clipboard_text_length", VGUI_System[0][7])
local get_clipboard_text = ffi.cast("get_clipboard_text", VGUI_System[0][11])
local set_clipboard_text = ffi.cast("set_clipboard_text", VGUI_System[0][9])


local function clipboard_import(text)
    set_clipboard_text(VGUI_System, text, #text)
end

local function clipboard_export()
    local clipboard_text_length = get_clipboard_text_length(VGUI_System)

    if (clipboard_text_length > 0) then
        local buffer = ffi.new("char[?]", clipboard_text_length)

        get_clipboard_text(VGUI_System, 0, buffer, clipboard_text_length * ffi.sizeof("char[?]", clipboard_text_length))
        return ffi.string(buffer, clipboard_text_length - 1)
    end
end

local ref = {
    master = ui.get("Rage", "Anti-aim", "General", "Anti-aim"),
    pitch = ui.get("Rage", "Anti-aim", "General", "Pitch"),
    freestanding = ui.get("Rage", "Anti-aim", "General", "Freestanding key"),
    base_angle = ui.get("Rage", "Anti-aim", "General", "Yaw base"),
    yaw_base = ui.get("Rage", "Anti-aim", "General", "Yaw"),
    yaw = ui.get("Rage", "Anti-aim", "General", "Yaw additive"),
    enable_jitter = ui.get("Rage", "Anti-aim", "General", "Yaw jitter"),
    jitter_conditions = ui.get("Rage", "Anti-aim", "General", "Yaw jitter conditions"),
    jitter_type = ui.get("Rage", "Anti-aim", "General", "Yaw jitter type"),
    enable_random_jitter = ui.get("Rage", "Anti-aim", "General", "Random jitter range"),
    jitter_range  = ui.get("Rage", "Anti-aim", "General", "Yaw jitter range"),
    desync_mode = ui.get("Rage", "Anti-aim", "General", "Fake yaw type"),
    desync_amount = ui.get("Rage", "Anti-aim", "General", "Body yaw limit"),
    manual_left = ui.get("Rage", "Anti-aim", "General", "Manual left key"),
    manual_right = ui.get("Rage", "Anti-aim", "General", "Manual right key"),
    manual_back = ui.get("Rage", "Anti-aim", "General", "Manual backwards key"),
    hide_shots = ui.get("Rage", "Exploits", "General", "Hide shots key"),
    fakeducking = ui.get("Rage", "Anti-aim", "Fake-lag", "Fake duck key"),
    legs = ui.get("Misc", "General", "Movement", "Leg movement"),
    slow_motion = ui.get("Misc", "General", "Movement", "Slow motion key"),
    menu_color = ui.get("Profile", "General", "Global settings", "Menu accent color"),
    double_tap = ui.get("Rage", "Exploits", "General", "Double tap key"),
    force_bodyaim = ui.get("Rage", "Aimbot", "Accuracy", "Force body-aim"),
    enable = ui.get("Rage", "Anti-aim", "Fake-lag", "Fake lag"),
    limit = ui.get("Rage", "Anti-aim", "Fake-lag", "Fake lag amount"),
    type = ui.get("Rage", "Anti-aim", "Fake-lag", "Fake lag type"),
    variance = ui.get("Rage", "Anti-aim", "Fake-lag", "Fake lag triggers"),
}

local var = {
	player_states = {"Global", "Standing", "Moving", "Slow motion", "Air", "On-key"},
	state_to_idx = {["Global"] = 1, ["Standing"] = 2, ["Moving"] = 3, ["Slow motion"] = 4, ["Air"] = 5, ["On-key"] = 6},
	aa_dir   = 0,
	active_i = 1,
	last_press_t = 0,
	p_state = 0,
	last_sway_time = 0,
	choked_cmds = 0,
	ts_time = 0,
	miss = {},
	on_shot_mode = "KEY",
	custom_keys = {},
	custom_key_saves = {},
	hit = {},
	shots = {},
	last_hit = {},
	stored_misses = {},
	stored_shots = {},
	last_nn = 0,
	hotkey_modes1 = { "ALWAYS ON", "HELD", "TOGGLED", "OFF HOTKEY" },
	hotkey_modes = { "Always on", "On hotkey", "Toggle", "Off hotkey" },
	best_value = 180,
	flip_value = 90,
	bestenemy = 0,
	flip_once = false,
	clantag_enbl = false,
	dragging = false,
	ox = 0, 
	oy = 0,
	last_selected = 0,
	classnames = {
	"CWorld",
	"CCSPlayer",
	"CFuncBrush"
	},
	nonweapons = {
	"knife",
	"hegrenade",
	"inferno",
	"flashbang",
	"decoy",
	"smokegrenade",
	"taser"
	},
}

local function print(str)
    if str == nil then
        error("print")
    end; client.log(str)
end

print("welcome "..user)

local function new_element(element, condition, config, callback)
    condition = condition or true
    config = config or false
    callback = callback or function() end

    local update = function()
        for k, v in pairs(elements) do
            if type(v.condition) == "function" then
                v.element:set_visible(v.condition())
            else
                v.element:set_visible(v.condition)
            end
        end
    end

    callbacks.register("paint", function(value)
        update()
        callback(value)
    end)

    table.insert(elements, { element = element, condition = condition})

    if config then
        table.insert(config, element)
    end

    update()

    return element
end

local master = new_element(ui.add_checkbox(string.format("wraith - %s", user)))
local tab = new_element(ui.add_dropdown("wraith tabs", {"anti-aim", "visuals", "misc", "config", "debug"}), function() return (master):get() end)