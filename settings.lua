--[[
-- Configuration script for the Fungal Shift Query mod
--
-- Changing any setting (other than enable) triggers a force update.
--
-- Note that this script cannot reference any file in the mods/ directory, as
-- the virtual filesystem is not yet initialized by the time this script runs.
-- Therefore, all values in files/common.lua and files/constants.lua are
-- instead hard-coded here.
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
MOD_ID = "shift_query"
MIN_SHIFTS = -1
MAX_SHIFTS = 20

function sq_mod_shift_range(mod_id, gui, in_main_menu, im_id, setting)
    -- luacheck: globals ModSettingGetNextValue ModSettingSetNextValue
    -- luacheck: globals GuiSlider mod_setting_group_x_offset
    -- luacheck: globals mod_setting_handle_change_callback
    -- luacheck: globals mod_setting_tooltip mod_setting_get_id
    local value = ModSettingGetNextValue(mod_setting_get_id(mod_id, setting))
    if type(value) ~= "number" then value = setting.default or 0 end
    
    local value_new = GuiSlider(
        gui, im_id,
        mod_setting_group_x_offset, 0,
        setting.ui_name,
        value,
        setting.value_min,
        setting.value_max,
        setting.value_default,
        setting.value_display_multiplier or 1,
        setting.value_display_formatting or "", 64)
    --value_new = clamp(math.floor(value_new), MIN_SHIFTS, MAX_SHIFTS)
    value_new = math.floor(value_new)
    if value ~= value_new then
        ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), value_new, false)
        mod_setting_handle_change_callback(mod_id, gui, in_main_menu, setting, value, value_new)
    end

    mod_setting_tooltip(mod_id, gui, in_main_menu, setting)
end

function sq_setting_changed( mod_id, gui, in_main_menu, setting, old_value, new_value )
    if old_value ~= new_value then
        GlobalsSetValue("shift_query.q_force_update", "1")
    end
end

mod_settings_version = 5
mod_settings = {
    -- luacheck: globals MOD_SETTING_SCOPE_RUNTIME
    {
        id = "enable",
        ui_name = "Enable UI",
        ui_description = "Display GUI",
        value_default = true,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "previous_count",
        ui_name = "Previous count",
        ui_description = "How many previous shifts should we display? (-1 = all)",
        value_default = 0,
        value_min = -0.5,
        value_max = 20,
        value_display_multiplier = 1,
        change_fn = sq_setting_changed,
        ui_fn = sq_mod_shift_range,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "next_count",
        ui_name = "Next count",
        ui_description = "How many pending shifts should we display? (-1 = all)",
        value_default = 20,
        value_min = -0.5,
        value_max = 20,
        value_display_multiplier = 1,
        change_fn = sq_setting_changed,
        ui_fn = sq_mod_shift_range,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "localize",
        ui_name = "Translate?",
        ui_description = "How should material names be displayed?",
        value_default = "locale",
        values = {
            {"locale", "Translated Name"},
            {"internal", "Internal Name"},
            {"both", "Both"},
        },
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "expand_from",
        ui_name = "Expand sources?",
        ui_description = "Show all source materials, or just the primary one?",
        value_default = "one",
        values = {
            {"one", "Primary Material"},
            {"all", "All Materials"},
        },
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "include_aplc",
        ui_name = "Include AP / LC recipes",
        ui_description = "Include Alchemic Precursor and Lively Concoction recipes",
        value_default = false,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "flask_real",
        ui_name = "Resolve Flasks",
        ui_description = "Show a log of past shifts with flasks resolved to the real material",
        value_default = false,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "enable_color",
        ui_name = "Color Text",
        ui_description = "Should text be drawn using colors?",
        value_default = true,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    -- luacheck: globals mod_settings_get_version mod_settings_update
    local old_version = mod_settings_get_version(MOD_ID)
    mod_settings_update(MOD_ID, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    -- luacheck: globals mod_settings_gui_count
    return mod_settings_gui_count(MOD_ID, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    -- luacheck: globals mod_settings_gui
    mod_settings_gui(MOD_ID, mod_settings, gui, in_main_menu)
end

-- vim: set ts=4 sts=4 sw=4:
