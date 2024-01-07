-- Fungal Query by Kaedenn
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
-- material probability tables change or if the shift logic itself
-- changes.
--
-- PLANNED FEATURES
--
-- There's no ImGui fallback behavior, nor are there any diagnostic
-- messages if ImGui isn't available.
--
-- Add "fungal_shift_ui_icon" to the ImGui window.
--
-- Proper internationalization support: custom language definitions for
-- SQ.format_final, the buttons, menus, etc.

dofile("mods/shift_query/common.lua")
dofile("mods/shift_query/materials.lua")
dofile("mods/shift_query/query.lua")
dofile("mods/shift_query/lib/feedback.lua")
dofile("mods/shift_query/l10n.lua")

SQ = {
    new = function(self, imgui)
        self._imgui = imgui
        self._fb = Feedback:init(imgui)
        self._iter_track = -1   -- used for update detection
        self._frame_track = -1  -- used for update detection
        self._override_ui = false -- display the override shift menu?
        self._ovui_mat_source = "water"
        self._ovui_mat_target = "water_swamp"
        return self
    end,

    --[[ Deduce {first_shift_index, last_shift_index} range ]]
    get_range = function(self)
        local curr_iter = get_curr_iter()
        local range_prev = math.floor(q_setting_get("previous_count"))
        local range_next = math.floor(q_setting_get("next_count"))
        q_logf("pcount=%s, ncount=%s, curr=%s", range_prev, range_next, iter)
        local idx_start = curr_iter
        local idx_end = curr_iter
        if range_prev < 0 then
            idx_start = 0
        elseif range_prev > 0 then
            idx_start = math.max(curr_iter - range_prev, 0)
        end

        if range_next < 0 then
            idx_end = MAX_SHIFTS
        elseif range_next > 0 then
            idx_end = math.min(curr_iter + range_next, MAX_SHIFTS)
        end

        q_logf("start = %s, end = %s", idx_start, idx_end)
        return {first=idx_start, last=idx_end}
    end,

    --[[ Format a shift result ]]
    format_shift = function(self, shift)
        local localize = q_setting_get("localize")
        return format_shift_loc(shift, localize)
    end,

    --[[ Format the final shift line ]]
    format_final = function(self, which, source, dest)
        return ("%s shift is %s -> %s"):format(which, source, dest)
    end,

    --[[ Determine and format a single shift ]]
    query = function(self, index)
        q_logf("query(%s)", index)
        local iter = get_curr_iter()
        local shift = sq_get_abs(index)
        local which_msg = format_relative(iter, index)
        for _, pair in ipairs(self:format_shift(shift)) do
            local line = self:format_final(which_msg, pair[1], pair[2])
            q_log(line)
            self._fb:add(line)
        end
    end,

    --[[ Determine and format all selected shifts ]]
    query_all = function(self)
        local bounds = self:get_range()
        q_logf("Querying shifts %s to %s", bounds.first, bounds.last)
        local iter = bounds.first
        while iter <= bounds.last do
            q_logf("Querying shift %s", iter)
            self:query(iter)
            iter = iter + 1
        end
    end,

    --[[ Determine if we should refresh the shift list ]]
    check_update = function(self)
        local iter = get_curr_iter()
        local frame = get_last_shift_frame()
        local draw = false
        if iter ~= self._iter_track then
            q_logf("trigger via iter %s -> %s", self._iter_track, iter)
            self._iter_track = iter
            draw = true
        end
        if frame ~= self._frame_track then
            q_logf("trigger via frame %s -> %s", self._frame_track, frame)
            self._frame_track = frame
            draw = true
        end
        return draw
    end,

    --[[ Draw the menu bar ]]
    draw_menu = function(self)
        if self._imgui.BeginMenuBar() then
            if self._imgui.BeginMenu("Actions") then
                local localize = q_setting_get("localize")
                local loc_str = f_enable(not localize)
                if self._imgui.MenuItem(loc_str .. " Translations") then
                    q_setting_set("localize", not localize)
                    self._iter_track = -1   -- force a refresh
                end
                local log_str = f_enable(not q_logging())
                if self._imgui.MenuItem(log_str .. " Debugging") then
                    q_set_logging(not q_logging())
                end
                if self._imgui.MenuItem("Clear") then
                    self._fb:clear()
                    self._override_ui = false
                end
                if self._imgui.MenuItem("Close") then
                    q_disable_gui()
                end
                --[[ if q_setting_get("override_ui") then
                    self._imgui.Separator()
                    if self._imgui.MenuItem("Do Custom Shift") then
                        self._override_ui = true
                    end
                end--]]
                self._imgui.EndMenu()
            end
            self._imgui.EndMenuBar()
        end
    end,

    --[[ Draw the main window ]]
    draw_window = function(self)
        if self._override_ui ~= true then
            self:_draw_window_main()
        else
            self:_draw_window_override()
        end
    end,

    --[[ Draw the main window content ]]
    _draw_window_main = function(self)
        local iter = get_curr_iter()

        -- Draw a helpful "refresh now" button
        if self._imgui.Button("Refresh Shifts") then
            self._fb:clear()
            q_log("Calculating shifts...")
            self:query_all()
        end

        if self:check_update() then
            self._fb:clear()
            self:query_all()
        end

        -- Draw the feedback window Clear button
        self._imgui.SameLine()
        self._fb:draw_button()

        -- Draw the current shift iteration
        self._imgui.SameLine()
        self._imgui.Text(("Shift: %s"):format(iter))

        -- Draw the current shift cooldown
        local last_shift_frame = get_last_shift_frame()
        local cooldown = get_cooldown_sec()
        if last_shift_frame > -1 then
            if cooldown > 0 then
                self._imgui.Text(("Cooldown: %s"):format(format_duration(cooldown)))
            else
                self._imgui.Text("Cooldown finished")
            end
        end

        -- Display what shifts the user has requested
        local prev_c = math.floor(q_setting_get("previous_count"))
        local next_c = math.floor(q_setting_get("next_count"))
        local next_text = f_shift_count(next_c, "pending")
        local prev_text = f_shift_count(prev_c, "previous")
        self._imgui.Text(("Displaying %s and %s"):format(prev_text, next_text))

        self._fb:draw_box()
    end,

    --[[ Draw the "Do a Custom Shift" window content ]]
    _draw_window_override = function(self)
        if self._imgui.Button("Main Menu") then
            self._override_ui = false
        end

        local ret, res
        ret, res = self._imgui.InputTextWithHint(
            "Source Material", "##force_prev", self._ovui_mat_source)
        if ret then self._ovui_mat_source = res end
        ret, res = self._imgui.InputTextWithHint(
            "Target Material", "##force_prev", self._ovui_mat_target)
        if ret then self._ovui_mat_target = res end

        if self._imgui.Button("Go!") then
            GamePrint(("Shifting '%s' -> '%s'"):format(self._ovui_mat_source, self._ovui_mat_target))
        end
    end,

    --[[ Draw everything ]]
    draw = function(self)
        self:draw_menu()
        self:draw_window()
    end
}

-- function OnWorldInitialized() end
-- function OnModPostInit() end
-- function OnPlayerSpawned(player_entity) end

imgui = nil
query = nil

function OnModPostInit()
    imgui = load_imgui({version="1.2.0", mod="FungalShiftQuery"})
    query = SQ:new(imgui)
end

-- The actual driving code, executed once per frame after world update
function OnWorldPostUpdate()
    local ready = q_get_enabled()
    local window_flags = imgui.WindowFlags.NoFocusOnAppearing
    window_flags = window_flags + imgui.WindowFlags.MenuBar
    window_flags = window_flags + imgui.WindowFlags.NoNavInputs

    if not imgui then
        GamePrint("imgui not initialized")
        ready = false
    end

    if not query then
        GamePrint("query object not initialized")
        ready = false
    end

    if ready then
        if imgui.Begin("Fungal Shifts", nil, window_flags) then
            local res, ret = pcall(query.draw, query)
            if not res then GamePrint(tostring(ret)) end
            imgui.End()
        end
    end
end

-- vim: set ts=4 sts=4 sw=4:
