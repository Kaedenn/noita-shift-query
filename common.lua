-- Common utilities
--
-- This file contains various common functions useful to mods outside
-- the Shift Query mod. Note that some of the values below would need
-- to be changed for other mods.
--
-- FIXME: KNOWN ISSUES:
--
-- When debugging is enabled and a shift uses a flask for either the
-- source or destination material, the other material should not have
-- the "(no flask)" designation, as it's redundant.

dofile_once("data/scripts/lib/utilities.lua")

K_MOD_ID = "shift_query"
K_CONFIG_LOG_ENABLE = K_MOD_ID .. "." .. "q_logging"
K_ON = "1"
K_OFF = "0"

-- Return the first value if the condition is true, the second otherwise
function ifelse(cond, trueval, falseval)
    if cond then
        return trueval
    end
    return falseval
end

-- Print a message to both the game and to the console.
function q_print(msg)
    GamePrint(msg)
    print(msg)
end

-- Returns true if logging is enabled, false otherwise.
function q_logging()
    return GlobalsGetValue(K_CONFIG_LOG_ENABLE, K_OFF) ~= K_OFF
end

-- Enable or disable logging
function q_set_logging(enable)
    if enable then
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, K_ON)
        q_log("Debugging is now enabled")
    else
        q_log("Disabling debugging")
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, K_OFF)
    end
end

-- Display a logging message if logging is enabled.
function q_log(msg)
    if q_logging() then
        return q_print("DEBUG: " .. msg)
    end
end

-- Get a configuration setting
function q_setting_get(setting)
    return ModSettingGet(K_MOD_ID .. "." .. setting)
end

-- Set a configuration setting
function q_setting_set(setting, value)
    ModSettingSetNextValue(K_MOD_ID .. "." .. setting, value, false)
end

-- Get the "enable gui?" setting's value
function q_get_enabled()
    local value = q_setting_get("enable")
    if value then
        return true
    end
    return false
end

-- Disable the GUI
function q_disable_gui()
    q_setting_set("enable", false)
end

-- Format a material with the possibility of including a flask.
-- Localizes the material if l10n is true.
function flask_or_loc(material, use_flask, l10n)
    local logging = q_logging()
    local mname = material
    if l10n then
        mname = CellFactory_GetUIName(material)
        if logging and mname ~= material then
            mname = ("%s [%s]"):format(mname, material)
        end
    end
    if not mname or mname == "" then mname = material end
    if use_flask then
        return ("flask or %s"):format(material)
    elseif logging then
        return ("%s (no flask)"):format(material)
    end
    return mname
end

-- Format a material with the possibility of including a flask.
-- Localizes the material.
function flask_or(material, use_flask)
    return flask_or_loc(material, use_flask, true)
end

-- Format a fungal shift. Returns a table of pairs of strings.
-- Localizes the materials if l10n is true.
function format_shift_loc(shift, l10n)
    if not shift then return {{"invalid shift", "invalid shift"}} end
    local source = shift.from
    local target = shift.to
    if not source or not target then
        local s_source = "valid"
        if not source then
            s_source = "no data"
        end
        local s_target = "valid"
        if not target then
            s_target = "no data"
        end
        return {s_source, s_target}
    end
    local s_target = flask_or_loc(target.material, target.flask, l10n)
    local material_pairs = {}
    if source.name_material then
        local s_source = flask_or_loc(source.name_material, source.flask, l10n)
        table.insert(material_pairs, {s_source, s_target})
    else
        for index, material in ipairs(source.materials) do
            local s_source = flask_or_loc(material, source.flask, l10n)
            table.insert(material_pairs, {s_source, s_target})
        end
    end
    return material_pairs
end

-- Invokes format_shift_loc with localization enabled.
function format_shift(shift)
    return format_shift_loc(shift, true)
end

-- Format a number relative to its current value
function format_relative(curr, index)
    local term = "invalid"
    if index == curr then
        term = "next"
    elseif index > curr then
        term = ("next+%s"):format(index-curr)
    elseif index == curr - 1 then
        term = "last"
    elseif index < curr - 1 then
        term = ("prev-%s"):format(curr-index-1)
    end
    if q_logging() then
        term = ("%s[i=%s]"):format(term, index)
    end
    return term
end

-- vim: set ts=4 sts=4 sw=4:
