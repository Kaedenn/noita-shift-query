--[[
-- Shift Query core logic
--
-- Nomenclature used below:
--
-- shift-info: table
--  flask: boolean
--  materials: {string...}
--  name_material: string (optional)
--]]

-- luacheck: globals pick_random_from_table_weighted random_nexti random_create

dofile("mods/shift_query/files/common.lua")
matinfo = dofile("mods/shift_query/files/materials.lua")

MAX_SHIFTS = 20     -- maximum number of shifts according to fungal_shift.lua
COOLDOWN = 60*60*5  -- post shift cooldown; five minutes

-- Get the current shift iteration
function get_curr_iter()
    return tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
end

-- Get the number of frames since the previous shift; -1 if none
function get_last_shift_frame()
    return tonumber(GlobalsGetValue("fungal_shift_last_frame", "-1"))
end

-- Get the pending cooldown in seconds; 0 if none or done
function get_cooldown_sec()
    local last_frame = get_last_shift_frame()
    if last_frame == -1 then return 0 end

    local frame = GameGetFrameNum()
    return (COOLDOWN - (frame - last_frame)) / 60
end

--[[ Determine the numbered shift, where 0 is the first shift
--
-- @param iter number
-- @returns table:{from=shift-info, to=shift-info}
--]]
function sq_get_abs(iter)
    local mats_from = matinfo.get_materials_from()
    local mats_to = matinfo.get_materials_to()
    SetRandomSeed(89346, 42345+iter)
    local rnd = random_create(9123, 58925+iter)

    local mat_from = pick_random_from_table_weighted(rnd, mats_from)
    local mat_to = pick_random_from_table_weighted(rnd, mats_to)

    mat_from.flask = false
    mat_to.flask = false
    if random_nexti(rnd, 1, 100) <= 75 then -- 75% to use a flask
        if random_nexti(rnd, 1, 100) <= 50 then -- 50% which side gets it
            mat_from.flask = true
        else
            mat_to.flask = true
        end
    end

    return {from=mat_from, to=mat_to}
end

--[[ Determine if the shift uses a "rare" material
--
-- @param shift_pair:table {from=shift-info, to=shift-info}
-- @returns rare_from:boolean, rare_to:boolean
--]]
function sq_is_rare_shift(shift_pair, cutoff)
    if type(cutoff) ~= "number" then cutoff = CUTOFF_RARE end
    local mats_from = shift_pair.from
    local mat_to = shift_pair.to
    local rare_from, rare_to = false, false

    for _, material in ipairs(mats_from) do
        if matinfo.is_rare_source(material, cutoff) then
            rare_from = true
        end
    end

    if matinfo.is_rare_target(mat_to.material, cutoff) then
        rare_to = true
    end

    return rare_from, rare_to
end

-- vim: set ts=4 sts=4 sw=4:
