-- Fungal Shift Query by Kaedenn
--
-- This mod lets you query past and pending fungal shifts both
-- _accurately_ and _safely_.
--
-- Some existing shift predictors are ambiguous about whether or not
-- the pending shift will use your held flask. This mod is entirely
-- unambiguous; if a flask is mentioned, then a flask will be used.
--
-- While the cheatgui mod lets you see fungal shifts, it does this by
-- invoking the shift and checking what changed, which causes problems
-- with the fungal timer mod. This mod doesn't have this issue; shifts
-- are deduced directly using the same algorithm Noita uses.
--
-- This mod instead clones part of data/scripts/magic/fungal_shift.lua
-- and runs the algorithm manually. Note that this will break if the
-- shift logic changes.
--
-- PLANNED FEATURES
--
-- Allow usage without Noita-Dear-ImGui using an alternate GUI library.
-- Can use gusgui from https://github.com/ofoxsmith/gusgui
--
-- Support different languages for static text (see files/common.lua).
--

dofile_once("mods/shift_query/files/common.lua")
-- luacheck: globals q_get_enabled format_duration
dofile_once("mods/shift_query/files/materials.lua")
-- luacheck: globals MatLib
dofile_once("mods/shift_query/files/query.lua")
-- luacheck: globals get_last_shift_frame get_cooldown_sec
dofile_once("mods/shift_query/files/squi.lua")
-- luacheck: globals SQ

imgui = nil
query = nil

--[[ Load the material table.
--
-- Because fungal shifts change the value returned by
-- CellFactory_GetUIName(), we need to cache these values after the
-- cell factory is initialized but before the world state (and thus the
-- shift log) is loaded ]]
function OnBiomeConfigLoaded()
    MatLib:init()
end

function OnModPostInit()
    if load_imgui then
        imgui = load_imgui({version="1.4.0", mod="FungalShiftQuery"})
        query = SQ:new(imgui)
    end
end

-- The actual driving code, executed once per frame after world update
function OnWorldPostUpdate()
    local ready = q_get_enabled()

    if not imgui and load_imgui then
        -- ImGui wasn't loaded, but is now
        OnModPostInit()
    end

    if not imgui then
        GamePrint(table.concat({
            "shift_query - Noita-Dear-ImGui not found;",
            "see workshop page for instructions"}, " "))
        GamePrint(table.concat({
            "shift_query - Ensure unsafe mods are enabled,",
            "Noita-Dear-ImGui is installed and active,",
            "and this mod is below Noita-Dear-ImGui in the mod list"}, " "))
        ready = false
    elseif not query then
        GamePrint("shift_query - query object not initialized")
        ready = false
    end

    if ready then
        local window_flags = bit.bor(
            imgui.WindowFlags.NoFocusOnAppearing,
            imgui.WindowFlags.MenuBar,
            imgui.WindowFlags.NoNavInputs,
            imgui.WindowFlags.HorizontalScrollbar)
        local wtitle = "Fungal Shifts"
        local last_shift = get_last_shift_frame()
        local cooldown = get_cooldown_sec()
        if last_shift > -1 and cooldown > 0 then
            wtitle = ("%s (%s)"):format(wtitle, format_duration(cooldown))
        end
        if imgui.Begin(wtitle .. "###Main", nil, window_flags) then
            local res, ret = pcall(query.draw, query)
            if not res then
                GamePrint(tostring(ret))
                print_error(tostring(ret))
            end
            imgui.End()
        end
    end
end

function OnPlayerSpawned(player_entity)
    if query ~= nil then
        query:refresh()
    end
end

-- vim: set ts=4 sts=4 sw=4:
