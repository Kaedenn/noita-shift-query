--[[
-- Locali(s,z)ation support logic and functions
--]]
dofile("mods/kae_test/common.lua")
dofile_once("data/scripts/lib/utilities.lua")

L10N = {
    CONF_NAME_LOC = "locale",
    CONF_NAME_INT = "internal",
    CONF_NAME_BOTH = "both",

    -- Get current configured localization mode
    get_mode = function()
        return q_setting_get("localize")
    end,

    -- Get the internal material symbol for the given material
    get_sym_for = function(material)
        local mid = CellFactory_GetType(material)
        if mid ~= -1 then
            return CellFactory_GetUIName(mid)
        end
        return nil
    end,

    -- Localize the given material
    get_name_for = function(material)
        -- Start with the simple case: given a UIName
        local name = GameTextGetTranslatedOrNot(material)
        if name and name ~= "" then return name end

        -- Lookup the material through Type->UIName
        local mid = CellFactory_GetType(material)
        local mname = CellFactory_GetUIName(mid)
        if mid ~= -1 and mname and mname ~= "" then
            name = GameTextGetTranslatedOrNot(mname)
            if name and name ~= "" then
                return name
            end
        end
        return nil
    end,

    -- Possibly localize the given material depending on the setting
    localize = function(material)
        local setting = L10N.get_mode()
        -- TODO
    end
}

-- vim: set ts=4 sts=4 sw=4:
