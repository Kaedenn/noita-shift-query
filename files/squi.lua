--[[
-- The Shift Query UI object
--]]

-- FIXME: 353335970 Shift 19 is Acid -> Acid
-- TODO: Display all icons for multi-material shifts
-- TODO: Draw material tags in hover

dofile_once("mods/shift_query/files/common.lua")
dofile_once("mods/shift_query/files/query.lua")
dofile_once("mods/shift_query/files/lib/feedback.lua")
dofile_once("mods/shift_query/files/constants.lua")
smallfolk = dofile_once("mods/shift_query/files/lib/smallfolk.lua")
APLC = dofile_once("mods/shift_query/files/aplc.lua")

RARE_MAT_COLOR = Feedback.colors.yellow_light

SQ = {
    mat_colors = {
        midas_precursor = {0.14, 0.24, 1},
        magic_liquid_hp_regeneration_unstable = {0.63, 0.95, 0.5},
    },

    --[[ Initialize SQ ]]
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

    --[[ Deduce the shift range (start, end-1)
    -- @return start_index, end_index
    --]]
    get_range = function(self)
        local curr_iter = get_curr_iter()
        local range_prev = math.floor(q_setting_get(SETTING_PREVIOUS))
        local range_next = math.floor(q_setting_get(SETTING_NEXT))
        local idx_start, idx_end = 0, MAX_SHIFTS
        if range_prev >= 0 then
            idx_start = math.max(curr_iter - range_prev, 0)
        end
        if range_next >= 0 then
            idx_end = math.min(curr_iter + range_next, MAX_SHIFTS)
        end
        return idx_start, idx_end
    end,

    --[[ Display either an AP or an LC recipe ]]
    print_aplc = function(self, mat, prob, combo)
        local msg_in_presence = {color="lightgray", "in the presence of"}
        local msg_and = {color="lightgray", "and"}
        local str_success = "is (%d%% success rate)"
        if q_setting_get(SETTING_TERSE) then
            msg_in_presence[1] = "with"
            str_success = "(%d%%)"
        end

        self._fb:add({
            {
                color=self.mat_colors[mat] or Feedback.colors.white,
                image=material_get_icon(mat),
                hover_text=get_hover_for(mat),
                hover_wrap=HOVER_WRAP,
                maybe_localize_material(mat),
            },
            str_success:format(prob)
        })
        local msgs = {}
        for _, entry in ipairs(combo) do
            table.insert(msgs, {
                image=material_get_icon(entry),
                hover_text=get_hover_for(entry),
                hover_wrap=HOVER_WRAP,
                maybe_localize_material(entry),
            })
        end
        local mode = q_setting_get(SETTING_LOCALIZE)
        if mode == FORMAT_INTERNAL then
            self._fb:add({"  ", msgs[1], msgs[2], msgs[3]})
        elseif mode == FORMAT_LOCALE then
            self._fb:add({"  ", msgs[2], msg_in_presence, msgs[1], msg_and, msgs[3]})
        else
            self._fb:add({"  ", msgs[2], msg_in_presence})
            self._fb:add({"  ", msgs[1], msg_and, msgs[3]})
        end
    end,

    --[[ Determine and format a single shift ]]
    query = function(self, index)
        local absolute = q_setting_get(SETTING_ABSOLUTE)
        local terse = q_setting_get(SETTING_TERSE)
        local iter = get_curr_iter()
        local shift_candidates = sq_get_abs(index)
        local which_msg = format_relative(iter, index, {
            next_shift="green",
            future_shift="cyan",
            past_shift="red_light",
        })
        local arrow_str = {color="lightgray", "->"}
        for attempt, shift in ipairs(shift_candidates) do
            q_logf("shift[%d][%d]=%s", iter, attempt, smallfolk.dumps(shift))
            local mat_from, mat_to = format_shift(shift)
            local rare_from, rare_to = sq_is_rare_shift(shift, nil)
            local msg_from, msg_to = {mat_from}, {mat_to}
            if rare_from then msg_from.color = RARE_MAT_COLOR end
            if rare_to then msg_to.color = RARE_MAT_COLOR end

            local line = {}
            if absolute then
                if not terse then
                    table.insert(which_msg, 1, "shift") -- To get the color of the shift
                end
                table.insert(line, which_msg)
                if not terse then
                    table.insert(line, {color="lightgray", "is"})
                end
            else
                table.insert(line, which_msg)
                if not terse then
                    table.insert(line, {color="lightgray", "shift is"})
                end
            end
            table.insert(line, msg_from)
            table.insert(line, arrow_str)
            table.insert(line, msg_to)
            if attempt > 1 then
                table.insert(line, {color="cyan", "if above shift fails"})
            end
            self._fb:add(line)
            if q_logging() then self._fb:add(smallfolk.dumps(line)) end

            local show_greed = false
            if shift.to.flask then
                if shift.to.greedy_mat == "gold" then show_greed = true end
                if q_setting_get(SETTING_GREED) then show_greed = true end
            end
            if show_greed then
                local gold_msg = {
                    color="lightgray",
                    {
                        image=material_get_icon("gold"),
                        hover_text=get_hover_for("gold"),
                        hover_wrap=HOVER_WRAP,
                        color=RARE_MAT_COLOR,
                    },
                    {
                        image=material_get_icon("grass_holy"),
                        hover_text=get_hover_for("grass_holy"),
                        hover_wrap=HOVER_WRAP,
                        color=RARE_MAT_COLOR,
                    },
                    "greedy shift is"
                }
                local target_msg = {
                    color="yellow",
                    image=material_get_icon(shift.to.greedy_mat),
                    hover_text=get_hover_for(shift.to.greedy_mat),
                    hover_wrap=HOVER_WRAP,
                    maybe_localize_material(shift.to.greedy_mat),
                }
                line = {which_msg, gold_msg, msg_from, arrow_str, target_msg}
                if not terse then
                    table.insert(line, {
                        color="lightgray",
                        hover_text=("When holding %s or %s"):format(
                            maybe_localize_material("gold"),
                            maybe_localize_material("grass_holy")),
                        hover_wrap=HOVER_WRAP,
                        "when holding a pouch of gold"
                    })
                end
                self._fb:add(line)
                if q_logging() then self._fb:add(smallfolk.dumps(line)) end
            end
        end
    end,

    --[[ Determine and format all selected shifts ]]
    query_all = function(self)
        if q_setting_get(SETTING_APLC) then
            self:query_aplc()
        end
        local idx_start, idx_end = self:get_range()
        q_logf("Querying shifts between %d and %d", idx_start, idx_end)
        for iter = idx_start, idx_end - 1 do
            q_logf("Querying shift %s", iter)
            self:query(iter)
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

    --[[ Print the shift map to the Feedback object ]]
    print_shift_map = function(self)
        local mode = q_setting_get(SETTING_LOCALIZE)
        for _, matpair in ipairs(self:get_shift_map()) do
            local mat_from, mat_to = unpack(matpair)
            local from_loc = MatLib:get(mat_from) or {}
            local from_loc_l = (from_loc.local_name or mat_from):lower()
            local to_loc = MatLib:get(mat_to) or {}
            local to_loc_l = (to_loc.local_name or mat_to):lower()
            local from_str, to_str = mat_from, mat_to
            if mode == FORMAT_LOCALE then
                from_str = from_loc_l
                to_str = to_loc_l
            elseif mode == FORMAT_BOTH then
                from_str = ("%s [%s]"):format(from_loc_l, mat_from)
                to_str = ("%s [%s]"):format(to_loc_l, mat_to)
            end
            self._fb:draw_line({
                {
                    color="green",
                    image=material_get_icon(mat_from),
                    hover_text=get_hover_for(mat_from),
                    hover_wrap=HOVER_WRAP,
                    from_str,
                },
                "became",
                {
                    color="green",
                    image=material_get_icon(mat_to),
                    hover_text=get_hover_for(mat_to),
                    hover_wrap=HOVER_WRAP,
                    to_str,
                }
            })
        end
    end,

    --[[ Format the cooldown timer ]]
    format_cooldown = function(self)
        local last_shift_frame = get_last_shift_frame()
        local cooldown = get_cooldown_sec()
        if last_shift_frame > -1 and cooldown > 0 then
            return format_duration(cooldown)
        end
        return nil
    end,

    --[[ Draw the menu bar using Noita-Dear-Imgui ]]
    draw_menu_imgui = function(self)
        local imgui = self._imgui
        local function menu_toggle(name, setting, f_func)
            if not f_func then f_func = f_show end
            local curr = q_setting_get(setting)
            local disp_str = f_func(not curr) .. " " .. name
            if imgui.MenuItem(disp_str) then
                q_setting_set(setting, not curr)
            end
        end
        if imgui.BeginMenuBar() then
            if imgui.BeginMenu("Actions") then
                if imgui.MenuItem("Force Refresh") then
                    self:refresh()
                end

                local debugging_str = f_enable(not q_logging())
                if imgui.MenuItem(debugging_str .. " Debugging") then
                    q_set_logging(not q_logging())
                end

                if imgui.MenuItem("Close") then
                    GamePrint("UI closed; re-open using the Mod Settings window")
                    q_disable_gui()
                end
                imgui.Separator()

                if imgui.MenuItem("Copy World Seed") then
                    local seed = tonumber(StatsGetValue("world_seed"))
                    imgui.SetClipboardText(seed)
                    GamePrint(("World Seed %s copied to the clipboard"):format(seed))
                end
                imgui.EndMenu()
            end

            if imgui.BeginMenu("Shifts") then
                local entries = {
                    {"Prior Shifts", SETTING_PREVIOUS},
                    {"Pending Shifts", SETTING_NEXT},
                }
                local choices = {
                    {"Show All", tostring(ALL_SHIFTS)},
                    {"Show One", tostring(1)},
                    {"Show None", tostring(0)},
                }
                for _, entry in ipairs(entries) do
                    local ename, evar = unpack(entry)
                    if imgui.BeginMenu(ename) then
                        for _, choice in ipairs(choices) do
                            local cname, cval = unpack(choice)
                            if imgui.MenuItem(cname) then
                                q_setting_set(evar, cval)
                            end
                        end
                        imgui.EndMenu()
                    end
                end
                imgui.EndMenu()
            end

            if imgui.BeginMenu("Display") then
                local i18n_conf = q_setting_get(SETTING_LOCALIZE)
                if i18n_conf ~= FORMAT_LOCALE then
                    if imgui.MenuItem("Show Translated Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_LOCALE)
                    end
                end
                if i18n_conf ~= FORMAT_INTERNAL then
                    if imgui.MenuItem("Show Internal Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_INTERNAL)
                    end
                end
                if i18n_conf ~= FORMAT_BOTH then
                    if imgui.MenuItem("Show Translated & Internal Names") then
                        q_setting_set(SETTING_LOCALIZE, FORMAT_BOTH)
                    end
                end
                imgui.Separator()

                local expand_opt = q_setting_get(SETTING_EXPAND)
                if expand_opt == EXPAND_ONE then
                    if imgui.MenuItem("Show All Source Materials") then
                        q_setting_set(SETTING_EXPAND, EXPAND_ALL)
                    end
                else
                    if imgui.MenuItem("Show Primary Source Material") then
                        q_setting_set(SETTING_EXPAND, EXPAND_ONE)
                    end
                end
                imgui.Separator()

                menu_toggle("Shift Log", SETTING_REAL, f_show)
                menu_toggle("AP/LC Recipes", SETTING_APLC, f_show)
                menu_toggle("Greedy Shifts", SETTING_GREED, f_show)
                imgui.Separator()

                menu_toggle("Colors", SETTING_COLOR, f_enable)
                menu_toggle("Images", SETTING_IMAGES, f_enable)
                menu_toggle("Absolute Numbers", SETTING_ABSOLUTE, f_enable)
                menu_toggle("Shorter Messages", SETTING_TERSE, f_enable)
                imgui.EndMenu()
            end
            imgui.EndMenuBar()
        end
    end,

    --[[ Draw the main window using Notia-Dear-ImGui ]]
    draw_window_imgui = function(self)
        local iter = get_curr_iter()

        if self:check_update() then
            self:refresh()
        end

        self._fb:configure("color", q_setting_get(SETTING_COLOR))
        self._fb:configure("images", q_setting_get(SETTING_IMAGES))
        self._fb:configure("debug", q_logging())

        -- Draw the current shift iteration and cooldown (if there's been a shift)
        if iter > 0 then
            self._imgui.Text(("Shift: %s"):format(iter))
            self._imgui.SameLine()
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
        self._fb:draw_line({
            "Displaying",
            {color="green", next_text},
            "and",
            {color="green", prev_text}
        })

        if q_setting_get(SETTING_REAL) then
            self:print_shift_map()
        end

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

-- vim: set ts=4 sts=4 sw=4:
