-- Configuration script for the Fungal Shift Query mod
--
-- PLANNED FEATURES
--
-- ** Ability to add/remove materials to existing source shift sets (both
-- one-at-a-time and in bulk)
-- ** Ability to modify source and destination probabilities
-- ** Ability to add/remove source and destination shift sets (both
-- one-at-a-time and in bulk)
-- ** Ability to override MAX_SHIFTS


dofile("data/scripts/lib/utilities.lua")
dofile("data/scripts/lib/mod_settings.lua")

MIN_SHIFTS = -1     -- values < 0 mean "all"
MAX_SHIFTS = 20     -- the game implicitly supports only 20 shifts

-- Available functions:
-- ModSettingSetNextValue(setting_id, next_value, true/false)
-- ModSettingSet(setting_id, new_value)

function mod_setting_changed_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
    if setting == "previous_count" or setting == "next_count" then
        if new_value < MIN_SHIFTS then
            GamePrint(("setting %s %s outside range"):format(setting, tostring(new_value)))
        end
    end
end

local mod_id = "shift_query"
mod_settings_version = 3
mod_settings = {
    {
        id = "previous_count",
        ui_name = "Previous count",
        ui_description = "How many previous shifts should we display? (-1 = all)",
        value_default = 0,
        value_min = MIN_SHIFTS,
        value_max = MAX_SHIFTS,
        value_display_multiplier = 1,
        change_fn = mod_setting_changed_callback,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "next_count",
        ui_name = "Next count",
        ui_description = "How many pending shifts should we display? (-1 = all)",
        value_default = -1,
        value_min = MIN_SHIFTS,
        value_max = MAX_SHIFTS,
        value_display_multiplier = 1,
        change_fn = mod_setting_changed_callback,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "localize",
        ui_name = "Translate?",
        ui_description = "How should material names be displayed?",
        value_default = "locale",
        values = {
            {"locale", "Localized Name"},
            {"internal", "Internal Name"},
            {"both", "Both"}
        },
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "enable",
        ui_name = "Enable UI",
        ui_description = "Display GUI",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    --[[{
        id = "override_ui",
        ui_name = "Enable Override UI",
        ui_description = "Enable use of the manual shifting UI",
        value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },]]
    {
        id = "include_aplc",
        ui_name = "Include AP / LC recipes",
        ui_description = "Include Alchemic Precursor and Lively Concoction recipes",
        value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(mod_id)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end

-- vim: set ts=4 sts=4 sw=4:
