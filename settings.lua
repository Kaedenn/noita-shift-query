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

--[[
-- FIXME: previous_count and next_count display -2 .. 20
-- FIXME: previous_count and next_count are not integers
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
dofile_once("mods/shift_query/files/common.lua")

-- luacheck: globals MOD_SETTING_SCOPE_RUNTIME

-- Available functions:
-- ModSettingSetNextValue(setting_id, next_value, true/false)
-- ModSettingSet(setting_id, new_value)

function mod_setting_changed_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
    --[[ TODO: enforce integer values
    logger_add(("Setting %s changed from %s to %s"):format(
        setting.id, tostring(old_value), tostring(new_value)))
    if setting.id == "previous_count" or setting.id == "next_count" then
        local final_value = math.floor(new_value)
        if final_value < MIN_SHIFTS then
            logger_add(("Setting %s %d below %d"):format(setting.id, new_value, final_value))
            final_value = MIN_SHIFTS
        elseif final_value > MAX_SHIFTS then
            logger_add(("Setting %s %d above %d"):format(setting.id, new_value, final_value))
            final_value = MAX_SHIFTS
        end
        if new_value ~= final_value then
            ModSettingSet(MOD_ID .. "." .. setting.id, final_value)
        end
        return final_value
    end
    ]]
end

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
            {FORMAT_LOCALE, "Localized Name"},
            {FORMAT_INTERAL, "Internal Name"},
            {FORMAT_BOTH, "Both"}
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
    {
        id = "include_aplc",
        ui_name = "Include AP / LC recipes",
        ui_description = "Include Alchemic Precursor and Lively Concoction recipes",
        value_default = false,
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
