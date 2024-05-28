--[[
-- Configuration script for the Fungal Shift Query mod
--
-- Changing any setting triggers a force update.
--
-- Note that this script cannot reference any file in the mods/ directory, as
-- the virtual filesystem is not yet initialized by the time this script runs.
-- Therefore, all values in files/common.lua and files/constants.lua are
-- instead hard-coded here.
--
-- The minimum value for the shift count settings is -0.5 rather than -1,
-- because there is (currently) no way to force a numeric setting to have
-- integer values. Specifying -1 results in the minimum appearing as -2.
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

mod_settings_version = 6
mod_settings = {
    -- luacheck: globals MOD_SETTING_SCOPE_RUNTIME
    {
        id = "enable",
        ui_name = "Enable UI",
        ui_description = "Closing the GUI through the Actions menu will uncheck this option.",
        value_default = true,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        category_id = "shift_range",
        ui_name = "Shift Display",
        settings = {
            {
                id = "previous_count",
                ui_name = "Previous count",
                ui_description = "How many previous shifts should we display? (-1 = all)",
                value_default = 0,
                value_min = -0.5,   -- See comment at the top of the file
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
                value_min = -0.5, -- See comment at the top of the file
                value_max = 20,
                value_display_multiplier = 1,
                change_fn = sq_setting_changed,
                ui_fn = sq_mod_shift_range,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            },
        },
    },
    {
        id = "localize",
        ui_name = "Translate?",
        ui_description = "How should material names be displayed?",
        value_default = "locale",
        values = {
            {"locale", "Translated Name"},
            {"internal", "Internal Name"},
            {"both", "Both Translated and Internal Names"},
        },
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        category_id = "display_features",
        ui_name = "Features",
        settings = {
            {
                id = "expand_from",
                ui_name = "Expand Sources",
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
                ui_name = "Include AP / LC Recipes",
                ui_description = "Include Alchemic Precursor and Lively Concoction recipes",
                value_default = true,
                change_fn = sq_setting_changed,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            },
            {
                id = "flask_real",
                ui_name = "Show Shift Log",
                ui_description = "Show a log of past shifts with flasks resolved to the real material",
                value_default = false,
                change_fn = sq_setting_changed,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            },
            {
                id = "show_greedy",
                ui_name = "Show Greedy Shifts",
                ui_description = [[
Show what material attempting to shift to gold would become. Attempting
to shift a material to gold has a 0.1% chance to succeed, with 99.9% of
attempts converting the source material to a random "greedy" material.
This option will display that material. Note that successful greedy
shifts are always displayed. Successful greedy shifts will also convert
materials to Holy Grass, if held.]],
                value_default = false,
                change_fn = sq_setting_changed,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            },
        },
    },
    {
        id = "enable_color",
        ui_name = "Enable Color Text",
        ui_description = "Should text be drawn using colors?",
        value_default = true,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "enable_images",
        ui_name = "Enable Material Images",
        ui_description = "Show material texture icons next to each material",
        value_default = true,
        change_fn = sq_setting_changed,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "terse",
        ui_name = "Terse Mode",
        ui_description = "Remove unnecessary text to make messages shorter",
        value_default = false,
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
