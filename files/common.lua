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
dofile_once("mods/shift_query/files/constants.lua")

MOD_ID = "shift_query"
K_CONFIG_LOG_ENABLE = MOD_ID .. "." .. "q_logging"

-- Return either "Enable" or "Disable" based on the condition
function f_enable(cond)
    if cond then return "Enable" end
    return "Disable"
end

-- Print a message to both the game and to the console
function q_print(msg)
    GamePrint(msg)
    print(msg)
end

-- Format a "<nu> pending/previous shift(s)" message
function f_shift_count(num, label)
    local prefix = tostring(num)
    local suffix = "shifts"
    if num < 0 then prefix = "all"
    elseif num == 0 then prefix = "zero"
    elseif num == 1 then
        prefix = "one"
        suffix = "shift"
    end
    return ("%s %s %s"):format(prefix, label, suffix)
end

-- Returns true if logging is enabled, false otherwise.
function q_logging()
    return GlobalsGetValue(K_CONFIG_LOG_ENABLE, FLAG_OFF) ~= FLAG_OFF
end

-- Enable or disable logging
function q_set_logging(enable)
    if enable then
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, FLAG_ON)
        q_log("Debugging is now enabled")
    else
        q_log("Disabling debugging")
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, FLAG_OFF)
    end
end

-- Display a logging message if logging is enabled.
function q_log(msg)
    if q_logging() then
        q_print("DEBUG: " .. msg)
    end
end

-- Display a formatted logging message if logging is enabled.
function q_logf(msg, ...)
    if q_logging() then
        q_log(msg:format(...))
    end
end

--[[ Configuration
-- Cache is necessary because it takes more than one update cycle before
-- configuration updates are finalized. After calling
-- ModSettingSetNextValue, the next several calls to ModSettingGet will
-- return the prior value for the next couple update cycles.
--
-- The cache allows for these values to appear instantly. Cache entries
-- are stored when setting a value and cleared once that value is
-- properly stored.
--]]
local config_cache = {}

--[[ Get the value for a particular setting ]]
function q_setting_get(setting)
    local value = ModSettingGet(MOD_ID .. "." .. setting)
    if config_cache[setting] ~= nil then
        local entry = config_cache[setting]
        if entry.old_value == value then
            return entry.new_value
        end
        if value == entry.new_value then
            config_cache[setting] = nil
            return value
        end
    end
    return value
end

--[[ Set the value for a particular setting ]]
function q_setting_set(setting, value)
    local old_value = ModSettingGet(MOD_ID .. "." .. setting)
    config_cache[setting] = {
        old_value = old_value,
        new_value = value
    }
    ModSettingSetNextValue(MOD_ID .. "." .. setting, value, false)
end

-- Get the "enable gui?" setting's value
function q_get_enabled()
    local value = q_setting_get(SETTING_ENABLE)
    if value then
        return true
    end
    return false
end

-- Disable the GUI
function q_disable_gui()
    q_setting_set(SETTING_ENABLE, false)
end

-- Clear the logging global if set
function logger_clear()
    local value = GlobalsGetValue("shift_query.logging") or ""
    if value ~= "" then
        GlobalsSetValue("shift_query.logging", "")
    end
end

-- Add a component to the logging global
function logger_add(piece)
    local old_log = GlobalsGetValue("shift_query.logging") or ""
    local new_log = tostring(piece)
    if old_log ~= "" then
        new_log = old_log .. "\n" .. new_log
    end
    GlobalsSetValue("shift_query.logging", new_log)
end

-- Localize a material, either "name" or "$mat_name".
function localize_material(material)
    local matid = CellFactory_GetType(material)
    local mname = material
    if matid ~= -1 then
        mname = CellFactory_GetUIName(matid)
    end
    local name = GameTextGetTranslatedOrNot(mname)
    if not name then -- handle nil
        return ""
    end
    return name
end

-- Localize a material based on the mode argument
function localize_material_via(material, loc_mode)
    if loc_mode == FORMAT_INTERNAL then
        return material
    end

    local local_name = localize_material(material)
    if local_name == "" or local_name == material then
        return material
    end

    if loc_mode == FORMAT_LOCALE then
        return local_name
    end

    if loc_mode == FORMAT_BOTH then
        return ("%s [%s]"):format(local_name, material)
    end

    return ("[%s]"):format(material)
end

-- Possibly localize a material based on q_logging, localize setting
function maybe_localize_material(material)
    local loc_mode = q_setting_get(SETTING_LOCALIZE)
    return localize_material_via(material, loc_mode)
end

-- Format a material with the possibility of including a flask.
function flask_or(material, use_flask)
    local logging = q_logging()
    local mname = maybe_localize_material(material)
    if use_flask then
        return ("flask or %s"):format(mname)
    end
    if logging then
        return ("%s (no flask)"):format(mname)
    end
    return mname
end

-- Format a fungal shift. Returns a table of pairs of strings.
function format_shift(shift)
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
    local s_target = flask_or(target.material, target.flask)
    local material_pairs = {}
    if source.name_material then
        local s_source = flask_or(source.name_material, source.flask)
        table.insert(material_pairs, {s_source, s_target})
    else
        for index, material in ipairs(source.materials) do
            local s_source = flask_or(material, source.flask)
            table.insert(material_pairs, {s_source, s_target})
        end
    end
    return material_pairs
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

-- Format a duration of time
function format_duration(nsecs)
    local total = math.abs(nsecs)
    local hours = math.floor(total / 60 / 60)
    local minutes = math.floor(total / 60) % 60
    local seconds = math.floor(total) % 60
    local parts = {}
    if hours ~= 0 then
        table.insert(parts, ("%dh"):format(hours))
    end
    if minutes ~= 0 then
        table.insert(parts, ("%dm"):format(minutes))
    end
    if seconds ~= 0 then
        table.insert(parts, ("%ds"):format(seconds))
    end
    if #parts == 0 then
        return "0s"
    end
    if nsecs < 0 then
        return "-" .. table.concat(parts)
    end
    return table.concat(parts)
end

-- vim: set ts=4 sts=4 sw=4:
