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

-- Return either "Enable" or "Disable" based on the condition
function f_enable(cond)
    if cond then return "Enable" end
    return "Disable"
end

-- Return the first non-false value of a function over a table of values
function first_result(func, values)
    for _, value in ipairs(values) do
        local result = func(value)
        if result then
            return result, value
        end
    end
    return nil, nil
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
        q_print("DEBUG: " .. msg)
    end
end

-- Display a formatted logging message if logging is enabled.
function q_logf(msg, ...)
    if q_logging() then
        q_log(msg:format(...))
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

-- Possibly localize a material based on q_logging, localize setting
function maybe_localize_material(material)
    local result = localize_material(material)
    local loc_mode = q_setting_get("localize")
    if result == "" or result == nil then
        result = ("[%s]"):format(material)
    elseif loc_mode == "internal" then
        result = material
    elseif loc_mode == "both" then
        result = ("%s [%s]"):format(localize_material(material), material)
    end
    return result
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
