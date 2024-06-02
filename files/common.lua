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
--
-- TODO:
--
-- Move the setting stuff into a class and allow stuff like
-- Config.previous_count.get()
-- Config.previous_count.set(num)
-- or something

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/shift_query/files/constants.lua")
smallfolk = dofile_once("mods/shift_query/files/lib/smallfolk.lua")
MatLib = dofile_once("mods/shift_query/files/materials.lua")

MOD_ID = "shift_query"
K_CONFIG_LOG_ENABLE = MOD_ID .. "." .. "q_logging"
K_CONFIG_FORCE_UPDATE = MOD_ID .. "." .. "q_force_update"

--[[ Return either "Enable" or "Disable" based on the condition ]]
function f_enable(cond)
    if cond then return "Enable" end
    return "Disable"
end

--[[ As above, but for "Show" or "Hide" ]]
function f_show(cond)
    if cond then return "Show" end
    return "Hide"
end

--[[ Trigger a force update ]]
function q_force_update()
    GlobalsSetValue(K_CONFIG_FORCE_UPDATE, FLAG_ON)
end

--[[ Clear the force update flag ]]
function q_clear_force_update()
    GlobalsSetValue(K_CONFIG_FORCE_UPDATE, FLAG_OFF)
end

--[[ True if an update is being forced ]]
function q_is_update_forced()
    return GlobalsGetValue(K_CONFIG_FORCE_UPDATE, FLAG_OFF) ~= FLAG_OFF
end

--[[ Print a message to both the game and to the console ]]
function q_print(msg)
    GamePrint(msg)
    print(msg)
end

--[[ Format a "<num> pending/previous shift(s)" message ]]
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

--[[ Returns true if logging is enabled, false otherwise ]]
function q_logging()
    return GlobalsGetValue(K_CONFIG_LOG_ENABLE, FLAG_OFF) ~= FLAG_OFF
end

--[[ Enable or disable logging ]]
function q_set_logging(enable)
    if enable then
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, FLAG_ON)
        q_log("Debugging is now enabled")
    else
        q_log("Disabling debugging")
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, FLAG_OFF)
    end
    q_force_update()
end

--[[ Display a logging message if logging is enabled ]]
function q_log(msg)
    if q_logging() then
        q_print("DEBUG: " .. msg)
    end
end

--[[ Display a formatted logging message if logging is enabled ]]
function q_logf(msg, ...)
    if q_logging() then
        local args = {...}
        for idx = 1, #args do
            if type(args[idx]) == "table" then
                args[idx] = smallfolk.dumps(args[idx])
            end
        end
        q_log(msg:format(unpack(args)))
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
--
-- FIXME: Just use ModSettingGetNextValue; this is unnecessary
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
    if old_value ~= value then
        q_force_update()
    end
end

-- Get the "enable gui?" setting's value
function q_get_enabled()
    return q_setting_get(SETTING_ENABLE) and true or false
end

-- Disable the GUI
function q_disable_gui()
    q_setting_set(SETTING_ENABLE, false)
end

--[[ Localize a material, either "name" or "$mat_name"
-- @param material string
-- @return string
--]]
function localize_material(material)
    local matinfo = MatLib:get(material)
    if not matinfo then
        -- Could not get material from MatLib; use fallback behavior
        local matid = CellFactory_GetType(material)
        local mname = material
        if matid ~= -1 then
            mname = CellFactory_GetUIName(matid)
        end
        return GameTextGetTranslatedOrNot(mname) or ""
    end

    return matinfo.local_name or ""
end

--[[ Localize a material based on the mode argument
-- @param material string
-- @param loc_mode string
-- @return string
--]]
function localize_material_via(material, loc_mode)
    local internal_name = material
    local local_name = localize_material(material)
    if q_setting_get(SETTING_TERSE) then
        local purge_pats = {"magic_liquid_", "material_", "_liquid"}
        for _, pat in ipairs(purge_pats) do
            if internal_name:match(pat) then
                internal_name = internal_name:gsub(pat, "")
            end
        end
    end
    if loc_mode == FORMAT_INTERNAL then
        return internal_name
    end

    if local_name == "" or local_name:lower() == material then
        return internal_name
    end

    if loc_mode == FORMAT_LOCALE then
        return local_name
    end

    if loc_mode == FORMAT_BOTH then
        return ("%s [%s]"):format(local_name, internal_name)
    end

    return ("[%s]"):format(internal_name)
end

--[[ Possibly localize a material based on q_logging, localize setting
-- @param material string
-- @return string
--]]
function maybe_localize_material(material)
    local loc_mode = q_setting_get(SETTING_LOCALIZE)
    return localize_material_via(material, loc_mode)
end

--[[ Format a material with the possibility of including a flask
-- @param material string
-- @param use_flask boolean
-- @return table
--]]
function flask_or(mname, use_flask)
    if use_flask then
        return {{color="cyan_light", "flask"}, {color="lightgray", "or"}, mname}
    end
    if q_logging() then
        return {mname, {color="lightgray", "(no flask)"}}
    end
    return {mname}
end

--[[ Format a fungal shift. Returns a pair of Feedback lines
-- @param shift {from=table, to=table}
-- @return table, table
--]]
function format_shift(shift)
    if not shift then return {"invalid shift", "invalid shift"} end
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
    local m_target = {
        image=material_get_icon(target.material),
        maybe_localize_material(target.material)
    }
    local s_source = {shift.from}
    local s_target = flask_or(m_target, target.flask)
    local want_expand = q_setting_get(SETTING_EXPAND)
    if want_expand == EXPAND_ONE and source.name_material then
        local mname = {
            image=material_get_icon(source.name_material),
            maybe_localize_material(source.name_material)
        }
        s_source = flask_or(mname, source.flask)
    else
        local s_sources = {}
        for _, mat in ipairs(source.materials) do
            table.insert(s_sources, {
                image=material_get_icon(mat),
                maybe_localize_material(mat)
            })
        end
        s_source = flask_or(s_sources, source.flask)
    end
    return s_source, s_target
end

--[[ Get the (probable) path to the material icon
-- @param matname string
-- @return string
--]]
function material_get_icon(matname)
    return ("data/generated/material_icons/%s.png"):format(matname)
end

--[[ Possibly format text with a given color
-- @param text string
-- @param color table|string|nil
-- @return table
--]]
function format_color(text, color)
    if color then
        return {color=color, text}
    end
    return {text}
end

--[[ Format a number relative to its current value
-- @param curr number
-- @param index number
-- @param colors table|nil
-- @return table
--]]
function format_relative(curr, index, colors)
    local color = colors or {}
    local term, term_color
    if index == curr then
        term = "next"
        term_color = color.next_shift
    elseif index > curr then
        term = ("next+%s"):format(index-curr)
        term_color = color.future_shift
    elseif index == curr - 1 then
        term = "prev"
        term_color = color.past_shift
    else
        term = ("prev-%s"):format(curr-index-1)
        term_color = color.past_shift
    end
    if q_setting_get(SETTING_ABSOLUTE) then
        term = ("%d"):format(index+1)
    end
    local result = format_color(term, term_color)
    if q_logging() then
        result[#result] = result[#result] .. ("[i=%s]"):format(index) 
    end
    return result
end

--[[ Format a duration of time
-- @param nsecs number
-- @return string
--]]
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
