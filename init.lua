-- Fungal Query by Kaedenn
--
-- This mod lets you query past and pending fungal shifts _safely_.
--
-- While the cheatgui mod lets you see fungal shifts, it does this by
-- invoking the shift and checking what changed, which causes problems
-- with the fungal timer mod.
--
-- This mod instead clones part of data/scripts/magic/fungal_shift.lua
-- and runs the algorithm manually. Note that this will break if the
-- material probabilities tables change or if the shift logic itself
-- changes!
--
-- PLANNED FEATURES
--
-- There's no ImGui fallback behavior, nor are there any diagnostic
-- messages if ImGui isn't available.
--
-- There's no way to alter the materials. Ideally the materials list
-- would be loaded via reading the fungal_shift.lua script directly
-- and custom materials could be specified via add, merge, or replace
-- library operations.
--
-- Add "fungal_shift_ui_icon" to the ImGui window.

dofile("mods/shift_query/common.lua")
dofile("mods/shift_query/materials.lua")

-- Any strings added to shift_messages will be displayed in the GUI
-- until the next calculation is ran (which clears the table)
local shift_messages = {}

-- Maximum number of shifts according to fungal_shift.lua
local MAX_SHIFTS = 20

-- Get the number of shifts that have occurred
function get_current_iter()
    return tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
end

-- Find the numbered fungal shift. The numbers used below are taken
-- directly from the fungal_shift.lua script
function get_abs_shift(player_entity, iter)
    q_log(string.format("get_abs_shift(player=%s, %s)",
                        tostring(player_entity), tostring(iter)))
    if not random_create then
        GamePrint("get_shift: random_create undefined")
        return SHIFT_FAIL
    end
    SetRandomSeed(89346, 42345+iter)
    local rnd = random_create(9123, 58925+iter)
    local mat_from = pick_random_from_table_weighted(rnd, MATERIALS_FROM)
    local mat_to = pick_random_from_table_weighted(rnd, MATERIALS_TO)

    mat_from.flask = false
    mat_to.flask = false
    if random_nexti(rnd, 1, 100) <= 75 then
        if random_nexti(rnd, 1, 100) <= 50 then
            mat_from.flask = true
        else
            mat_to.flask = true
        end
    end

    return {from=mat_from, to=mat_to}
end

-- Build the final shift string
function q_shift_str(which, source, dest)
    return ("%s shift is %s -> %s"):format(which, source, dest)
end

-- Deduce and format the absolute-indexed shift
function q_find_shift(shift_index)
    q_log(("q_find_shift(%s)"):format(tostring(shift_index)))
    local curr_iter = get_current_iter()
    local player = get_players()[1]
    local shift_result = get_abs_shift(player, shift_index)
    local next_msg = format_relative(curr_iter, shift_index)
    for index, spair in ipairs(format_shift(shift_result)) do
        local msg = q_shift_str(next_msg, spair[1], spair[2])
        GamePrint(msg)
        table.insert(shift_messages, msg)
    end
end

-- Determine the absolute start and end range for shifts
function q_which_shifts()
    local curr_iter = get_current_iter()
    local range_prev = math.floor(q_setting_get("previous_count"))
    local range_next = math.floor(q_setting_get("next_count"))
    q_log(string.format("start-count = %s, end-count = %s, curr = %s",
                        range_prev, range_next, curr_iter))
    local idx_start = curr_iter
    local idx_end = curr_iter
    if range_prev < 0 then
        idx_start = 0
    elseif range_prev > 0 then
        idx_start = curr_iter - range_prev
    end
    if idx_start < 0 then
        idx_start = 0
    end

    if range_next < 0 then
        idx_end = MAX_SHIFTS
    elseif range_next > 0 then
        idx_end = curr_iter + range_next
    end
    if idx_end > MAX_SHIFTS then
        idx_end = MAX_SHIFTS
    end

    if idx_start > idx_end then
        idx_start = idx_end
    end
    q_log(("start = %s, end = %s"):format(idx_start, idx_end))
    return {first=idx_start, last=idx_end}
end

-- Find all relevant shifts based on the settings
function q_find_shifts()
    local range_bounds = q_which_shifts()
    local rstart = range_bounds.first
    local rend = range_bounds.last
    q_log(("Querying shifts from %s to %s"):format(rstart, rend))
    local i = rstart
    while i <= rend do
        q_log(("Querying shift %s"):format(i))
        q_find_shift(i)
        i = i + 1
    end
end

function q_imgui_build_menu(imgui)
    if imgui.BeginMenuBar() then
        if imgui.BeginMenu("Actions") then
            local mstr = ifelse(q_logging(), "Disable", "Enable")
            if imgui.MenuItem(mstr .. " Debugging") then
                q_set_logging(not q_logging())
            end
            if imgui.MenuItem("Clear") then
                shift_messages = {}
            end
            if imgui.MenuItem("Close") then
                q_disable_gui()
            end
            imgui.EndMenu()
        end
        imgui.EndMenuBar()
    end
end

function q_imgui_build(imgui)
    local curr_iter = get_current_iter()

    -- Button to display all selected shifts
    if imgui.Button("Get Shifts") then
        shift_messages = {}
        q_log("Calculating shifts...")
        q_find_shifts()
    end

    imgui.SameLine()
    if imgui.Button("Get Next") then
        shift_messages = {}
        q_log("Calculating next shift...")
        q_find_shift(get_current_iter())
    end

    imgui.SameLine()
    if imgui.Button("Get Prior") then
        shift_messages = {}
        if curr_iter > 0 then
            q_log("Deducing most recent shift...")
            q_find_shift(curr_iter-1)
        else
            GamePrint("No shifts have been made")
            table.insert(shift_messages, "No shifts have been made")
        end
    end

    -- Display the current shift index
    imgui.Text(("Current shift iteration is %s"):format(curr_iter))

    -- Display what shifts the user has requested
    local prev_c = math.floor(q_setting_get("previous_count"))
    local next_c = math.floor(q_setting_get("next_count"))
    local prev_f = "%s previous shifts"
    local next_f = "%s pending shifts"
    local prev_text = string.format(prev_f, prev_c)
    local next_text = string.format(next_f, next_c)
    if prev_c < 0 then
        prev_text = string.format(prev_f, "all")
    elseif prev_c == 0 then
        prev_text = string.format(prev_f, "zero")
    elseif prev_c == 1 then
        prev_text = "one previous shift"
    end
    if next_c < 0 then
        next_text = string.format(next_f, "all")
    elseif next_c == 0 then
        next_text = string.format(next_f, "zero")
    elseif next_c == 1 then
        prev_text = "one pending shift"
    end
    imgui.Text(("Displaying %s and %s"):format(prev_text, next_text))

    -- Display all messages
    for index, msg in ipairs(shift_messages) do
        imgui.Text(msg)
    end
end

-- We don't presently use these functions, but they're here if we ever do
-- function OnWorldInitialized() end
-- function OnModPostInit() end
-- function OnPlayerSpawned(player_entity) end

local imgui = load_imgui({version="1.1.0", mod="FungalShiftQuery"})

-- The actual driving code, executed once per frame after world update
function OnWorldPostUpdate()
    local window_flags = imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.MenuBar
    if q_get_enabled() then
        if imgui.Begin("Fungal Shifts", nil, window_flags) then
            q_imgui_build_menu(imgui)
            q_imgui_build(imgui)
            imgui.End()
        end
    end
end

-- vim: set ts=4 sts=4 sw=4:
