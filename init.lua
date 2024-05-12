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
-- material probability tables change or if the shift logic itself
-- changes.
--
-- PLANNED FEATURES
--
-- Add either flask or pouch icon next to each material with the
-- material's CellData color (parse "data/materials.xml").
--
-- Allow usage without Noita-Dear-ImGui using an alternate GUI library.
-- Can use gusgui from https://github.com/ofoxsmith/gusgui
--
-- Add "fungal_shift_ui_icon" to the ImGui window.

dofile_once("mods/shift_query/files/common.lua")
dofile_once("mods/shift_query/files/query.lua")
dofile_once("mods/shift_query/files/lib/feedback.lua")
dofile_once("mods/shift_query/files/constants.lua")
APLC = dofile_once("mods/shift_query/files/aplc.lua")

RARE_MAT_COLOR = Feedback.colors.yellow_light

SQ = {
    mat_colors = {
        midas_precursor = {0.14, 0.24, 1},
        magic_liquid_hp_regeneration_unstable = {0.63, 0.95, 0.5},
    },

    new = function(self, imgui)
        self._imgui = imgui
        self._fb = Feedback:init(imgui)
        self._iter_track = -1   -- used for update detection
        self._frame_track = -1  -- used for update detection
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

        q_logf("start=%s, end=%s", idx_start, idx_end)
        return {first=idx_start, last=idx_end}
    end,

    --[[ Display either an AP or an LC recipe ]]
    print_aplc = function(self, mat, prob, combo)
        local result = maybe_localize_material(mat)
        local mat1 = maybe_localize_material(combo[1])
        local mat2 = maybe_localize_material(combo[2])
        local mat3 = maybe_localize_material(combo[3])
        local color = self.mat_colors[mat] or {1, 1, 1}
        self._fb:add({{result, color=color}, ("is (%d%% success rate)"):format(prob)})
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
        q_logf("query(%d)", index)
        local iter = get_curr_iter()
        local shift = sq_get_abs(index)
        local which_msg = format_relative(iter, index, {
            next_shift="green",
            future_shift="cyan",
            past_shift="red_light",
        })
        for idx, pair in ipairs(format_shift(shift)) do
            q_logf("pair[%d]={%s, %s}", idx, pair[1], pair[2])
            local rare_from, rare_to = sq_is_rare_shift(shift, nil)
            local str_from = pair[1]
            local str_to = pair[2]
            if rare_from then
                str_from = {color=RARE_MAT_COLOR, pair[1]}
            end
            if rare_to then
                str_to = {color=RARE_MAT_COLOR, pair[2]}
            end

            self._fb:add({
                which_msg, 
                {color="lightgray", "shift is"},
                str_from,
                {color="lightgray", "->"},
                str_to
            })
            local show_greed = false
            if shift.to.flask then
                if shift.to.greedy_mat == "gold" then show_greed = true end
                if q_setting_get(SETTING_GREED) then show_greed = true end
            end
            if show_greed then
                self._fb:add({
                    which_msg,
                    {color="lightgray", "greedy shift is"},
                    str_from,
                    {color="lightgray", "->"},
                    {color="yellow", shift.to.greedy_mat},
                    {color="lightgray", "when holding a pouch of gold"},
                })
            end
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
        if q_is_update_forced() then
            q_clear_force_update()
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

    --[[ Obtain the actual list of shifted materials ]]
    get_shift_map = function(self)
        local world = EntityGetWithTag("world_state")[1]
        local state = EntityGetComponent(world, "WorldStateComponent")[1]
        local shifts = ComponentGetValue2(state, "changed_materials")
        local shift_pairs = {}
        for idx = 1, #shifts, 2 do
            local mat1 = shifts[idx]
            local mat2 = shifts[idx+1]
            q_logf("shift %d shifted %s to %s", (idx+1)/2, mat1, mat2)
            table.insert(shift_pairs, {mat1, mat2})
        end
        return shift_pairs
    end,

    --[[ Format the cooldown timer ]]
    format_cooldown = function(self)
        local last_shift_frame = get_last_shift_frame()
        local cooldown = get_cooldown_sec()
        if last_shift_frame > -1 then
            if cooldown > 0 then
                return format_duration(cooldown)
            end
        end
        return nil
    end,

    --[[ Draw the menu bar using Noita-Dear-Imgui ]]
    draw_menu_imgui = function(self)
        if self._imgui.BeginMenuBar() then
            if self._imgui.BeginMenu("Actions") then
                if self._imgui.MenuItem("Refresh") then
                    self:refresh()
                end
                self._imgui.Separator()

                local i18n_conf = q_setting_get(SETTING_LOCALIZE)
                if i18n_conf ~= FORMAT_LOCALE then
                    if self._imgui.MenuItem("Show Local Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_LOCALE)
                    end
                end
                if i18n_conf ~= FORMAT_INTERNAL then
                    if self._imgui.MenuItem("Show Internal Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_INTERNAL)
                    end
                end
                if i18n_conf ~= FORMAT_BOTH then
                    if self._imgui.MenuItem("Show Local & Internal Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_BOTH)
                    end
                end

                self._imgui.Separator()
                local expand_opt = q_setting_get(SETTING_EXPAND)
                if expand_opt == EXPAND_ONE then
                    if self._imgui.MenuItem("Show All Source Materials") then
                        q_setting_set(SETTING_EXPAND, EXPAND_ALL)
                    end
                else
                    if self._imgui.MenuItem("Show Primary Source Material") then
                        q_setting_set(SETTING_EXPAND, EXPAND_ONE)
                    end
                end

                self._imgui.Separator()
                local real_str = f_show(not q_setting_get(SETTING_REAL))
                if self._imgui.MenuItem(real_str .. " Shift Log") then
                    q_setting_set(SETTING_REAL, not q_setting_get(SETTING_REAL))
                end

                local aplc_str = f_show(not q_setting_get(SETTING_APLC))
                if self._imgui.MenuItem(aplc_str .. " AP/LC Recipes") then
                    q_setting_set(SETTING_APLC, not q_setting_get(SETTING_APLC))
                end

                local greed_str = f_show(not q_setting_get(SETTING_GREED))
                if self._imgui.MenuItem(greed_str .. " Greedy Shifts") then
                    q_setting_set(SETTING_GREED, not q_setting_get(SETTING_GREED))
                end

                self._imgui.Separator()
                if self._imgui.MenuItem("Close") then
                    GamePrint("UI closed; re-open using the Mod Settings window")
                    q_disable_gui()
                end
                self._imgui.EndMenu()
            end

            if self._imgui.BeginMenu("Display") then
                local item_str
                if self._imgui.BeginMenu("Prior Shifts") then
                    if self._imgui.MenuItem("Show All") then
                        q_setting_set(SETTING_PREVIOUS, tostring(ALL_SHIFTS))
                    end
                    if self._imgui.MenuItem("Show One") then
                        q_setting_set(SETTING_PREVIOUS, tostring(1))
                    end
                    self._imgui.EndMenu()
                end
                if self._imgui.BeginMenu("Pending Shifts") then
                    if self._imgui.MenuItem("Show All") then
                        q_setting_set(SETTING_NEXT, tostring(ALL_SHIFTS))
                    end
                    if self._imgui.MenuItem("Show Next") then
                        q_setting_set(SETTING_NEXT, tostring(1))
                    end
                    self._imgui.EndMenu()
                end

                self._imgui.Separator()
                item_str = f_enable(not q_logging())
                if self._imgui.MenuItem(item_str .. " Debugging") then
                    q_set_logging(not q_logging())
                end
                item_str = f_enable(not q_setting_get(SETTING_COLOR))
                if self._imgui.MenuItem(item_str .. " Colors") then
                    q_setting_set(SETTING_COLOR, not q_setting_get(SETTING_COLOR))
                end

                self._imgui.EndMenu()
            end
            self._imgui.EndMenuBar()
        end
    end,

    --[[ Draw the main window using Notia-Dear-ImGui ]]
    draw_window_imgui = function(self)
        local iter = get_curr_iter()

        if self:check_update() then
            self:refresh()
        end

        -- Draw the current shift iteration
        self._imgui.Text(("Shift: %s"):format(iter))
        self._imgui.SameLine()

        -- Draw the current shift cooldown (if there's been a shift)
        if iter > 0 then
            local cooldown = self:format_cooldown()
            if cooldown ~= nil then
                self._imgui.Text(("Cooldown: %s"):format(cooldown))
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

        if q_setting_get(SETTING_REAL) then
            for _, matpair in ipairs(self:get_shift_map()) do
                -- Don't localize the material; shifting affects that
                local from_str, to_str = matpair[1], matpair[2]
                self._fb:draw_line({
                    {color="green", from_str},
                    "became",
                    {color="green", to_str}
                })
            end
        end

        self._fb:configure("color", q_setting_get(SETTING_COLOR))
        self._fb:draw_box()
    end,

    --[[ Draw everything using Noita-Dear-Imgui ]]
    draw_imgui = function(self)
        self:draw_menu_imgui()
        self:draw_window_imgui()
    end,

    --[[ Draw everything using the appropriate GUI library ]]
    draw = function(self)
        self:draw_imgui()
    end,
}

imgui = nil
query = nil

-- function OnWorldInitialized() end

function OnModPostInit()
    if load_imgui then
        imgui = load_imgui({version="1.3.0", mod="FungalShiftQuery"})
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
