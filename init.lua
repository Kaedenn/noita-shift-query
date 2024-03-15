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

dofile_once("mods/shift_query/files/common.lua")
dofile_once("mods/shift_query/files/materials.lua")
dofile_once("mods/shift_query/files/query.lua")
dofile_once("mods/shift_query/lib/feedback.lua")
dofile_once("mods/shift_query/files/constants.lua")
APLC = dofile_once("mods/shift_query/files/aplc.lua")

MAT_AP = "midas_precursor"
MAT_LC = "magic_liquid_hp_regeneration_unstable"

SQ = {
    new = function(self, imgui)
        self._imgui = imgui
        self._fb = Feedback:init(imgui)
        self._iter_track = -1   -- used for update detection
        self._frame_track = -1  -- used for update detection
        self._force_update = false
        return self
    end,

    --[[ Refresh and re-query everything ]]
    refresh = function(self)
        self._fb:clear()
        q_log("Calculating shifts...")
        self:query_all()
    end,

    --[[ Deduce {first_shift_index, last_shift_index} range ]]
    get_range = function(self)
        local curr_iter = get_curr_iter()
        local range_prev = math.floor(q_setting_get(SETTING_PREVIOUS))
        local range_next = math.floor(q_setting_get(SETTING_NEXT))
        q_logf("pcount=%s, ncount=%s, curr=%s", range_prev, range_next, curr_iter)
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

    --[[ Format the final shift line ]]
    format_final = function(self, which, source, dest)
        return ("%s shift is %s -> %s"):format(which, source, dest)
    end,

    --[[ Display either an AP or an LC recipe ]]
    print_aplc = function(self, mat, prob, combo)
        local result = maybe_localize_material(mat)
        local mat1 = maybe_localize_material(combo[1])
        local mat2 = maybe_localize_material(combo[2])
        local mat3 = maybe_localize_material(combo[3])
        self._fb:addf("%s is (%.2f%% success rate)", result, prob)
        local mode = q_setting_get(SETTING_LOCALIZE)
        if mode == FORMAT_INTERNAL then
            self._fb:addf("  %s, %s, %s", mat1, mat2, mat3)
        elseif mode == FORMAT_LOCALE then
            self._fb:addf("  %s, in the presence of %s and %s", mat2, mat1, mat3)
        else
            self._fb:addf("  %s, in the presence of", mat2)
            self._fb:addf("  %s and %s", mat1, mat3)
        end
    end,

    --[[ Determine and format a single shift ]]
    query = function(self, index)
        q_logf("query(%s)", index)
        local iter = get_curr_iter()
        local shift = sq_get_abs(index)
        local which_msg = format_relative(iter, index)
        for _, pair in ipairs(format_shift(shift)) do
            local line = self:format_final(which_msg, pair[1], pair[2])
            q_log(line)
            self._fb:add(line)
        end
    end,

    --[[ Determine and format all selected shifts ]]
    query_all = function(self)
        if q_setting_get(SETTING_APLC) then
            self:query_aplc()
        end
        local bounds = self:get_range()
        q_logf("Querying shifts %s to %s", bounds.first, bounds.last)
        local iter = bounds.first
        while iter <= bounds.last do
            q_logf("Querying shift %s", iter)
            self:query(iter)
            iter = iter + 1
        end
    end,

    --[[ Determine the AP / LC recipes ]]
    query_aplc = function(self)
        if not APLC then
            self._fb:add("APLC API not available; sorry")
            return
        end
        local lc_combo, ap_combo, lc_prob, ap_prob = APLC.get_recipe()
        if not lc_combo or not ap_combo then
            self._fb:add("Failed to determine AP/LC recipes")
            return
        end
        self:print_aplc(MAT_AP, ap_prob, ap_combo)
        self:print_aplc(MAT_LC, lc_prob, lc_combo)
    end,

    --[[ Determine if we should refresh the shift list ]]
    check_update = function(self)
        if self._force_update then
            self._force_update = false
            return true
        end
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
                local i18n_conf = q_setting_get(SETTING_LOCALIZE)
                if i18n_conf ~= FORMAT_LOCALE then
                    if self._imgui.MenuItem("Show Local Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_LOCALE)
                        self._force_update = true
                    end
                end
                if i18n_conf ~= FORMAT_INTERNAL then
                    if self._imgui.MenuItem("Show Internal Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_INTERNAL)
                        self._force_update = true
                    end
                end
                if i18n_conf ~= FORMAT_BOTH then
                    if self._imgui.MenuItem("Show Local & Internal Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_BOTH)
                        self._force_update = true
                    end
                end

                self._imgui.Separator()
                local aplc_str = f_enable(not q_setting_get(SETTING_APLC))
                if self._imgui.MenuItem(aplc_str .. " AP/LC Recipes") then
                    q_setting_set(SETTING_APLC, not q_setting_get(SETTING_APLC))
                    self._force_update = true
                end

                self._imgui.Separator()
                local log_str = f_enable(not q_logging())
                if self._imgui.MenuItem(log_str .. " Debugging") then
                    q_set_logging(not q_logging())
                end
                if self._imgui.MenuItem("Clear") then
                    self._fb:clear()
                end
                if self._imgui.MenuItem("Close") then
                    q_disable_gui()
                end
                self._imgui.EndMenu()
            end

            if self._imgui.BeginMenu("Display") then
                if self._imgui.BeginMenu("Prior Shifts") then
                    if self._imgui.MenuItem("Show All") then
                        q_setting_set(SETTING_PREVIOUS, tostring(ALL_SHIFTS))
                        self._force_update = true
                    end
                    if self._imgui.MenuItem("Show One") then
                        q_setting_set(SETTING_PREVIOUS, tostring(1))
                        self._force_update = true
                    end
                    self._imgui.EndMenu()
                end
                if self._imgui.BeginMenu("Pending Shifts") then
                    if self._imgui.MenuItem("Show All") then
                        q_setting_set(SETTING_NEXT, tostring(ALL_SHIFTS))
                        self._force_update = true
                    end
                    if self._imgui.MenuItem("Show Next") then
                        q_setting_set(SETTING_NEXT, tostring(1))
                        self._force_update = true
                    end
                    self._imgui.EndMenu()
                end
                self._imgui.EndMenu()
            end
            self._imgui.EndMenuBar()
        end
    end,

    --[[ Draw the main window ]]
    draw_window = function(self)
        self:_draw_window_main()
    end,

    --[[ Draw the main window content ]]
    _draw_window_main = function(self)
        local iter = get_curr_iter()

        -- Draw a helpful "refresh now" button
        if self._imgui.Button("Refresh Shifts") then
            self:refresh()
        end

        if self:check_update() then
            self:refresh()
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
        local prev_c = math.floor(q_setting_get(SETTING_PREVIOUS))
        local next_c = math.floor(q_setting_get(SETTING_NEXT))
        local next_text = f_shift_count(next_c, "pending")
        local prev_text = f_shift_count(prev_c, "previous")
        self._imgui.Text(("Displaying %s and %s"):format(prev_text, next_text))

        self._fb:draw_box()
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
    imgui = load_imgui({version="1.3.0", mod="FungalShiftQuery"})
    query = SQ:new(imgui)

    -- Fix problem with contradicting localize options (boolean / string)
    local localize = q_setting_get(SETTING_LOCALIZE)
    if localize ~= FORMAT_LOCALE then
        if localize ~= FORMAT_INTERNAL then
            if localize ~= FORMAT_BOTH then
                q_setting_set(SETTING_LOCALIZE, FORMAT_LOCALE)
            end
        end
    end
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

function OnPlayerSpawned(player_entity)
    if query ~= nil then
        query:refresh()
    end
end

-- vim: set ts=4 sts=4 sw=4:
